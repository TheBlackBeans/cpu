build:

LATEX ?= lualatex
LATEX_FLAGS ?= -interaction=batchmode -output-directory=out
COMPILER ?= iverilog
COMPILER_FLAGS ?= -g2012 -gsupported-assertions

# Meta targets
all: build doc
.PHONY: all

build: out/cpu out/vm out/vm-clock out/asj out/clock out/clock-nostop
.PHONY: build

doc: out/instructionset.pdf
.PHONY: doc

check: check/cpu check/asj
.PHONY: check

test: test/cpu test/vm test/vm-clock test/asj test/clock test/clock-nostop
.PHONY: test

run: out/cpu
	@out/cpu
.PHONY: run

clean:
	[ -d out/vm-objs ] && $(RM) -r out/vm-objs
	[ -d out ] && $(RM) out/*
	[ -d src/asj/target ] && $(RM) -r src/asj/target
.PHONY: clean

out:
	@mkdir out
out/vm-objs: | out
	@mkdir out/vm-objs

# Instruction set
out/%.pdf out/%.aux out/%.log &: docs/%.tex | out
	$(LATEX) $(LATEX_FLAGS) $<

# CPU-relevant stuff
CPU_SOURCES := $(wildcard src/cpu/*.sv)

out/cpu: $(CPU_SOURCES) | out
	@echo "Compiling the CPU"
	@$(COMPILER) $(COMPILER_FLAGS) -o $@ $^

check/cpu:
	@if which svlint >/dev/null 2>&1; then echo "Calling svlint"; svlint $(CPU_SOURCES); fi
	@echo "Null-building the CPU"
	@$(COMPILER) $(COMPILER_FLAGS) -t null $(CPU_SOURCES)
	@echo "Checking test decriptions"
	@cd tests/cpu && for f in *; do if [[ -f "$$f/description.txt" ]]; then ./read_description.sh --lint "$$f"; fi; done
.PHONY: check/cpu

test/cpu: check/cpu
	@echo "Running CPU tests"
	@tests/cpu/run_tests.sh
.PHONY: test/cpu

# Assembler-relevant stuff
ASSEMBLER_SOURCES := $(wildcard src/asj/*.rs) src/asj/asj.clx src/asj/asj.cgr

out/asj: src/asj/target/release/asj
	@cp $< $@

out/asj-debug: src/asj/target/debug/asj
	@cp $< $@

src/asj/%.clx: src/asj/%.lx
	beans compile lexer $<

src/asj/%.cgr: src/asj/%.gr src/asj/%.clx
	beans compile parser --lexer $(word 2,$^) $<

src/asj/target/release/asj: $(ASSEMBLER_SOURCES)
	cd src/asj && cargo build --release

src/asj/target/debug/asj: $(ASSEMBLER_SOURCES)
	cd src/asj && cargo build

check/asj: $(ASSEMBLER_SOURCES)
	cd src/asj && cargo clippy
.PHONY: check/asj

test/asj: out/asj
	@tests/asj/run_tests.sh
.PHONY: test/asj

# VM-relevant stuff
VM_SOURCES := src/vm/main.cpp
VM_HEADERS := src/vm/instruction.hpp src/vm/io_interface.h

out/vm-objs/main.o: src/vm/main.cpp src/vm/instruction.hpp src/vm/io_interface.h | out/vm-objs
	@echo "Compiling the VM core"
	@$(CXX) $(CXXFLAGS) -g -O2 -Wall -Wextra -c -o $@ src/vm/main.cpp

out/vm: out/vm-objs/main.o src/vm/stubs.c
	@echo "Compiling the empty I/O VM"
	@$(CC) $(CFLAGS) -lstdc++ -g -O2 -Wall -Wextra -o $@ out/vm-objs/main.o src/vm/stubs.c
out/vm-clock: out/vm-objs/main.o src/vm/clock.c
	@echo "Compiling the clock-specific I/O VM"
	@$(CC) $(CFLAGS) -lstdc++ -g -O2 -Wall -Wextra -o $@ -pthread out/vm-objs/main.o src/vm/clock.c

check/vm check/vm-clock:
	@echo "No VM check"
.PHONY: check/vm check/vm-clock

test/vm: check/vm
	@echo "No VM test available"
.PHONY: test/vm
test/vm-clock: check/vm-clock
	@echo "No VM test available"
.PHONY: test/vm-clock

# Program
out/clock: src/program/clock.asj out/asj
	@echo "Compiling the clock program"
	@out/asj $< -o $@
out/clock-nostop: src/program/clock-nostop.asj out/asj
	@echo "Compiling the clock-nostop program"
	@out/asj $< -o $@

check/clock check/clock-nostop:
	@echo "Checking is made by compiling the program"
.PHONY: check/clock check/clock-nostop

test/clock:
	@echo "No clock program test available"
.PHONY: test/clock

test/clock-nostop:
	@echo "No clock program test available"
.PHONY: test/clock-nostop
