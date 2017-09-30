library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity gray2bin_tb is
--  Port ( );
end gray2bin_tb;

architecture Behavioral of gray2bin_tb is

	component  gray2bin 
			Port 
			( 
				clk : in STD_LOGIC;
				datain : in STD_LOGIC_VECTOR (7 downto 0);
				datain_dv : in std_logic;
				dataout : out STD_LOGIC_VECTOR (7 downto 0);
				dataout_dv : out std_logic
			);
	end component;
	
	signal datain: std_logic_vector(7 downto 0) := "00000000";
	signal datain_d1: std_logic_vector(7 downto 0) := "00000000";
	signal datain_d2: std_logic_vector(7 downto 0) := "00000000";
	signal clk: std_logic := '0';

begin

	process
	begin
		clk <= '1';
		wait for 5 ns;
		clk <= '0';
		wait for 5 ns;
	end process;
	
	data_generator: process(clk)
	begin
		if(rising_edge(clk)) then
			datain <= datain + 1;
		end if;
	end process;
	
	dut: gray2bin 
			Port map
			( 
				clk => clk,--: in STD_LOGIC;
				datain => datain,--: in STD_LOGIC_VECTOR (7 downto 0);
				datain_dv => '1', --: in std_logic;
				dataout => open,--: out STD_LOGIC_VECTOR (7 downto 0);
				dataout_dv => open --: out std_logic
			);
			
	datain_d1 <= datain when rising_edge(clk);
	datain_d2 <= datain_d1 when rising_edge(clk);

end Behavioral;
