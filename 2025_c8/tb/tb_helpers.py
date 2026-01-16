import os
import sys

#Original SW functions that are useful for some file generation
target_dir = os.path.abspath('../sw')
sys.path.append(target_dir)
from solution import *

#Global helper functions useful for all testbenches
target_dir = os.path.abspath('../../common')
sys.path.append(target_dir)
from tb_global import *

#Cocotb imports
import cocotb

#TODO - make this a parameter we pass in
#TEST_STIMULUS = "../misc/test_stimulus_001" #If test stimulus folder is not found then all stimulus will be randomly generated

def generate_files(test_stimulus_dir):
    #Try and find all test stimulus if we can, otherwise generate on the fly
    if os.path.exists(test_stimulus_dir) :
        stim_dir = os.path.abspath(test_stimulus_dir)
        points_file = os.path.join(stim_dir, "points.txt")
        if not os.path.isfile(points_file):
            cocotb.log.error(f"points.txt does not exist in test stimulus folder: {stim_dir}.\n ")
        
        conns_file = os.path.join(stim_dir, "conns.txt")
        sorted_file = os.path.join(stim_dir, "sorted.txt")
        network_file = os.path.join(stim_dir, "network.txt")
        answer_file = os.path.join(stim_dir, "answer.txt")
        if not os.path.isfile(conns_file) or not os.path.isfile(sorted_file) or not os.path.isfile(network_file) or not os.path.isfile(answer_file) :
            cocotb.log.info(f"Generating connections files...")
            connections = generate_conn_files(points_file, conns_file, sorted_file, int(get_define("NUM_CONNS")))
            networks = generate_network_file(conns_file, network_file, connections)
            generate_answer_file(answer_file, int(get_define("NUM_NTWRKS")), networks)
    else:
        cocotb.log.error(f"{test_name} does not support auto generated points, please provide a test stimulus folder in {stim_dir}")

    return points_file, conns_file, sorted_file, network_file, answer_file

def generate_conn_files(points_file, conns_file, sorted_file, max_conns):
    with open(points_file, 'r') as file:
        cfile = open(conns_file, 'w')
        sfile = open(sorted_file, 'w')
        point_id = 0
        points = []
        total_connections = 0
        connections = []
        for line in file:
            x, y, z = line.split(",")
            new_point = Point(point_id, [int(x), int(y), int(z)])

            #Check connection length to all existing points and insert into list of connections if less than the 1000th connection point
            for point in points:
                dist = Vector3D.dist_approx(point.location, new_point.location)
                new_connection = (dist, point.id, new_point.id)
                cfile.write(f"{new_connection}\n")
                if total_connections < max_conns or dist <= connections[max_conns-1][0]:
                    connections = insert_sort_min(new_connection, connections)[:max_conns]
                    if(total_connections < max_conns) : total_connections += 1

                    
            #Add to list of points
            points.append(new_point)

            point_id += 1

        #Write sorted connections to file
        for conn in connections:
            sfile.write(f"{conn}\n")
        cfile.close()
        sfile.close()

        return connections

def print_networks(networks):
    network_str = ""
    for network in networks:
        network_str += str(network) + "|"
    return network_str[:-1]

def generate_network_file(sorted_file, network_file, connections):
    networks = []
    with open(sorted_file, 'r') as sfile:
        nfile = open(network_file, 'w')

        #Create networks in same order as HW. HW starts with the last connection rather than the first one
        first_network = Network(1, connections[-1][1], connections[-1][2])
        networks.append(first_network)
        nfile.write(f"{first_network}\n")
        for i in range(len(connections)-2, -1, -1):
            #The search function here is different in HW but end result is the same 
            point0_network_id = find_network_from_point(networks, connections[i][1])
            point1_network_id = find_network_from_point(networks, connections[i][2])

            if point0_network_id == 0 and point1_network_id == 0: #Create new network since neither points were found in a network
                new_network = Network(len(networks)+1, connections[i][1], connections[i][2])
                networks.append(new_network)
            elif point0_network_id == point1_network_id: #Both points exist in the same network so this connection is redundant
                nfile.write(f"{print_networks(networks)}\n")
                continue
            elif point0_network_id == 0 or point1_network_id == 0: #Add this connection to an existing network
                if point0_network_id != 0: networks[point0_network_id-1].add_conn(connections[i][1], connections[i][2])
                else: networks[point1_network_id-1].add_conn(connections[i][1], connections[i][2])
            else: #Create a new network and combine connections from both networks
                new_network = Network(len(networks)+1, connections[i][1], connections[i][2])
                for j in range(len(networks[point0_network_id-1].connections)):
                    new_network.add_conn(networks[point0_network_id-1].connections[j][0], networks[point0_network_id-1].connections[j][1])
                for j in range(len(networks[point1_network_id-1].connections)):
                    new_network.add_conn(networks[point1_network_id-1].connections[j][0], networks[point1_network_id-1].connections[j][1])

                networks[point0_network_id-1].clear_info()
                networks[point1_network_id-1].clear_info()
                networks.append(new_network)

            nfile.write(f"{print_networks(networks)}\n")

        nfile.close()

    return networks

def generate_answer_file(answer_file, max_networks, networks):
    with open(answer_file, 'w') as afile:

        #Sort networks by size (number of points)
        network_sizes = []
        for i in range(len(networks)):
            network_sizes = insert_sort_max(len(networks[i].points), network_sizes)

        #Print max network sizes and total multiplication of each size
        final_network_product = network_sizes[0]
        for i in range(1, max_networks):
            final_network_product *= network_sizes[i]

        afile.write(str(final_network_product))

def find_network_from_point(networks, point) :
    for network in networks:
        if (point in network.points):
            return network.id

    return 0 #Invalid network

#Helper function to update the current network based on info passed from the simulation
def update_network(networks, connection, action):
    new_networks = networks
    pointa = connection[0]
    pointa_ntwrk = find_network_from_point(new_networks, pointa)
    pointb = connection[1]
    pointb_ntwrk = find_network_from_point(new_networks, pointb)

    match action :
        case "NEW" :
            new_network = Network(len(new_networks)+1, pointa, pointb)
            new_networks.append(new_network)
        case "WR_A" :
            new_networks[pointb_ntwrk-1].add_conn(pointa, pointb)
        case "WR_B" :
            new_networks[pointa_ntwrk-1].add_conn(pointa, pointb)
        case "MERGE" :
            new_network = Network(len(new_networks)+1, pointa, pointb)
            for j in range(len(new_networks[pointa_ntwrk-1].connections)):
                new_network.add_conn(new_networks[pointa_ntwrk-1].connections[j][0], new_networks[pointa_ntwrk-1].connections[j][1])
            for j in range(len(new_networks[pointb_ntwrk-1].connections)):
                new_network.add_conn(new_networks[pointb_ntwrk-1].connections[j][0], new_networks[pointb_ntwrk-1].connections[j][1])

            new_networks[pointa_ntwrk-1].clear_info()
            new_networks[pointb_ntwrk-1].clear_info()
            new_networks.append(new_network)
        case "IGNORE" :
            pass
        case "LOOKUP" :
            pass

    return new_networks