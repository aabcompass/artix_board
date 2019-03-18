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
      clk_pri : in STD_LOGIC;--+
      artix_addr: in std_logic_vector(1 downto 0);--+
      --artix_ctrl: in std_logic;
      --clk_40MHz_slave: in STD_LOGIC; --removed
      --clk_wiz_0_reset: in STD_LOGIC; --not presented
      
      
      -- to/from other artix
      --artix_gtu: out std_logic;  --not presented
      --artix_40mhz_0: out std_logic; --removed
      --artix_40mhz_1: out std_logic; --removed
      --artix_val_evt: out std_logic := '1'; -- always '1' --??
       
      -- clk to SPACIROC
      ec_val_evt_2_p, ec_val_evt_2_n: out std_logic;
      ec_val_evt_3_p, ec_val_evt_3_n: out std_logic;
      ec_clk_gtu_2_p, ec_clk_gtu_2_n: out std_logic;
      ec_clk_gtu_3_p, ec_clk_gtu_3_n: out std_logic;
      ec_40MHz_2_p, ec_40MHz_2_n: out std_logic;
      ec_40MHz_3_p, ec_40MHz_3_n: out std_logic;
      
      -- data to ZYNQ
      zynq_frame_p, zynq_frame_n: out std_logic;
      zynq_data_p, zynq_data_n: out std_logic_vector(11 downto 0);
      zynq_clk_p, zynq_clk_n: out std_logic;
      
      --from SPACIROCs
      ec_data_left: in std_logic_vector(47 downto 0); -- A(7:0) & B(7:0) & ... & F(7:0)
      ec_transmit_on_left: in std_logic_vector(5 downto 0); -- A & B & ... & F
      ec_data_right: in std_logic_vector(47 downto 0); -- A(7:0) & B(7:0) & ... & F(7:0)
      ec_transmit_on_right: in std_logic_vector(5 downto 0); -- A & B & ... & F
      
      -- locked
      --locked: out std_logic; --XP
      --led_a8: out std_logic;  --XP
      --led_slave: out std_logic;  --XP
      --clk_gtu_aux: out std_logic;  --XP
      
      sr_ck_frw_in: in std_logic;--; -- not presented in PCB
      sr_ck_frw_out0, sr_ck_frw_out1: out std_logic
    );
end top_artix;

