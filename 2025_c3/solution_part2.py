#AOC Challenge 3 https://adventofcode.com/2025/day/3

#For this challenge find largest twelve digit number in a larger number

import math
   
#Not optimized as we search entire string by number of digits. We should be able to just create a sliding window and read the number once
#and update the digits as you move the sliding window
def main():

    numbers = []
    lines = []
    num_digits = 12

    with open('input2.txt', 'r') as file:
        for line in file:
            line = line.rstrip('\n')
            print(f"\nOriginal line:  {line}")
            digits = line[0:num_digits]
            prev_ind = 0
            for j in range(num_digits):
                start_ind = 0 if j == 0 else prev_ind
                end_ind = len(line)-(num_digits-j)
                replaced_digit = False
                #print(f"Starting index: {start_ind}")
                for i in range(start_ind, end_ind+1):
                    if(line[i] > digits[j]):
                        #print(f"Found replacement at {i} using digit {line[i]}")
                        digits = digits[:j] + line[i:i+num_digits-j]
                        prev_ind = i

                prev_ind = max(prev_ind, j)

                prev_ind += 1 #Increment to next position
            
            numbers.append(int(digits))
            lines.append(line)

            print(f"Largest number: {digits}")

    sum = 0
    for i in range(len(numbers)):
        sum += numbers[i]

    print(f"Answer: {sum}")

    

if __name__ == "__main__":
    main()