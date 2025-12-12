library ieee;                  
use ieee.std_logic_1164.all;  

entity tb_pipeline is
end entity;

architecture behavior of tb_pipeline is

    -- IMPORTANTE: O componente deve chamar pipeline_mips (igual ao seu arquivo principal)
    component pipeline_mips is
        port(
            clock  : in std_logic;
            reset  : in std_logic
        );
    end component;

    signal clock_sg  : std_logic := '0';
    signal reset_sg  : std_logic := '1';

    -- Ajustado para 10 ps conforme sua preferência
    constant CLK_PERIOD : time := 10 ps;   
    
begin

    inst_top: pipeline_mips
        port map(
            clock => clock_sg,
            reset => reset_sg
        );

    -- Geração do Clock (5ps High, 5ps Low)
    clock_sg <= not clock_sg after CLK_PERIOD/2;

    -- Processo de estímulos
    process
    begin
        -- 1. Reset Ativo
        reset_sg <= '1';
        
        -- Espera 2 ciclos (20 ps) para garantir o reset
        wait for CLK_PERIOD * 2;
        
        -- 2. Libera o reset
        reset_sg <= '0';
        
        -- 3. Roda a simulação por 100 ciclos (1000 ps)
        wait for CLK_PERIOD * 100;
        
        report "Simulação concluída!" severity note;
        wait; -- Para a simulação
    end process;

end behavior;