architecture Behavioral of top_artix is


	component clk_wiz_0
	port
	 (-- Clock in ports
		clk_in_pri           : in     std_logic;
		-- Clock out ports
		clk_ec          : out    std_logic;
		clk_ec_hf          : out    std_logic;
		clk_serdes          : out    std_logic;
		-- Status and control signals
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


	COMPONENT axis_dwidth_converter_0
		PORT (
			aclk : IN STD_LOGIC;
			aresetn : IN STD_LOGIC;
			s_axis_tvalid : IN STD_LOGIC;
			s_axis_tready : OUT STD_LOGIC;
			s_axis_tdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
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
	signal clk_hf: std_logic; --half of clk_ec
	signal clk_serdes : std_logic;

	signal clk_gtu_i: std_logic;
	
	signal locked_i, locked_ec_d1, locked_ec_d2, locked_z_d1, locked_z_d2: std_logic := '0';
	
	signal artix_40mhz_0_i, artix_40mhz_1_i: std_logic := '0';
	signal reset_readout, nreset_readout, rst_fifo: std_logic := '1';
	signal nrst_hf, rst_hf: std_logic := '0';
	signal clk_40MHZ_p_i: std_logic;
--	signal start_load_fifo: std_logic := '0';
--	signal din_fifo_generator_512to64_dv: std_logic := '0';
--	signal din_fifo_generator_64to16_dv: std_logic := '0';
--	signal dout_fifo_generator_64to16_dv: std_logic := '0';
--	signal zynq_clk: std_logic := '0';
	
	signal readout_clk_counter: std_logic_vector(9 downto 0) := (others => '0');
	signal readout_dataout_left, readout_dataout_right: std_logic_vector(512*6-1 downto 0) := (others => '0');
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
	signal m_axis_tvalid_left_hf: std_logic_vector(5 downto 0) := (others => '0');
	signal m_axis_tvalid_hf: std_logic_vector(7 downto 0) := (others => '0');
	
	signal led : std_logic := '0';
	--signal counter_40MHz_slave: std_logic_vector(7 downto 0) := (others => '0');
	
	signal loader_fifo_gen_512to64_counter: std_logic_vector(4 downto 0) := (others => '0');

	signal test_counter_left, test_counter_right : std_logic_vector(7 downto 0) := (others => '0');
	
begin

	sr_ck_frw_out0 <= sr_ck_frw_in;
	sr_ck_frw_out1 <= sr_ck_frw_in;

--  inst_clk_wiz_0 : clk_wiz_0
--   port map ( 
--   -- Clock in ports
--   clk_in_40 => clk_pri,
--   clk_in_sel => artix_addr(1),
--  -- Clock out ports  
--   clk_out_80 => clk_ec,
--   clk_out_100 => clk_z,
--  -- Status and control signals                
--   locked => locked_i            
-- );

i_clk_wiz_0 : clk_wiz_0
   port map ( 
   -- Clock in ports
   clk_in_pri => clk_pri,
  -- Clock out ports  
   clk_ec => clk_ec,
   clk_ec_hf => clk_hf,
   clk_serdes => clk_serdes,
  -- Status and control signals                
   locked => locked_i            
 );

	--locked <= locked_i;
	-- led blinking for debug
	--led_a8 <= led;
	--led <= not led when rising_edge(clk_ec);
	
	locked_ec_d1 <= locked_i when rising_edge(clk_ec);
	locked_ec_d2 <= locked_ec_d1 when rising_edge(clk_ec);
	locked_z_d1 <= locked_i when rising_edge(clk_hf);
	locked_z_d2 <= locked_z_d1 when rising_edge(clk_hf);
	
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
	
	--clk_gtu_aux <= clk_gtu_i;

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

		dw_conv_left : axis_dwidth_converter_0
				PORT MAP (
				aclk => clk_ec,
				aresetn => nreset_readout,
				s_axis_tvalid => readout_dataout_left_dv(0),
				s_axis_tready => open,
				s_axis_tdata => readout_dataout_left(511+512*i downto 512*i),
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
				s_axis_tdata => readout_dataout_right(511+512*i downto 512*i),
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
		
	serdes_left: serdes2zynq 
			Port map( 
				clk => clk_serdes,--: in STD_LOGIC;
				clkdiv => clk_hf,--: in STD_LOGIC;
				reset_serdes => rst_hf,
				datain => m_axis_tdata_left_hf(7+8*i downto 8*i),--: in STD_LOGIC_VECTOR (7 downto 0);
				dataout_p => zynq_data_p(i),--: out STD_LOGIC;
				dataout_n => zynq_data_n(i)); --: out STD_LOGIC);
		
	serdes_right: serdes2zynq 
			Port map( 
				clk => clk_serdes,--: in STD_LOGIC;
				clkdiv => clk_hf,--: in STD_LOGIC;
				reset_serdes => rst_hf,
				datain => m_axis_tdata_right_hf(7+8*i downto 8*i),--: in STD_LOGIC_VECTOR (7 downto 0);
				dataout_p => zynq_data_p(6+i),--: out STD_LOGIC;
				dataout_n => zynq_data_n(6+i)); --: out STD_LOGIC);

	end generate;
	
	m_axis_tvalid_hf <= (7 downto 0 => m_axis_tvalid_left_hf(0));

	serdes_frame: serdes2zynq 
		Port map( 
			clk => clk_serdes,--: in STD_LOGIC;
			clkdiv => clk_hf,--: in STD_LOGIC;
			reset_serdes => rst_hf,
			datain => m_axis_tvalid_hf,--: in STD_LOGIC_VECTOR (7 downto 0);
			dataout_p => zynq_frame_p,--: out STD_LOGIC;
			dataout_n => zynq_frame_n); --: out STD_LOGIC);

	serdes_frw_clk: serdes2zynq 
		Port map( 
			clk => clk_serdes,--: in STD_LOGIC;
			clkdiv => clk_hf,--: in STD_LOGIC;
			reset_serdes => rst_hf,
			datain => "01010101",--: in STD_LOGIC_VECTOR (7 downto 0);
			dataout_p => zynq_clk_p,--: out STD_LOGIC;
			dataout_n => zynq_clk_n); --: out STD_LOGIC);
  
end Behavioral;
