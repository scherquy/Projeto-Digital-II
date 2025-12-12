library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity monociclo is
port(
    reset, clock : in std_logic
);
end entity;

architecture behavior of monociclo is

    -- TIPOS
    type memoria_inst_t is array (0 to 255) of std_logic_vector (19 downto 0);
    type memoria_dados_t is array (0 to 255) of std_logic_vector (15 downto 0);
    type registradores_t is array (0 to 15) of std_logic_vector(15 downto 0);

    --- PC
    signal PC : std_logic_vector (7 downto 0);
    signal opcode : std_logic_vector(3 downto 0);

    -- INICIALIZA A MEMORIA COM INSTRUCOES
    -- MEMORIA DE INSTRUCOES
    signal memoria_instrucoes : memoria_inst_t := (
	-- Formato I: LDI (20 bits: OPCODE(4) | RT(4)
        0 => "01000010000000001010", -- LDI R2, 10
        1 => "01000011000000001010", -- LDI R3, 10
        2 => "01001010000000000101", -- LDI R10, 5
        3 => "01001011000000000010", -- LDI R11, 2
	-- Formato R: ADD, SUB, MUL (20 bits: OPCODE(4) | RD(4) | RS(4) | RT(4) | dont care
        4 => "00010100001000110000", -- ADD R4, R2, R3 (10 + 10)
        5 => "00100101001010100000", -- SUB R5, R2, R10 (10 -5 )
        6 => "00110110101110100000", -- MUL R6, R11, R10 ( 2 * 5 )
	-- Formato I: ADDI, SUBI, MULI, LW, SW (20 bits: OPCODE(4) | RT(4) | RS(4) | IMD(8)   RT <- DADO
        7 => "01010111101100000010", -- ADDI R7, R11, 2 ( 2 + 2)
        8 => "01101000001100001001", -- SUBI R8, R3, 9  ( 10 - 9 )
        9 => "01111001101100000101", -- MULI R9, R11, 5 ( 2 * 5 )
        10 => "10011000000000000100", -- SW do R8 no endereco 4
        11 => "10010010000000001010", -- SW do R2 no endereco 10
        12 => "10001100000000000100", -- LW no R12 do endereco 4
        13 => "10001101000000001010", -- LW no R13 do endereco 10
	-- Formato J: JMP (20 bits: OPCODE(4) | ENDERECO(8) | dont care)
	14 => "10100011001000000000", -- JMP 50        
	-- Formato B: BEQ, BNE (20 bits: OPCODE(4) | RS(4) | RT(4) | DESLOC(8)) 
        50 => "10111101101000001010", -- BEQ R13 == R10 pula para o 50 + 10
        51 => "01101101110100000001", -- SUBI R13, R13, 1 
        52 => "10100011001000000000", -- volta pro loop
        others => (others => '0')
    );

	signal memoria_instrucoes_out : std_logic_vector (19 downto 0);

	---------------------- // MEMORIA DE DADOS \\ --------------------
	signal memoria_dados : memoria_dados_t := (others => (others => '0')); -- zera a memoria de dados
	signal memoria_dados_out : std_logic_vector(15 downto 0);

	---------------------- // BANCO DE REGISTRAORES \\ --------------------
	signal banco_reg : registradores_t := (others => (others => '0')); -- zera o banco de registradores
	signal reg_rd, reg_rs, reg_rt : std_logic_vector(3 downto 0);
	signal valor_rs, valor_rt    : std_logic_vector(15 downto 0); -- valores temporarios para armazenar no banco de registradores
	
    -- SINAIS

    signal imediato, endereco_jump, deslocamento : std_logic_vector(7 downto 0);
    signal offset_ext : std_logic_vector(15 downto 0);

    -- DADOS INTERNOS
    
    signal ula_saida : std_logic_vector(15 downto 0);
    signal mult_res  : std_logic_vector(31 downto 0);
    
begin

    --BUSCA 
    memoria_instrucoes_out <= memoria_instrucoes(conv_integer(PC));

    --DECODIFICACAO
    opcode <= memoria_instrucoes_out(19 downto 16); -- instrucao
    reg_rd <= memoria_instrucoes_out(15 downto 12); -- destino Tipo R
    reg_rs <= memoria_instrucoes_out(11 downto 8);  -- origem 
   
    reg_rt <= memoria_instrucoes_out(7 downto 4) when (opcode="0001" or opcode="0010" or opcode="0011") 
                   else memoria_instrucoes_out(15 downto 12);

    imediato      <= memoria_instrucoes_out(7 downto 0);
    endereco_jump <= memoria_instrucoes_out(15 downto 8);
    deslocamento  <= memoria_instrucoes_out(7 downto 0);
    offset_ext <= "00000000" & imediato; -- extensao do imediato

    --LEITRUA DOS REGISTRADORES
    valor_rs <= banco_reg(conv_integer(reg_rs));
    valor_rt <= banco_reg(conv_integer(reg_rt)); 

    --ACESSO A MEMORIA DE DADOS
    memoria_dados_out <= memoria_dados(conv_integer(valor_rs + offset_ext));

    -- ULA
    mult_res <= valor_rs * valor_rt when opcode = "0011" else --mul
                valor_rs * offset_ext;                        --muli
    
    with opcode select
      ula_saida <= valor_rs + valor_rt       when "0001", --add
                   valor_rs - valor_rt       when "0010", -- sub
                   mult_res(15 downto 0)     when "0011" | "0111", --mul/muli
                   valor_rs + offset_ext     when "0101", -- addi
                   valor_rs - offset_ext     when "0110", -- dubi
                   (others => '0')           when others;

    -- PROCES PRINCIPAL 
    process(reset, clock)
    begin
        if reset = '1' then
            PC <= (others => '0');
            banco_reg <= (others => (others => '0'));
            memoria_dados <= (others => (others => '0')); 
        elsif rising_edge(clock) then
            
            -- deixa R0 = 0
            banco_reg(0) <= (others => '0');
            
            -- incrementa PC
            PC <= PC + 1;

            case opcode is
                -- escreve no banco de registradores
                when "0001" | "0010" | "0011" | "0101" | "0110" | "0111" => 
                    if reg_rd /= "0000" and opcode < "0100" then --tipo R usa reg_rd
                        banco_reg(conv_integer(reg_rd)) <= ula_saida;
                    elsif reg_rt /= "0000" then --tipo I usa reg_rt
                        banco_reg(conv_integer(reg_rt)) <= ula_saida;
                    end if;

                -- LDI
                when "0100" => 
                    if reg_rt /= "0000" then 
                        banco_reg(conv_integer(reg_rt)) <= offset_ext;
                    end if;

                -- LW
                when "1000" => 
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= memoria_dados_out;
                    end if;

                --SW
                when "1001" => 
                    --escreve o valor de rt na mememoria	
                    memoria_dados(conv_integer(valor_rs + offset_ext)) <= valor_rt;

                -- JUMP
                when "1010" => 
                    PC <= endereco_jump;

                --BEQ
                when "1011" => 
                    if valor_rs = valor_rt then
                        PC <= PC + deslocamento; -- deslocamento = pc + memoria de instrucao
                    end if;

                -- BNE
                when "1100" => 
                    if valor_rs /= valor_rt then
                        PC <= PC + deslocamento;
                    end if;

                when others => null;
            end case;
        end if;
    end process;

end architecture;
