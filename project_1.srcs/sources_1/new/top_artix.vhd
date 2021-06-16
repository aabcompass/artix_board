-------------------------------------------------------
--! @file top_artix.vhd
--! @brief Artix top level module
--! @author Alexander Belov
-------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library UNISIM;
use UNISIM.VComponents.all;


Library xpm;
use xpm.vcomponents.all;
--

entity top_artix is
    generic(CLK_RATIO : integer := 75);
    Port 
    ( 
      --! system
      clk_pri : in STD_LOGIC;--!< Primary clock from Zynq
      artix_addr: in std_logic_vector(1 downto 0);--!< 2bit address for distinguish which Artix (from 3)
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
      ec_data_left: in std_logic_vector(47 downto 0); --!< Data signals from ASICs A(7:0) & B(7:0) & ... & F(7:0)
      ec_data_ki_left: in std_logic_vector(5 downto 0); --!< Data signals from ASICs A(7:0) & B(7:0) & ... & F(7:0)
      ec_transmit_on_left: in std_logic_vector(5 downto 0); --!< Transmit signal from ASICs A & B & ... & F
      ec_data_right: in std_logic_vector(47 downto 0); --!< Data signals from ASICs  A(7:0) & B(7:0) & ... & F(7:0)
      ec_data_ki_right: in std_logic_vector(5 downto 0); --!< Data signals from ASICs  A(7:0) & B(7:0) & ... & F(7:0)
      ec_transmit_on_right: in std_logic_vector(5 downto 0); --!< Transmit signal from ASICs A & B & ... & F
      
      --! from SPACIROCs 
      sr_ck_frw_in: in std_logic;--; -- not presented in PCB
      sr_ck_frw_out0, sr_ck_frw_out1: out std_logic;
      
      bitstream_in: in std_logic;
      bitstream_out: out std_logic;
			sr_ck: in STD_LOGIC;
		  sr_in : in STD_LOGIC;
		  sr_out : out STD_LOGIC;
			latch : in STD_LOGIC
    );
end top_artix;

architecture Behavioral of top_artix is

	--constant gen_mode : std_logic := '0'; 

	COMPONENT vio_0
		PORT (
			clk : IN STD_LOGIC;
			probe_out0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			probe_out1 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			probe_out2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
		);
	END COMPONENT;


component clk_wiz_div10
port
 (-- Clock in ports
  -- Clock out ports
  clk_200MHz          : out    std_logic;
  clk_100MHz          : out    std_logic;
  clk_serdes          : out    std_logic;
  clk_serdes_shifted          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  clk_in_pri           : in     std_logic
 );
