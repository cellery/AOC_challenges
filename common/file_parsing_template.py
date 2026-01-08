import math
import sys
import os

target_dir = os.path.abspath('../common')
sys.path.append(target_dir)
from progress import update_progress, process_file_with_progress

def parse_file(line, index):
    pass

def main():
    #Create progress bar for parsing the file and generate the connection list as we parse each point
    process_file_with_progress('input.txt', line_processor=parse_file, sleep_per_line=0.0)

if __name__ == "__main__":
    main()
