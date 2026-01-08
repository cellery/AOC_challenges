#Challenge here: https://adventofcode.com/2025/day/1

#Rotation problem, take in a file where each line rotates a dial left or right N amount. Count how many times the dial is set to 0, the dial starts at 50

import math

DEBUG = 1

if __name__ == "__main__":
    dial_position = 50
    zero_count = 0

    with open('input.txt', 'r') as file:
        for line in file:
            direction = line[0]
            amount = int(line[1:])

            if direction == 'L':
                dial_position -= amount
            elif direction == 'R':
                dial_position += amount
                
            # Wrap around the dial (0-99)
            dial_position %= 100

            # If dial ends on 0 that counts as well
            if dial_position == 0:
                zero_count += 1

    print(f'The dial was on 0 a total of {zero_count} times.')