end component;
	component clk_ec_gen
	port
	 (-- Clock in ports
		-- Clock out ports
		clk_ec          : out    std_logic;
		clk_hf          : out    std_logic;
		clk_ec_serdes          : out    std_logic;
		-- Status and control signals
		reset             : in     std_logic;
		locked            : out    std_logic;
		clk_in1           : in     std_logic
	 );
	 end component;

	COMPONENT slow_ctrl is
			Port ( clk : in STD_LOGIC;
							sr_ck: in STD_LOGIC;
						 sr_in : in STD_LOGIC;
						 sr_out : out STD_LOGIC;
						 latch : in STD_LOGIC;
						 sreg_input_reg: out std_logic_vector(31 downto 0);
						 sreg_output_reg: in std_logic_vector(31 downto 0));
	end COMPONENT;

	COMPONENT asic_odelay is
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
    	shift_time: in std_logic_vector(2 downto 0)
    );
	end COMPONENT;


	COMPONENT pmt_readout_top
  	Port ( 
  		-- clks resets
  		clk_sp : in  STD_LOGIC; -- SPACIROC redout clock (80 MHz)
  		clk_gtu : in  STD_LOGIC; -- 400 kHz clock (really not clock, but signal)
  		reset: in std_logic;	
  		gen_mode: in std_logic;	
  		-- ext io
  		x_data_pc: in std_logic_vector(7 downto 0); -- ext. pins
  		x_data_ki: in std_logic; -- ext. pins
  		-- dataout
  		dataout :  out std_logic_vector(64+511 downto 0); -- all data in one vector in oreder to facilitate data re-mapping
  		dataout_dv : out std_logic;
  		-- states
  		readout_process_state, readout_dutycounter_process_state : out std_logic_vector(3 downto 0);
  		-- config module
  		transmit_delay: in std_logic_vector(3 downto 0)
  	);
  end COMPONENT;


	COMPONENT axis_dwidth_converter_0
		PORT (
			aclk : IN STD_LOGIC;
			aresetn : IN STD_LOGIC;
			s_axis_tvalid : IN STD_LOGIC;
			s_axis_tready : OUT STD_LOGIC;
			s_axis_tdata : IN STD_LOGIC_VECTOR((511+64) DOWNTO 0);
			m_axis_tvalid : OUT STD_LOGIC;
			m_axis_tready : IN STD_LOGIC;
			m_axis_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT axis_clock_converter_0
	  PORT (
	    s_axis_aresetn : IN STD_LOGIC;
	    m_axis_aresetn : IN STD_LOGIC;
	    s_axis_aclk : IN STD_LOGIC;
	    s_axis_tvalid : IN STD_LOGIC;
	    s_axis_tready : OUT STD_LOGIC;
	    s_axis_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	    m_axis_aclk : IN STD_LOGIC;
	    m_axis_tvalid : OUT STD_LOGIC;
	    m_axis_tready : IN STD_LOGIC;
	    m_axis_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	  );
	END COMPONENT;	
	
	COMPONENT serdes2zynq is
	    Port ( clk : in STD_LOGIC;
	           clkdiv : in STD_LOGIC;
	           reset_serdes: in std_logic;
	           datain : in STD_LOGIC_VECTOR (7 downto 0);
	           dataout_p : out STD_LOGIC;
	           dataout_n : out STD_LOGIC);
	end COMPONENT;

	signal clk_ec: std_logic;
	signal clk_200MHz: std_logic;
	signal clk_hf: std_logic; --half of clk_ec
	signal clk_serdes : std_logic;
	signal clk_serdes_shifted : std_logic;
	signal clk_ec_serdes : std_logic;

	signal clk_gtu_i: std_logic;
	
	signal locked_i, locked_clk_ec, locked_ec_d1, locked_ec_d2, locked_z_d1, locked_z_d2: std_logic := '0';
	signal clk_wiz_div10_rst: std_logic;
	
	signal artix_40mhz_0_i, artix_40mhz_1_i: std_logic := '0';
	signal reset_readout, nreset_readout, rst_fifo: std_logic := '1';
	signal reset_asic_odelay_cmd, reset_asic_odelay: std_logic := '1';
	signal nrst_hf, rst_hf: std_logic := '0';
	signal clk_40MHZ_p_i: std_logic;
--	signal start_load_fifo: std_logic := '0';
--	signal din_fifo_generator_512to64_dv: std_logic := '0';
--	signal din_fifo_generator_64to16_dv: std_logic := '0';
--	signal dout_fifo_generator_64to16_dv: std_logic := '0';
--	signal zynq_clk: std_logic := '0';
	
	signal readout_clk_counter: std_logic_vector(9 downto 0) := (others => '0');
	signal readout_dataout_left, readout_dataout_right: std_logic_vector((512+64)*6-1 downto 0) := (others => '0');
	signal readout_dataout_left_dv: std_logic_vector(5 downto 0) := (others => '0');
	
	signal m_axis_tvalid_left, m_axis_tvalid_right: std_logic_vector(5 downto 0) := (others => '0');
	signal m_axis_tready_left, m_axis_tready_right: std_logic_vector(5 downto 0) := (others => '0');
--	signal data_left_A, data_left_B, data_left_C, data_left_D, data_left_E, data_left_F: std_logic_vector(511 downto 0) := (others => '0');
--	signal data_right_A, data_right_B, data_right_C, data_right_D, data_right_E, data_right_F: std_logic_vector(511 downto 0) := (others => '0');
--	signal din_fifo_generator_512to64_left, din_fifo_generator_512to64_right: std_logic_vector(511 downto 0) := (others => '0');
--	signal din_fifo_generator_64to16_left, din_fifo_generator_64to16_right: std_logic_vector(63 downto 0) := (others => '0');
--	signal dout_fifo_generator_64to16_left, dout_fifo_generator_64to16_right: std_logic_vector(15 downto 0) := (others => '0');
--	signal dout_fifo_generator_64to16: std_logic_vector(31 downto 0) := (others => '0');

	signal m_axis_tdata_left, m_axis_tdata_right: std_logic_vector(6*8-1 downto 0) := (others => '0');
	signal m_axis_tdata_left_hf, m_axis_tdata_right_hf: std_logic_vector(6*8-1 downto 0) := (others => '0');
	signal m_axis_tdata_left_hf_2, m_axis_tdata_right_hf_2: std_logic_vector(6*8-1 downto 0) := (others => '0');
	signal m_axis_tvalid_left_hf: std_logic_vector(5 downto 0) := (others => '0');
	signal m_axis_tvalid_hf: std_logic_vector(7 downto 0) := (others => '0');
	signal m_axis_tvalid_hf_2: std_logic_vector(7 downto 0) := (others => '0');
	
	signal led : std_logic := '0';
	--signal counter_40MHz_slave: std_logic_vector(7 downto 0) := (others => '0');
	
	signal loader_fifo_gen_512to64_counter: std_logic_vector(4 downto 0) := (others => '0');

	signal test_counter_left, test_counter_right : std_logic_vector(7 downto 0) := (others => '0');
	
	signal idelay_REFCLK_200MHZ: std_logic;
	signal idelay_rst_200MHZ: std_logic;
	signal transmit_delay, transmit_delay_vio, transmit_delay_sc: std_logic_vector(3 downto 0);
	
	signal ec_transmit_on_left_d1, ec_transmit_on_right_d1: std_logic_vector(5 downto 0) := (others => '0');
	signal sreg_input_reg, sreg_output_reg: std_logic_vector(31 downto 0) := (others => '0');
	signal shift_time, shift_time_sc, shift_time_vio: std_logic_vector(2 downto 0) := (others => '0');
	signal gen_mode, vio_influence: std_logic_vector(0 downto 0) := "0";
	signal is_testmode2, is_testmode2_sync: std_logic:= '0';
	signal frame_on, frame_on_sync: std_logic:= '0';
	
   attribute keep : string;
	attribute keep of ec_transmit_on_left_d1 : signal is "true";
	attribute keep of ec_transmit_on_right_d1 : signal is "true";
	
	
begin


	bitstream_out <= bitstream_in;

	sr_ck_frw_out0 <= sr_ck_frw_in;
	sr_ck_frw_out1 <= sr_ck_frw_in;

	i_clk_ec_gen : clk_ec_gen
   port map ( 
   -- Clock out ports  
    clk_ec => clk_ec,
    clk_ec_serdes => clk_ec_serdes,
    clk_hf => clk_hf,
   -- Status and control signals                
    reset => '0',
    locked => locked_clk_ec,
    -- Clock in ports
    clk_in1 => clk_pri--clk_hf
  );

	clk_wiz_div10_rst <= not locked_clk_ec;

	i_clk_wiz : clk_wiz_div10
   port map ( 
    -- Clock in ports
    clk_in_pri => clk_hf,
    reset => clk_wiz_div10_rst,
    -- Clock out ports  
    clk_200MHz => clk_200MHz,--clk_ec,
    clk_100MHz => open, --clk_hf,
    clk_serdes => clk_serdes,
    clk_serdes_shifted => clk_serdes_shifted,
    -- Status and control signals                
    locked => locked_i            
 );
	
		
	locked_ec_d1 <= locked_clk_ec when rising_edge(clk_ec);
	locked_ec_d2 <= locked_clk_ec when rising_edge(clk_ec);
	locked_z_d1 <= locked_i when rising_edge(clk_hf);
	locked_z_d2 <= locked_z_d1 when rising_edge(clk_hf);
		
	reset_ec_process: process(clk_ec)
		variable counter: integer range 0 to 1023 := 0;
	begin
		if(rising_edge(clk_ec)) then
			if(locked_ec_d2 = '0') then counter := 0;  reset_readout <= '1'; end if;
			if(counter = 1023) then reset_readout <= '0'; 
			else counter := counter + 1; end if;
		end if;
	end process;
	
	nreset_readout <= not reset_readout;

	reset_ec_hf_process: process(clk_hf)
		variable counter: integer range 0 to 1023 := 0;
	begin
		if(rising_edge(clk_hf)) then
			if(locked_z_d2 = '0') then counter := 0;  nrst_hf <= '0'; rst_hf <= '1'; end if;
			if(counter = 1023) then nrst_hf <= '1'; rst_hf <= '0';
			else counter := counter + 1; end if;
		end if;
	end process;

	i_sc: slow_ctrl 
			Port map( clk => clk_200MHz,--: in STD_LOGIC;
							sr_ck => sr_ck,--: in STD_LOGIC;
						 sr_in => sr_in,--: in STD_LOGIC;
						 sr_out => sr_out,--: out STD_LOGIC;
						 latch => latch,--: in STD_LOGIC;
						 sreg_input_reg => sreg_input_reg,--: out std_logic_vector(31 downto 0);
						 sreg_output_reg => sreg_output_reg);--: in std_logic_vector(31 downto 0));


	is_testmode2 <= sreg_input_reg(8);
	frame_on <= sreg_input_reg(10); 
	
	 xpm_cdc_gen_mode0 : xpm_cdc_single
	 generic map (
	    DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
	    INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
	                         -- values
	    SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
	    SRC_INPUT_REG => 0   -- DECIMAL; integer; 0=do not register input, 1=register input
	 )
	 port map (
	    dest_out => gen_mode(0), -- 1-bit output: src_in synchronized to the destination clock domain. This output
	                          -- is registered.

	    dest_clk => clk_ec, -- 1-bit input: Clock signal for the destination clock domain.
	    src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
	    src_in => sreg_input_reg(3)      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
	 );	

  xpm_cdc_transmit_delay_sc : xpm_cdc_array_single
   generic map (
      DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
      INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
                           -- values
      SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 0,  -- DECIMAL; 0=do not register input, 1=register input
      WIDTH => 4           -- DECIMAL; range: 1-1024
   )
   port map (
      dest_out => transmit_delay_sc, -- WIDTH-bit output: src_in synchronized to the destination clock domain. This
                            -- output is registered.

      dest_clk => clk_ec, -- 1-bit input: Clock signal for the destination clock domain.
      src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in => sreg_input_reg(7 downto 4)     -- WIDTH-bit input: Input single-bit array to be synchronized to destination clock
   );




   xpm_cdc_shift_time_sc : xpm_cdc_array_single
   generic map (
      DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
      INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
                           -- values
      SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 0,  -- DECIMAL; 0=do not register input, 1=register input
      WIDTH => 3           -- DECIMAL; range: 1-1024
   )
   port map (
      dest_out => shift_time_sc, -- WIDTH-bit output: src_in synchronized to the destination clock domain. This
                            -- output is registered.

      dest_clk => clk_ec, -- 1-bit input: Clock signal for the destination clock domain.
      src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in => sreg_input_reg(2 downto 0)      -- WIDTH-bit input: Input single-bit array to be synchronized to destination clock
    );

  xpm_cdc_single_inst : xpm_cdc_single
	 generic map (
	    DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
	    INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
	                         -- values
	    SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
	    SRC_INPUT_REG => 0   -- DECIMAL; integer; 0=do not register input, 1=register input
	 )
	 port map (
	    dest_out => reset_asic_odelay_cmd, -- 1-bit output: src_in synchronized to the destination clock domain. This output
	                          -- is registered.

	    dest_clk => clk_ec, -- 1-bit input: Clock signal for the destination clock domain.
	    src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
	    src_in => sreg_input_reg(9)      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
	 );	

	
  xpm_cdc_is_testmode2_sync : xpm_cdc_single
	 generic map (
	    DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
	    INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
	                         -- values
	    SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
	    SRC_INPUT_REG => 0   -- DECIMAL; integer; 0=do not register input, 1=register input
	 )
	 port map (
	    dest_out => is_testmode2_sync, -- 1-bit output: src_in synchronized to the destination clock domain. This output
	                          -- is registered.

	    dest_clk => clk_hf, -- 1-bit input: Clock signal for the destination clock domain.
	    src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
	    src_in => is_testmode2      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
	 );	

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
					when 1 => if(readout_clk_counter = (2*(CLK_RATIO-2)-1)) then
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

	reset_asic_odelay <= reset_readout or reset_asic_odelay_cmd;

 i_asic_odelay: asic_odelay 
    Port map( 
      clk => clk_ec_serdes,--: std_logic;
      clkdiv => clk_ec,--: std_logic;
      reset_serdes => reset_asic_odelay,--reset_readout,--: std_logic;
      -- inputs
      clk_gtu => clk_gtu_i,--: in std_logic;
      clk_40MHZ_p => clk_40MHZ_p_i,--: in std_logic;
      -- to ASICs
      ec_clk_gtu_2_p => ec_clk_gtu_2_p, 
      ec_clk_gtu_2_n => ec_clk_gtu_2_n,--: out std_logic;
   		ec_clk_gtu_3_p => ec_clk_gtu_3_p,--, 
   		ec_clk_gtu_3_n => ec_clk_gtu_3_n,--: out std_logic;
    	ec_40MHz_2_p => ec_40MHz_2_p,--, 
    	ec_40MHz_2_n => ec_40MHz_2_n,--: out std_logic;
    	ec_40MHz_3_p => ec_40MHz_3_p,--, 
    	ec_40MHz_3_n => ec_40MHz_3_n,--: out std_logic;
     	ec_40MHz_tst_p => open,--, 
    	ec_40MHz_tst_n => open,--: out std_logic;
   	-- params
    	shift_time => shift_time--: in std_logic_vector(1 downto 0)
    );
	
	--clk_gtu_aux <= clk_gtu_i;

	inst_OBUFDS_ec_val_evt_2: obufds port map(ec_val_evt_2_p, ec_val_evt_2_n, '1');
	inst_OBUFDS_ec_val_evt_3: obufds port map(ec_val_evt_3_p, ec_val_evt_3_n, '1');

  -- PMT readout instantiate

