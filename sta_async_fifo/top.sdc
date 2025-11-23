# ---------------------------------------------------------
# 1) Define the two asynchronous clocks
# ---------------------------------------------------------
create_clock -name wclk -period 10 [get_ports wclk]
create_clock -name rclk -period 10 [get_ports rclk]

# Tell STA these two clocks are entirely asynchronous
set_clock_groups -asynchronous \
    -group { wclk } \
    -group { rclk }


# ---------------------------------------------------------
# 2) Input delays for write clock domain
# ---------------------------------------------------------
set_input_delay 1 -clock wclk [get_ports wdata*]
set_input_delay 1 -clock wclk [get_ports winc]

# Do NOT assign reset to a clock (fix your mistake)
# wrst_n is async → treat separately
# set_input_delay 1 -clock wclk [get_ports wrst_n]   <-- remove


# ---------------------------------------------------------
# 3) Input delays for read clock domain
# ---------------------------------------------------------
set_input_delay 1 -clock rclk [get_ports rinc]

# Do NOT assign reset to a clock (fix your mistake)
# rrst_n is async
# set_input_delay 1 -clock rclk [get_ports rrst_n]   <-- remove


# ---------------------------------------------------------
# 4) Output delays for read clock domain
# ---------------------------------------------------------
set_output_delay 1 -clock rclk [get_ports rdata*]


# ---------------------------------------------------------
# 5) Resets are asynchronous – mark them false paths
# ---------------------------------------------------------
set_false_path -from [get_ports wrst_n]
set_false_path -from [get_ports rrst_n]

# ---------------------------------------------------------
# 6) IMPORTANT: Disable timing between the two pointer domains
# ---------------------------------------------------------
set_false_path -from [get_clocks wclk] -to [get_clocks rclk]
set_false_path -from [get_clocks rclk] -to [get_clocks wclk]
