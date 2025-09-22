# Start VCD tracing (writes to 'dump.vcd' by default)
open_vcd          ;# opens dump.vcd automatically
log_vcd [get_objects -r /tb_adder/*]
start_vcd

run all

stop_vcd
quit