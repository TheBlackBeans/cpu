from subprocess import Popen, PIPE, STDOUT
from threading import Thread
from time import sleep
import urwid, urwid.curses_display

class State:
    def __init__(self):
        self._a = False
        self._z = False
    @property
    def a(self):
        return "1" if self._a else "0"
    @property
    def z(self):
        return "1" if self._z else "0"

class Wrapper(Thread):
    def __init__(self, state, label, loop):
        super().__init__()
        self._state = state
        self._label = label
        self._loop = loop
        self.stop = False
    def run(self):
        with Popen(
                ["out/cpu"],
                stdin=PIPE,
                stdout=PIPE,
                stderr=STDOUT,
        ) as f:
            if f.stdout is None or f.stdin is None:
                exit(1)
            while not self.stop:
                line = f.stdout.readline().decode("utf-8").strip()
                if f.poll() is not None:
                    break
                if line == "WAIT":
                    sleep(0.00045)
                    f.stdin.write("\n".encode())
                    f.stdin.flush()
                elif line == "0>":
                    f.stdin.write((self._state.a + "\n").encode())
                    f.stdin.flush()
                elif line == "1>":
                    f.stdin.write((self._state.z + "\n").encode())
                    f.stdin.flush()
                else:
                    self._label.set_text(line)
                    self._loop.draw_screen()

state = State()
label = urwid.Text("bonjour")
boutons = urwid.Text("0 0")

def update_state(key):
    if key in {'a', 'A'}:
        state._a = not state._a
    elif key in {'z', 'Z'}:
        state._z = not state._z
    elif key in {'q', 'Q'}:
        wrapper.stop = True
        raise urwid.ExitMainLoop()
    boutons.set_text(f"{state.a} {state.z}")

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
