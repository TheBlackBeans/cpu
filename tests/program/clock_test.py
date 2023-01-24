#!/usr/bin/env python3

from subprocess import Popen, PIPE, STDOUT
import sys

if len(sys.argv) != 8:
    print("Usage: " + sys.argv[0] + " <n. SEND> <init years> ... <init seconds>\nInvalid sys.argv length of " + str(len(sys.argv)))
    sys.exit(1)

try:
    inputs = list(map(int, sys.argv[1:]))
except ValueError as e:
    print("Usage: " + sys.argv[0] + " <n. SEND> <init years> ... <init seconds>\nFailed to convert an argument to an int:\n" + str(e))
    sys.exit(1)

class Bit: pass
newblock = Bit()
newblock2 = Bit()
bit0 = Bit()
bit1 = Bit()

def extend_sint(s, l):
    return (("0" * (l - len(s))) + s) if len(s) < l else s

send0 = "0\n".encode()
send1 = "1\n".encode()
def transform_bits_seq(seq):
    port = yield None
    
    def send_data(data):
        nonlocal port
        yield data
        port = yield None
    def send(data):
        if data[1 - port]:
            port1 = port
            while port == port1:
                yield from send_data(send1 if data[port] else send0)
            yield from send_data(send1 if data[port] else send0)
        else:
            yield from send_data(send1 if data[port] else send0)
        port1 = port
        while port == port1:
            yield from send_data(send0)
        yield from send_data(send0)
    for b in seq:
        if b is newblock:
            yield from send([True, True])
        elif b is newblock2:
            if port == 0:
                while port == 0:
                    yield from send_data(send1)
            else:
                while port == 1:
                    yield from send_data(send1)
            yield send1
            return
        elif b is bit0:
            yield from send([True, False])
        elif b is bit1:
            yield from send([False, True])
        else:
            raise Exception("Invalid bit object")

def transform_number(i):
    if i == 0:
        yield newblock
        return
    
    j = 0
    while (2 << j) < i:
        j = j + 1
    while j > 0:
        yield (bit1 if i & (1 << j) else bit0)
        j = j - 1
    yield (bit1 if i & 1 else bit0)
    yield newblock
def transform_number1(i):
    had1 = False
    for b in transform_number(i):
        if had1:
            yield b
        elif b is bit1:
            had1 = True
        else:
            yield b
def transform_number2(i):
    for b in transform_number(i):
        if b is newblock:
            yield newblock2
        else:
            yield b
def merge_iters(it1, it2):
    while (v := next(it1, None)) is not None:
        yield v
    while (v := next(it2, None)) is not None:
        yield v

bits_seq = merge_iters(transform_number(inputs[1]),
           merge_iters(transform_number1(inputs[2]),
           merge_iters(transform_number1(inputs[3]),
           merge_iters(transform_number(inputs[4]),
           merge_iters(transform_number(inputs[5]),
                       transform_number2(inputs[6]))))))
if inputs[0] <= 0:
    for b in bits_seq:
        if b is bit0:
            print("0", end="")
        elif b is bit1:
            print("1", end="")
        elif b is newblock:
            print("#", end="")
        elif b is newblock2:
            print("-", end="")
        else:
            print("?", end="")
    print()
    sys.exit(0)

tbs = transform_bits_seq(bits_seq)
tbs.send(None)
curtime = ["  "] * 6
curtime[5] = "    "
setup_done = False
with Popen(
    ["out/cpu"],
    stdin=PIPE,
    stdout=PIPE,
    stderr=STDOUT,
) as f:
    if f.stdout is None or f.stdin is None:
        sys.exit(1)
    
    while inputs[0] > 0:
        line = f.stdout.readline().decode("utf-8").strip()
        if f.poll() is not None:
            break
        if line == "WAIT":
            f.stdin.write("\n".encode())
            f.stdin.flush()
        elif line == "RECV 0":
            if setup_done:
                raise Exception("Setup is already done, receiving 0")
            f.stdin.write(tbs.send(0))
            f.stdin.flush()
            try:
                tbs.send(None)
            except StopIteration:
                setup_done = True
        elif line == "RECV 1":
            if setup_done:
                raise Exception("Setup is already done, receiving 1")
            f.stdin.write(tbs.send(1))
            f.stdin.flush()
            try:
                tbs.send(None)
            except StopIteration:
                setup_done = True
        elif line == "RECV 2":
            f.stdin.write(send1)
            f.stdin.flush()
            try:
                tbs.send(None)
            except StopIteration:
                setup_done = True
        elif line.startswith("SEND "):
            vals = line.split(' ')
            if setup_done:
                if vals[1] == "0":
                    print(f"{curtime[3]}/{curtime[4]}/{curtime[5]}  {curtime[2]}:{curtime[1]}:{curtime[0]}")
                    inputs[0] = inputs[0] - 1
            curtime[int(vals[1])] = extend_sint(vals[2], 4 if vals[1] == "5" else 2)
        else:
            print("## " + line)
    
    f.communicate("2\n".encode())
