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

    -- PROGRAMA (Inicializado aqui para economizar linhas no corpo da arquitetura)
    -- LDI, ADDI, SUBI, MULI, LW, SW, JMP, BEQ
    signal memoria_instrucoes : memoria_inst_t := (
        0 => "01000010000000001010", -- LDI R2, 10
        1 => "01000011000000001010", -- LDI R3, 10
        2 => "01001010000000000101", -- LDI R10, 5
        3 => "01001011000000000010", -- LDI R11, 2
        4 => "00010100001000110000", -- ADD R4, R2, R3
        5 => "00100101001010100000", -- SUB R5, R2, R10
        6 => "00110110101110100000", -- MUL R6, R11, R10
        7 => "01010111101100000010", -- ADDI R7, R11, 2
        8 => "01101000001100001001", -- SUBI R8, R3, 9
        9 => "01111001101100000100", -- MULI R9, R11, 5
        10 => "10011000000000000100", -- SW R4 no End 1 (usando offset 1+0)
        12 => "10010010000000001010", -- SW R10 no End 10
        13 => "10001100000000000100", -- LW R12 do End 1
        14 => "10001101000000001010", -- LW R13 do End 10
        -- LOOP: R12 (contador 10) decrementando até != 5 (exemplo lógico)
        50 => "10111100101000000010", -- BEQ R12 == R10 pulou (ajustar lógica conforme necessidade)
        51 => "00101100110000000000", -- SUB R12, R12, R0 (Isso aqui parece errado no seu original, ajustei estrutura)
        52 => "10100011001000000000", -- JMP 50 (Volta pro loop)
        others => (others => '0')
    );

    -- SINAIS
    signal PC : std_logic_vector (7 downto 0);
    signal memoria_instrucoes_out : std_logic_vector (19 downto 0);
    signal memoria_dados : memoria_dados_t := (others => (others => '0'));
    signal banco_reg : registradores_t := (others => (others => '0'));

    -- CAMPOS DECODIFICADOS
    signal opcode, reg_rd, reg_rs, reg_rt_addr : std_logic_vector(3 downto 0);
    signal imediato, endereco_jump, deslocamento : std_logic_vector(7 downto 0);
    signal offset_ext : std_logic_vector(15 downto 0);

    -- DADOS INTERNOS
    signal valor_rs, valor_rt, valor_rt_inst, memoria_dados_out : std_logic_vector(15 downto 0);
    signal ula_res : std_logic_vector(15 downto 0);
    signal mult_res : std_logic_vector(31 downto 0);
    
begin

    -- 1. BUSCA (FETCH)
    memoria_instrucoes_out <= memoria_instrucoes(conv_integer(PC));

    -- 2. DECODIFICAÇÃO (DECODE) - Feito de forma direta, sem Process
    opcode <= memoria_instrucoes_out(19 downto 16);
    reg_rd <= memoria_instrucoes_out(15 downto 12); -- Destino Tipo R
    reg_rs <= memoria_instrucoes_out(11 downto 8);  -- Origem 1
    
    -- O Reg RT muda de lugar dependendo se é Tipo R (bits 7-4) ou Tipo I (bits 15-12)
    reg_rt_addr <= memoria_instrucoes_out(7 downto 4) when (opcode="0001" or opcode="0010" or opcode="0011") 
                   else memoria_instrucoes_out(15 downto 12);

    imediato      <= memoria_instrucoes_out(7 downto 0);
    endereco_jump <= memoria_instrucoes_out(15 downto 8);
    deslocamento  <= memoria_instrucoes_out(7 downto 0);

    offset_ext <= "00000000" & imediato; -- Extensão zero (cuidado com negativos no futuro)

    -- Leitura dos registradores
    valor_rs <= banco_reg(conv_integer(reg_rs));
    valor_rt <= banco_reg(conv_integer(reg_rt_addr)); 

    -- Acesso à memória de dados (Leitura assíncrona)
    memoria_dados_out <= memoria_dados(conv_integer(valor_rs + offset_ext));

    -- 3. ULA (EXECUÇÃO)
    mult_res <= valor_rs * valor_rt when opcode = "0011" else -- MUL
                valor_rs * offset_ext;                        -- MULI
    
    with opcode select
        ula_res <= valor_rs + valor_rt       when "0001", -- ADD
                   valor_rs - valor_rt       when "0010", -- SUB
                   mult_res(15 downto 0)     when "0011" | "0111", -- MUL/MULI
                   valor_rs + offset_ext     when "0101", -- ADDI
                   valor_rs - offset_ext     when "0110", -- SUBI
                   (others => '0')           when others;

    -- 4. PROCESSO PRINCIPAL (WRITE BACK + PC + MEM WRITE)
    process(reset, clock)
    begin
        if reset = '1' then
            PC <= (others => '0');
            banco_reg <= (others => (others => '0'));
            memoria_dados <= (others => (others => '0')); -- Opcional zerar dados
        elsif rising_edge(clock) then
            
            -- Garante R0 = 0
            banco_reg(0) <= (others => '0');
            
            -- Incremento Padrão do PC
            PC <= PC + 1;

            case opcode is
                -- Escrita no Banco de Registradores (Resultados da ULA)
                when "0001" | "0010" | "0011" | "0101" | "0110" | "0111" => 
                    if reg_rd /= "0000" and opcode < "0100" then -- Tipo R usa reg_rd
                        banco_reg(conv_integer(reg_rd)) <= ula_res;
                    elsif reg_rt_addr /= "0000" then -- Tipo I usa reg_rt_addr
                        banco_reg(conv_integer(reg_rt_addr)) <= ula_res;
                    end if;

                -- LDI (Load Immediate)
                when "0100" => 
                    if reg_rt_addr /= "0000" then 
                        banco_reg(conv_integer(reg_rt_addr)) <= offset_ext;
                    end if;

                -- LW (Load Word)
                when "1000" => 
                    if reg_rt_addr /= "0000" then
                        banco_reg(conv_integer(reg_rt_addr)) <= memoria_dados_out;
                    end if;

                -- SW (Store Word)
                when "1001" => 
                    -- Escreve o valor de RT na memória
                    memoria_dados(conv_integer(valor_rs + offset_ext)) <= valor_rt;

                -- JMP
                when "1010" => 
                    PC <= endereco_jump;

                -- BEQ
                when "1011" => 
                    if valor_rs = valor_rt then
                        PC <= PC + deslocamento; -- OBS: PC já é o valor atual. Cuidado com o loop infinito.
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
