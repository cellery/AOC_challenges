#Challenge 8 of AOC can be found here: https://adventofcode.com/2025/day/8

#Given a list of 1000 points in a point cloud find the 1000 closest connections to each other. Create a network of connected points

import math

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

class Point:
    #Will need to track id, location
    def __init__(self, id, location):
        self.id = id #Point ID
        self.location = Vector3D(location)

#Insert slow isn't very fast but will be more straightforward to implement in HW
#New value will be a tuple of 3 values, only use the first value to do the comparison
def insert_sort(new_value, list):
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

class Network:
    #Track list of points and connections in network
    def __init__(self):
        self.points = []
        self.connections = []

    #Returns true if connection point is added successfully
    #Returns false if both points already exist in network
    def add_conn(self, point0, point1):
        if (point0 in self.points) ^ (point1 in self.points):
            if point0 in self.points:
                self.points.append(point1)
            else:
                self.points.append(point0)
        else:
            return False

        self.connections.append((point0, point1))
        return True
    
    def clear_info(self):
        self.points = []
        self.connections = []



def main():

    points = []
    connections = []
    networks = []
    total_connections = 0
    max_connections = 11
    point_id = 0
    max_distance = 0xFFFFFFFF

    with open('input.txt', 'r') as file:
        for line in file:
            if line:
                x, y, z = line.split(",")
                new_point = Point(point_id, [int(x), int(y), int(z)])

                #Check connection length to all existing points and insert into list of connections if less than the 1000th connection point
                for point in points:
                    dist = Vector3D.dist_approx(point.location, new_point.location)
                    if total_connections < max_connections or dist <= connections[max_connections-1][0]:
                        new_connection = (dist, point.id, new_point.id)
                        #Build first network if none exist yet
                        if len(networks) == 0:
                            new_network = Network()
                            new_network.add_conn(new_connection[1], new_connection[2])
                            networks.append(new_network)
                        else:
                            #Search all networks to see if connection needs to expand a network, be ignored, or create a new network
                            for network in networks:
                                make_network = True
                                add_conn = True
                                if (new_connection[1] in network.points) or (new_connection[2] in network.points):
                                    make_network = False
                                    add_conn = network.add_conn(new_connection[1], new_connection[2])

                            #This is true only if the connection was not found in any of the existing networks
                            if make_network:
                                new_network = Network()
                                new_network.add_conn(new_connection[1], new_connection[2])
                                networks.append(new_network)

                            
                            if add_conn:
                                #If add connection is true then the connection was successfully added. If we're already at max connections we need to now
                                #remove the furthest connection and update existing networks
                                if total_connections == max_connections:
                                    removed_conn = connections[max_connections-1]
                                    connections = insert_sort(new_connection, connections)

                                    #Now find what network the connection is and regenerate network(s) based on list of connections in network exlcuding the removed one
                                    for network in networks:
                                        if (removed_conn[1] in network.points):
                                            network_conns = network.connections
                                            networks[i] = 
                                else:
                                    connections = insert_sort(new_connection, connections)
                                    total_connections += 1


                        #Check if connection already exists in a network before we add it
                        if len(networks) != 0:
                            new_network = True
                            add_conn = True
                            for network in networks:
                                if (new_connection[1] in network) ^ (new_connection[2] in network):
                                    new_network = False
                                    if connections[1] in network:
                                        network.append(new_connection[2])
                                    else:
                                        network.append(new_connection[1])
                                    break
                                elif new_connection[1] in network and new_connection[2] in network:
                                    new_network = False
                                    add_conn = False
                                    break

                        if new_network:
                            networks.append([connections[i][1], connections[i][2]]) 

                        if add_conn:
                            connections = insert_sort(new_connection, connections)
                            #Need to remove furthest connection
                            #This part is tricky as it could sever a connection that converts 1 network into 2
                            #We need to track not only points in a network but their connectivity to each other
                            if total_connections == max_connections:
                        total_connections = max_connections if total_connections == max_connections else total_connections+1

                #Check for new connections
                points.append(new_point)

                point_id += 1

    #Print info on our connections
    for i in range(max_connections):
        print(f"Connection {i} distance is: {connections[i][0]} between points {connections[i][1]} and {connections[i][2]}")

    #Once we've found our shortest connections we need to traverse networks to find 15 largest networks
    networks.append([connections[0][1], connections[0][2]])
    for i in range(1, max_connections):
        new_network = True
        for network in networks:
            if (connections[i][1] in network) ^ (connections[i][2] in network):
                new_network = False
                if connections[i][1] in network:
                    network.append(connections[i][2])
                else:
                    network.append(connections[i][1])
                break
            elif connections[i][1] in network and connections[i][2] in network:
                new_network = False
                break

        if new_network:
           networks.append([connections[i][1], connections[i][2]]) 

    #Print networks
    for i in range(len(networks)):
        print(f"Network {i}: {networks[i]}")
                


    


if __name__ == "__main__":
    main()
