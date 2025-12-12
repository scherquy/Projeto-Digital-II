library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity pipeline_mips is
port(
    reset, clock : in std_logic
);
end entity;

architecture behavior of pipeline_mips is

    -- TIPOS (Iguais ao original)
    type memoria_inst_t is array (0 to 255) of std_logic_vector (19 downto 0);
    type memoria_dados_t is array (0 to 255) of std_logic_vector (15 downto 0);
    type registradores_t is array (0 to 15) of std_logic_vector(15 downto 0);

    -- SINAIS GERAIS
    signal PC : std_logic_vector (7 downto 0);
    
    -- BANCO DE REGISTRADORES E MEMORIAS
    signal banco_reg : registradores_t := (others => (others => '0'));
    
    signal memoria_instrucoes : memoria_inst_t := (
        -- Suas instruções originais
        0 => "01000010000000001010", -- LDI R2, 10
        1 => "01000011000000001010", -- LDI R3, 10
        2 => "01001010000000000101", -- LDI R10, 5
        3 => "01001011000000000010", -- LDI R11, 2
        4 => "00010100001000110000", -- ADD R4, R2, R3
        5 => "00100101001010100000", -- SUB R5, R2, R10
        6 => "00110110101110100000", -- MUL R6, R11, R10
        7 => "01010111101100000010", -- ADDI R7, R11, 2
        8 => "01101000001100001001", -- SUBI R8, R3, 9
        9 => "01111001101100000101", -- MULI R9, R11, 5
        10 => "10011000000000000100", -- SW R4 no End 1
        12 => "10010010000000001010", -- SW R10 no End 10
        13 => "10001100000000000100", -- LW R12 do End 1
        14 => "10001101000000001010", -- LW R13 do End 10
        15 => "10100011001000000000", -- JMP 50       
        -- LOOP
        50 => "10111101101000001010", -- BEQ R13 == R10
        51 => "00101101110110000000", -- SUB R13, R13, R10
        52 => "10100011001000000000", -- JMP 50
        others => (others => '0')
    );
    signal memoria_dados : memoria_dados_t := (others => (others => '0'));
    
    -- Sinais de Leitura de Memória (Como no original)
    signal memoria_instrucoes_out : std_logic_vector(19 downto 0); -- Agora sai do IF/ID
    signal memoria_dados_out : std_logic_vector(15 downto 0);      -- Sai do MEM/WB

    -- =======================================================================
    -- REGISTRADORES DE PIPELINE (Necessários para dividir os estágios)
    -- =======================================================================

    -- IF/ID Register
    signal IF_ID_PC   : std_logic_vector(7 downto 0);
    signal IF_ID_Inst : std_logic_vector(19 downto 0); -- Contém a instrução buscada

    -- ID/EX Register
    signal ID_EX_PC        : std_logic_vector(7 downto 0);
    signal ID_EX_Opcode    : std_logic_vector(3 downto 0);
    signal ID_EX_Valor_RS  : std_logic_vector(15 downto 0); -- Antigo valor_rs lido
    signal ID_EX_Valor_RT  : std_logic_vector(15 downto 0); -- Antigo valor_rt lido
    signal ID_EX_Offset    : std_logic_vector(15 downto 0); -- Antigo offset_ext
    signal ID_EX_RegDest   : std_logic_vector(3 downto 0);  -- Quem vai ser escrito
    signal ID_EX_EndJump   : std_logic_vector(7 downto 0);  -- Antigo endereco_jump
    signal ID_EX_Desloc    : std_logic_vector(7 downto 0);  -- Antigo deslocamento

    -- EX/MEM Register
    signal EX_MEM_Opcode    : std_logic_vector(3 downto 0);
    signal EX_MEM_UlaSaida  : std_logic_vector(15 downto 0); -- Resultado da ULA
    signal EX_MEM_Valor_RT  : std_logic_vector(15 downto 0); -- Dado para SW (veio do RT)
    signal EX_MEM_RegDest   : std_logic_vector(3 downto 0);
    
    -- MEM/WB Register
    signal MEM_WB_Opcode    : std_logic_vector(3 downto 0);
    signal MEM_WB_MemOut    : std_logic_vector(15 downto 0); -- Dado lido da memória
    signal MEM_WB_UlaSaida  : std_logic_vector(15 downto 0);
    signal MEM_WB_RegDest   : std_logic_vector(3 downto 0);

    -- SINAIS DE CONTROLE E DECODIFICACAO (Nomes originais)
    signal next_PC : std_logic_vector(7 downto 0);
    signal pcsrc   : std_logic; 
    signal branch_target : std_logic_vector(7 downto 0);
    
    -- Estes sinais agora são extraídos da instrução no estágio DECODE
    signal opcode : std_logic_vector(3 downto 0);
    signal reg_rs, reg_rt, reg_rd : std_logic_vector(3 downto 0);
    signal imediato : std_logic_vector(7 downto 0);
    signal offset_ext : std_logic_vector(15 downto 0);
    signal w_reg_dest_temp : std_logic_vector(3 downto 0); -- Auxiliar para decidir destino
    
