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

entity serdes2zynq is
    Port ( clk : in STD_LOGIC;
           clkdiv : in STD_LOGIC;
           reset_serdes: in std_logic;
           datain : in STD_LOGIC_VECTOR (7 downto 0);
           dataout_p : out STD_LOGIC;
           dataout_n : out STD_LOGIC);
end serdes2zynq;

architecture Behavioral of serdes2zynq is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral : architecture is "yes";


	signal OQ: std_logic;
	signal OQ_delayed: std_logic;



begin



-- <-----Cut code below this line and paste into the architecture body---->

   -- OSERDESE2: Output SERial/DESerializer with bitslip
   --            Artix-7
   -- Xilinx HDL Language Template, version 2016.2
   OSERDESE2_inst : OSERDESE2
   generic map (
      DATA_RATE_OQ => "DDR",   -- DDR, SDR
      DATA_RATE_TQ => "SDR",   -- DDR, BUF, SDR
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


		 OBUFDS_inst : OBUFDS
			generic map (
							IOSTANDARD => "DEFAULT", -- Specify the output I/O standard
							SLEW => "FAST")          -- Specify the output slew rate
			port map (
							O => dataout_p,     -- Diff_p output (connect directly to top-level port)
							OB => dataout_n,   -- Diff_n output (connect directly to top-level port)
							I => OQ   -- Buffer input 
			);



end Behavioral;
