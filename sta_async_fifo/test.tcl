# Load .lib file
read_liberty toy.lib

# Load your RTL or synthesized netlist
read_verilog fifo1_mapped.v

# Link design
link_design fifo1   ;# top module name

# Load timing constraints
read_sdc top.sdc

report_checks -path_delay min_max
report_wns -max       ;# worst negative slack (setup)
report_wns -min       ;# worst hold slack
report_tns -max
report_tns -min
report_worst_slack -max
report_clock_skew -setup
report_clock_latency -clock rclk
report_clock_min_period -clocks rclk
report_clock_latency -clock wclk
report_clock_min_period -clocks wclk
report_power


