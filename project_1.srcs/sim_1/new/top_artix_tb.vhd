

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity top_artix_tb is
--  Port ( );
end top_artix_tb;

architecture Behavioral of top_artix_tb is

	component top_artix
			generic(gen_mode : std_logic := '0');
			Port 
			( 
     -- system
			 clk_pri : in STD_LOGIC;--+
			 artix_addr: in std_logic_vector(1 downto 0);--+
			  
			 -- clk to SPACIROC
			 ec_val_evt_2_p, ec_val_evt_2_n: out std_logic;
			 ec_val_evt_3_p, ec_val_evt_3_n: out std_logic;
			 ec_clk_gtu_2_p, ec_clk_gtu_2_n: out std_logic;
			 ec_clk_gtu_3_p, ec_clk_gtu_3_n: out std_logic;
			 ec_40MHz_2_p, ec_40MHz_2_n: out std_logic;
			 ec_40MHz_3_p, ec_40MHz_3_n: out std_logic;
			 
			 -- data to ZYNQ
			 zynq_frame_p, zynq_frame_n: out std_logic;
			 zynq_data_p, zynq_data_n: out std_logic_vector(11 downto 0);
			 zynq_clk_p, zynq_clk_n: out std_logic;
			 
			 --from SPACIROCs
			 ec_data_left: in std_logic_vector(47 downto 0); -- A(7:0) & B(7:0) & ... & F(7:0)
			 ec_transmit_on_left: in std_logic_vector(5 downto 0); -- A & B & ... & F
			 ec_data_right: in std_logic_vector(47 downto 0); -- A(7:0) & B(7:0) & ... & F(7:0)
			 ec_transmit_on_right: in std_logic_vector(5 downto 0); -- A & B & ... & F
			 
			 
			 sr_ck_frw_in: in std_logic;--; -- not presented in PCB
			 sr_ck_frw_out0, sr_ck_frw_out1: out std_logic
			);
	end component;

	signal clk_pri: std_logic := '0';
	
begin

	clk_gen: process
	begin
		clk_pri <= '0';
		wait for 5 ns;
		clk_pri <= '1';
		wait for 5 ns;
	end process;
	
	dut: top_artix 
	generic map (gen_mode => '1')
	port map
	(
		clk_pri => clk_pri,
		artix_addr => "10",
		ec_data_left => (others => '0'),
		ec_data_right => (others => '0'),
		ec_transmit_on_left => (others => '0'),
		ec_transmit_on_right => (others => '0'),
		sr_ck_frw_in => '0'		
	);

end Behavioral;
