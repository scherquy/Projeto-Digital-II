library ieee;                 
use ieee.std_logic_1164.all;  

entity tb_pipeline is
end entity;

architecture behavior of tb_pipeline is

component pipeline is
    port(
        clock  : in std_logic;
        reset  : in std_logic
    );
end component;

signal clock_sg  : std_logic := '0';
signal reset_sg  : std_logic := '1';

-- Defina tempos realistas (ns = nanosegundos)
constant CLK_PERIOD : time := 100 ps;  -- Clock de 100 MHz
constant RESET_TIME : time := 200 ps;  -- Reset por 2 ciclos de clock

begin

inst_top: pipeline
    port map(
        clock => clock_sg,
        reset => reset_sg
    );

-- Clock de 100 MHz (período 10 ns)
clock_sg <= not clock_sg after CLK_PERIOD/2;

-- Processo de controle
process
begin
    -- Mantém reset ativo por 2 ciclos de clock
    reset_sg <= '1';
    wait for RESET_TIME;
    
    -- Libera o reset
    reset_sg <= '0';
    
    -- Executa por um tempo (ex: 100 ciclos)
    wait for CLK_PERIOD * 100;
    
    -- Finaliza simulação
    report "Simulação concluída!" severity note;
    wait;
end process;

end behavior;