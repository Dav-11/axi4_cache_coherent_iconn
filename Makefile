# Makefile for adder simulation

# Source files
TOP := top # todo: add sim src

VERILOG_SOURCES := \
	./hdl/top.sv \
	./hdl/l1_controller/fsm_b_noif.sv \
	./hdl/l1_controller/fsm_a_noif.sv \
	./hdl/l1_controller/mshr.sv \
	./hdl/l1_controller/fsm_c.sv \
	./hdl/l1_controller/l1_controller_noif.sv \
	./hdl/iconn/dir_mem_arb.sv \
	./hdl/iconn/ram_test.sv \
	./hdl/iconn/interconnect_noif.sv \
	./hdl/iconn/iconn_mem_ctrl_delay.sv \
	./hdl/iconn/rrArbiters_noif.sv \
	./hdl/iconn/mem_hw.sv \
	./hdl/iconn/fsm_i_noif.sv \
	./hdl/iconn/circ_buf.sv \
	./hdl/iconn/fsm_l_noif.sv \
	./hdl/iconn/queues_noif.sv \
	./hdl/iconn/main_mem_arb.sv \
	./hdl/iconn/dir_mem.sv \
	./hdl/common/dp_ram_clk.sv \
	./hdl/common/utils.sv \
	./hdl/common/param_pkg.sv

	# todo: add sim src


# Output directory for Verilator (optional, but good for cleanliness)
BUILD_DIR := .out

.PHONY: all clean run view vcd

all: run

compile:
	mkdir -p $(BUILD_DIR)
	xvlog --sv $(VERILOG_SOURCES)

elaborate: compile
	xelab -debug typical $(TOP) -s $(TOP).sim

run: elaborate
	xsim $(TOP).sim -runall

dump.vcd: elaborate dump_vcd.tcl $(VERILOG_SOURCES)
	xsim $(TOP).sim -t dump_vcd.tcl

# Rule to view the VCD with GTKWave
view: dump.vcd
	@echo "--- Opening VCD with GTKWave ---"
	gtkwave dump.vcd &

# Rule to clean up generated files
clean:
	@echo "--- Cleaning up ---"
	rm -rf *.jou *.log *.pb xsim.dir *.sim $(BUILD_DIR)  *.wdb