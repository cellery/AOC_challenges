#Challenge 8 of AOC can be found here: https://adventofcode.com/2025/day/8

#Given a list of 1000 points in a point cloud find the 1000 closest connections to each other. Create a network of connected points
#For part 2 instead create one network with all points, start with closest points and connect them and continue until all points are in the network

import math
import sys
import os

target_dir = os.path.abspath('../common')
sys.path.append(target_dir)
from progress import process_file_with_progress


class Vector3D:
    def __init__(self, x, y, z):
        self.x = x
        self.y = y
        self.z = z

    def __init__(self, points):
        self.x = points[0]
        self.y = points[1]
        self.z = points[2]

    @staticmethod
    def dist_approx(a, b):
        #Not true distance as we don't take square root but for this comparison does not matter to have true distance
        return ((a.x - b.x)**2 + (a.y - b.y)**2 + (a.z - b.z)**2)
    
    def __str__(self):
        return f"({self.x},{self.y},{self.z})"

class Point:
    max_nn = 10
    #Will need to track id, location
    def __init__(self, id, location):
        self.id = id #Point ID
        self.location = Vector3D(location)
        #List of nearest neighbors
        self.nn = []

    @staticmethod
    def dist_approx(a, b):
        #Not true distance as we don't take square root but for this comparison does not matter to have true distance
        return Vector3D.dist_approx(a.location, b.location)
    
    #Check if new point is one of closest points, insert into list if it is
    def check_nn(self, new_point):
        approx_dist = Point.dist_approx(self, new_point)
        if(len(self.nn) == 0): self.num_nn.append((approx_dist, new_point))
        elif(len(self.nn) < Point.max_nn):  insert_sort_min(approx_dist, self.nn)
        elif(approx_dist <= self.nn[len(self.nn)]): self.nn = insert_sort_min(approx_dist, self.nn)[:Point.max_nn]
        else: return False

        return True


#Insert sort isn't very fast but will be more straightforward to implement in HW
#New value will be a tuple of 3 values, only use the first value to do the comparison
def insert_sort_min(new_value, list):
    inserted = False
    for i in range(len(list)):
        if new_value.dist <= list[i].dist:
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

class Connection:
    #Track list of points and connections in network
    def __init__(self, dist, point0, point1):
        self.dist = dist
        self.point0 = point0
        self.point1 = point1

    def __str__(self):
        return f"({self.point0}<->{self.point1})"

class Network:     
    #Track list of points and connections in network
    def __init__(self, id, point0, point1):
        self.id = id
        self.valid = True
        self.points = []
        self.connections = []
        self.add_conn(point0, point1)

    #Empty network
    def __init__(self, id):
        self.id = id
        self.valid = True
        self.points = []
        self.connections = []

    #Returns true if connection point is added successfully
    #Returns false if both points already exist in network
    def add_conn(self, connection):
        if(connection.point0 in self.points and connection.point1 in self.points):
            return False
        elif(connection.point0 in self.points):
            self.points.append(connection.point1)
        elif(connection.point1 in self.points):
            self.points.append(connection.point0)
        else:
            self.points.append(connection.point0)
            self.points.append(connection.point1)

        self.connections.append(connection)
        return True


    def clear_info(self):
        self.points = []
        self.connections = []
        self.valid = False

points = []
connections = []
network = Network(0)
point_id = 0


#We're going to build a network one point at a time
#For each new point generate all possible new connections and create a sorted list of new connections and current network connections
#Create a new network starting from the shortest connection until all points in the network are connected
#Repeat this process for each new point
#The list of connections will grow up to ~2xfinal_num_conns
def build_network(line, index):
    global points
    global connections
    global network
    global point_id

    if line:
        x, y, z = line.split(",")
        new_point = Point(point_id, [int(x), int(y), int(z)])

        #Generate all new potential connections with the new point
        for point in points:
            dist = Point.dist_approx(point, new_point)
            new_connection = Connection(dist, point.id, new_point.id)
            connections = insert_sort_min(new_connection, connections)

        #Add to list of points
        points.append(new_point)
            
        #Now build a new network with list of sorted connections, drop any connections not used at the end
        if(len(points) >= 2):
            network.clear_info()
            network.add_conn(connections[0])
            for i in range(1, len(connections)):
                if (connections[i].point0 not in network.points or connections[i].point1 not in network.points):
                    network.add_conn(connections[i])

                if (len(network.points) == len(points)): break

            connections = network.connections

        point_id += 1

def main():
    global points
    global connections
    global network

    #Create progress bar for parsing the file and generate the connection list as we parse each point
    process_file_with_progress('input2.txt', line_processor=build_network, sleep_per_line=0.0)

    #Print info on our connections
    for i in range(len(connections)):
        print(f"Connection {i} distance is: {connections[i].dist} between points {connections[i].point0} and {connections[i].point1}")

    #Print network
    conn_strings = ",".join(map(str, network.connections))
    print(f"Network : {conn_strings} - {len(network.points)} points")

    #Print last connection and the two points connected
    print(f"Last connection points are: {points[connections[-1].point0].location} and {points[connections[-1].point1].location}")

    answer = int(points[connections[-1].point0].location.x) * int(points[connections[-1].point1].location.x)

    print(f"Final answer Point{connections[-1].point0} x coord {points[connections[-1].point0].location.x} * Point{connections[-1].point1} x coord {points[connections[-1].point1].location.x} is {answer} ")

if __name__ == "__main__":
    main()
