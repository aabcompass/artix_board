-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.09.2015 13:38:00
-- Design Name: 
-- Module Name: gray2bin - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


--taken from wikipedia.org
--int gray2bin(int x) 
--{
--   return x ^ ((x & 0x88888888) >> 3) ^ ((x & 0xCCCCCCCC) >> 2) ^ ((x & 0xEEEEEEEE) >> 1);
--}

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- latency = 2 clk
entity gray2bin is
    Port 
    ( 
			clk : in STD_LOGIC;
			datain : in STD_LOGIC_VECTOR (7 downto 0);
			datain_dv : in std_logic;
			dataout : out STD_LOGIC_VECTOR (7 downto 0);
			dataout_dv : out std_logic
		);
end gray2bin;

architecture Behavioral of gray2bin is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral : architecture is "yes";


	signal arg1, arg2, arg3, datain_d1: std_logic_vector(7 downto 0) := (others => '0');
	signal datain_dv_d1: std_logic := '0';
	
	signal b, g : std_logic_vector(7 downto 0) := "00000000";
	
begin

-- before 26Sep2017

--	arg1 <= (datain and X"88") when rising_edge(clk);
--	arg2 <= (datain and X"CC") when rising_edge(clk);
--	arg3 <= (datain and X"EE") when rising_edge(clk);
--	datain_d1 <= datain when rising_edge(clk);

--	--dataout <= datain_d1 xor ("000" & arg1(4 downto 0)) xor ("00" & arg2(5 downto 0)) xor ("0" & arg3(6 downto 0)) when rising_edge(clk);
--	dataout <= datain_d1 xor ("000" & arg1(7 downto 3)) xor ("00" & arg2(7 downto 2)) xor ("0" & arg3(7 downto 1)) when rising_edge(clk);
--	datain_dv_d1 <= datain_dv when rising_edge(clk);
--	dataout_dv <= datain_dv_d1 when rising_edge(clk);

-- after 26Sep2017
	
	g <= datain;
	
	b(7)<= g(7) when rising_edge(clk);	
	b(6)<= g(7) xor g(6) when rising_edge(clk);	
	b(5)<= g(7) xor g(6) xor g(5) when rising_edge(clk);	
	b(4)<= g(7) xor g(6) xor g(5) xor g(4) when rising_edge(clk);	
	b(3)<= g(7) xor g(6) xor g(5) xor g(4) xor g(3) when rising_edge(clk);	
	b(2)<= g(7) xor g(6) xor g(5) xor g(4) xor g(3) xor g(2) when rising_edge(clk);	
	b(1)<= g(7) xor g(6) xor g(5) xor g(4) xor g(3) xor g(2) xor g(1) when rising_edge(clk);	
	b(0)<= g(7) xor g(6) xor g(5) xor g(4) xor g(3) xor g(2) xor g(1) xor g(0) when rising_edge(clk);	
	
	dataout <= b  when rising_edge(clk);
	datain_dv_d1 <= datain_dv  when rising_edge(clk);
	dataout_dv <= datain_dv_d1  when rising_edge(clk);
	
end Behavioral;
