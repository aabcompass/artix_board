#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[8]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[2]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[0]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[1]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[3]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[4]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[5]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[6]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[7]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[9]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[10]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[12]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[14]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[16]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[18]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[20]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[22]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[24]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[26]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[28]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[30]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[31]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[29]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[27]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[25]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[23]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[21]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[19]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[17]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[15]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[13]}]
#set_property MARK_DEBUG true [get_nets {i_sc/sreg_input_reg[11]}]
#set_property MARK_DEBUG true [get_nets sr_out_OBUF]
#set_property MARK_DEBUG true [get_nets latch_IBUF]
#set_property MARK_DEBUG true [get_nets sr_ck_IBUF]
#set_property MARK_DEBUG true [get_nets sr_in_IBUF]
#set_property MARK_DEBUG true [get_nets <const0>]





#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk_ec]



