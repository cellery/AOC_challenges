#AOC Challenge 3 https://adventofcode.com/2025/day/3

#For this challenge find largest two digit number in a larger number
import math
import sys
import os

target_dir = os.path.abspath('../common')
sys.path.append(target_dir)
from progress import update_progress, process_file_with_progress

numbers = []
lines = []

def parse_file(line, index):
    global numbers
    global lines

    if line:
        first_digit = line[0]
        second_digit = line[1]
        for i in range(2, len(line)):
            if(line[i] > second_digit): second_digit = line[i]
            if(line[i] > first_digit and i < len(line)-1):
                first_digit = line[i]
                second_digit = line[i+1]
        
        numbers.append(int(first_digit + second_digit))
        lines.append(line)
        

def main():
    global numbers
    global lines
    #Create progress bar for parsing the file and generate the connection list as we parse each point
    process_file_with_progress('input2.txt', line_processor=parse_file, sleep_per_line=0.0)

    sum = 0
    for i in range(len(numbers)):
        print(f"Original line: {lines[i]}")
        print(f"Largest number: {numbers[i]}")
        sum += numbers[i]

    print(f"Answer: {sum}")

    

if __name__ == "__main__":
    main()