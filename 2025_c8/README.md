# AOC 2025 Challenge 8

This project contains a python solution for both parts of the challenge. I've also created a RTL solution for the first part of this question. Please refer to [Summary](docs/Summary.pdf) for a more detailed breakdown of the RTL project and the testbench. See below sections on how to run the test bench and synthesize the module.

## Prerequisites
Here's a list of various tool versions I used to run the simulation and synthesis. I would recommend matching these versions but not necessarily required, see below Setup Environment section on how to setup your environment.
- Ubuntu 22.04 LTS
- Python 3.12.3 
- Verilator 5.043 devel rev v5.042-142-g8130fed77
- Vivado 2025.2

## Repository layout

- docs/  - Various diagrams of some of the blocks, a PDF going into more details on the blocks in this module
- misc/ - Test stimulus files
- src/ - RTL source files
- sw/ - Python source code for solving both parts of the challenge
- synth/ - Scripts and collateral to run Vivado synthesis on the module
- tb/ - cocotb testbench environment 

## Setup environment
The testbench environment I have uses Verilator as the simulator and cocotb for the testbench framework so you will first need to install Verilator before you're able to run any testcases.
```
1) Install verilator (https://verilator.org/guide/latest/install.html)
2) git clone git@github.com:cellery/AOC_challenges.git
3) cd AOC_challenges/2025_c8
4) ./setup.sh
```

## Run a testcase
There is currently only one monolithic testcase for the entire design. Simply cd into the tb folder and run make to launch the testcase. 
```
1) source venv/bin/activate
2) cd tb
3) make
```
If the test is running properly you should see similar output to the following:
```
...
 58660.00ns INFO     test                               All points read in!
 58660.00ns INFO     test                               Final answer: 4264. Actual answer: 4264
 58660.00ns INFO     test                               cocotb finished
 58660.00ns INFO     cocotb.regression                  tb.aoc_2025_chal8 passed
 58660.00ns INFO     cocotb.regression                  **************************************************************************************
                                                        ** TEST                          STATUS  SIM TIME (ns)  REAL TIME (s)  RATIO (ns/s) **
                                                        **************************************************************************************
                                                        ** tb.aoc_2025_chal8              PASS       58660.00           1.26      46431.75  **
                                                        **************************************************************************************
                                                        ** TESTS=1 PASS=1 FAIL=0 SKIP=0              58660.00           1.26      46376.79  **
                                                        **************************************************************************************

```


## Run synthesis
For synthesis I am using the Vivado toolchain to do some resource and timing estimates for the design. The script generates 3 different configurations of the module and you can specify which one you want to synthesize with tclargs. Here's an example of synthesizing the design and generating reports.
```
cd synth
#You can pass in either synth_small, synth_medium, synth_full, or all
vivado -mode batch -source run_vivado.tcl -tclargs -runs synth_small
```
After the script finishes you can checkout both the utilization report and the timing report in the build folder.
```
ls build/*.txt
build/synth_small_timing_summary.txt  build/synth_small_utilization.txt
```
>Note: The build folder is deleted every time the script is run so copy generated files somewhere else if you wish to keep them.