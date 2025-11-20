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
	signal PC : std_logic_vector (7 downto 0); --sinal para o PC
	signal mux_branch, mux_jump : std_logic_vector (7 downto 0); --sinais para os muxes de saltos para o PC

	type memoria is array (integer range 0 to 255) of std_logic_vector (19 downto 0); --definicao da memoria
	signal memoria_instrucoes : memoria; --memoria de instrucoes
	signal memoria_instrucoes_out : std_logic_vector (19 downto 0); --saida da memoria de instrucoes
	signal opcode : std_logic_vector(3 downto 0);
	signal reg_1, reg_2 : std_logic_vector (3 downto 0); --registradores que vao fazer os calculos na ULA
	signal reg_destino : std_logic_vector (3 downto 0);
	signal imediato : std_logic_vector (7 downto 0);

	signal memoria_dados : memoria; --memoria de dados
	signal memoria_dados_out : std_logic_vector (19 downto 0); --saida da memoria de dados

  --operacoes e saida da ULA
	signal saida_ula : std_logic_vector(3 downto 0);
	signal soma, sub : std_logic_vector (3 downto 0);
	signal mult : std_logic_vector (7 downto 0);
	
begin
	process(reset, clock)
	begin
	end process;

end architecture;
