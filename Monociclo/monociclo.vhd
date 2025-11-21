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

	--MEMORIA DE INSTRUÇAO
	type memoria is array (integer range 0 to 255) of std_logic_vector (19 downto 0); --definicao da memoria
	signal memoria_instrucoes 		: memoria; --memoria de instrucoes
	signal memoria_instrucoes_out 		: std_logic_vector (19 downto 0); --saida da memoria de instrucoes
	
	-- CAMPOS DA INSTRUÇAO (OPCODE, REGISTRADORES, VALOR IMD)
	signal opcode 				: std_logic_vector(3 downto 0);
	signal reg_rs  				: (3 downto); --registradores que vao fazer os calculos na ULA
	signal reg_rt 				: (3 downto 0);
	signal reg_rd 				: std_logic_vector (3 downto 0);
	signal imediato				: std_logic_vector (7 downto 0);

	-- MEMORIA DE DADOS
	signal memoria_dados : memoria; 
	signal memoria_dados_out : std_logic_vector (19 downto 0); --saida da memoria de dados


	-- BANCO DE REGISTRADORES DO MIPS 
	type registradores is array (0 to 15) of std_logic_vector(15 downto 0); -- 16 registradores com 16 bits de tamanho
	signal banco_reg : registradores;
	
	
	--SINAIAS PARA ULA
	signal saida_ula : std_logic_vector(3 downto 0);
	signal soma	 : std_logic_vector (3 downto 0);
	signal sub	 : std_logic_vector (3 downto 0);
	signal mult      : std_logic_vector (7 downto 0);
	signal equal	 : std_logic;



begin

memoria_instrucoes_out <= memoria_instrucoes(conv_integer(PC));
opcode <= memoria_instrucoes_out(19 downto 16);

-- TIPO R
reg_rs <= memoria_instrucoes_out(15 downto 12) when opcode = "0001" or opcode = "0010" or opcode = "0011" else
	(others => '0');
reg_rt <= memoria_instrucoes_out(11 downto 8) when opcode = "0001" or opcode = "0010" or opcode = "0011" else
	(others => '0');
reg_rd <= memoria_instrucoes_out(7 downto 4) when opcode = "0001" or opcode = "0010" or opcode = "0011" else
	(others => '0');

-- TIPO I





-- OPERAÇOES DA ULA
soma <= reg_rs + reg_rt;
sub  <= reg_rs - reg_rt;
mult <= reg_rs * reg_rt;		
equal <= '1' when reg_rs = reg_rt else '0'; 

-- dois primeiros bits do opcode define a operaçao e os outros dois restantes o tipo de instruçao ? ? 
-- OPCODES DA ULA
saida_ula <= 	soma when opcode(1 downto 0) = "01" else
		sub  when opcode(1 downto 0) = "10" else
		mult when opcode(1 downto 0);


	process(reset, clock)
	begin
		if(reset = '1') then
			PC     <= (others =>'0');
			reg_rs <= (others=>'0');
			reg_rt <= (others=>'0');
			reg_rd <= (others=>'0');
			
		elsif(clock = '1' and clock'event) then
			
			case opcode is

				when "0001"
				reg_
				




		end if;
	end process;

end architecture;
