library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

--library UNISIM;
--use UNISIM.VComponents.all;
--

entity pmt_readout_top is
	Port ( 
		-- clks resets
		clk_sp : in  STD_LOGIC; -- SPACIROC redout clock (80 MHz)
		clk_gtu : in  STD_LOGIC; -- 400 kHz clock (really not clock, but signal)
		transmit_on : in  STD_LOGIC; 
		reset: in std_logic;		
		gen_mode: in std_logic;
		acq_on: in std_logic;
		-- ext io
		x_data_pc: in std_logic_vector(7 downto 0); -- ext. pins
		x_data_ki: in std_logic;
		-- dataout
		dataout :  out std_logic_vector(64+511 downto 0) := (others => '0'); -- all data in one vector in oreder to facilitate data re-mapping
		dataout_dv : out std_logic := '0';
		-- states
		readout_process_state, readout_dutycounter_process_state : out std_logic_vector(3 downto 0);
		-- config module
		transmit_delay: in std_logic_vector(3 downto 0)
	);
end pmt_readout_top;


architecture Behavioral of pmt_readout_top is

function reverse_any_vector (a: in std_logic_vector)
return std_logic_vector is
  variable result: std_logic_vector(a'RANGE);
  alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
begin
  for i in aa'RANGE loop
    result(i) := aa(i);
  end loop;
  return result;
end; -- function reverse_any_vector


	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral : architecture is "yes";

	component clk_80MHz
	port
	 (-- Clock in ports
		CLK_IN1           : in     std_logic;
		-- Clock out ports
		CLK_OUT1          : out    std_logic;
		-- Status and control signals
		RESET             : in     std_logic;
		LOCKED            : out    std_logic
	 );
	end component;

	COMPONENT fifo_generator_1
	  PORT (
	    wr_clk : IN STD_LOGIC;
	    rd_clk : IN STD_LOGIC;
	    din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
	    wr_en : IN STD_LOGIC;
	    rd_en : IN STD_LOGIC;
	    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	    valid : OUT STD_LOGIC;
	    full : OUT STD_LOGIC;
	    empty : OUT STD_LOGIC
	  );
	END COMPONENT;
	
	signal clk_40MHZ_p_i, clk: std_logic := '1';
	signal rst_i: std_logic;
	signal clk_gtu_i: std_logic;
	signal select_sc_probe_i, select_sc_probe_d1: std_logic := '0';
	signal readout_clk_counter: std_logic_vector(9 downto 0) := (others => '0');
	signal reset_counter: std_logic_vector(20 downto 0) := (others => '0');
	signal select_sc_probe_counter: std_logic_vector(10 downto 0) := (others => '0');
	signal start_load_spaciroc_counter: std_logic_vector(10 downto 0) := (others => '0');
	signal sr_rstb_counter: std_logic_vector(10 downto 0) := (others => '0');
	signal counter_of_asics: std_logic_vector(15 downto 0) := (others => '0');
	
	signal user_led_counter : std_logic_vector(23 downto 0) := (others => '0');
	
   
    signal x_data_pc_d1, x_data_pc_d2, x_data_pc_binary: std_logic_vector(7 downto 0) := (others => '0');
    signal x_data_ki_d1, x_data_ki_d2, x_data_ki_binary: std_logic;
    signal fifo_datain: std_logic_vector(63 downto 0) := (others => '0');
    signal fifo_ki_datain: std_logic_vector(7 downto 0) := (others => '0');
    signal readout_channels_gray: std_logic_vector(63 downto 0) := (others => '0');
    signal readout_channels_ki_gray: std_logic_vector(7 downto 0) := (others => '0');
    
    signal configuration_le_d1: std_logic := '0';
    
    signal x_data_pc_d1_dv: std_logic := '0';
    signal x_data_pc_d1_or, x_data_pc_binary_or: std_logic := '0';
    
    signal readout_duty_counter: std_logic_vector(1 downto 0) := "00";

    COMPONENT gray2bin 
    Port 
    ( 
        clk : in STD_LOGIC;
        datain : in STD_LOGIC_VECTOR (7 downto 0);
        datain_dv : in std_logic;
        dataout : out STD_LOGIC_VECTOR (7 downto 0);
        dataout_dv : out std_logic
    );
    end COMPONENT;
    
    signal readout_channels_gray_dv, readout_channels_gray_dv_d1 : std_logic := '0';
    signal fifo_datain_dv : std_logic := '0';
    signal readout_bit_counter : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal readout_bit_counter2 : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal tmp_vec : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal delay_counter : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    
    signal dataout_unmapped : std_logic_vector(511 downto 0)  := (others => '0');
    signal dataout_ki_unmapped : std_logic_vector(63 downto 0)  := (others => '0');
    
    attribute keep : string;
    attribute keep of x_data_pc_d1 : signal is "true";
    attribute keep of readout_bit_counter : signal is "true";
    attribute keep of readout_bit_counter2: signal is "true";
    attribute keep of readout_process_state : signal is "true";
    attribute keep of readout_channels_ki_gray : signal is "true";
    attribute keep of dataout_ki_unmapped : signal is "true";


begin

  clk <= clk_sp;
  clk_gtu_i <= clk_gtu;

	-- Readout
	x_data_pc_d1 <= x_data_pc when rising_edge(clk);
	x_data_pc_d2 <= x_data_pc_d1 when rising_edge(clk);
	x_data_pc_binary <= x_data_pc_d2 when rising_edge(clk);

	x_data_ki_d1 <= x_data_ki when rising_edge(clk);
	x_data_ki_d2 <= x_data_ki_d1 when rising_edge(clk);
	x_data_ki_binary <= x_data_ki_d2 when rising_edge(clk);

	
	-- readout_process_v2
	readout_process_v2: process(clk)
		variable state : integer range 0 to 8 := 0;
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				state := 0;
				delay_counter <= "0000";
				readout_bit_counter <= "000000";
				readout_bit_counter2 <= "00000000";
				readout_channels_gray_dv <= '0';
			else 
				readout_process_state <= conv_std_logic_vector(state, 4);
				case state is
					when 0 => if(acq_on = '1') then
												state := state + 1;
										end if;
					when 1 => if(clk_gtu_i = '0') then
											state := state + 1;
										end if;
					-- waiting for a transmission
					when 2 => if(clk_gtu_i = '1') then
											state := state + 1;
											readout_bit_counter <= "000000";
											readout_bit_counter2 <= "00000000";
										end if;
					when 3 => if(transmit_on = '1') then
											state := state + 1;
										elsif(readout_bit_counter2 = "10111111") then --No transmit_on, i.e. no asic in most case (or it doesn't work)
											delay_counter <= "0000";
											state := 8;
										else
											readout_bit_counter2 <= readout_bit_counter2 + 1;
										end if;
					when 4 => if(delay_counter = transmit_delay) then
											state := state + 1;
											delay_counter <= "0000";
										else
											delay_counter <= delay_counter + 1;
										end if;
										readout_bit_counter <= "000000";
					-- readout
					when 5 => for i in 0 to 7 loop
											readout_channels_gray(7+i*8 downto i*8) <= readout_channels_gray(6+i*8 downto i*8) & x_data_pc_binary(i);
										end loop;
										readout_channels_ki_gray <= readout_channels_ki_gray(6 downto 0) & x_data_ki_binary;
										state := state + 1;
										if(readout_bit_counter(2 downto 0) = "111") then
											readout_channels_gray_dv <= '1';
										else
											readout_channels_gray_dv <= '0';
										end if;
					when 6 => readout_channels_gray_dv <= '0';
										if(readout_bit_counter = "111111") then
											state := 1;
										else
											state := state + 1;
											readout_bit_counter <= readout_bit_counter + 1;
										end if;
					when 7 => state := state - 2;
					when 8 => if(delay_counter = "1000") then
											state := 1;
											readout_channels_gray_dv <= '0';
										else
											readout_channels_gray_dv <= '1';
											delay_counter <= delay_counter + 1;
										end if;
				end case;				
			end if;
		end if;
	end process;
	
	-- gray2bin has a 2 clk latency
	inst_gray2bin_gen: for i in 0 to 7 generate
		inst_gray2bin: gray2bin port map(clk, readout_channels_gray(7+8*i downto 8*i), '1', fifo_datain(7+8*i downto 8*i), open);
	end generate inst_gray2bin_gen;
	--inst_gray2bin_ki: gray2bin port map(clk, readout_channels_ki_gray(7 downto 0), '1', fifo_ki_datain(7 downto 0), open);
	
	tmp_vec <=  readout_channels_ki_gray when rising_edge(clk);
	fifo_ki_datain <= tmp_vec when rising_edge(clk);
	
	readout_channels_gray_dv_d1 <= readout_channels_gray_dv when rising_edge(clk);
	fifo_datain_dv <= readout_channels_gray_dv_d1 when rising_edge(clk);

	--serial to parallel converter
	-- -- test generator 1
	serial2parallel: process(clk)
		variable state : integer range 0 to 7 := 0;
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				state := 0;
			else
				if(fifo_datain_dv = '1') then
					case state is
						when 0 => if(gen_mode = '0') then
												dataout_unmapped(63+64*7 downto 64*7) <= fifo_datain;
												dataout_ki_unmapped(7+8*7 downto 8*7) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*7 downto 64*7) <= X"3830282018100800";
												dataout_ki_unmapped(7+8*7 downto 8*7) <= X"40";
											end if;
											dataout_dv <= '0';
											state := state + 1;
						when 1 => if(gen_mode = '0') then
												dataout_unmapped(63+64*6 downto 64*6) <= fifo_datain;
												dataout_ki_unmapped(7+8*6 downto 8*6) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*6 downto 64*6) <= X"3931292119110901";
												dataout_ki_unmapped(7+8*6 downto 8*6) <= X"41";
											end if;
											dataout_dv <= '0';
											state := state + 1;
						when 2 => if(gen_mode = '0') then
												dataout_unmapped(63+64*5 downto 64*5) <= fifo_datain;
												dataout_ki_unmapped(7+8*5 downto 8*5) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*5 downto 64*5) <= X"3A322A221A120A02";
												dataout_ki_unmapped(7+8*5 downto 8*5) <= X"42";
											end if;
											dataout_dv <= '0';
											state := state + 1;
						when 3 => if(gen_mode = '0') then	
												dataout_unmapped(63+64*4 downto 64*4) <= fifo_datain;
												dataout_ki_unmapped(7+8*4 downto 8*4) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*4 downto 64*4) <= X"3B332B231B130B03";
												dataout_ki_unmapped(7+8*4 downto 8*4) <= X"43";
											end if;
											dataout_dv <= '0';
											state := state + 1;
						when 4 => if(gen_mode = '0') then	
												dataout_unmapped(63+64*3 downto 64*3) <= fifo_datain;
												dataout_ki_unmapped(7+8*3 downto 8*3) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*3 downto 64*3) <= X"3C342C241C140C04";
												dataout_ki_unmapped(7+8*3 downto 8*3) <= X"44";
											end if;
											dataout_dv <= '0';
											state := state + 1;
						when 5 => if(gen_mode = '0') then	
												dataout_unmapped(63+64*2 downto 64*2) <= fifo_datain;
												dataout_ki_unmapped(7+8*2 downto 8*2) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*2 downto 64*2) <= X"3D352D251D150D05";
												dataout_ki_unmapped(7+8*2 downto 8*2) <= X"45";
											end if;
											dataout_dv <= '0';
											state := state + 1;
						when 6 => if(gen_mode = '0') then	
												dataout_unmapped(63+64*1 downto 64*1) <= fifo_datain;
												dataout_ki_unmapped(7+8*1 downto 8*1) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*1 downto 64*1) <= X"3E362E261E160E06";
												dataout_ki_unmapped(7+8*1 downto 8*1) <= X"46";
											end if;
											dataout_dv <= '0';
											state := state + 1;
						when 7 => if(gen_mode = '0') then	
												dataout_unmapped(63+64*0 downto 64*0) <= fifo_datain;
												dataout_ki_unmapped(7+8*0 downto 8*0) <= fifo_ki_datain;
											else
												dataout_unmapped(63+64*0 downto 64*0) <= X"3F372F271F170F07";
												dataout_ki_unmapped(7+8*0 downto 8*0) <= X"47";
											end if;
											dataout_dv <= '1';
											state := 0;
					end case;
				else
					dataout_dv <= '0';
				end if;						
			end if;
		end if;
	end process; 
	
	ch_mapping: for i in 0 to 7 generate
		ch_mapping: for j in 0 to 7 generate
			constant src: integer := i*8 + (7-j); 
			constant dst: integer := i + j*8;
		begin
			dataout(dst*8 + 7 downto dst*8) <= dataout_unmapped(src*8 + 7 downto src*8);
		end generate;
	end generate;
	
	dataout(512+64-1 downto 512) <= dataout_ki_unmapped; 
	
