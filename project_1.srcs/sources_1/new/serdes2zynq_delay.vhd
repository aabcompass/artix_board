----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2018 05:51:14 PM
-- Design Name: 
-- Module Name: serdes2zynq - Behavioral
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


Library UNISIM;
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity serdes2zynq_delay is
    Port ( clk : in STD_LOGIC;
           clkdiv : in STD_LOGIC;
           idelay_REFCLK_200MHZ: in std_logic;
           idelay_rst_200MHZ: in std_logic;
           reset_serdes: in std_logic;
           datain : in STD_LOGIC_VECTOR (7 downto 0);
           dataout_p : out STD_LOGIC;
           dataout_n : out STD_LOGIC);
end serdes2zynq_delay;

architecture Behavioral of serdes2zynq_delay is

	signal OQ: std_logic;
	signal OQ_delayed: std_logic;

	attribute IODELAY_GROUP : STRING;
	attribute IODELAY_GROUP of ODELAYE2_inst: label is "iodelay_group_name";


begin



-- <-----Cut code below this line and paste into the architecture body---->

   -- OSERDESE2: Output SERial/DESerializer with bitslip
   --            Artix-7
   -- Xilinx HDL Language Template, version 2016.2
   OSERDESE2_inst : OSERDESE2
   generic map (
      DATA_RATE_OQ => "DDR",   -- DDR, SDR
      DATA_RATE_TQ => "DDR",   -- DDR, BUF, SDR
      DATA_WIDTH => 8,         -- Parallel data width (2-8,10,14)
      INIT_OQ => '0',          -- Initial value of OQ output (1'b0,1'b1)
      INIT_TQ => '0',          -- Initial value of TQ output (1'b0,1'b1)
      SERDES_MODE => "MASTER", -- MASTER, SLAVE
      SRVAL_OQ => '0',         -- OQ output value when SR is used (1'b0,1'b1)
      SRVAL_TQ => '0',         -- TQ output value when SR is used (1'b0,1'b1)
      TBYTE_CTL => "FALSE",    -- Enable tristate byte operation (FALSE, TRUE)
      TBYTE_SRC => "FALSE",    -- Tristate byte source (FALSE, TRUE)
      TRISTATE_WIDTH => 1      -- 3-state converter width (1,4)
   )
   port map (
      OFB => open,             -- 1-bit output: Feedback path for data
      OQ => OQ,               -- 1-bit output: Data path output
      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
      SHIFTOUT1 => open,
      SHIFTOUT2 => open,
      TBYTEOUT => open,   -- 1-bit output: Byte group tristate
      TFB => open,             -- 1-bit output: 3-state control
      TQ => open,               -- 1-bit output: 3-state control
      CLK => CLK,             -- 1-bit input: High speed clock
      CLKDIV => CLKDIV,       -- 1-bit input: Divided clock
      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      D1 => datain(0),
      D2 => datain(1),
      D3 => datain(2),
      D4 => datain(3),
      D5 => datain(4),
      D6 => datain(5),
      D7 => datain(6),
      D8 => datain(7),
      OCE => '1',             -- 1-bit input: Output data clock enable
      RST => reset_serdes,             -- 1-bit input: Reset
      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      SHIFTIN1 => '0',
      SHIFTIN2 => '0',
      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0',
      TBYTEIN => '0',     -- 1-bit input: Byte group tristate
      TCE => '0'              -- 1-bit input: 3-state clock enable
   );





   iodelay_group_name : IDELAYCTRL
   port map (
      RDY => open,       -- 1-bit output: Ready output
      REFCLK => idelay_REFCLK_200MHZ, -- 1-bit input: Reference clock input
      RST => idelay_rst_200MHZ        -- 1-bit input: Active high reset input
   );


   ODELAYE2_inst : ODELAYE2
		generic map (
			 CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
			 DELAY_SRC => "ODATAIN",           -- Delay input (ODATAIN, CLKIN)
			 HIGH_PERFORMANCE_MODE => "FALSE", -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
			 ODELAY_TYPE => "FIXED",           -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
			 ODELAY_VALUE => 0,                -- Output delay tap setting (0-31)
			 PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
			 REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
			 SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
		)
		port map (
			 CNTVALUEOUT => open, -- 5-bit output: Counter value output
			 DATAOUT => OQ_delayed,         -- 1-bit output: Delayed data/clock output
			 C => '0',                     -- 1-bit input: Clock input
			 CE => '0',                   -- 1-bit input: Active high enable increment/decrement input
			 CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
			 CLKIN => '0',             -- 1-bit input: Clock delay input
			 CNTVALUEIN => "00000",   -- 5-bit input: Counter value input
			 INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
			 LD => '0',                   -- 1-bit input: Loads ODELAY_VALUE tap delay in VARIABLE mode, in VAR_LOAD or
																	 -- VAR_LOAD_PIPE mode, loads the value of CNTVALUEIN
		
			 LDPIPEEN => '0',       -- 1-bit input: Enables the pipeline register to load data
			 ODATAIN => OQ,         -- 1-bit input: Output delay data input
			 REGRST => '0'            -- 1-bit input: Active-high reset tap-delay input
		);
		
		
		 OBUFDS_inst : OBUFDS
		 generic map (
				IOSTANDARD => "DEFAULT", -- Specify the output I/O standard
				SLEW => "FAST")          -- Specify the output slew rate
		 port map (
				O => dataout_p,     -- Diff_p output (connect directly to top-level port)
				OB => dataout_n,   -- Diff_n output (connect directly to top-level port)
				I => OQ_delayed     -- Buffer input 
		 );



end Behavioral;
