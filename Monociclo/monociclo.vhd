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
	--PC e MUXES para o PC
	signal PC : std_logic_vector (7 downto 0); --sinal para o PC
	signal mux_branch, mux_jump : std_logic_vector (7 downto 0); --sinais para os muxes de saltos para o PC

	--CAMPOS QUE VAO NA MEMORIA, OPCODE, REGISTRADORES, IMEDIATO
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

memoria_instrucoes_out <= memoria_instrucoes(conv_integer(PC));
opcode <= memoria_instrucoes_out(19 downto 16);

--tipo R
reg_1 <= memoria_instrucoes_out(15 downto 12) when opcode = "0001" or opcode = "0010" or opcode = "0011" else
	(others => '0');
reg_2 <= memoria_instrucoes_out(11 downto 8) when opcode = "0001" or opcode = "0010" or opcode = "0011" else
	(others => '0');
reg_destino <= memoria_instrucoes_out(7 downto 4) when opcode = "0001" or opcode = "0010" or opcode = "0011" else
	(others => '0');
	
		


	process(reset, clock)
	begin
		if(reset = '0') then
			PC <= (others => '0');
		elsif(clock = '1' and clock'event) then
			PC <= PC + 1;
		end if;
	end process;

end architecture;