--	dataout(512+64-1 downto 512) <= 
--		  "00" & dataout_ki_unmapped(5+6*7 downto 0+6*7)
--		& "00" & dataout_ki_unmapped(5+6*6 downto 0+6*6)
--		& "00" & dataout_ki_unmapped(5+6*5 downto 0+6*5)
--		& "00" & dataout_ki_unmapped(5+6*4 downto 0+6*4) 
--		& "00" & dataout_ki_unmapped(5+6*3 downto 0+6*3) 
--		& "00" & dataout_ki_unmapped(5+6*2 downto 0+6*2)
--		& "00" & dataout_ki_unmapped(5+6*1 downto 0+6*1) 
--		& "00" & dataout_ki_unmapped(5+6*0 downto 0+6*0);

--	dataout(512+64-1 downto 512) <= 
--		  "00" & reverse_any_vector(dataout_ki_unmapped(5+6*7+16 downto 0+6*7+16))
--		& "00" & reverse_any_vector(dataout_ki_unmapped(5+6*6+16 downto 0+6*6+16))
--		& "00" & reverse_any_vector(dataout_ki_unmapped(5+6*5+16 downto 0+6*5+16))
--		& "00" & reverse_any_vector(dataout_ki_unmapped(5+6*4+16 downto 0+6*4+16)) 
--		& "00" & reverse_any_vector(dataout_ki_unmapped(5+6*3+16 downto 0+6*3+16)) 
--		& "00" & reverse_any_vector(dataout_ki_unmapped(5+6*2+16 downto 0+6*2+16))
--		& "00" & reverse_any_vector(dataout_ki_unmapped(5+6*1+16 downto 0+6*1+16)) 
--		& "00" & reverse_any_vector(dataout_ki_unmapped(5+6*0+16 downto 0+6*0+16));


end Behavioral;



