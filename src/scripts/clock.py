from subprocess import Popen, PIPE, STDOUT
from threading import Thread
from time import sleep
import datetime
import urwid, urwid.curses_display

def extend_sint(s, l):
    return (("0" * (l - len(s))) + s) if len(s) < l else s

class State:
    def __init__(self):
        self.a = False
        self.z = False
        self.e = False

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
                elif line == "RECV 2":
                    f.stdin.write((("1" if self._state.e else "0") + "\n").encode())
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
    elif key in {'e', 'E'}:
        state.e = not state.e
    elif key in {'q', 'Q'}:
        wrapper.stop = True
        raise urwid.ExitMainLoop()
    boutons.set_text(" ".join("#" if v else " " for v in (state.a, state.z, state.e)))

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
