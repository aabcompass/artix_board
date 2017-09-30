create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list inst_clk_wiz_0/inst/clk_out_100]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dout_fifo_generator_64to16_left[0]} {dout_fifo_generator_64to16_left[1]} {dout_fifo_generator_64to16_left[2]} {dout_fifo_generator_64to16_left[3]} {dout_fifo_generator_64to16_left[4]} {dout_fifo_generator_64to16_left[5]} {dout_fifo_generator_64to16_left[6]} {dout_fifo_generator_64to16_left[7]} {dout_fifo_generator_64to16_left[8]} {dout_fifo_generator_64to16_left[9]} {dout_fifo_generator_64to16_left[10]} {dout_fifo_generator_64to16_left[11]} {dout_fifo_generator_64to16_left[12]} {dout_fifo_generator_64to16_left[13]} {dout_fifo_generator_64to16_left[14]} {dout_fifo_generator_64to16_left[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dout_fifo_generator_64to16_right[0]} {dout_fifo_generator_64to16_right[1]} {dout_fifo_generator_64to16_right[2]} {dout_fifo_generator_64to16_right[3]} {dout_fifo_generator_64to16_right[4]} {dout_fifo_generator_64to16_right[5]} {dout_fifo_generator_64to16_right[6]} {dout_fifo_generator_64to16_right[7]} {dout_fifo_generator_64to16_right[8]} {dout_fifo_generator_64to16_right[9]} {dout_fifo_generator_64to16_right[10]} {dout_fifo_generator_64to16_right[11]} {dout_fifo_generator_64to16_right[12]} {dout_fifo_generator_64to16_right[13]} {dout_fifo_generator_64to16_right[14]} {dout_fifo_generator_64to16_right[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list dout_fifo_generator_64to16_dv]]

