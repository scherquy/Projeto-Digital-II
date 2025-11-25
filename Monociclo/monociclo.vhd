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
    signal opcode   : std_logic_vector(3 downto 0);
    signal reg_rs    : std_logic_vector (3 downto 0);
    signal reg_rt    : std_logic_vector (3 downto 0);
    signal reg_rd    : std_logic_vector (3 downto 0);
    signal imediato  : std_logic_vector (7 downto 0);

    -- MEMORIA DE DADOS (cada posição 16 bits)
    type memoria_dados_t is array (integer range 0 to 255) of std_logic_vector (15 downto 0);
    signal memoria_dados       : memoria_dados_t;
    signal memoria_dados_out   : std_logic_vector (15 downto 0);
    signal endereco_mem        : std_logic_vector (8 downto 0);

    -- BANCO DE REGISTRADORES DO MIPS
    type registradores is array (integer range 0 to 15) of std_logic_vector(15 downto 0);
    signal banco_reg : registradores;

    -- SINAIS PARA ULA
    signal saida_ula : std_logic_vector (15 downto 0);
    signal soma      : std_logic_vector (15 downto 0);
    signal sub       : std_logic_vector (15 downto 0);
    signal mult      : std_logic_vector (31 downto 0);
    signal equal     : std_logic;

    -- VALOR CARREGADO DOS REGISTRADORES
    signal valor_rs  : std_logic_vector(15 downto 0);
    signal valor_rt  : std_logic_vector(15 downto 0);

    -- EXTENSÃO DO IMEDIATO
    signal offset_ext : std_logic_vector(15 downto 0);

begin

    -- buscar instrução
    memoria_instrucoes_out <= memoria_instrucoes(conv_integer(PC));

    -- decodifica campos
    opcode  <= memoria_instrucoes_out(19 downto 16);
    reg_rs  <= memoria_instrucoes_out(15 downto 12);
    reg_rt  <= memoria_instrucoes_out(11 downto 8);
    reg_rd  <= memoria_instrucoes_out(7 downto 4);
    imediato<= memoria_instrucoes_out(7 downto 0);

    -- extensão do imediato 
    offset_ext <= "00000000" & imediato;

    -- ler registradores  
    valor_rs <= banco_reg(conv_integer(reg_rs));
    valor_rt <= banco_reg(conv_integer(reg_rt));

    -- ULA
    soma <= valor_rs + valor_rt;
    sub  <= valor_rs - valor_rt;
    mult <= valor_rs * valor_rt;
    equal<= '1' when valor_rs = valor_rt else '0';

    saida_ula <= soma when opcode = "0001" else
                 sub  when opcode = "0010" else
                 mult(15 downto 0) when opcode = "0011" else
                 (others => '0');

    -- calcular endereco_mem 
    endereco_mem <= valor_rs + offset_ext;

    --
    process(reset, clock)
    begin
        if reset = '1' then
            PC <= (others => '0');
            banco_reg <= (others => (others => '0')); -- limpa todos no reset
        elsif clock'event and clock = '1' then
           
            PC <= PC + 1;

            -- garante r0 = 0 (sempre)
            banco_reg(0) <= (others => '0');

            case opcode is

                ---------- TIPO R -------------
                when "0001" => -- ADD rd <- rs + rt
                    if reg_rd /= "0000" then
                        banco_reg(conv_integer(reg_rd)) <= saida_ula;
                    end if;

                when "0010" => -- SUB rd <- rs - rt
                    if reg_rd /= "0000" then
                        banco_reg(conv_integer(reg_rd)) <= saida_ula;
                    end if;

                when "0011" => -- MUL rd <- rs * rt
                    if reg_rd /= "0000" then
                        banco_reg(conv_integer(reg_rd)) <= saida_ula;
                    end if;

                ---------- TIPO I -------------
                when "0100" => -- LDI rt <- imediato (zero-extend)
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= offset_ext;
                    end if;

                when "0101" => -- ADDI rt <- rs + imd (zero-extend)
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= valor_rs + offset_ext;
                    end if;

                when "0110" => -- SUBI rt <- rs - imd
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= valor_rs - offset_ext;
                    end if;

                when "0111" => -- MULI rt <- rs * imd
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= valor_rs * offset_ext;
                    end if;

                when "1000" => -- LW rt <- Mem[rs + imd]
                    if reg_rt /= "0000" then
                        banco_reg(conv_integer(reg_rt)) <= memoria_dados(conv_integer(endereco_mem));
                    end if;

                when "1001" => -- SW Mem[rs + imd] <- rt
                    memoria_dados(conv_integer(endereco_mem)) <= valor_rt;

                ---------- TIPO J -------------
                when "1010" => -- JMP PC <- IMD
                    PC <= imediato; -- imediato tem 8 bits; PC tem 8 bits

                when "1011" => -- BEQ (PC <- PC + offset se igual)
                    if equal = '1' then
                        PC <= PC + offset_ext;
                    end if;

                when "1100" => -- BNE
                    if equal = '0' then
                        PC <= PC + offset_ext;
		     end if;

                when others =>
                    null;
            end case; -- case opcode
        end if;
    end process;

end architecture;

