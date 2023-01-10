from subprocess import Popen, PIPE, STDOUT
from time import sleep

with Popen(
    ["out/cpu"],
    stdin=PIPE,
    stdout=PIPE,
    stderr=STDOUT,
) as f:
    if f.stdout is None or f.stdin is None:
        exit(1)
    while True:
        line = f.stdout.readline().decode("utf-8").strip()
        if f.poll() is not None:
            break
        if line == "WAIT":
            sleep(0.0005)
            f.stdin.write("\n".encode())
            f.stdin.flush()
        elif line == "0>":
            f.stdin.write((input("0> ") + "\n").encode())
            f.stdin.flush()
        elif line == "1>":
            f.stdin.write((input("1> ") + "\n").encode())
            f.stdin.flush()
        else:
            print(line)
