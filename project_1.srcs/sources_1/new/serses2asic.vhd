----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/27/2019 06:06:39 PM
-- Design Name: 
-- Module Name: serses2asic - Behavioral
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

entity serses2asic is
    Port ( 
    	CLK : in STD_LOGIC;
    	CLKDIV : in STD_LOGIC;
    	reset_serdes : in STD_LOGIC;
    	front_sig: in STD_LOGIC_VECTOR(1 downto 0); --"01" - rising, "10" - falling, "00" - no sig
    	shift_time: in std_logic_vector(2 downto 0);
    	OQ: out std_logic
    	);
end serses2asic;

architecture Behavioral of serses2asic is

	signal rising_sig, falling_sig, sig: std_logic_vector(5 downto 0) := "000000";

begin

	shift_select: process(clkdiv)
	begin
		if(rising_edge(clkdiv)) then
			case shift_time is
				when "000" => rising_sig <= "111111"; falling_sig <= "000000";
				when "001" => rising_sig <= "111110"; falling_sig <= "000001";
				when "010" => rising_sig <= "111100"; falling_sig <= "000011";
				when "011" => rising_sig <= "111000"; falling_sig <= "000111";
				when "100" => rising_sig <= "110000"; falling_sig <= "001111";
				when "101" => rising_sig <= "100000"; falling_sig <= "011111";
				when others => rising_sig <= "UUUUUU"; falling_sig <= "UUUUUU";
			end case;
		end if;
	end process;
	
	ctlr_process: process(clkdiv)
	begin
		if(rising_edge(clkdiv)) then
			case front_sig is
				when "01" => sig <= rising_sig;
				when "10" => sig <= falling_sig;
				when "00" => sig <= "000000";
				when "11" => sig <= "111111";
				when others => sig <= "UUUUUU";
			end case;
		end if;
	end process;
	

   OSERDESE2_inst : OSERDESE2
   generic map (
      DATA_RATE_OQ => "DDR",   -- DDR, SDR
      DATA_RATE_TQ => "SDR",   -- DDR, BUF, SDR
      DATA_WIDTH => 6,         -- Parallel data width (2-8,10,14)
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
      D1 => sig(0),
      D2 => sig(1),
      D3 => sig(2),
      D4 => sig(3),
      D5 => sig(4),
      D6 => sig(5),
      D7 => '0',
      D8 => '0',
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



end Behavioral;
