# test_my_design.py (simple)

#Cocotb imports
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, Timer, Lock

#Import functions from testbench classes and helpers
from tb_classes import *
from tb_helpers import *

#TODO - Add randomization for test parameters
ASSERTS_ENABLED = 1 #Global enable for all asserts for test case
CONN_ASSERTS = 1
SORT_ASSERTS = 1
NTWRK_ASSERTS = 1

@cocotb.test()
async def aoc_2025_chal8(dut):
    #Get test name for printing, TODO - is there a built in feature in cocotb to get this already?
    test_name = inspect.stack()[0].function

    points_file, conns_file, sorted_file, network_file, answer_file = generate_files()

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Make sure AXI inputs are in a known state during reset
    point_o = PointOrchestrator(points_file, dut, dut.clk, dut.rst_n)
    point_o.reset()

    #Connection checker verifies all generated connections match generated list from sw test and are properly sorted
    if ASSERTS_ENABLED and CONN_ASSERTS:
        conn_checker = ConnChecker(conns_file, sorted_file, dut, dut.clk, dut.rst_n)
        conn_checker_cr = cocotb.start_soon(conn_checker.check_conn())
        if SORT_ASSERTS:
            sort_checker_cr = cocotb.start_soon(conn_checker.check_sort())

    #Network checker blocks checks that at each step a new point is read in the current networks match from sw
    if ASSERTS_ENABLED and NTWRK_ASSERTS:
        ntwrk_checker = NetworkChecker(network_file, sorted_file, dut, dut.clk, dut.rst_n)
        ntwrk_conn_checker_cr = cocotb.start_soon(ntwrk_checker.check_conn())
        ntwrk_checker_cr = cocotb.start_soon(ntwrk_checker.check_ntwrk())

    # Initial reset pulse
    dut.rst_n.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)

    #Read out points from file and send into DUT to start the test
    while (point_o.status != Status.DONE):
        await point_o.write_point()

    #Optional asserts for the sort block
    if ASSERTS_ENABLED and SORT_ASSERTS:
        while (conn_checker.sort_status != Status.DONE):
            await sort_checker_cr

    #Optional asserts for the network block
    if ASSERTS_ENABLED and NTWRK_ASSERTS:
        while (ntwrk_checker.ntwrk_status != Status.DONE):
            await cocotb.triggers.Combine(ntwrk_conn_checker_cr, ntwrk_checker_cr)

    with open(answer_file, 'r') as afile:
        #Wait for the final answer - TODO should have a timeout here
        while not dut.answer_vld.value:
            await RisingEdge(dut.clk)
            
        await ReadOnly()
        correct_answer = int(afile.readline().strip())
        cocotb.log.info(f"Final answer: {int(dut.answer.value)}. Actual answer: {correct_answer}")
        assert int(dut.answer.value) == correct_answer 

    #Keep in case we want to re-enable this for any debugging
    #cocotb.log.info("Running a few more cycles...")
    ##Wait for a bit longer to capture just after our last coroutine finishes
    #for _ in range(100):
    #    await RisingEdge(dut.clk)

    cocotb.log.info("cocotb finished")
