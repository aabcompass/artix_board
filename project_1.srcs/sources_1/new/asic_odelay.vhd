----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/27/2019 02:35:23 PM
-- Design Name: 
-- Module Name: asic_odelay - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

entity asic_odelay is
    Port ( 
      clk: std_logic;
      clkdiv: std_logic;
      reset_serdes: std_logic;
      -- inputs
      clk_gtu: in std_logic;
      clk_40MHZ_p: in std_logic;
      -- to ASICs
      ec_clk_gtu_2_p, ec_clk_gtu_2_n: out std_logic;
   		ec_clk_gtu_3_p, ec_clk_gtu_3_n: out std_logic;
    	ec_40MHz_2_p, ec_40MHz_2_n: out std_logic;
    	ec_40MHz_3_p, ec_40MHz_3_n: out std_logic;
    	ec_40MHz_tst_p, ec_40MHz_tst_n: out std_logic;
    	-- params
    	shift_time: in std_logic_vector(2 downto 0) := "000"
    );
end asic_odelay;

architecture Behavioral of asic_odelay is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral : architecture is "yes";


	component serses2asic is
    Port ( 
    	CLK : in STD_LOGIC;
    	CLKDIV : in STD_LOGIC;
    	reset_serdes : in STD_LOGIC;
    	front_sig: in STD_LOGIC_VECTOR(1 downto 0); --"01" - rising, "10" - falling, "00" - no sig
    	shift_time: in std_logic_vector(2 downto 0);
    	OQ: out std_logic
    	);
	end component;

	component serses2asic_uni is
    Port ( 
    	CLK : in STD_LOGIC;
    	CLKDIV : in STD_LOGIC;
    	reset_serdes : in STD_LOGIC;
    	front_sig: in STD_LOGIC_VECTOR(1 downto 0); --"01" - rising, "10" - falling, "00" - no sig
    	shift_time: in std_logic_vector(2 downto 0);
    	OQ: out std_logic;
    	OQ_compl: out std_logic
    	);
	end component;

	
	signal clk_gtu_d1 : std_logic := '0';
	signal clk_40MHZ_p_d1 : std_logic := '0';
	
	signal front_sig_gtu, front_sig_clk_40MHz: std_logic_vector(1 downto 0) := (others => '0');
	
	signal clk_gtu_i2, clk_gtu_i3, clk_40MHz2, clk_40MHz3: std_logic;

begin


	clk_gtu_d1 <= clk_gtu when rising_edge(clkdiv);
	clk_40MHZ_p_d1 <= clk_40MHZ_p when rising_edge(clkdiv);
	
	front_sig_gtu <= clk_gtu_d1 & clk_gtu;
	front_sig_clk_40MHz <= clk_40MHZ_p_d1 & clk_40MHZ_p;
	
	i_serdes_gtu2: serses2asic
    Port map( 
    	CLK => clk,--: in STD_LOGIC;
    	CLKDIV =>  clkdiv,--: in STD_LOGIC;
    	reset_serdes => reset_serdes,--: in STD_LOGIC;
    	front_sig => front_sig_gtu,--: in STD_LOGIC_VECTOR(1 downto 0); --"01" - rising, "10" - falling, "00" - no sig
    	shift_time => shift_time,--: in std_logic_vector(1 downto 0);
    	OQ => clk_gtu_i2--: out std_logic
    	);

	i_serdes_gtu3: serses2asic
    Port map( 
    	CLK => clk,--: in STD_LOGIC;
    	CLKDIV =>  clkdiv,--: in STD_LOGIC;
    	reset_serdes => reset_serdes,--: in STD_LOGIC;
    	front_sig => front_sig_gtu,--: in STD_LOGIC_VECTOR(1 downto 0); --"01" - rising, "10" - falling, "00" - no sig
    	shift_time => shift_time,--: in std_logic_vector(1 downto 0);
    	OQ => clk_gtu_i3--: out std_logic
    	);

	i_serdes_clk40MHz2: serses2asic_uni
    Port map( 
    	CLK => clk,--: in STD_LOGIC;
    	CLKDIV =>  clkdiv,--: in STD_LOGIC;
    	reset_serdes => reset_serdes,--: in STD_LOGIC;
    	front_sig => front_sig_clk_40MHz,--: in STD_LOGIC_VECTOR(1 downto 0); --"01" - rising, "10" - falling, "00" - no sig
    	shift_time => shift_time,--: in std_logic_vector(1 downto 0);
    	OQ => ec_40MHz_2_p,--: out std_logic
    	OQ_compl => ec_40MHz_2_n--: out std_logic
    	);

	i_serdes_clk40MHz3: serses2asic_uni
    Port map( 
    	CLK => clk,--: in STD_LOGIC;
    	CLKDIV =>  clkdiv,--: in STD_LOGIC;
    	reset_serdes => reset_serdes,--: in STD_LOGIC;
    	front_sig => front_sig_clk_40MHz,--: in STD_LOGIC_VECTOR(1 downto 0); --"01" - rising, "10" - falling, "00" - no sig
    	shift_time => shift_time,--: in std_logic_vector(1 downto 0);
    	OQ => ec_40MHz_3_p,--: out std_logic
    	OQ_compl => ec_40MHz_3_n--: out std_logic
    	);


	inst_OBUFDS_gtu2: obufds port map(ec_clk_gtu_2_p, ec_clk_gtu_2_n, clk_gtu_i2);
	inst_OBUFDS_gtu3: obufds port map(ec_clk_gtu_3_p, ec_clk_gtu_3_n, clk_gtu_i3);
--	inst_OBUFDS_clk40_2: obufds port map(ec_40MHz_2_p, ec_40MHz_2_n, clk_40MHz2);
--	inst_OBUFDS_clk40_3: obufds port map(ec_40MHz_3_p, ec_40MHz_3_n, clk_40MHz3);
	--inst_OBUFDS_clk40_tst: obufds port map(ec_40MHz_tst_p, ec_40MHz_tst_n, clk_40MHz3);


end Behavioral;
