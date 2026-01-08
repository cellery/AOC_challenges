# test_my_design.py (simple)

#Testbench imports
import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def aoc_2025_chal8(dut):
    """Try accessing the design."""

    for _ in range(1000):
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")

    cocotb.log.info("cocotb finished")
