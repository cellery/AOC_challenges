#Python libraries for general testbench
import os
import sys
import inspect
import re
from enum import Enum
from itertools import zip_longest

#Helper functions for the testbench classes
from tb_helpers import *

#Cocotb imports
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, Timer, Lock

#Global helper functions useful for all testbenches
target_dir = os.path.abspath('../../common')
sys.path.append(target_dir)
from tb_global import *

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

        num_points = 0
        if self.rst_n.value and self.locs_rdy.value:
            line = self.pfile.readline().strip()
            if line:
                locs = line.split(",")
                for loc in range(len(self.locs)) : self.locs[loc].value = int(locs[loc])
                self.locs_vld.value = 1
                num_points += 1
            else:
                self.locs_vld.value = 0
                cocotb.log.info(f"All points read in!")
                self.pfile.close()
                self.status = Status.DONE

        if(num_points >= int(get_define("NUM_POINTS"))):
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
        while True :
            await RisingEdge(self.clk)
            await ReadOnly()

            #TODO - Figure out why the last connection from conns.txt is not being checked!
            if self.dut.dist_calc_i.conn_vld.value == 1 :
                line = self.cfile.readline().strip()
                if line:
                    dist, pointa, pointb = re.sub(r"\(|\)|\s", "", line).split(",")
                    conn_struct_mapping = [("pointb",clog2(int(self.dut.NUM_POINTS.value))), ("pointa",clog2(int(self.dut.NUM_POINTS.value))), ("distance", (int(self.dut.DIM_W.value)+1)*2+2)]
                    conn_struct = decode_packed_struct(self.dut.dist_calc_i.conn.value, conn_struct_mapping)
                    passing = True
                    passing = passing and int(conn_struct["distance"],2) == int(dist)
                    passing = passing and int(conn_struct["pointa"],2) == int(pointa)
                    passing = passing and int(conn_struct["pointb"],2) == int(pointb)
                    if not passing:
                        cocotb.log.info(f"Connection: ({int(conn_struct["distance"],2)}, {int(conn_struct["pointa"],2)}, {int(conn_struct["pointb"],2)}) does not match expected: ({dist}, {pointa}, {pointb})")

                    assert passing
                else:
                    self.cfile.close()
                    break
                

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
            if line_ind == 0 :
                conn_path = self.dut.ins_sorter_i.sort_node_loop[line_ind].first_node.node.conn_cur
            elif line_ind < int(get_define("NUM_CONNS"))-1:
                conn_path = self.dut.ins_sorter_i.sort_node_loop[line_ind].next_nodes.node.conn_cur
            else:
                conn_path = self.dut.ins_sorter_i.sort_node_loop[line_ind].last_node.node.conn_cur

            conn_struct = decode_packed_struct(conn_path.value, conn_struct_mapping)

            passing = True
            passing = passing and int(conn_struct["distance"],2) == int(dist)
            passing = passing and int(conn_struct["pointa"],2) == int(pointa)
            passing = passing and int(conn_struct["pointb"],2) == int(pointb)
            if not passing:
                cocotb.log.info(f"Sorted Connection point {line_ind} failed!")
                cocotb.log.info(f"Sorted connection: ({int(conn_struct["distance"],2)}, {int(conn_struct["pointa"],2)}, {int(conn_struct["pointb"],2)})  does not match expected: ({dist}, {pointa}, {pointb})")

            assert passing

            line = self.sfile.readline().strip()
            line_ind += 1

        self.sfile.close()
        self.sort_status = Status.DONE       

