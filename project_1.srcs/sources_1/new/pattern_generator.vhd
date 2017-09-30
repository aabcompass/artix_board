library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.VComponents.all;
--

entity pattern_generator is
    Port 
    ( 
      -- system
      clk_40MHz : in STD_LOGIC;
      artix_addr: in std_logic_vector(1 downto 0);
      artix_ctrl: in std_logic;
      
      -- data to ZYNQ
      zynq_frame: out std_logic;
      zynq_data: out std_logic_vector(15 downto 0);
      zynq_clk_p, zynq_clk_n: out std_logic;
      
      -- locked
      locked: out std_logic;
      led_a8: out std_logic;
      led_slave: out std_logic
    );
end pattern_generator;


architecture Behavioral of pattern_generator is

  component clk_wiz_0
  port
   (-- Clock in ports
    clk_in_40           : in     std_logic;
    -- Clock out ports
    clk_out_80          : out    std_logic;
    clk_out_100          : out    std_logic;
    -- Status and control signals
    locked            : out    std_logic
   );
  end component;

	signal counter_a : std_logic_vector(15 downto 0) := (0 => '0', others => '0');
	signal counter_b : std_logic_vector(15 downto 0) := (0 => '1', others => '0');
	
	signal clk_ec, clk_z, zynq_clk: std_logic;
	signal locked_i: std_logic := '0';
	signal dout_fifo_generator_64to16_dv: std_logic := '0';

begin

  inst_clk_wiz_0 : clk_wiz_0
   port map ( 

   -- Clock in ports
   clk_in_40 => clk_40MHz,
  -- Clock out ports  
   clk_out_80 => clk_ec,
   clk_out_100 => clk_z,
  -- Status and control signals                
   locked => locked_i            
 );

	locked <= locked_i;

  counter_a <= counter_a + 2 when rising_edge(clk_z);
  counter_b <= counter_b + 2 when rising_edge(clk_z);

   -- instantiate DDR buffer for 16 bit out data
   ODDR_inst_gen: for i in 15 downto 0 generate
     ODDR_inst : ODDR
     generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
        INIT => '0',   -- Initial value for Q port ('1' or '0')
        SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
     port map (
        Q => zynq_data(i),   -- 1-bit DDR output
        C => clk_z,    -- 1-bit clock input
        CE => '1',  -- 1-bit clock enable input
        D1 => counter_a(i),  -- 1-bit data input (positive edge)
        D2 => counter_b(i),  -- 1-bit data input (negative edge)
        R => '0',    -- 1-bit reset input
        S => '0'     -- 1-bit set input
     );
   end generate;

   -- instantiate DDR buffer for signal FRAME
   ODDR_inst_dv : ODDR
   generic map(
      DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT => '0',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => zynq_frame,   -- 1-bit DDR output
      C => clk_z,    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => dout_fifo_generator_64to16_dv,  -- 1-bit data input (positive edge)
      D2 => dout_fifo_generator_64to16_dv,  -- 1-bit data input (negative edge)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

   -- instantiate DDR buffer for output clock
   ODDR_inst_clk : ODDR
   generic map(
      DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT => '0',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => zynq_clk,   -- 1-bit DDR output
      C => clk_z,    -- 1-bit clock input
      CE => '1',  -- 1-bit clock enable input
      D1 => '1',  -- 1-bit data input (positive edge)
      D2 => '0',  -- 1-bit data input (negative edge)
      R => '0',    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );

  -- instantiate differential output buffer for zynq_clk_p/n
	inst_OBUFDS_zynq_clk: obufds port map(zynq_clk_p, zynq_clk_n, zynq_clk);
 
end Behavioral;
