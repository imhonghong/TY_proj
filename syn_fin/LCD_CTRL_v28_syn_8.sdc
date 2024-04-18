###################################################################

# Created by write_sdc on Thu Apr 18 22:29:36 2024

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_operating_conditions slow -library slow
set_wire_load_mode top
set_wire_load_model -name tsmc13_wl10 -library slow
set_ideal_network [get_ports clk]
create_clock [get_ports clk]  -period 10.04  -waveform {0 5.02}
set_input_delay -clock clk  0  [get_ports reset]
set_input_delay -clock clk  0  [get_ports {IROM_Q[7]}]
set_input_delay -clock clk  0  [get_ports {IROM_Q[6]}]
set_input_delay -clock clk  0  [get_ports {IROM_Q[5]}]
set_input_delay -clock clk  0  [get_ports {IROM_Q[4]}]
set_input_delay -clock clk  0  [get_ports {IROM_Q[3]}]
set_input_delay -clock clk  0  [get_ports {IROM_Q[2]}]
set_input_delay -clock clk  0  [get_ports {IROM_Q[1]}]
set_input_delay -clock clk  0  [get_ports {IROM_Q[0]}]
set_input_delay -clock clk  0  [get_ports {cmd[2]}]
set_input_delay -clock clk  0  [get_ports {cmd[1]}]
set_input_delay -clock clk  0  [get_ports {cmd[0]}]
set_input_delay -clock clk  0  [get_ports cmd_valid]
set_output_delay -clock clk  0  [get_ports IROM_EN]
set_output_delay -clock clk  0  [get_ports {IROM_A[5]}]
set_output_delay -clock clk  0  [get_ports {IROM_A[4]}]
set_output_delay -clock clk  0  [get_ports {IROM_A[3]}]
set_output_delay -clock clk  0  [get_ports {IROM_A[2]}]
set_output_delay -clock clk  0  [get_ports {IROM_A[1]}]
set_output_delay -clock clk  0  [get_ports {IROM_A[0]}]
set_output_delay -clock clk  0  [get_ports IRB_RW]
set_output_delay -clock clk  0  [get_ports {IRB_D[7]}]
set_output_delay -clock clk  0  [get_ports {IRB_D[6]}]
set_output_delay -clock clk  0  [get_ports {IRB_D[5]}]
set_output_delay -clock clk  0  [get_ports {IRB_D[4]}]
set_output_delay -clock clk  0  [get_ports {IRB_D[3]}]
set_output_delay -clock clk  0  [get_ports {IRB_D[2]}]
set_output_delay -clock clk  0  [get_ports {IRB_D[1]}]
set_output_delay -clock clk  0  [get_ports {IRB_D[0]}]
set_output_delay -clock clk  0  [get_ports {IRB_A[5]}]
set_output_delay -clock clk  0  [get_ports {IRB_A[4]}]
set_output_delay -clock clk  0  [get_ports {IRB_A[3]}]
set_output_delay -clock clk  0  [get_ports {IRB_A[2]}]
set_output_delay -clock clk  0  [get_ports {IRB_A[1]}]
set_output_delay -clock clk  0  [get_ports {IRB_A[0]}]
set_output_delay -clock clk  0  [get_ports busy]
set_output_delay -clock clk  0  [get_ports done]
