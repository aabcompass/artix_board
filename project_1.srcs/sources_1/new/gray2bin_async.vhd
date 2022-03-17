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
entity gray2bin_async is
    Port 
    ( 
			datain : in STD_LOGIC_VECTOR (5 downto 0);
			dataout : out STD_LOGIC_VECTOR (5 downto 0)
		);
end gray2bin_async;

architecture Behavioral of gray2bin_async is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral : architecture is "yes";


	
	signal b, g : std_logic_vector(5 downto 0) := "000000";
	
begin

	g <= datain;
	
	b(5)<= g(5);-- when rising_edge(clk);	
	b(4)<= g(5) xor g(4);-- when rising_edge(clk);	
	b(3)<= g(5) xor g(4) xor g(3);-- when rising_edge(clk);	
	b(2)<= g(5) xor g(4) xor g(3) xor g(2);-- when rising_edge(clk);	
	b(1)<= g(5) xor g(4) xor g(3) xor g(2) xor g(1);-- when rising_edge(clk);	
	b(0)<= g(5) xor g(4) xor g(3) xor g(2) xor g(1) xor g(0);-- when rising_edge(clk);	
	
	dataout <= b;--  when rising_edge(clk);
	
end Behavioral;