begin

    -- =======================================================================
    -- ESTÁGIO 1: IF (Busca)
    -- =======================================================================
    next_PC <= branch_target when pcsrc = '1' else PC + 1;

    -- =======================================================================
    -- ESTÁGIO 2: ID (Decodificação) - USANDO SEUS NOMES
    -- =======================================================================
    -- Recupera a instrução do registrador de pipeline para decodificar
    memoria_instrucoes_out <= IF_ID_Inst; 

    -- As atribuições abaixo são idênticas à lógica do seu monociclo
    opcode <= memoria_instrucoes_out(19 downto 16);
    reg_rd <= memoria_instrucoes_out(15 downto 12);
    reg_rs <= memoria_instrucoes_out(11 downto 8);
    
    reg_rt <= memoria_instrucoes_out(7 downto 4) when (opcode="0001" or opcode="0010" or opcode="0011") 
             else memoria_instrucoes_out(15 downto 12);

    imediato <= memoria_instrucoes_out(7 downto 0);
    
    offset_ext <= "00000000" & imediato; -- Extensao do imediato

    -- Lógica auxiliar para definir quem será gravado no WB (RD ou RT?)
    w_reg_dest_temp <= reg_rd when (opcode="0001" or opcode="0010" or opcode="0011") 
                       else reg_rt;

    -- =======================================================================
    -- PROCESSO DO PIPELINE (CLOCKED)
    -- =======================================================================
    process(reset, clock)
        -- Variáveis locais para simular a ULA e Multiplicador (Sinais "ula_saida" e "mult_res")
        variable ula_saida : std_logic_vector(15 downto 0);
        variable mult_res  : std_logic_vector(31 downto 0);
        -- Variável auxiliar para acesso à memória
        variable end_memoria : integer;
    begin
        if reset = '1' then
            PC <= (others => '0');
            banco_reg <= (others => (others => '0'));
            memoria_dados <= (others => (others => '0'));
            
            -- Reset dos registradores internos do pipeline
            IF_ID_PC <= (others => '0'); IF_ID_Inst <= (others => '0');
            ID_EX_PC <= (others => '0'); ID_EX_Opcode <= (others => '0'); 
            ID_EX_Valor_RS <= (others => '0'); ID_EX_Valor_RT <= (others => '0');
            EX_MEM_Opcode <= (others => '0'); EX_MEM_UlaSaida <= (others => '0');
            MEM_WB_Opcode <= (others => '0');
            
            pcsrc <= '0';
            
        elsif rising_edge(clock) then
            
            -- Garante R0 = 0
            banco_reg(0) <= (others => '0');

            -----------------------------------------------------------
            -- 1. IF: Atualiza PC
            -----------------------------------------------------------
            PC <= next_PC;
            
            -- Escreve no Reg Pipeline IF/ID
            IF_ID_PC   <= PC;
            IF_ID_Inst <= memoria_instrucoes(conv_integer(PC));

            -----------------------------------------------------------
            -- 2. ID: Lê Banco de Registradores e passa para EX
            -----------------------------------------------------------
            ID_EX_PC       <= IF_ID_PC;
            ID_EX_Opcode   <= opcode; -- Seu sinal 'opcode'
            
            -- Leitura dos valores (igual ao sinal 'valor_rs' e 'valor_rt' do monociclo)
            ID_EX_Valor_RS <= banco_reg(conv_integer(reg_rs));
            ID_EX_Valor_RT <= banco_reg(conv_integer(reg_rt));
            
            ID_EX_Offset   <= offset_ext; -- Seu sinal 'offset_ext'
            
            -- Passa endereços para saltos
            ID_EX_EndJump  <= memoria_instrucoes_out(15 downto 8); -- endereco_jump
            ID_EX_Desloc   <= memoria_instrucoes_out(7 downto 0);  -- deslocamento
            ID_EX_RegDest  <= w_reg_dest_temp;

            -----------------------------------------------------------
            -- 3. EX: ULA (Calcula 'ula_saida' e 'mult_res')
            -----------------------------------------------------------
            ula_saida := (others => '0');
            
            -- Prepara multiplicação (mult_res)
            -- ID_EX_Valor_RS é o antigo 'valor_rs' e ID_EX_Valor_RT é 'valor_rt'
            mult_res := ID_EX_Valor_RS * ID_EX_Valor_RT; 

            case ID_EX_Opcode is
                when "0001" => ula_saida := ID_EX_Valor_RS + ID_EX_Valor_RT; -- ADD
                when "0010" => ula_saida := ID_EX_Valor_RS - ID_EX_Valor_RT; -- SUB
                when "0011" => ula_saida := mult_res(15 downto 0);           -- MUL
                when "0100" => ula_saida := ID_EX_Offset;                    -- LDI
                when "0101" => ula_saida := ID_EX_Valor_RS + ID_EX_Offset;   -- ADDI
                when "0110" => ula_saida := ID_EX_Valor_RS - ID_EX_Offset;   -- SUBI
                when "0111" => -- MULI
                    mult_res := ID_EX_Valor_RS * ID_EX_Offset;
                    ula_saida := mult_res(15 downto 0);
                when others => ula_saida := (others => '0'); 
            end case;
            
            -- Calculo endereço para LW/SW (Soma RS + Offset)
            if (ID_EX_Opcode = "1000" or ID_EX_Opcode = "1001") then
                ula_saida := ID_EX_Valor_RS + ID_EX_Offset; 
            end if;

            -- Lógica de Branch/Jump (Controla PCSrc)
            pcsrc <= '0';
            if ID_EX_Opcode = "1010" then -- JMP
                pcsrc <= '1';
                branch_target <= ID_EX_EndJump;
            elsif ID_EX_Opcode = "1011" then -- BEQ
                if ID_EX_Valor_RS = ID_EX_Valor_RT then
                    pcsrc <= '1';
                    branch_target <= ID_EX_PC + ID_EX_Desloc;
                end if;
            elsif ID_EX_Opcode = "1100" then -- BNE
                if ID_EX_Valor_RS /= ID_EX_Valor_RT then
                    pcsrc <= '1';
                    branch_target <= ID_EX_PC + ID_EX_Desloc;
                end if;
            end if;

            -- Escreve no Reg Pipeline EX/MEM
            EX_MEM_Opcode   <= ID_EX_Opcode;
            EX_MEM_UlaSaida <= ula_saida;      -- Guarda resultado da ULA
            EX_MEM_Valor_RT <= ID_EX_Valor_RT; -- Guarda valor p/ store
            EX_MEM_RegDest  <= ID_EX_RegDest;

            -----------------------------------------------------------
            -- 4. MEM: Acesso à Memória de Dados
            -----------------------------------------------------------
            end_memoria := conv_integer(EX_MEM_UlaSaida);

            if EX_MEM_Opcode = "1001" then -- SW
                memoria_dados(end_memoria) <= EX_MEM_Valor_RT;
            end if;

            -- LW (Lê e passa para WB)
            MEM_WB_MemOut <= memoria_dados(end_memoria); -- memoria_dados_out
            
            MEM_WB_Opcode   <= EX_MEM_Opcode;
            MEM_WB_UlaSaida <= EX_MEM_UlaSaida;
            MEM_WB_RegDest  <= EX_MEM_RegDest;

            -----------------------------------------------------------
            -- 5. WB: Escrita no Banco
            -----------------------------------------------------------
            -- Verifica se não é SW, JMP ou Branch
            if (MEM_WB_Opcode /= "1001" and MEM_WB_Opcode /= "1010" and 
                MEM_WB_Opcode /= "1011" and MEM_WB_Opcode /= "1100" and MEM_WB_RegDest /= "0000") then
                
                if MEM_WB_Opcode = "1000" then -- LW
                    banco_reg(conv_integer(MEM_WB_RegDest)) <= MEM_WB_MemOut;
                else -- R-Type ou I-Type
                    banco_reg(conv_integer(MEM_WB_RegDest)) <= MEM_WB_UlaSaida;
                end if;
            end if;

        end if;
    end process;

end architecture;
