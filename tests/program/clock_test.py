#!/usr/bin/env python3

from subprocess import Popen, PIPE, STDOUT
import sys

if len(sys.argv) != 8:
    print("Usage: tests/clock/clock_test.py <n. SEND> <init years> ... <init seconds>\nInvalid sys.argv length of " + str(len(sys.argv)))
    sys.exit(1)

try:
    inputs = list(map(int, sys.argv[1:]))
except ValueError as e:
    print("Usage: tests/clock/clock_test.py <n. SEND> <init years> ... <init seconds>\nFailed to convert an argument to an int:\n" + str(e))
    sys.exit(1)

class Bit: pass
newblock = Bit()
newblock2 = Bit()
bit0 = Bit()
bit1 = Bit()

def extend_sint(s, l):
    return (("0" * (l - len(s))) + s) if len(s) < l else s

def transform_bits_seq(seq):
    send0 = "0\n".encode()
    send1 = "1\n".encode()
    send2 = "2\n".encode()
    port = yield None
    
    for b in seq:
        if b is newblock:
            port1 = port
            while port == port1:
                yield send1
                port = yield None
            yield send1
            port = yield None
            port1 = port
            while port == port1:
                yield send0
                port = yield None
            yield send0
            port = yield None
        elif b is newblock2:
            port1 = port
            while port == port1:
                yield send1
                port = yield None
            yield send1
            return
        elif b is bit0:
            while port != 0:
                yield send0
                port = yield None
            yield send1
            port = yield None
            port1 = port
            while port == port1:
                yield send0
                port = yield None
            yield send0
            port = yield None
        elif b is bit1:
            while port != 1:
                yield send0
                port = yield None
            yield send1
            port = yield None
            port1 = port
            while port == port1:
                yield send0
                port = yield None
            yield send0
            port = yield None
        else:
            raise Exception("Invalid bit object")
    yield send2

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
            f.stdin.write(tbs.send(0))
            f.stdin.flush()
            try:
                tbs.send(None)
            except StopIteration:
                setup_done = True
        elif line == "RECV 1":
            f.stdin.write(tbs.send(1))
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







sys.exit(0)
azerty.No = error

class State:
    def __init__(self, bits_seq):
        self._bits_seq = bits_seq
date = []

class Wrapper(Thread):
    def __init__(self, state, label, loop):
        super().__init__()
        self._state = state
        self._label = label
        self._loop = loop
        self.stop = False
        self._time = ["  "] * 6
        self._time[5] = "    "
    def run(self):
        with Popen(
                ["out/cpu"],
                stdin=PIPE,
                stdout=PIPE,
                stderr=STDOUT,
        ) as f:
            if f.stdout is None or f.stdin is None:
                exit(1)
            target = datetime.datetime.now()
            while not self.stop:
                line = f.stdout.readline().decode("utf-8").strip()
                if f.poll() is not None:
                    break
                if line == "WAIT":
                    target += datetime.timedelta(microseconds=500)
                    delay = (target - datetime.datetime.now()).total_seconds()
                    if delay > 0:
                        sleep(delay)
                    f.stdin.write("\n".encode())
                    f.stdin.flush()
                elif line == "RECV 0":
                    f.stdin.write((("1" if self._state.a else "0") + "\n").encode())
                    f.stdin.flush()
                elif line == "RECV 1":
                    f.stdin.write((("1" if self._state.z else "0") + "\n").encode())
                    f.stdin.flush()
                elif line.startswith("SEND "):
                    vals = line.split(' ')
                    self._time[int(vals[1])] = extend_sint(vals[2], 4 if vals[1] == "5" else 2)
                    self._label.set_text(f"{self._time[3]}/{self._time[4]}/{self._time[5]}  {self._time[2]}:{self._time[1]}:{self._time[0]}")
                    self._loop.draw_screen()
                else:
                    pass
            if f.poll() is None:
                f.communicate("2\n".encode())

state = State()
label = urwid.Text("  /  /        :  :  ")
boutons = urwid.Text("    ")

def update_state(key):
    if key in {'a', 'A'}:
        state.a = not state.a
    elif key in {'z', 'Z'}:
        state.z = not state.z
    elif key in {'q', 'Q'}:
        wrapper.stop = True
        raise urwid.ExitMainLoop()
    boutons.set_text(("#" if state.a else " ") + "  " + ("#" if state.z else " "))

pile = urwid.Pile([label, boutons])
top = urwid.Filler(pile, valign='top')
loop = urwid.MainLoop(
    top,
    unhandled_input=update_state,
    screen=urwid.curses_display.Screen(),
)
wrapper = Wrapper(state, label, loop)
wrapper.start()
loop.run()
