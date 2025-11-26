library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity monociclo_tb is
end entity;

architecture tb of monociclo_tb is

    -- sinais para conectar com o DUT
    signal clk_tb   : std_logic := '0';
    signal reset_tb : std_logic := '0';

    -- instanciação do DUT
    component monociclo
    port(
        reset : in std_logic;
        clock : in std_logic
    );
    end component;

begin

    -- DUT
    DUT: monociclo
        port map (
            reset => reset_tb,
            clock => clk_tb
        );

    -------------------------------------------------------------
    -- GERADOR DE CLOCK (Período: 20 ps, ou seja 50 GHz)
    -- altere para 10 ns ou 100 ns se preferir algo mais realista
    -------------------------------------------------------------
    clock_process : process
    begin
        clk_tb <= '0';
        wait for 10 ps;
        clk_tb <= '1';
        wait for 10 ps;
    end process;

    -------------------------------------------------------------
    -- PROCESSO DE ESTÍMULOS
    -------------------------------------------------------------
    stim_proc: process
    begin
        ---------------------------------------------------------
        -- RESET
        ---------------------------------------------------------
        reset_tb <= '1';
        wait for 50 ps;
        reset_tb <= '0';

        ---------------------------------------------------------
        -- CARREGAR INSTRUÇÕES NA MEMÓRIA
        -- OBS: depende do nome da memória no DUT
        ---------------------------------------------------------
        wait for 20 ps;

        DUT.memoria_instrucoes(0) <= "010000010000001010"; -- LDI r1 <- 10
        DUT.memoria_instrucoes(1) <= "010000100000000101"; -- LDI r2 <- 5
        DUT.memoria_instrucoes(2) <= "000100110001001000"; -- ADD r3 <- r1 + r2
        DUT.memoria_instrucoes(3) <= "011000110001000001"; -- SUBI r3 <- r1 - 1
        DUT.memoria_instrucoes(4) <= "100000110000000001"; -- LW r3 <- Mem[r0 + 1]
        DUT.memoria_instrucoes(5) <= "101000000000010000"; -- JMP 16

        -- também pode inicializar memória de dados
        DUT.memoria_dados(1) <= x"000A";

        ---------------------------------------------------------
        -- tempo suficiente para simular várias instruções
        ---------------------------------------------------------
        wait for 2000 ps;

        -- fim da simulação
        wait;
    end process;

end architecture;

