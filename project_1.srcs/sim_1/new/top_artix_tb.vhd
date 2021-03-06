library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity top_artix_tb is
end top_artix_tb;

architecture Behavioral of top_artix_tb is

	component top_artix
			generic(IS_SIM: std_logic:= '1');
			Port 
			( 
     --! system
			 clk_pri : in STD_LOGIC;--!< Primary clock from Zynq
			 artix_addr: in std_logic_vector(1 downto 0);--!< 2bit address for distinguish which Artix (from 3)
     	 gtu_zb: in std_logic;
			 --! gen mode
			-- gen_mode: in std_logic;
			  
			 --! clk to SPACIROC
			 ec_val_evt_2_p, ec_val_evt_2_n: out std_logic; --!< Clock and strobe signals for ASIC control
			 ec_val_evt_3_p, ec_val_evt_3_n: out std_logic;
			 ec_clk_gtu_2_p, ec_clk_gtu_2_n: out std_logic;
			 ec_clk_gtu_3_p, ec_clk_gtu_3_n: out std_logic;
			 ec_40MHz_2_p, ec_40MHz_2_n: out std_logic;
			 ec_40MHz_3_p, ec_40MHz_3_n: out std_logic;
			 --ec_40MHz_tst_p, ec_40MHz_tst_n: out std_logic;
			 
			 --! data to ZYNQ
			 zynq_frame_p, zynq_frame_n: out std_logic; --!< Frame diff signal for data transfer from Artix to Zynq
			 zynq_data_p, zynq_data_n: out std_logic_vector(11 downto 0); --!< Data diff signals for data transfer from Artix to Zynq
			 zynq_clk_p, zynq_clk_n: out std_logic; --!< Clock diff signal for data transfer from Artix to Zynq
			 
			 --! from SPACIROCs
			 ec_data_left: in std_logic_vector(47 downto 0) := (others => '0'); --!< Data signals from ASICs A(7:0) & B(7:0) & ... & F(7:0)
			 ec_data_ki_left: in std_logic_vector(5 downto 0) := (others => '0'); --!< Data signals from ASICs A(7:0) & B(7:0) & ... & F(7:0)
			 ec_transmit_on_left: in std_logic_vector(5 downto 0) := (others => '0'); --!< Transmit signal from ASICs A & B & ... & F
			 ec_data_right: in std_logic_vector(47 downto 0) := (others => '0'); --!< Data signals from ASICs  A(7:0) & B(7:0) & ... & F(7:0)
			 ec_data_ki_right: in std_logic_vector(5 downto 0) := (others => '0'); --!< Data signals from ASICs  A(7:0) & B(7:0) & ... & F(7:0)
			 ec_transmit_on_right: in std_logic_vector(5 downto 0) := (others => '0'); --!< Transmit signal from ASICs A & B & ... & F
			 
			 --! from SPACIROCs 
			 sr_ck_frw_in: in std_logic := '0';--; -- not presented in PCB
			 sr_ck_frw_out0, sr_ck_frw_out1: out std_logic;
			 
			 bitstream_in: in std_logic := '0';
			 bitstream_out: out std_logic;
			sr_ck: in STD_LOGIC := '0';
		  sr_in : in STD_LOGIC := '0';
		  --sr_out : out STD_LOGIC;
			latch : in STD_LOGIC := '0'


			);
	end component;

	signal clk_pri: std_logic := '0';
	signal gtu_zb: std_logic := '0';
	signal ec_40MHz_2_p: std_logic := '0';
	signal gtu: std_logic := '0';
	signal transmit_on: std_logic := '0';
	signal is_transmit_on: std_logic := '1';
	signal ec_data_left: std_logic_vector(47 downto 0) := (others => '0');
	signal ec_transmit_on_left, ec_transmit_on_right: std_logic_vector(5 downto 0) := (others => '0');
	
begin

	clk_gen: process
	begin
		clk_pri <= '0';
		wait for 5 ns;
		clk_pri <= '1';
		wait for 5 ns;
	end process;
	
	ec_data_left_gen: process(ec_40MHz_2_p)
	begin
		if(rising_edge(ec_40MHz_2_p)) then
			ec_data_left <= ec_data_left + 1;
			if(ec_data_left = X"0000000002FF") then
				gtu_zb <= '1';
			end if;
		end if;
	end process;
	
	
	dut: top_artix 
	generic map (IS_SIM => '1')
	port map
	(
		clk_pri => clk_pri,
		gtu_zb => gtu_zb,
		--gen_mode => '0',
		artix_addr => "10",
		ec_40MHz_2_p => ec_40MHz_2_p,
		ec_data_left => ec_data_left,
		ec_data_right => (others => '0'),
		ec_transmit_on_left => ec_transmit_on_left,
		ec_transmit_on_right => ec_transmit_on_right,
		sr_ck_frw_in => '0',
		bitstream_in => '0',
		ec_clk_gtu_2_p => gtu
	);
	
	ec_transmit_on_left <= (others => '0');
	ec_transmit_on_right <= (others => transmit_on);--transmit_on);
	
	transmit_on_gen: process(ec_40MHz_2_p)
		variable state : integer range 0 to 4 := 0;
		variable cnt : integer := 0;
	begin
		if(rising_edge(ec_40MHz_2_p)) then
			case state is
				when 0 => if(gtu = '0') then
										state := state + 1;
									end if;
				when 1 => if(gtu = '1') then
										state := state + 1;
									end if;
				when 2 => if(cnt = 0) then
										cnt := 0;
										state := state + 1;
									else
										cnt := cnt + 1;	
									end if;
				when 3 => transmit_on <= is_transmit_on;
									if(cnt = 6) then
										cnt := 0;
									state := state + 1;
										else
										cnt := cnt + 1;	
									end if;
				when 4 => transmit_on <= '0';
									state := 0;
			end case;
		end if;
	end process;



end Behavioral;
