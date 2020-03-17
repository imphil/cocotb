TOPLEVEL_LANG ?= verilog
SIM ?= icarus

PWD=$(shell pwd)

ifeq ($(OS),Msys)
WPWD=$(shell sh -c 'pwd -W')
else
WPWD=$(shell pwd)
endif

# Matrix parameters
DATA_WIDTH ?= 32
A_ROWS ?= 10
B_COLUMNS ?= 4
A_COLUMNS_B_ROWS ?= 6

ifeq ($(TOPLEVEL_LANG),verilog)
    VERILOG_SOURCES = $(WPWD)/../hdl/matrix_multiplier.v

    # Set module parameters
    ifeq ($(SIM),icarus)
        COMPILE_ARGS += -Pmatrix_multiplier.DATA_WIDTH=$(DATA_WIDTH) -Pmatrix_multiplier.A_ROWS=$(A_ROWS) -Pmatrix_multiplier.B_COLUMNS=$(B_COLUMNS) -Pmatrix_multiplier.A_COLUMNS_B_ROWS=$(A_COLUMNS_B_ROWS)
    else ifeq ($(SIM),$(filter $(SIM),questa aldec))
        SIM_ARGS += -gDATA_WIDTH=$(DATA_WIDTH) -gA_ROWS=$(A_ROWS) -gB_COLUMNS=$(B_COLUMNS) -gA_COLUMNS_B_ROWS=$(A_COLUMNS_B_ROWS)
    else ifeq ($(SIM),vcs)
        COMPILE_ARGS += -pvalue+matrix_multiplier/DATA_WIDTH=$(DATA_WIDTH) -pvalue+matrix_multiplier/A_ROWS=$(A_ROWS) -pvalue+matrix_multiplier/B_COLUMNS=$(B_COLUMNS) -pvalue+matrix_multiplier/A_COLUMNS_B_ROWS=$(A_COLUMNS_B_ROWS)
    else ifneq ($(filter $(SIM),ius xcelium),)
        EXTRA_ARGS += -defparam "matrix_multiplier.DATA_WIDTH=$(DATA_WIDTH)" -defparam "matrix_multiplier.A_ROWS=$(A_ROWS)" -defparam "matrix_multiplier.B_COLUMNS=$(B_COLUMNS)" -defparam "matrix_multiplier.A_COLUMNS_B_ROWS=$(A_COLUMNS_B_ROWS)"
    endif

else ifeq ($(TOPLEVEL_LANG),vhdl)
    VHDL_SOURCES = $(WPWD)/../../mean/hdl/mean_pkg.vhd $(WPWD)/../hdl/matrix_multiplier.vhd

    ifneq ($(filter $(SIM),GHDL questa aldec),)
        # GHDL, questa, and aldec all use SIM_ARGS with '-g' for setting generics
        SIM_ARGS += -gDATA_WIDTH=$(DATA_WIDTH) -gA_ROWS=$(A_ROWS) -gB_COLUMNS=$(B_COLUMNS) -gA_COLUMNS_B_ROWS=$(A_COLUMNS_B_ROWS)
    else ifneq ($(filter $(SIM),ius xcelium),)
        SIM_ARGS += -generic "matrix_multiplier:DATA_WIDTH=>$(DATA_WIDTH)" -generic "matrix_multiplier:A_ROWS=>$(A_ROWS)" -generic "matrix_multiplier:B_COLUMNS=>$(B_COLUMNS)" -generic "matrix_multiplier:A_COLUMNS_B_ROWS=>$(A_COLUMNS_B_ROWS)"
    endif

    ifeq ($(SIM),GHDL)
        EXTRA_ARGS += --std=08
        SIM_ARGS += --wave=wave.ghw
    endif
else
    $(error "A valid value (verilog or vhdl) was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG)")
endif

# Fix the seed to ensure deterministic tests
export RANDOM_SEED := 123456789

# Export generics to test
# Can't use plusargs since they aren't supported by GHDL
export DATA_WIDTH
export A_ROWS
export B_COLUMNS
export A_COLUMNS_B_ROWS

TOPLEVEL    := matrix_multiplier
MODULE      := test_matrix_multiplier

include $(shell cocotb-config --makefiles)/Makefile.inc
include $(shell cocotb-config --makefiles)/Makefile.sim


# Profiling

DOT_BINARY ?= dot

# Location of test_profile.pstat
ifeq ($(SIM),$(filter $(SIM),GHDL aldec))
    PSTAT_DIR = ./sim_build/
else
    PSTAT_DIR = ./
endif

test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	$(shell cocotb-config --python-bin) -m gprof2dot -f pstats $(PSTAT_DIR)$< | $(DOT_BINARY) -Tsvg -o $@

.PHONY: profile
profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg
