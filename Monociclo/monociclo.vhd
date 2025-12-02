library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;



entity monociclo is
port(
    reset, clock : in std_logic --pinos do reset e do clock para o PC
);
end entity;


architecture behavior of monociclo is

      -- PC e MUXES para o PC
     signal PC : std_logic_vector (7 downto 0); --sinal para o PC

    -- MEMORIA DE INSTRUÇAO
     type memoria_inst_t is array (integer range 0 to 255) of std_logic_vector (19 downto 0);
     signal memoria_instrucoes       : memoria_inst_t;
     signal memoria_instrucoes_out   : std_logic_vector (19 downto 0);

    -- CAMPOS DA INSTRUÇAO (OPCODE, REGISTRADORES, VALOR IMD)
     signal opcode    : std_logic_vector(3 downto 0);
     signal reg_rs    : std_logic_vector(3 downto 0);
     signal reg_rt    : std_logic_vector(3 downto 0);
     signal reg_rd    : std_logic_vector(3 downto 0);
     signal imediato  : std_logic_vector(7 downto 0);
     signal endereco_jump : std_logic_vector(7 downto 0);
     signal deslocamento : std_logic_vector(7 downto 0);	

    -- MEMORIA DE DADOS (cada posição 16 bits)
    type memoria_dados_t is array (integer range 0 to 255) of std_logic_vector (15 downto 0);
    signal memoria_dados       : memoria_dados_t;
    signal memoria_dados_out   : std_logic_vector (15 downto 0); -- valor
    signal endereco_mem        : std_logic_vector (15 downto 0);

    -- BANCO DE REGISTRADORES DO MIPS
    type registradores is array (integer range 0 to 15) of std_logic_vector(15 downto 0); -- indices sendo representador por inteiros por isso a conversao
    signal banco_reg : registradores;

    -- SINAIS PARA ULA
    signal saida_ula : std_logic_vector (15 downto 0);
    signal soma      : std_logic_vector (15 downto 0);
    signal sub       : std_logic_vector (15 downto 0);
    signal mult      : std_logic_vector (31 downto 0);
    signal muli	     : std_logic_vector (31 downto 0);
    signal equal     : std_logic;

    -- VALOR CARREGADO DOS REGISTRADORES
    signal valor_rs  : std_logic_vector(15 downto 0);
    signal valor_rt  : std_logic_vector(15 downto 0);

    -- EXTENSÃO DO IMEDIATO
    signal offset_ext : std_logic_vector(15 downto 0);
    signal offset_ext_signed : std_logic_vector(15 downto 0);
    signal init_done : std_logic := '0'; --para teste





begin

    -- buscar instrução
    memoria_instrucoes_out <= memoria_instrucoes(conv_integer(PC)) when reset = '0' else
    (others => '0');

    -- buscar dados da memoria
    memoria_dados_out <= memoria_dados(conv_integer(endereco_mem(7 downto 0)));

    --opcode da memoria de instrucao
    opcode <= memoria_instrucoes_out(19 downto 16);	

  
-- Decodificar instrucao
process(memoria_instrucoes_out, opcode)
begin
    -- resetar campos 
    reg_rs <= (others => '0');
    reg_rt <= (others => '0');
    reg_rd <= (others => '0');
    imediato <= (others => '0');
    endereco_jump <= (others => '0');
    deslocamento <= (others => '0');
    
    case opcode is
        -- Formato R: ADD, SUB, MUL (20 bits: OPCODE(4) | RD(4) | RS(4) | RT(4) | 0000)
        when "0001" | "0010" | "0011" =>  -- ADD, SUB, MUL
            reg_rd <= memoria_instrucoes_out(15 downto 12);
            reg_rs <= memoria_instrucoes_out(11 downto 8);
            reg_rt <= memoria_instrucoes_out(7 downto 4);
        
        -- Formato I: LDI, ADDI, SUBI, MULI, LW, SW (20 bits: OPCODE(4) | RT(4) | RS(4) | IMD(8))
        when "0100" | "0101" | "0110" | "0111" | "1000" | "1001" =>  -- LDI, ADDI, SUBI, MULI, LW, SW
            reg_rt <= memoria_instrucoes_out(15 downto 12);
            reg_rs <= memoria_instrucoes_out(11 downto 8);
            imediato <= memoria_instrucoes_out(7 downto 0);
        
        -- Formato J: JMP (20 bits: OPCODE(4) | ENDERECO(8) | 00000000)
        when "1010" =>  -- JMP
            endereco_jump <= memoria_instrucoes_out(15 downto 8);
        
        -- Formato B: BEQ, BNE (20 bits: OPCODE(4) | RS(4) | RT(4) | DESLOC(8))
        when "1011" | "1100" =>  -- BEQ, BNE
            reg_rs <= memoria_instrucoes_out(15 downto 12);
            reg_rt <= memoria_instrucoes_out(11 downto 8);
            deslocamento <= memoria_instrucoes_out(7 downto 0);
        
        when others =>
            null;
    end case;
end process;




    -- extensão do imediato 
    offset_ext <= "00000000" & imediato;
    offset_ext_signed <= (15 downto 8 => imediato(7)) & imediato;



    -- ler registradores  
    valor_rs <= banco_reg(conv_integer(reg_rs));
    valor_rt <= banco_reg(conv_integer(reg_rt));

    -- ULA
    soma <= valor_rs + valor_rt;
    sub  <= valor_rs - valor_rt;
    mult <= valor_rs * valor_rt;
    muli <= valor_rs * offset_ext;
    equal<= '1' when valor_rs = valor_rt else '0';

    saida_ula <= soma when opcode = "0001" else
                 sub  when opcode = "0010" else
                 mult(15 downto 0) when opcode = "0011" else
		 muli(15 downto 0) when opcode = "0111" else
                 (others => '0');

    -- calcular endereco_mem 
    endereco_mem <= valor_rs + offset_ext;

    --
    process(reset, clock)
    begin
        if reset = '1' then
            PC <= (others => '0');
            banco_reg <= (others => (others => '0')); -- limpa todos no reset
            memoria_dados <= (others => (others => '0'));  -- limpa memória de dados
	    memoria_instrucoes <= (others => (others => '0'));
	               -- TIPO I: | OPCODE(4) | RT(4) | RS(4) | IMD(8)| rt <- imd    
	memoria_instrucoes(0) <= "01000010000000001010"; -- LDI banco_reg(2) <- 10
        memoria_instrucoes(1) <= "01000011000000001010"; -- LDI banco_reg(3) <- 10
	memoria_instrucoes(2) <= "01001010000000000101"; -- LDI banco_reg(10)<- 5
	memoria_instrucoes(3) <= "01001011000000000010"; -- LDI banco_reg(11)<- 2
		       -- TIPO R: | OPCODE(4) | RD(4) | RS(4) | RT(4) | don't care(4)| rd <- rs + rt
	memoria_instrucoes(4) <= "00010100001000110000"; -- ADD banco_reg(4) <-banco_reg(2) + banco_reg(3) |10 + 10| 
        memoria_instrucoes(5) <= "00100101001010100000"; -- SUB banco_reg(5) <- banco_reg(2) - banco_reg(10) | 10 - 5|
        memoria_instrucoes(6) <= "00110110101110100000"; -- MUL banco_reg(6) <- banco_reg(11) * banco_reg(10) | 2 * 5|     



	elsif clock'event and clock = '1' then
           

            -- garante r0 = 0 (sempre)
            banco_reg(0) <= (others => '0');

            case opcode is

                ---------- TIPO R -------------
                when "0001" => -- ADD rd <- rs + rt
                    if reg_rd /= "0000" then
                        banco_reg(conv_integer(reg_rd)) <= saida_ula;
                    end if;
		PC <= PC + 1;

                when "0010" => -- SUB rd <- rs - rt
                    if reg_rd /= "0000" then
                        banco_reg(conv_integer(reg_rd)) <= saida_ula;
                    end if;
		PC <= PC + 1;

                when "0011" => -- MUL rd <- rs * rt
                    if reg_rd /= "0000" then
                        banco_reg(conv_integer(reg_rd)) <= saida_ula;
                    end if;
		PC <= PC + 1;

                ---------- TIPO I -------------
             
		 when "0100" => -- LDI rt <- imediato 
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= offset_ext;
                    end if;
		PC <= PC + 1;

                when "0101" => -- ADDI rt <- rs + imd 
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= valor_rs + offset_ext;
                    end if;
		PC <= PC + 1;

                when "0110" => -- SUBI rt <- rs - imd
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= valor_rs - offset_ext;
                    end if;
		PC <= PC + 1;

                when "0111" => -- MULI rt <- rs * imd
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= saida_ula;
                    end if;
		PC <= PC + 1;

                when "1000" => -- LW rt <- Mem[rs + imd]
                    if reg_rt /= "0000" then
  		
			banco_reg(conv_integer(reg_rt)) <= memoria_dados_out;                  
		    
                    end if;
		PC <= PC + 1;

                when "1001" => -- SW Mem[rs + imd] <- rt
		
		memoria_dados(conv_integer(endereco_mem(7 downto 0))) <= valor_rt; -- limitar da posicao 0 a 255
                
		PC <= PC + 1;
	
                ---------- TIPO J -------------
                when "1010" => -- JMP PC <- IMD
                    PC <= endereco_jump;   -- imediato tem 8 bits; PC tem 8 bits

                when "1011" => -- BEQ (PC <- PC + imd)
                    if equal = '1' then
                        PC <= PC + offset_ext_signed(7 downto 0);  
		    else -- para nao sobrescrever o salto
		    PC <= PC + 1;

                    end if;

                when "1100" => -- BNE
                    if equal = '0' then
                        PC <= PC + offset_ext_signed(7 downto 0);  
		    else
		     PC <= PC + 1;
		     end if;

                when others => PC <= PC + 1;
            end case; 
        end if;
    end process;

 process(clock)
begin
    if rising_edge(clock) and init_done = '0' then
                init_done <= '1';
    end if;
end process;


end architecture;

