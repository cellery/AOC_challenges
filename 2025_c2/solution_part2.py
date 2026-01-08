#Challenge 2 of AOC can be found here: https://adventofcode.com/2025/day/2

#Given list of ranges of numbers find all numbers in the range that have digits that repeat at least twice in the number (i.e. 11, 22, 123123123, etc.)

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
    num_ranges = [p.strip() for p in data.strip().split(",") if p.strip() != ""]
    
    total_sum = 0
    for num_range in num_ranges:
        min_val = int(num_range.split("-")[0])
        max_val = int(num_range.split("-")[1])
        patterns = []
        print("")
        print(f"Min: {min_val}, Max: {max_val}")

        min_num_digits = get_num_digits(min_val)
        max_num_digits = get_num_digits(max_val)

        print(f"Min digits: {min_num_digits}, Max digits: {max_num_digits}")

        cur_num_digits = min_num_digits
        cur_num = min_val

        while(cur_num_digits <= max_num_digits):
            #We need to loop through 1 - cur_num_digits to check for all possible patterns
            #Once we have exhausted all possible patterns that fit in our range then increment num digits until we go over max number of digits for this range
            cur_num_digits = get_num_digits(cur_num)
            
            print(f"Current num digits: {cur_num_digits}")
            for i in range(1, cur_num_digits):
                if float(math.floor(cur_num_digits/i)) == cur_num_digits/i: #cur_num_digits has to be divisible by i for a pattern to occur
                    pattern = math.floor(cur_num / (10 ** (cur_num_digits-i)))
                    print(f"Pattern: {pattern}")
                    new_num = int(str(pattern) * int(cur_num_digits/i))
                    print(f"New number: {new_num}")
                    while(new_num <= max_val and get_num_digits(new_num) == cur_num_digits):
                        if(new_num >= min_val and new_num <= max_val and new_num not in patterns):
                            print(f"Matching pattern: {pattern}, full number {new_num}")
                            total_sum += new_num
                            patterns.append(new_num)

                        #Increment pattern for next check
                        pattern += 1
                        new_num = int(str(pattern) * int(cur_num_digits/i))

            cur_num = 10 ** cur_num_digits
            cur_num_digits += 1
            
                        
    print(f"Total sum: {total_sum}")

if __name__ == "__main__":
    main()
