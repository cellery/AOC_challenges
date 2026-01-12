# test_my_design.py (simple)


#Cocotb imports
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, Timer

#Python libraries for general testbench
import os
import sys
import inspect
import re
from enum import Enum

#Pytest
import pytest

#Import helper functions from sw area
from generate_files import *
target_dir = os.path.abspath('../../common')
sys.path.append(target_dir)
from tb_helpers import clog2, decode_packed_struct

#TODO - Add randomization for test parameters
ASSERTS_ENABLED = 1 #Global enable for all asserts for test case
CONN_ASSERTS = 1
SORT_ASSERTS = 1
NTWRK_ASSERTS = 1
TEST_STIMULUS = "../misc/test_stimulus_001" #If test stimulus folder is not found then all stimulus will be randomly generated
NUM_POINTS = 20
NUM_CONNS = 20
NUM_NTWRKS = 3

class Status(Enum):
    IDLE = 0
    RUNNING = 1
    DONE = 2

class PointOrchestrator:
    def __init__(self, pfile, dut, clk, rst_n):
        self.dut = dut
        self.clk = clk
        self.rst_n = rst_n
        self.locs = [dut.xloc, dut.yloc, dut.zloc]
        self.locs_vld = dut.locs_vld
        self.locs_rdy = dut.locs_rdy
        self.status = Status.IDLE

        self.pfile = open(pfile, 'r')

    def __del__(self):
        self.pfile.close()

    async def write_point(self):
        await RisingEdge(self.clk)

        if self.rst_n.value and self.locs_rdy.value:
            line = self.pfile.readline().strip()
            if line:
                locs = line.split(",")
                for loc in range(len(self.locs)) : self.locs[loc].value = int(locs[loc])
                self.locs_vld.value = 1
            else:
                self.locs_vld.value = 0
                cocotb.log.info(f"All points read in!")
                self.pfile.close()
                self.status = Status.DONE

    def reset(self):
        # Reset location inputs
        for loc in self.locs: loc.value = 0

        self.status = Status.RUNNING

class ConnChecker:
    def __init__(self, cfile, sfile, dut, clk, rst_n):
        self.dut = dut
        self.clk = clk
        self.rst_n = rst_n
        self.sort_status = Status.IDLE

        self.cfile = open(cfile, 'r')
        self.sfile = open(sfile, 'r')

    def __del__(self):
        self.cfile.close()
        self.sfile.close()

    async def check_conn(self):
        line = self.cfile.readline().strip()
        while 1 :
            await RisingEdge(self.clk)
            await ReadOnly()

            if self.dut.dist_calc_i.conn_vld.value == 1 :
                if line:
                    dist, pointa, pointb = re.sub(r"\(|\)|\s", "", line).split(",")
                    conn_struct_mapping = [("pointb",clog2(int(self.dut.NUM_POINTS.value))), ("pointa",clog2(int(self.dut.NUM_POINTS.value))), ("distance", (int(self.dut.DIM_W.value)+1)*2+2)]
                    conn_struct = decode_packed_struct(self.dut.dist_calc_i.conn.value, conn_struct_mapping)
                    assert int(conn_struct["distance"],2) == int(dist)
                    assert int(conn_struct["pointa"],2) == int(pointa)
                    assert int(conn_struct["pointb"],2) == int(pointb)
                else:
                    self.sfile.close()
                    break
                line = self.cfile.readline().strip()

    async def check_sort(self):
        self.sort_status = Status.RUNNING

        #Wait for ins sorter to finish
        while not self.dut.ins_sorter_i.sort_done.value :
            await RisingEdge(self.clk)
            await ReadOnly()

        line_ind = 0
        line = self.sfile.readline().strip()
        while line :
            dist, pointa, pointb = re.sub(r"\(|\)|\s", "", line).split(",")
            conn_struct_mapping = [("pointb",clog2(int(self.dut.NUM_POINTS.value))), ("pointa",clog2(int(self.dut.NUM_POINTS.value))), ("distance", (int(self.dut.DIM_W.value)+1)*2+2)]
            conn_path = self.dut.ins_sorter_i.sort_node_loop[line_ind].first_node.node.conn_cur if line_ind == 0 else self.dut.ins_sorter_i.sort_node_loop[line_ind].next_nodes.node.conn_cur
            conn_struct = decode_packed_struct(conn_path.value, conn_struct_mapping)
            assert int(conn_struct["distance"],2) == int(dist)
            assert int(conn_struct["pointa"],2) == int(pointa)
            assert int(conn_struct["pointb"],2) == int(pointb)

            line = self.sfile.readline().strip()
            line_ind += 1

        self.sfile.close()
        self.sort_status = Status.DONE        

@cocotb.test()
async def aoc_2025_chal8(dut):
    #Get test name for printing, TODO - is there a built in feature in cocotb to get this already?
    test_name = inspect.stack()[0].function

    #Try and find all test stimulus if we can, otherwise generate on the fly
    if os.path.exists(TEST_STIMULUS) :
        stim_dir = os.path.abspath(TEST_STIMULUS)
        points_file = os.path.join(stim_dir, "points.txt")
        if not os.path.isfile(points_file):
            cocotb.log.error(f"points.txt does not exist in test stimulus folder: {stim_dir}.\n Please provide valid points.txt file in folder or clear TEST_STIMULUS global variable")
        
        conns_file = os.path.join(stim_dir, "conns.txt")
        sorted_file = os.path.join(stim_dir, "sorted.txt")
        network_file = os.path.join(stim_dir, "network.txt")
        if not os.path.isfile(conns_file) or not os.path.isfile(sorted_file) or not os.path.isfile(network_file):
            cocotb.log.info(f"Generating connections files...")
            connections = generate_conn_files(points_file, conns_file, sorted_file, NUM_CONNS)
            generate_network_file(conns_file, network_file, connections)
    else:
        cocotb.log.error(f"{test_name} does not support auto generated points, please provide a test stimulus folder in TEST_STIMULUS global variable")

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Make sure AXI inputs are in a known state during reset
    point_o = PointOrchestrator(points_file, dut, dut.clk, dut.rst_n)
    point_o.reset()

    #Connection checker verifies all generated connections match generated list from sw test
    if ASSERTS_ENABLED and CONN_ASSERTS:
        conn_checker = ConnChecker(conns_file, sorted_file, dut, dut.clk, dut.rst_n)
        conn_checker_thread = cocotb.start_soon(conn_checker.check_conn())

    if ASSERTS_ENABLED and SORT_ASSERTS:
        sort_checker_thread = cocotb.start_soon(conn_checker.check_sort())

    # Reset pulse
    dut.rst_n.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)

    while (point_o.status != Status.DONE):
        await point_o.write_point()

    while (conn_checker.sort_status != Status.DONE):
        await sort_checker_thread

    #Wait for a bit longer to capture just after our last thread finishes
    for _ in range(100):
        await RisingEdge(dut.clk)

    cocotb.log.info("cocotb finished")
