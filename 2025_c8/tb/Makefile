# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(shell find ../src/ -iname "*.*v")

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = top

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = tb

EXTRA_ARGS += --trace --trace-structs

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim