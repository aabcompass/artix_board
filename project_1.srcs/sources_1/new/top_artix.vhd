library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.VComponents.all;
--

entity top_artix is
    generic(gen_mode : std_logic := '0');
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
      led_slave: out std_logic;
      clk_gtu_aux: out std_logic;
      
      sr_ck_frw_in: in std_logic;
      sr_ck_frw_out0, sr_ck_frw_out1: out std_logic
    );
end top_artix;

architecture Behavioral of top_artix is

--Clock in Select: When '1', selects the primary input clock; When '0', the secondary input clock is selected. Available when two input clocks are specified.

	component clk_wiz_0
	port
	 (-- Clock in ports
		clk_in_40           : in     std_logic;
		clk_in2           : in     std_logic;
		clk_in_sel           : in     std_logic;
		-- Clock out ports
		clk_out_80          : out    std_logic;
		clk_out_100          : out    std_logic;
		-- Status and control signals
		reset             : in     std_logic;
		locked            : out    std_logic
	 );
	end component;

	COMPONENT pmt_readout_top
  	Port ( 
  		-- clks resets
  		clk_sp : in  STD_LOGIC; -- SPACIROC redout clock (80 MHz)
  		clk_gtu : in  STD_LOGIC; -- 400 kHz clock (really not clock, but signal)
  		reset: in std_logic;	
  		gen_mode: in std_logic;	
  		-- ext io
  		x_data_pc: in std_logic_vector(7 downto 0); -- ext. pins
  		-- dataout
  		dataout :  out std_logic_vector(511 downto 0); -- all data in one vector in oreder to facilitate data re-mapping
  		dataout_dv : out std_logic;
  		-- states
  		readout_process_state, readout_dutycounter_process_state : out std_logic_vector(3 downto 0);
  		-- config module
  		transmit_delay: in std_logic_vector(3 downto 0)
  	);
  end COMPONENT;

  COMPONENT fifo_generator_512to64
    PORT (
      rst : IN STD_LOGIC;
      wr_clk : IN STD_LOGIC;
      rd_clk : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC;
      valid : OUT STD_LOGIC
    );
  END COMPONENT;
  
  COMPONENT fifo_generator_64to16
      PORT (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        valid : OUT STD_LOGIC
      );
    END COMPONENT;  

	signal clk_ec: std_logic;
	signal clk_z: std_logic;
	signal clk_40MHZ_p_i: std_logic;
	signal clk_gtu_i: std_logic;
	signal locked_i, locked_ec_d1, locked_ec_d2, locked_z_d1, locked_z_d2: std_logic := '0';
	signal artix_40mhz_0_i, artix_40mhz_1_i: std_logic := '0';
	signal reset_readout, rst_fifo: std_logic := '1';
	signal start_load_fifo: std_logic := '0';
	signal din_fifo_generator_512to64_dv: std_logic := '0';
	signal din_fifo_generator_64to16_dv: std_logic := '0';
	signal dout_fifo_generator_64to16_dv: std_logic := '0';
	signal zynq_clk: std_logic := '0';
	
	signal readout_clk_counter: std_logic_vector(9 downto 0) := (others => '0');
	signal readout_dataout_left, readout_dataout_right: std_logic_vector(512*6-1 downto 0) := (others => '0');
	signal readout_dataout_left_dv: std_logic_vector(5 downto 0) := (others => '0');
	signal data_left_A, data_left_B, data_left_C, data_left_D, data_left_E, data_left_F: std_logic_vector(511 downto 0) := (others => '0');
	signal data_right_A, data_right_B, data_right_C, data_right_D, data_right_E, data_right_F: std_logic_vector(511 downto 0) := (others => '0');
	signal din_fifo_generator_512to64_left, din_fifo_generator_512to64_right: std_logic_vector(511 downto 0) := (others => '0');
	signal din_fifo_generator_64to16_left, din_fifo_generator_64to16_right: std_logic_vector(63 downto 0) := (others => '0');
	signal dout_fifo_generator_64to16_left, dout_fifo_generator_64to16_right: std_logic_vector(15 downto 0) := (others => '0');
	signal dout_fifo_generator_64to16: std_logic_vector(31 downto 0) := (others => '0');
	
	signal led : std_logic := '0';
	--signal counter_40MHz_slave: std_logic_vector(7 downto 0) := (others => '0');
	
	signal loader_fifo_gen_512to64_counter: std_logic_vector(4 downto 0) := (others => '0');

	signal test_counter_left, test_counter_right : std_logic_vector(7 downto 0) := (others => '0');
