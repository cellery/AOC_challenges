# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(shell find ../src/ -iname "*.*v" | grep pkg)
VERILOG_SOURCES += $(shell find ../src/ -iname "*.*v" | grep -v pkg)

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = top

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = tb

# Verilator simulation defines
EXTRA_ARGS += +define+DIM_W=38 +define+NUM_POINTS=1000 +define+NUM_CONNS=1000 +define+NUM_NTWRKS=3 

#Other verilator options
EXTRA_ARGS += --trace --trace-structs --structs-packed 

#Optionally enable memory tracing
#EXTRA_ARGS += --trace-max-array 0 --trace-max-width 0 

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim