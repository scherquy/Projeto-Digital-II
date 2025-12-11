library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity pipeline is
port(
    reset, clock : in std_logic
);
end entity;

architecture behavior of pipeline is

    -- TIPOS
    type memoria_inst_t is array (0 to 255) of std_logic_vector (19 downto 0);
    type memoria_dados_t is array (0 to 255) of std_logic_vector (15 downto 0);
    type registradores_t is array (0 to 15) of std_logic_vector(15 downto 0);


	
    --- PC
    signal PC : std_logic_vector (7 downto 0);
    signal PC_next : std_logic_vector (7 downto 0);
  



    -- INICIALIZA A MEMORIA COM INSTRUCOES E COLOCA ZERO NO RESTANTE
    

    -- MEMORIA DE INSTRUCOES
    signal memoria_instrucoes : memoria_inst_t := (
	-- Formato I: LDI, ADDI, SUBI, MULI, LW, SW (20 bits: OPCODE(4) | RT(4)
        0 => "01000010000000001010", -- LDI R2, 10
        1 => "01000011000000001010", -- LDI R3, 10
        2 => "01001010000000000101", -- LDI R10, 5
        3 => "01001011000000000010", -- LDI R11, 2
	-- Formato R: ADD, SUB, MUL (20 bits: OPCODE(4) | RD(4) | RS(4) | RT(4) | don't care
        4 => "00010100001000110000", -- ADD R4, R2, R3 (10 + 10)
        5 => "00100101001010100000", -- SUB R5, R2, R10 (10 -5 )
        6 => "00110110101110100000", -- MUL R6, R11, R10 ( 2 * 5 )
	-- Formato I: LDI, ADDI, SUBI, MULI, LW, SW (20 bits: OPCODE(4) | RT(4) | RS(4) | IMD(8)   RT <- DADO
        7 => "01010111101100000010", -- ADDI R7, R11, 2 ( 2 + 2)
        8 => "01101000001100001001", -- SUBI R8, R3, 9  ( 10 - 9 ) 	
        9 => "01111001101100000100", -- MULI R9, R11, 5 ( 2 * 5 )
       -- 10 => "10011000000000000100", -- SW R4 no End 1 (usando offset 1+0) (guarda 1)
	--- FALTOU INSTRU?AO NA POSI?AO 11
       -- 12 => "10010010000000001010", -- SW R10 no End 10 (guarda 10)
      --  13 => "10001100000000000100", -- LW R12 do End 1 (1)
      --  14 => "10001101000000001010", -- LW R13 do End 10 (10)
	-- Formato J: JMP (20 bits: OPCODE(4) | ENDERECO(8) | 00000000)
	--15 => "10100011001000000000", -- JMP 50        
	-- LOOP: R12 (contador 10) decrementando ate o 5
	-- Formato B: BEQ, BNE (20 bits: OPCODE(4) | RS(4) | RT(4) | DESLOC(8)) 
      --  50 => "10111101101000001010", -- BEQ R13 == R10  (10 == 5) se for igual pula para o end 60 
     --   51 => "00101101110110000000", -- SUB R13, R13, R10, ( 10 - 1) 
     --   52 => "10100011001000000000", -- JMP 50 (Volta pro loop)
        others => (others => '0')
    );

	


	---------------------- // MEMORIA DE DADOS \\ --------------------
	signal memoria_dados : memoria_dados_t := (others => (others => '0')); -- zera a memoria de dados
	


	---------------------- // BANCO DE REGISTRAORES \\ --------------------
	signal banco_reg : registradores_t := (others => (others => '0')); -- zera o banco de registradores
	
	


 
  

    -------///SINAIS DO PIPELINE \\\------------

    -- EST핯IO IF/ID
    signal IF_ID_instruction : std_logic_vector(19 downto 0);
    
    -- EST핯IO ID/EX (Controle + Dados)
    signal ID_EX_opcode : std_logic_vector(3 downto 0);
    signal ID_EX_reg_rs, ID_EX_reg_rt, ID_EX_reg_rd : std_logic_vector(3 downto 0);
    signal ID_EX_valor_rs, ID_EX_valor_rt : std_logic_vector(15 downto 0);
    signal ID_EX_offset_ext : std_logic_vector(15 downto 0);
    
    -- EST핯IO EX/MEM (Controle + Dados)
    signal EX_MEM_opcode : std_logic_vector(3 downto 0);
    signal EX_MEM_resultado_ula : std_logic_vector(15 downto 0);
    signal EX_MEM_valor_rt : std_logic_vector(15 downto 0); -- Dado para SW
    signal EX_MEM_reg_dest : std_logic_vector(3 downto 0);
    
    -- EST핯IO MEM/WB (Controle + Dados)
    signal MEM_WB_opcode : std_logic_vector(3 downto 0);
    signal MEM_WB_resultado_ula : std_logic_vector(15 downto 0);
    signal MEM_WB_dado_mem : std_logic_vector(15 downto 0); -- Dado lido do LW
    signal MEM_WB_reg_dest : std_logic_vector(3 downto 0);


    


begin

PC_next <= PC + 1;


    -----------------------| LOGICA PIPELINE |-----------------------

   process(reset, clock)
begin
    if reset = '1' then
        PC <= (others => '0');
        banco_reg <= (others => (others => '0'));
        memoria_dados <= (others => (others => '0'));
        
        -- Reset pipeline
        IF_ID_instruction <= (others => '0');
        ID_EX_opcode <= (others => '0');
        ID_EX_reg_rs <= (others => '0');
        ID_EX_reg_rt <= (others => '0');
        ID_EX_reg_rd <= (others => '0');
        ID_EX_valor_rs <= (others => '0');
        ID_EX_valor_rt <= (others => '0');
        ID_EX_offset_ext <= (others => '0');  
        
        EX_MEM_opcode <= (others => '0');
        EX_MEM_resultado_ula <= (others => '0');
        EX_MEM_valor_rt <= (others => '0');
        EX_MEM_reg_dest <= (others => '0');
        
        MEM_WB_opcode <= (others => '0');
        MEM_WB_resultado_ula <= (others => '0');
        MEM_WB_dado_mem <= (others => '0');
        MEM_WB_reg_dest <= (others => '0');
        
    elsif rising_edge(clock) then
        -- Garante R0 = 0
        banco_reg(0) <= (others => '0');  
        
        --------------------------------
        --  (Instruction Fetch)
        --------------------------------
        PC <= PC + 1;  -- Simplificado
        
        
        IF_ID_instruction <= memoria_instrucoes(conv_integer(PC));  
        
        --------------------------------
        -- (Instruction Decode)
        --------------------------------
        ID_EX_opcode <= IF_ID_instruction(19 downto 16);
        ID_EX_reg_rd <= IF_ID_instruction(15 downto 12);
        ID_EX_reg_rs <= IF_ID_instruction(11 downto 8);
        
        
        if IF_ID_instruction(19 downto 16) = "0001" or 
           IF_ID_instruction(19 downto 16) = "0010" or 
           IF_ID_instruction(19 downto 16) = "0011" then
            ID_EX_reg_rt <= IF_ID_instruction(7 downto 4);  -- Tipo R
        else
            ID_EX_reg_rt <= IF_ID_instruction(15 downto 12); -- Tipo I
        end if;
        
        ID_EX_offset_ext <= "00000000" & IF_ID_instruction(7 downto 0);
        
        -- Leitura do banco de registradores
        ID_EX_valor_rs <= banco_reg(conv_integer(ID_EX_reg_rs));
        ID_EX_valor_rt <= banco_reg(conv_integer(ID_EX_reg_rt));
        
        --------------------------------
        --  EX (Execute) - COMPLETO
        --------------------------------
        case ID_EX_opcode is
            when "0001" =>  -- ADD
                EX_MEM_resultado_ula <= ID_EX_valor_rs + ID_EX_valor_rt;
            when "0010" =>  -- SUB
                EX_MEM_resultado_ula <= ID_EX_valor_rs - ID_EX_valor_rt;
            when "0011" =>  -- MUL
                EX_MEM_resultado_ula <= ID_EX_valor_rs * ID_EX_valor_rt;
            when "0100" =>  -- LDI
                EX_MEM_resultado_ula <= ID_EX_offset_ext;
            when "0101" =>  -- ADDI
                EX_MEM_resultado_ula <= ID_EX_valor_rs + ID_EX_offset_ext;
            when "0110" =>  -- SUBI
                EX_MEM_resultado_ula <= ID_EX_valor_rs - ID_EX_offset_ext;
            when "0111" =>  -- MULI
                EX_MEM_resultado_ula <= ID_EX_valor_rs * ID_EX_offset_ext;
            when others =>
                EX_MEM_resultado_ula <= (others => '0');
        end case;
        
        EX_MEM_opcode <= ID_EX_opcode;
        EX_MEM_valor_rt <= ID_EX_valor_rt;
        
        -- Determina registrador destino
        if ID_EX_opcode = "0001" or ID_EX_opcode = "0010" or 
           ID_EX_opcode = "0011" then
            EX_MEM_reg_dest <= ID_EX_reg_rd;  -- Tipo R
        else
            EX_MEM_reg_dest <= ID_EX_reg_rt;  -- Tipo I
        end if;
        
        --------------------------------
        --  MEM (Memory Access)
        --------------------------------
        if EX_MEM_opcode = "1000" then  -- LW
            MEM_WB_dado_mem <= memoria_dados(conv_integer(EX_MEM_resultado_ula(7 downto 0)));
        elsif EX_MEM_opcode = "1001" then  -- SW
            memoria_dados(conv_integer(EX_MEM_resultado_ula(7 downto 0))) <= EX_MEM_valor_rt;
        end if;
        
        MEM_WB_opcode <= EX_MEM_opcode;
        MEM_WB_resultado_ula <= EX_MEM_resultado_ula;
        MEM_WB_reg_dest <= EX_MEM_reg_dest;
        
        --------------------------------
        --  WB (Write Back) 
        --------------------------------
        if MEM_WB_opcode = "0001" or MEM_WB_opcode = "0010" or 
           MEM_WB_opcode = "0011" or MEM_WB_opcode = "0100" or 
           MEM_WB_opcode = "0101" or MEM_WB_opcode = "0110" or 
           MEM_WB_opcode = "0111" then
            if MEM_WB_reg_dest /= "0000" then
                banco_reg(conv_integer(MEM_WB_reg_dest)) <= MEM_WB_resultado_ula;
            end if;
        elsif MEM_WB_opcode = "1000" then  -- LW
            if MEM_WB_reg_dest /= "0000" then
                banco_reg(conv_integer(MEM_WB_reg_dest)) <= MEM_WB_dado_mem;
            end if;
        end if;
        
    end if;
end process; 

end architecture;