class NetworkChecker:
    def __init__(self, nfile, sfile, dut, clk, rst_n):
        self.dut = dut
        self.clk = clk
        self.rst_n = rst_n
        self.num_cr_running = 0
        self.ntwrk_status = Status.IDLE
        self.lock = cocotb.triggers.Lock()

        self.sfile = open(sfile, 'r')
        self.nfile = open(nfile, 'r')

    def __del__(self):
        self.sfile.close()
        self.nfile.close()

    async def update_status(self, cr_name, new_status):
        async with self.lock:
            if new_status == Status.RUNNING:
                cocotb.log.info(f"Network status: started {cr_name}")
                self.num_cr_running += 1
            elif new_status == Status.DONE:
                self.num_cr_running -= 1
                cocotb.log.info(f"Network status: finished {cr_name}")

            #The only potential issue with this is if we had a coroutine start and finish so quickly that no other coroutines spun up
            #This would cause ntwrk_status to prematurely go to Status.Done. However no coroutine should finish before other coroutines have started
            if self.ntwrk_status == Status.IDLE and self.num_cr_running > 0 :
                self.ntwrk_status = Status.RUNNING
            elif self.ntwrk_status == Status.RUNNING and self.num_cr_running == 0 :
                self.ntwrk_status = Status.DONE
            
            cocotb.log.info(f"Overall network block status: {self.ntwrk_status}")

    async def check_conn(self):
        await self.update_status(inspect.stack()[0].function, Status.RUNNING)

        line_ind = 0
        reversed_lines = list(reversed(self.sfile.readlines())) #Connections come in reverse order into the network block
        self.sfile.close()

        #Check that each point sampled on ready/valid matches our golden data
        while line_ind < len(reversed_lines): 
            await RisingEdge(self.clk)
            await ReadOnly()

            if self.dut.point_ntwrk_i.points_in_vld.value and self.dut.point_ntwrk_i.points_in_rdy.value:
                line = reversed_lines[line_ind].strip()
                dist, pointa, pointb = re.sub(r"\(|\)|\s", "", line).split(",")
                assert int(self.dut.point_ntwrk_i.pointa_in.value) == int(pointa)
                assert int(self.dut.point_ntwrk_i.pointb_in.value) == int(pointb)
                line_ind += 1

        await self.update_status(inspect.stack()[0].function, Status.DONE)

    async def check_ntwrk(self):
        await self.update_status(inspect.stack()[0].function, Status.RUNNING)

        num_conns_read = 0
        action_string_table = ["NEW", "WR_A", "WR_B", "MERGE", "IGNORE", "LOOKUP", "UPDATE"]
        networks = []

        while True:
            await RisingEdge(self.clk)
            await ReadOnly()

            if self.dut.point_ntwrk_i.read_in_point_r.value:                
                #Grab action and point info to update our network model
                ntwrk_action = int(self.dut.point_ntwrk_i.point_ntwrk_action.value)
                cocotb.log.info(f"Point Action:  {action_string_table[ntwrk_action]}")
                pointa = int(self.dut.point_ntwrk_i.pointa_in_r.value)
                pointb = int(self.dut.point_ntwrk_i.pointb_in_r.value)

                #If point -> network LUT requires another lookup we need to wait for that additional lookup to finish to determine action
                if action_string_table[ntwrk_action] == "LOOKUP":
                    #TODO - Should add a timeout here as this may get stuck if logic is not working...
                    while not self.dut.point_ntwrk_i.remap_done.value:
                        await RisingEdge(self.clk)
                        await ReadOnly()

                    ntwrk_action = int(self.dut.point_ntwrk_i.remap_ntwrk_action.value)
                    cocotb.log.info(f"Point Action (Final):  {action_string_table[ntwrk_action]}")
                    pointa = int(self.dut.point_ntwrk_i.lookupa_orig_point.value)
                    pointb = int(self.dut.point_ntwrk_i.lookupb_orig_point.value)

                networks = update_network(networks, [pointa, pointb], action_string_table[ntwrk_action])

                #Read next line of golden file and check each network in golden file matches our modeled networks in HW
                line = self.nfile.readline().strip()
                golden_networks_str = line.split("|")
                test_pass = True
                for network, golden in zip_longest(networks, golden_networks_str):
                    test_pass =  str(network) == golden and test_pass

                cocotb.log.info(f"Network conn {num_conns_read} ({pointa}, {pointb}) with action {action_string_table[ntwrk_action]}")

                if not test_pass:
                    cocotb.log.info(f"Network check failed at conn {num_conns_read} ({pointa}, {pointb}) with action {action_string_table[ntwrk_action]}")
                    for network, golden in zip_longest(networks, golden_networks_str):
                        cocotb.log.info(f"Modeled network: {str(network)}")
                        cocotb.log.info(f"Golden network:  {str(golden)}")

                assert test_pass

                num_conns_read += 1
                if(num_conns_read >= int(get_define("NUM_CONNS"))):
                    break


        await self.update_status(inspect.stack()[0].function, Status.DONE)