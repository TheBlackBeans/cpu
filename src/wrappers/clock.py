from subprocess import Popen, PIPE, STDOUT
from threading import Thread
from time import sleep
import datetime
import urwid, urwid.curses_display

class State:
    def __init__(self):
        self.a = False
        self.z = False

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
                elif line == "0>":
                    f.stdin.write((("1" if self._state.a else "0") + "\n").encode())
                    f.stdin.flush()
                elif line == "1>":
                    f.stdin.write((("1" if self._state.z else "0") + "\n").encode())
                    f.stdin.flush()
                else:
                    self._label.set_text(line)
                    self._loop.draw_screen()

state = State()
label = urwid.Text("bonjour")
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
