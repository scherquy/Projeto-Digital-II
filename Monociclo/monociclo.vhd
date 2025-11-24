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
	signal reg_rs  				: std_logic_vector (3 downto 0); 
	signal reg_rt 				: std_logic_vector (3 downto 0);
	signal reg_rd 				: std_logic_vector (3 downto 0);
	signal imediato				: std_logic_vector (7 downto 0);

	-- MEMORIA DE DADOS
	signal memoria_dados : memoria; 
	signal memoria_dados_out : std_logic_vector (19 downto 0); --saida da memoria de dados


	-- BANCO DE REGISTRADORES DO MIPS 
	type registradores is array (0 to 15) of std_logic_vector(15 downto 0); -- 16 registradores com 16 bits de tamanho
	signal banco_reg : registradores;
	banco_reg(0) <= (others => '0'); -- Constante 0 no registrador 0
	
	--SINAIAS PARA ULA
	signal saida_ula : std_logic_vector(15 downto 0);
	signal soma	 : std_logic_vector (15 downto 0);
	signal sub	 : std_logic_vector (15 downto 0);
	signal mult      : std_logic_vector (31 downto 0);
	signal equal	 : std_logic;
	
	-- VALOR CARREGADO DOS REGISTRADORES
	signal valor_rs	 : std_logic_vector(15 downto 0);
	signal valor_rt  : std_logic_vector(15 downto 0);


begin

memoria_instrucoes_out <= memoria_instrucoes(conv_integer(PC));
opcode <= memoria_instrucoes_out(19 downto 16);


-- CAMPOS DAS INSTRUÇOES
opcode <= memoria_instrucoes_out(19 downto 16);
reg_rs <= memoria_instrucoes_out(15 downto 12);
reg_rt <= memoria_instrucoes_out(11 downto 8);
reg_rd <= memoria_instrucoes_out(7 downto 4);
imediato <= memoria_instrucoes_out(7 downto 0);


-- LER OS VALORES DOS REGS
valor_rs <= banco_reg(to_integer(unsigned(reg_rs))); -- valor_rs recebe o valor que esta no registrador rs indicado pela instrucao. Ex: se reg_rs for 0010 entao valor_rs recebe o valor que esta no registrador 2.
valor_rt <= banco_reg(to_integer(unsigned(reg_rt)));






-- OPERAÇOES DA ULA
soma <= valor_rs + valor_rt;
sub  <= valor_rs - valor_rt;
mult <= valor_rs * valor_rt;		
equal <= '1' when reg_rs = reg_rt else '0'; 

 

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



				---------- TIPO R -------------

			  when "0001" => -- ADD rd <- rs + rt
		
			   	if(reg_rd /= "0000") then
				  banco_reg(to_integer(unsigned(reg_rd))) <= saida_ula; -- opcode define a saida da ULA
				end if;

			  when "0010" =>  -- SUB rd <- rs - rt
			  
				if(reg_rd /= "0000") then
				  banco_reg(to_integer(unsigned(reg_rd))) <= saida_ula
				end if;

			 when "0011" => -- MULT rd <- rs * rt
				
			     if(reg_rd /= "0000") then
			        banco_reg(to_integer(unsigned(reg_rd))) <= saida_ula
			     end if;



				---------- TIPO I -------------
				
			when "0100" => --  LDI rt <- imd
			
				if(reg_rt /= "0000") then
				banco_reg(to_integer(unsigned(reg_rt))) <= imediato;

		       when "0101" => -- ADDI rt <- imd + rs
		
				if(reg_rt /= "0000") then
				banco_reg(to_integer(unsigned(reg_rt))) <= reg_rs + imediato;
		      
		       when "0110" => -- SUBI rt <- imd - rs
				
				if(reg_rt /= "0000") then
				banco_reg(to_integer(unsiged(reg_rt))) <= reg_rs - imediato;

		     
		       when "0111" => -- MULI rt <- imd * rs

				if(reg_rt /= "0000") then
				banco_reg(to_integer(unsigend(reg_rt))) <= reg_rs * imediato;

			when "1000" => -- LW
			
			

			when "1001" => -- SW


			
			     ---------- TIPO J -------------
			

			when "1010" -- JMP

			

			when "1011" -- BEQ




			when "1100" -- BNE
			

			
			 


		end if;
	end process;

end architecture;