--	i_vio_0 : vio_0
--  PORT MAP (
--    clk => clk_ec,
--    probe_out0 => transmit_delay_vio,
--    probe_out1 => shift_time_vio,
--    probe_out2 => vio_influence
--	--transmit_delay <= X"7"
--  );
  
  timings_param_selector: process(clk_ec)
  begin
  	if(rising_edge(clk_ec)) then
  		if(vio_influence = "1") then
  			transmit_delay <= transmit_delay_vio;
  			shift_time <= shift_time_vio;
  		else
  			transmit_delay <= transmit_delay_sc;
  			shift_time <= shift_time_sc;  			
  		end if;
  	end if;
  end process;

	ec_transmit_on_left_d1 <= ec_transmit_on_left when rising_edge(clk_ec);
	ec_transmit_on_right_d1 <= ec_transmit_on_right when rising_edge(clk_ec);

  
	gen_inst_pmt_readout: for i in 0 to 5 generate
		inst_pmt_readout_left : pmt_readout_top
			Port map ( 
				-- clks resets
				clk_sp => clk_ec, --: in  STD_LOGIC; -- SPACIROC redout clock (80 MHz)
				clk_gtu => clk_gtu_i,-- : in  STD_LOGIC; -- 400 kHz clock (really not clock, but signal)
				reset => reset_readout,--: in std_logic;	
				gen_mode => gen_mode(0),	
				-- ext io
				x_data_pc => ec_data_left(7+8*i downto 0+8*i),--: in std_logic_vector(7 downto 0); -- ext. pins
				x_data_ki => ec_data_ki_left(i),--: in std_logic_vector(7 downto 0); -- ext. pins
				-- dataout
				dataout => readout_dataout_left((511+64)+(512+64)*i downto (512+64)*i),--:  out std_logic_vector(511 downto 0); -- all data in one vector in oreder to facilitate data re-mapping
				dataout_dv => readout_dataout_left_dv(i),--: out std_logic;
				-- states
				readout_process_state => open,--, 
				readout_dutycounter_process_state => open,--: out std_logic_vector(3 downto 0);
				-- config module
				transmit_delay => transmit_delay--conv_std_logic_vector(7, 4)--: in std_logic_vector(3 downto 0)
			);
		
		inst_pmt_readout_right : pmt_readout_top
			Port map ( 
				-- clks resets
				clk_sp => clk_ec, --: in  STD_LOGIC; -- SPACIROC redout clock (80 MHz)
				clk_gtu => clk_gtu_i,-- : in  STD_LOGIC; -- 400 kHz clock (really not clock, but signal)
				reset => reset_readout,--: in std_logic;
				gen_mode => gen_mode(0),		
				-- ext io
				x_data_pc => ec_data_right(7+8*i downto 0+8*i),--: in std_logic_vector(7 downto 0); -- ext. pins
				x_data_ki => ec_data_ki_right(i),--: in std_logic_vector(7 downto 0); -- ext. pins
				-- dataout
				dataout => readout_dataout_right((511+64)+(512+64)*i downto (512+64)*i),--:  out std_logic_vector(511 downto 0); -- all data in one vector in oreder to facilitate data re-mapping
				dataout_dv => open,--: out std_logic;
				-- states
				readout_process_state => open,--, 
				readout_dutycounter_process_state => open,--: out std_logic_vector(3 downto 0);
				-- config module
				transmit_delay => transmit_delay--conv_std_logic_vector(7, 4)--: in std_logic_vector(3 downto 0)
			);		

		dw_conv_left : axis_dwidth_converter_0
				PORT MAP (
				aclk => clk_ec,
				aresetn => nreset_readout,
				s_axis_tvalid => readout_dataout_left_dv(0),
				s_axis_tready => open,
				s_axis_tdata => readout_dataout_left((511+64)+(512+64)*i downto (512+64)*i),
				m_axis_tvalid => m_axis_tvalid_left(i),
				m_axis_tready => m_axis_tready_left(i),
				m_axis_tdata => m_axis_tdata_left(7+8*i downto 8*i)
			);

		dw_conv_right : axis_dwidth_converter_0
			PORT MAP (
				aclk => clk_ec,
				aresetn => nreset_readout,
				s_axis_tvalid => readout_dataout_left_dv(0),
				s_axis_tready => open,
				s_axis_tdata => readout_dataout_right((511+64)+(512+64)*i downto (512+64)*i),
				m_axis_tvalid => m_axis_tvalid_right(i),
				m_axis_tready => m_axis_tready_right(i),
				m_axis_tdata => m_axis_tdata_right(7+8*i downto 8*i)
			);
			
	axis_clkconv_left : axis_clock_converter_0
			PORT MAP (
				s_axis_aresetn => nreset_readout,
				m_axis_aresetn => nrst_hf,
				s_axis_aclk => clk_ec,
				s_axis_tvalid => m_axis_tvalid_left(i),
				s_axis_tready => m_axis_tready_left(i),
				s_axis_tdata => m_axis_tdata_left(7+8*i downto 8*i),
				m_axis_aclk => clk_hf,
				m_axis_tvalid => m_axis_tvalid_left_hf(i),
				m_axis_tready => '1',
				m_axis_tdata => m_axis_tdata_left_hf(7+8*i downto 8*i)
			);
		
	axis_clkconv_right : axis_clock_converter_0
			PORT MAP (
				s_axis_aresetn => nreset_readout,
				m_axis_aresetn => nrst_hf,
				s_axis_aclk => clk_ec,
				s_axis_tvalid => m_axis_tvalid_right(i),
				s_axis_tready => m_axis_tready_right(i),
				s_axis_tdata => m_axis_tdata_right(7+8*i downto 8*i),
				m_axis_aclk => clk_hf,
				m_axis_tvalid => open,
				m_axis_tready => '1',
				m_axis_tdata => m_axis_tdata_right_hf(7+8*i downto 8*i)
			);
	test_mode2_select: process(clk_hf)
		variable artix_addr_mode: std_logic_vector(1 downto 0);
	begin
		if(rising_edge(clk_hf)) then
			--artix_addr_mode
			case artix_addr is
				when "00" => artix_addr_mode := "10";
				when "01" => artix_addr_mode := "01";
				when "10" => artix_addr_mode := "00";
				when others => artix_addr_mode := "00";			
			end case;
			if(is_testmode2_sync = '1') then
				m_axis_tdata_left_hf_2(7+8*i downto 8*i) <= "00" & artix_addr_mode & '0' & conv_std_logic_vector(i, 3);
				m_axis_tdata_right_hf_2(7+8*i downto 8*i) <= "00" & artix_addr_mode & '1' & conv_std_logic_vector(i, 3);
			else
				m_axis_tdata_left_hf_2(7+8*i downto 8*i) <= m_axis_tdata_left_hf(7+8*i downto 8*i);
				m_axis_tdata_right_hf_2(7+8*i downto 8*i) <= m_axis_tdata_right_hf(7+8*i downto 8*i);
			end if;		
		end if;
	end process;
		
		
	serdes_left: serdes2zynq 
			Port map( 
				clk => clk_serdes,--: in STD_LOGIC;
				clkdiv => clk_hf,--: in STD_LOGIC;
				reset_serdes => rst_hf,
				datain => m_axis_tdata_left_hf_2(7+8*i downto 8*i),--: in STD_LOGIC_VECTOR (7 downto 0);
				dataout_p => zynq_data_p(i),--: out STD_LOGIC;
				dataout_n => zynq_data_n(i)); --: out STD_LOGIC);
		
	serdes_right: serdes2zynq 
			Port map( 
				clk => clk_serdes,--: in STD_LOGIC;
				clkdiv => clk_hf,--: in STD_LOGIC;
				reset_serdes => rst_hf,
				datain => m_axis_tdata_right_hf_2(7+8*i downto 8*i),--: in STD_LOGIC_VECTOR (7 downto 0);
				dataout_p => zynq_data_p(6+i),--: out STD_LOGIC;
				dataout_n => zynq_data_n(6+i)); --: out STD_LOGIC);

	end generate;
	
	--m_axis_tvalid_hf <= (7 downto 0 => (m_axis_tvalid_left_hf(0) and frame_on_sync));
	m_axis_tvalid_hf <= (7 downto 0 => (m_axis_tvalid_left_hf(0)));
	--m_axis_tvalid_hf_2 <= m_axis_tvalid_hf when rising_edge(clk_serdes);

	  xpm_frame_on : xpm_cdc_single
   generic map (
      DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
      INIT_SYNC_FF => 0,   -- DECIMAL; integer; 0=disable simulation init values, 1=enable simulation init
                           -- values
      SIM_ASSERT_CHK => 0, -- DECIMAL; integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 0   -- DECIMAL; integer; 0=do not register input, 1=register input
   )
   port map (
      dest_out => frame_on_sync, -- 1-bit output: src_in synchronized to the destination clock domain. This output
                            -- is registered.

      dest_clk => clk_hf, -- 1-bit input: Clock signal for the destination clock domain.
      src_clk => '0',   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in => frame_on      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
   );

	frame_on_process: process(clk_hf)
		variable state : integer range 0 to 3 := 0;
	begin
		if(rising_edge(clk_hf)) then
			case state is
				when 0 => m_axis_tvalid_hf_2 <= (others => '0');
									if(frame_on_sync = '1') then
										state := state + 1;
									end if;
				when 1 => if(m_axis_tvalid_left_hf(0) = '0') then
										state := state + 1;
									end if;
				when 2 => m_axis_tvalid_hf_2 <= m_axis_tvalid_hf;
									if(frame_on_sync = '0') then
										state := state + 1;
									end if;
				when 3 => m_axis_tvalid_hf_2 <= m_axis_tvalid_hf;
									if(m_axis_tvalid_left_hf(0) = '0') then
										state := 0;
									end if;
			end case;
		end if; 
	end process;

	serdes_frame: serdes2zynq 
		Port map( 
			clk => clk_serdes,--: in STD_LOGIC;
			clkdiv => clk_hf,--: in STD_LOGIC;
			reset_serdes => rst_hf,
			datain => m_axis_tvalid_hf_2,--: in STD_LOGIC_VECTOR (7 downto 0);
			dataout_p => zynq_frame_p,--: out STD_LOGIC;
			dataout_n => zynq_frame_n); --: out STD_LOGIC);

	idelay_REFCLK_200MHZ <= clk_ec;
	idelay_rst_200MHZ <= reset_readout;
	
	serdes_frw_clk: serdes2zynq
		Port map( 
			clk => clk_serdes_shifted,--: in STD_LOGIC;
			clkdiv => clk_hf,--: in STD_LOGIC;
			--idelay_REFCLK_200MHZ => idelay_REFCLK_200MHZ,
			--idelay_rst_200MHZ => idelay_rst_200MHZ,
			reset_serdes => rst_hf,
			datain => "01010101",--: in STD_LOGIC_VECTOR (7 downto 0);
			dataout_p => zynq_clk_p,--: out STD_LOGIC;
			dataout_n => zynq_clk_n); --: out STD_LOGIC);
  
end Behavioral;
