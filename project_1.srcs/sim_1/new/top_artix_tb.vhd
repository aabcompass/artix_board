----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.06.2016 17:55:34
-- Design Name: 
-- Module Name: top_artix_tb - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_artix_tb is
--  Port ( );
end top_artix_tb;

architecture Behavioral of top_artix_tb is

	component top_artix
			Port 
			( 
				-- system
				clk_40MHz : in STD_LOGIC;
				artix_addr: in std_logic_vector(1 downto 0);
				artix_ctrl: in std_logic;
				clk_40MHz_slave: in STD_LOGIC;
				clk_wiz_0_reset: in STD_LOGIC;
				
				
				-- to/from other artix
				artix_gtu: out std_logic;
				artix_40mhz_0: out std_logic;
				artix_40mhz_1: out std_logic;
				artix_val_evt: out std_logic;
				
				-- clk to SPACIROC
				ec_val_evt_2_p, ec_val_evt_2_n: out std_logic;
				ec_val_evt_3_p, ec_val_evt_3_n: out std_logic;
				ec_clk_gtu_2_p, ec_clk_gtu_2_n: out std_logic;
				ec_clk_gtu_3_p, ec_clk_gtu_3_n: out std_logic;
				ec_40MHz_2_p, ec_40MHz_2_n: out std_logic;
				ec_40MHz_3_p, ec_40MHz_3_n: out std_logic;
				
				-- data to ZYNQ
				zynq_frame: out std_logic;
				zynq_data: out std_logic_vector(15 downto 0);
				zynq_clk_p, zynq_clk_n: out std_logic;
				
				--from SPACIROCs
				ec_data_left: in std_logic_vector(47 downto 0); -- A(7:0) & B(7:0) & ... & F(7:0)
				ec_transmit_on_left: in std_logic_vector(5 downto 0); -- A & B & ... & F
				ec_data_right: in std_logic_vector(47 downto 0); -- A(7:0) & B(7:0) & ... & F(7:0)
				ec_transmit_on_right: in std_logic_vector(5 downto 0); -- A & B & ... & F
				
				-- locked
				locked: out std_logic;
				led_a8: out std_logic;
				led_slave: out std_logic
			);
	end component;

	signal clk_40MHz: std_logic := '0';
	
begin

	clk_gen: process
	begin
		clk_40MHz <= '0';
		wait for 12.5 ns;
		clk_40MHz <= '1';
		wait for 12.5 ns;
	end process;
	
	dut: top_artix port map
	(
		clk_40MHz => clk_40MHz,
		artix_addr => "10",
		artix_ctrl => '0',
		clk_40MHz_slave => '0',
		clk_wiz_0_reset => '0',
		ec_data_left => (others => '0'),
		ec_data_right => (others => '0'),
		ec_transmit_on_left => (others => '0'),
		ec_transmit_on_right => (others => '0')		
	);

end Behavioral;