begin

	sr_ck_frw_out0 <= sr_ck_frw_in;
	sr_ck_frw_out1 <= sr_ck_frw_in;

  inst_clk_wiz_0 : clk_wiz_0
   port map ( 
		reset => clk_wiz_0_reset,
   -- Clock in ports
   clk_in_40 => clk_40MHz,
   clk_in2 => clk_40MHz_slave,
   clk_in_sel => artix_addr(1),
  -- Clock out ports  
   clk_out_80 => clk_ec,
   clk_out_100 => clk_z,
  -- Status and control signals                
   locked => locked_i            
 );

	locked <= locked_i;
	-- led blinking for debug
	led_a8 <= led;
	led <= not led when rising_edge(clk_ec);
	
	locked_ec_d1 <= locked_i when rising_edge(clk_ec);
	locked_ec_d2 <= locked_ec_d1 when rising_edge(clk_ec);
	locked_z_d1 <= locked_i when rising_edge(clk_z);
	locked_z_d2 <= locked_z_d1 when rising_edge(clk_z);
	
	--counter_40MHz_slave <= counter_40MHz_slave + 1 when rising_edge(clk_40MHz_slave);
	--led_slave <= counter_40MHz_slave(7);
	
	reset_ec_process: process(clk_ec)
		variable counter: integer range 0 to 1023 := 0;
	begin
		if(rising_edge(clk_ec)) then
			if(locked_ec_d2 = '0') then counter := 0;  reset_readout <= '1'; end if;
			if(counter = 1023) then reset_readout <= '0'; 
			else counter := counter + 1; end if;
		end if;
	end process;

	reset_z_process: process(clk_z)
		variable counter: integer range 0 to 1023 := 0;
	begin
		if(rising_edge(clk_z)) then
			if(locked_z_d2 = '0') then counter := 0;  rst_fifo <= '1'; end if;
			if(counter = 1023) then rst_fifo <= '0'; 
			else counter := counter + 1; end if;
		end if;
	end process;

  readout_clk_former_process: process(clk_ec)	
		variable state : integer range 0 to 1 := 0;
	begin
		if(rising_edge(clk_ec)) then
			if(reset_readout = '1') then
				state := 0;
				readout_clk_counter <= (others => '0');
				clk_40MHZ_p_i <= '0';
				clk_gtu_i <= '0';
			else
				case state is
					when 0 => if(readout_clk_counter = (2*2-1)) then
											state := state + 1;
											readout_clk_counter <= (others => '0');
										else	
											readout_clk_counter <= readout_clk_counter + 1;
										end if;
										clk_40MHZ_p_i <= not clk_40MHZ_p_i;
										clk_gtu_i <= '0';
					when 1 => if(readout_clk_counter = (2*98-1)) then
											state := 0;
											readout_clk_counter <= (others => '0');
										else
											readout_clk_counter <= readout_clk_counter + 1;
										end if;
										clk_40MHZ_p_i <= not clk_40MHZ_p_i;
										clk_gtu_i <= '1';
				end case;
			end if;
		end if;
	end process;
	
	clk_gtu_aux <= clk_gtu_i;

	inst_OBUFDS_gtu2: obufds port map(ec_clk_gtu_2_p, ec_clk_gtu_2_n, clk_gtu_i);
	inst_OBUFDS_gtu3: obufds port map(ec_clk_gtu_3_p, ec_clk_gtu_3_n, clk_gtu_i);
	inst_OBUFDS_clk40_2: obufds port map(ec_40MHz_2_p, ec_40MHz_2_n, clk_40MHZ_p_i);
	inst_OBUFDS_clk40_3: obufds port map(ec_40MHz_3_p, ec_40MHz_3_n, clk_40MHZ_p_i);
	inst_OBUFDS_ec_val_evt_2: obufds port map(ec_val_evt_2_p, ec_val_evt_2_n, '1');
	inst_OBUFDS_ec_val_evt_3: obufds port map(ec_val_evt_3_p, ec_val_evt_3_n, '1');

  -- PMT readout instantiate
  
	gen_inst_pmt_readout: for i in 0 to 5 generate
		inst_pmt_readout_left : pmt_readout_top
			Port map ( 
				-- clks resets
				clk_sp => clk_ec, --: in  STD_LOGIC; -- SPACIROC redout clock (80 MHz)
				clk_gtu => clk_gtu_i,-- : in  STD_LOGIC; -- 400 kHz clock (really not clock, but signal)
				reset => reset_readout,--: in std_logic;	
				gen_mode => gen_mode,	
				-- ext io
				x_data_pc => ec_data_left(7+8*i downto 0+8*i),--: in std_logic_vector(7 downto 0); -- ext. pins
				-- dataout
				dataout => readout_dataout_left(511+512*i downto 512*i),--:  out std_logic_vector(511 downto 0); -- all data in one vector in oreder to facilitate data re-mapping
				dataout_dv => readout_dataout_left_dv(i),--: out std_logic;
				-- states
				readout_process_state => open,--, 
				readout_dutycounter_process_state => open,--: out std_logic_vector(3 downto 0);
				-- config module
				transmit_delay => conv_std_logic_vector(7, 4)--: in std_logic_vector(3 downto 0)
			);
		
		inst_pmt_readout_right : pmt_readout_top
				Port map ( 
					-- clks resets
					clk_sp => clk_ec, --: in  STD_LOGIC; -- SPACIROC redout clock (80 MHz)
					clk_gtu => clk_gtu_i,-- : in  STD_LOGIC; -- 400 kHz clock (really not clock, but signal)
					reset => reset_readout,--: in std_logic;
					gen_mode => gen_mode,		
					-- ext io
					x_data_pc => ec_data_right(7+8*i downto 0+8*i),--: in std_logic_vector(7 downto 0); -- ext. pins
					-- dataout
					dataout => readout_dataout_right(511+512*i downto 512*i),--:  out std_logic_vector(511 downto 0); -- all data in one vector in oreder to facilitate data re-mapping
					dataout_dv => open,--: out std_logic;
					-- states
					readout_process_state => open,--, 
					readout_dutycounter_process_state => open,--: out std_logic_vector(3 downto 0);
					-- config module
					transmit_delay => conv_std_logic_vector(7, 4)--: in std_logic_vector(3 downto 0)
				);		
	end generate;
	
	-- aliasing
	start_load_fifo <= readout_dataout_left_dv(0);
	
  data_left_A <= readout_dataout_left(511+512*0 downto 512*0);
  data_left_B <= readout_dataout_left(511+512*1 downto 512*1);
  data_left_C <= readout_dataout_left(511+512*2 downto 512*2);
  data_left_D <= readout_dataout_left(511+512*3 downto 512*3);
  data_left_E <= readout_dataout_left(511+512*4 downto 512*4);
  data_left_F <= readout_dataout_left(511+512*5 downto 512*5);
  
  data_right_A <= readout_dataout_right(511+512*0 downto 512*0);
  data_right_B <= readout_dataout_right(511+512*1 downto 512*1);
  data_right_C <= readout_dataout_right(511+512*2 downto 512*2);
  data_right_D <= readout_dataout_right(511+512*3 downto 512*3);
  data_right_E <= readout_dataout_right(511+512*4 downto 512*4);
  data_right_F <= readout_dataout_right(511+512*5 downto 512*5);
  
  -- remapping
  loader_fifo_gen_512to64_cnt_proc: process(clk_ec)
  begin
  	if(rising_edge(clk_ec)) then
  		if(loader_fifo_gen_512to64_counter = "10110" or start_load_fifo = '1') then
  			loader_fifo_gen_512to64_counter <= (others => '0');
  		else
  			loader_fifo_gen_512to64_counter <= loader_fifo_gen_512to64_counter + 1;
  		end if;
  	end if;
  	
  end process;
	
  -- loader fifo_generator_512to64
  loader_fifo_generator_512to64: process(clk_ec)
    variable state: integer range 0 to 7 := 0;
  begin
    if(rising_edge(clk_ec)) then
      case state is
        when 0 => 
            if(start_load_fifo = '1') then
            	state := state + 1;
            end if;
      	when 1 =>         
						din_fifo_generator_512to64_left <= data_left_A;
						din_fifo_generator_512to64_right <= data_right_F;
						if(loader_fifo_gen_512to64_counter = "00000") then
							din_fifo_generator_512to64_dv <= '1';									
							state := state + 1;
						else
							din_fifo_generator_512to64_dv <= '0';
						end if;
				when 2 =>
            din_fifo_generator_512to64_left <= data_left_B;
            din_fifo_generator_512to64_right <= data_right_E;
						if(loader_fifo_gen_512to64_counter = "00000") then
							din_fifo_generator_512to64_dv <= '1';									
							state := state + 1;
						else
							din_fifo_generator_512to64_dv <= '0';
						end if;
        when 3 =>
            din_fifo_generator_512to64_left <= data_left_C;
            din_fifo_generator_512to64_right <= data_right_D;
						if(loader_fifo_gen_512to64_counter = "00000") then
            	din_fifo_generator_512to64_dv <= '1';									
            	state := state + 1;
            else
            	din_fifo_generator_512to64_dv <= '0';
            end if;
        when 4 =>
            din_fifo_generator_512to64_left <= data_left_D;
            din_fifo_generator_512to64_right <= data_right_C;
						if(loader_fifo_gen_512to64_counter = "00000") then
            	din_fifo_generator_512to64_dv <= '1';									
            	state := state + 1;
            else
            	din_fifo_generator_512to64_dv <= '0';
            end if;
        when 5 =>
            din_fifo_generator_512to64_left <= data_left_E;
            din_fifo_generator_512to64_right <= data_right_B;
						if(loader_fifo_gen_512to64_counter = "00000") then
            	din_fifo_generator_512to64_dv <= '1';									
            	state := state + 1;
            else
            	din_fifo_generator_512to64_dv <= '0';
            end if;
        when 6 =>
            din_fifo_generator_512to64_left <= data_left_F;
            din_fifo_generator_512to64_right <= data_right_A;
						if(loader_fifo_gen_512to64_counter = "00000") then
            	din_fifo_generator_512to64_dv <= '1';									
            	state := state + 1;
            else
            	din_fifo_generator_512to64_dv <= '0';
            end if;
        when 7 =>    
            din_fifo_generator_512to64_dv <= '0';
            state := 0;        
      end case;
    end if;
  end process;
  
  -- FIFOs for parallel to serial convertion 512 -> 64
  fifo_generator_512to64_left : fifo_generator_512to64
    PORT MAP (
      rst => rst_fifo,
      wr_clk => clk_ec,
      rd_clk => clk_ec,
      din => din_fifo_generator_512to64_left,
      wr_en => din_fifo_generator_512to64_dv,
      rd_en => '1',
      dout => din_fifo_generator_64to16_left,
      full => open,
      empty => open,
      valid => din_fifo_generator_64to16_dv
    );

  fifo_generator_512to64_right : fifo_generator_512to64
    PORT MAP (
      rst => rst_fifo,
      wr_clk => clk_ec,
      rd_clk => clk_ec,
      din => din_fifo_generator_512to64_right,
      wr_en => din_fifo_generator_512to64_dv,
      rd_en => '1',
      dout => din_fifo_generator_64to16_right,
      full => open,
      empty => open,
      valid => open
    );


  -- FIFOs for parallel to serial convertion 64 -> 16
  inst_fifo_generator_64to16_left : fifo_generator_64to16
  PORT MAP (
    rst => rst_fifo,
    wr_clk => clk_ec,
    rd_clk => clk_z,
    din => din_fifo_generator_64to16_left,
    wr_en => din_fifo_generator_64to16_dv,
    rd_en => '1',
    dout => dout_fifo_generator_64to16_left,
    full => open,
    empty => open,
    valid => dout_fifo_generator_64to16_dv
  );

  inst_fifo_generator_64to16_right : fifo_generator_64to16
  PORT MAP (
    rst => rst_fifo,
    wr_clk => clk_ec,
    rd_clk => clk_z,
    din => din_fifo_generator_64to16_right,
    wr_en => din_fifo_generator_64to16_dv,
    rd_en => '1',
    dout => dout_fifo_generator_64to16_right,
    full => open,
    empty => open,
    valid => open
  );

   
   dout_fifo_generator_64to16 <= dout_fifo_generator_64to16_right & dout_fifo_generator_64to16_left;
   -- test generator 2
   --test_counter_left <= test_counter_left + 2 when rising_edge(clk_z);
   --test_counter_right <= test_counter_right + 2 when rising_edge(clk_z);
   --dout_fifo_generator_64to16 <= test_counter_right & (test_counter_right + 1) & test_counter_left & (test_counter_left + 1) when rising_edge(clk_z);
   
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
        D1 => dout_fifo_generator_64to16(2*i),  -- 1-bit data input (positive edge) (odd ��������)
        D2 => dout_fifo_generator_64to16(2*i+1),  -- 1-bit data input (negative edge) (even ������) -- ������������
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
    
  -- clock forwarding to artixes 0 and 2
  artix_40mhz_0_i <= not artix_40mhz_0_i when rising_edge(clk_ec);
  artix_40mhz_1_i <= not artix_40mhz_1_i when rising_edge(clk_ec);
  artix_40mhz_0 <= artix_40mhz_0_i;
  artix_40mhz_1 <= artix_40mhz_1_i;
  artix_val_evt <= '1';
  
end Behavioral;
