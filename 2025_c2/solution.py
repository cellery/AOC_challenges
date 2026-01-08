#Challenge 2 of AOC can be found here: https://adventofcode.com/2025/day/2

#Given list of ranges of numbers find all numbers in the range that have digits that repeat twice in the number (i.e. 11, 22, 123123, etc.)

import math


#Could convert to string and get length of string but want to make this HW friendly so we will do divide by 10 method
def get_num_digits(number):
    cur_num = number
    total_digits = 0
    while cur_num > 0:
        total_digits += 1
        cur_num //= 10
    return total_digits

def main():
    with open("input.txt", "r", encoding="utf-8") as f:
        data = f.read()
    ranges = [p.strip() for p in data.strip().split(",") if p.strip() != ""]
    
    total_sum = 0
    for range in ranges :
        min_val = int(range.split("-")[0])
        max_val = int(range.split("-")[1])
        print(f"Min: {min_val}, Max: {max_val}")

        min_num_digits = get_num_digits(min_val)
        max_num_digits = get_num_digits(max_val)

        print(f"Min digits: {min_num_digits}, Max: {max_num_digits}")

        cur_num_digits = min_num_digits
        cur_num = min_val
        #Repeating patterns can only occur when number of digits is even so skip this range if both digits are the same and odd
        if(min_num_digits == max_num_digits and min_num_digits % 2 != 0):
            continue
        else:
            while(cur_num <= max_val):
                #If number is odd number of digits bump it up to next number that has 1 more digit
                if cur_num_digits % 2 != 0:
                    cur_num = 10 ** (cur_num_digits)
                    cur_num_digits += 1
                else:
                    bottom_half = cur_num % (10 ** int(cur_num_digits/2))
                    top_half = math.floor(cur_num / (10 ** int(cur_num_digits/2)))
                    if bottom_half == top_half:
                        print(f"Matching pattern: {bottom_half}, full number {cur_num}")
                        total_sum += cur_num
                        cur_num = (top_half+1) * (10 ** int(cur_num_digits/2)) + top_half+1
                    elif bottom_half < top_half:
                        cur_num = top_half * (10 ** int(cur_num_digits/2)) + top_half
                    elif bottom_half > top_half:
                        cur_num = (top_half+1) * (10 ** int(cur_num_digits/2)) + top_half+1
                        
        print(f"Total sum: {total_sum}")





if __name__ == "__main__":
    main()
