----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/31/2019 02:27:39 PM
-- Design Name: 
-- Module Name: slow_ctrl - Behavioral
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

Library xpm;
use xpm.vcomponents.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity slow_ctrl is
    Port ( clk : in STD_LOGIC;
						sr_ck: in STD_LOGIC;
           sr_in : in STD_LOGIC;
           sr_out : out STD_LOGIC;
           latch : in STD_LOGIC;
           sreg_input_reg: out std_logic_vector(31 downto 0) := (others => '0');
           sreg_output_reg: in std_logic_vector(31 downto 0));
end slow_ctrl;

architecture Behavioral of slow_ctrl is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral : architecture is "yes";


	signal sreg_input: std_logic_vector(32 downto 0) := (others => '0');
	signal sreg_output: std_logic_vector(31 downto 0) := (others => '0');
	signal sr_ck_d1, sr_ck_d2, latch_d1: std_logic := '0';



begin



-- <-----Cut code below this line and paste into the architecture body---->

   -- xpm_cdc_single: Single-bit Synchronizer
   -- Xilinx Parameterized Macro, version 2018.1

   xpm_cdc_single_ck : xpm_cdc_single
   generic map (
      DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
      INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
                           -- values
      SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 0  -- DECIMAL; integer; 0=do not register input, 1=register input
   )
   port map (
      dest_out => sr_ck_d1, -- 1-bit output: src_in synchronized to the destination clock domain. This output
                            -- is registered.

      dest_clk => clk, -- 1-bit input: Clock signal for the destination clock domain.
      src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in => sr_ck      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
   );

   xpm_cdc_single_latch : xpm_cdc_single
   generic map (
      DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
      INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
                           -- values
      SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 0  -- DECIMAL; integer; 0=do not register input, 1=register input
   )
   port map (
      dest_out => latch_d1, -- 1-bit output: src_in synchronized to the destination clock domain. This output
                            -- is registered.

      dest_clk => clk, -- 1-bit input: Clock signal for the destination clock domain.
      src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in => latch      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
   );

	
	sr_ck_d2 <= sr_ck_d1 when rising_edge(clk);

	sreg: process(clk)
	begin
		if(rising_edge(clk)) then
			if(latch_d1 = '1') then
				sreg_input_reg <= sreg_input(32 downto 1);
				sreg_output <= sreg_output_reg;
			else
				if(sr_ck_d1 = '1' and sr_ck_d2 = '0') then
					sreg_input  <=  sreg_input(31 downto 0) & sr_in;
					sreg_output <= sreg_output(30 downto 0) & '0';
				end if; 			
			end if;
		end if;
	end process;
	
	sr_out <= sreg_output(31);

end Behavioral;
