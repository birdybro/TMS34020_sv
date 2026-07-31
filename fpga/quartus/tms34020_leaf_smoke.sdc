create_clock -name fpga_clk -period 20.000 [get_ports {clk_i}]

set_input_delay -clock fpga_clk 2.000 [remove_from_collection [all_inputs] [get_ports {clk_i}]]
set_output_delay -clock fpga_clk 2.000 [all_outputs]

set_false_path -from [get_ports {reset_i}]
