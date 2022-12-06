import sys

with open(sys.argv[1], "rb") as f:
    blob_content = f.read()
    size = len(blob_content)//4
    for i in range(size):
        instruction = int.from_bytes(blob_content[4*i:4*(i+1)], 'little')
        formatted_instruction = f"{bin(instruction)[2:]:0>32}"
        print(f"{i:0>9} | {formatted_instruction}")
