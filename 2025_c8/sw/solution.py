#Challenge 8 of AOC can be found here: https://adventofcode.com/2025/day/8

#Given a list of 1000 points in a point cloud find the 1000 closest connections to each other. Create a network of connected points

import math
import sys
import os

target_dir = os.path.abspath('../../common')
sys.path.append(target_dir)
from progress import update_progress, process_file_with_progress

class Vector3D:
    #TODO - Fix python to support different init methods
    #def __init__(self, x, y, z):
    #    self.x = x
    #    self.y = y
    #    self.z = z

    def __init__(self, points):
        self.x = points[0]
        self.y = points[1]
        self.z = points[2]

    @staticmethod
    def dist_approx(a, b):
        #Not true distance as we don't take square root but for this comparison does not matter to have true distance
        return ((a.x - b.x)**2 + (a.y - b.y)**2 + (a.z - b.z)**2)

class Point:
    #Will need to track id, location
    def __init__(self, id, location):
        self.id = id #Point ID
        self.location = Vector3D(location)

#Insert sort isn't very fast but will be more straightforward to implement in HW
#New value will be a tuple of 3 values, only use the first value to do the comparison
def insert_sort_min(new_value, list):
    inserted = False
    for i in range(len(list)):
        if new_value[0] <= list[i][0]:
            list.insert(i, new_value)
            inserted = True
            ins_ind = i
            break

    if not inserted:
        list.append(new_value)
        ins_ind = len(list)

    return list

#Input list is single number, not tuple
def insert_sort_max(new_value, list):
    inserted = False
    for i in range(len(list)):
        if new_value >= list[i]:
            list.insert(i, new_value)
            inserted = True
            ins_ind = i
            break

    if not inserted:
        list.append(new_value)
        ins_ind = len(list)

    return list

class Network:     
    #Track list of points and connections in network
    def __init__(self, id, point0, point1):
        self.id = id
        self.valid = True
        self.points = []
        self.connections = []
        self.add_conn(point0, point1)

    #Returns true if connection point is added successfully
    #Returns false if both points already exist in network
    def add_conn(self, point0, point1):
        if(point0 in self.points and point1 in self.points):
            return False
        elif(point0 in self.points):
            self.points.append(point1)
        elif(point1 in self.points):
            self.points.append(point0)
        else:
            self.points.append(point0)
            self.points.append(point1)

        self.connections.append((point0, point1))
        return True


    def clear_info(self):
        self.points = []
        self.connections = []
        self.valid = False

points = []
connections = []
used_points = []
total_connections = 0
final_num_conns = 1000
point_id = 0

def generate_connection_list(line, index):
    global point_id
    global total_connections
    global points
    global used_points
    global connections
    if line:
        x, y, z = line.split(",")
        new_point = Point(point_id, [int(x), int(y), int(z)])

        #Check connection length to all existing points and insert into list of connections if less than the 1000th connection point
        for point in points:
            dist = Vector3D.dist_approx(point.location, new_point.location)
            if total_connections < final_num_conns or dist <= connections[final_num_conns-1][0]:
                new_connection = (dist, point.id, new_point.id)
                
                connections = insert_sort_min(new_connection, connections)[:final_num_conns]
                if(total_connections < final_num_conns): 
                    total_connections+=1


                
        #Add to list of points
        points.append(new_point)

        point_id += 1


def main():
    global point_id
    global total_connections
    global points
    global used_points
    global connections

    networks = []
    network_sizes = []
    max_networks = 3

    #Create progress bar for parsing the file and generate the connection list as we parse each point
    process_file_with_progress('../misc/input2.txt', line_processor=generate_connection_list, sleep_per_line=0.0)

    #Print info on our connections
    print(f"Max number of connections: {final_num_conns}")
    for i in range(final_num_conns):
        print(f"Connection {i} distance is: {connections[i][0]} between points {connections[i][1]} and {connections[i][2]}")

    #Once we've found our shortest connections we need to traverse networks to find 15 largest networks
    first_network = Network(0, connections[0][1], connections[0][2])
    networks.append(first_network)
    for i in range(1, final_num_conns):
        point0_network_id = -1
        point1_network_id = -1
        for network in networks:
            if (connections[i][1] in network.points):
                point0_network_id = network.id
            if (connections[i][2] in network.points):
                point1_network_id = network.id

            if point0_network_id >= 0 and point1_network_id >= 0:
                break

        if point0_network_id == -1 and point1_network_id == -1: #Create new network since neither points were found in a network
            new_network = Network(len(networks), connections[i][1], connections[i][2])
            networks.append(new_network)
        elif point0_network_id == point1_network_id: #Both points exist in the same network so this connection is redundant
            continue
        elif point0_network_id == -1 or point1_network_id == -1: #Add this connection to an existing network
            if point0_network_id >= 0: networks[point0_network_id].add_conn(connections[i][1], connections[i][2])
            else: networks[point1_network_id].add_conn(connections[i][1], connections[i][2])
        else: #Need to combine two different networks together, invalidate one of the networks
            networks[point0_network_id].add_conn(connections[i][1], connections[i][2])
            for j in range(len(networks[point1_network_id].connections)):
                networks[point0_network_id].add_conn(networks[point1_network_id].connections[j][0], networks[point1_network_id].connections[j][1])

            networks[point1_network_id].clear_info()


    #Print networks
    for i in range(len(networks)):
        if(networks[i].valid):
            print(f"Network {i}: {networks[i].connections} - {len(networks[i].points)} points")

    #Sort networks by size (number of points)
    for i in range(len(networks)):
        network_sizes = insert_sort_max(len(networks[i].points), network_sizes)

    #Print max network sizes and total multiplication of each size
    final_network_product = network_sizes[0]
    print(f"Network 0 size: {network_sizes[0]}")
    #Could use reduction function instead for this
    for i in range(1, max_networks):
        print(f"Network {i} size: {network_sizes[i]}")
        final_network_product *= network_sizes[i]

    print(f"Final network product size: {final_network_product}")

if __name__ == "__main__":
    main()