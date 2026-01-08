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

            prev_dial_pos = dial_position

            if direction == 'L':
                dial_position -= amount
            elif direction == 'R':
                dial_position += amount

            #Count how many times it goes past 0 as well
            if dial_position >= 100:
                zero_count += math.floor(dial_position/100)
                #If dial position is exactly a multiple of 100, we will count it again below so subtract 1 here
                if dial_position % 100 == 0:
                    zero_count -= 1
                
                #Add a zero count for passing the initial 0
                if prev_dial_pos < 0:
                    zero_count += 1
            elif dial_position > 0 and dial_position < 100:
                if prev_dial_pos < 0:
                    zero_count += 1
            elif dial_position < 0 and dial_position > -100:
                if prev_dial_pos > 0:
                    zero_count += 1
            elif dial_position <= -100:
                zero_count += abs(math.ceil(dial_position/100))
                #If dial position is exactly a multiple of 100, we will count it again below so subtract 1 here
                if dial_position % 100 == 0:
                    zero_count -= 1

                #If dial started positive add another count for the initial passing of zero
                if prev_dial_pos > 0:
                    zero_count += 1
                
            # Wrap around the dial (0-99)
            dial_position %= 100

            # If dial ends on 0 that counts as well
            if dial_position == 0:
                zero_count += 1

    print(f'The dial was on 0 a total of {zero_count} times.')