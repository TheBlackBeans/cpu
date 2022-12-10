build:

LATEX ?= lualatex
LATEX_FLAGS ?= -interaction=batchmode -output-directory=out
COMPILER ?= iverilog
COMPILER_FLAGS ?= -g2012 -gsupported-assertions

# Meta targets
all: build doc
.PHONY: all

build: out/cpu out/vm out/asj out/clock
.PHONY: build

doc: out/instructionset.pdf
.PHONY: doc

check: check/cpu check/vm check/asj
.PHONY: check

test: test/cpu test/vm test/asj test/clock
.PHONY: test

run: out/cpu
	@out/cpu
.PHONY: run

clean:
	[ -d out ] && $(RM) out/*
	$(RM) -r target
.PHONY: clean

out:
	@mkdir out

# CPU-relevant stuff
CPU_SOURCES := $(wildcard src/*.sv)
#CPU_SOURCES := \
	src/ip.sv \
	src/reg.sv \
	src/main.sv # Last one

out/cpu: $(CPU_SOURCES) | out
	@echo "Compiling the CPU"
	@$(COMPILER) $(COMPILER_FLAGS) -o $@ $^

check/cpu:
	@if which svlint >/dev/null 2>&1; then echo "Calling svlint"; svlint $(CPU_SOURCES); fi
	@echo "Null-building the CPU"
	@$(COMPILER) $(COMPILER_FLAGS) -t null $(CPU_SOURCES)
	@echo "Checking test decriptions"
	@cd tests; for f in *; do if [[ -f "$$f/description.txt" ]]; then ./read_description.sh --lint "$$f"; fi; done
.PHONY: check/cpu

test/cpu: check/cpu
	@echo "Running CPU tests"
	@tests/run_tests.sh
.PHONY: test/cpu

# Program
PROGRAM_SOURCE := src/clock.asj

out/clock: $(PROGRAM_SOURCE) out/asj
	@echo "Compiling the clock program"
	@out/asj $(PROGRAM_SOURCE) -o $@

check/clock:
	@echo "Checking is made by compiling the program"
.PHONY: check/clock

test/clock:
	@echo "No clock program test available"
.PHONY: test/clock

# VM-relevant stuff
VM_SOURCES := vm/main.cpp

out/vm: $(VM_SOURCES) | out
	@echo "Compiling the VM"
	@$(CXX) $(CXXFLAGS) -g -O2 -Wall -Wextra -o $@ $^

check/vm:
	@echo "No VM check"
.PHONY: check/vm

test/vm: check/vm
	@echo "No VM test available"
.PHONY: test/vm

# Assembler-relevant stuff
ASSEMBLER_SOURCES := $(wildcard assembler/*.rs) assembler/asj.clx assembler/asj.cgr

out/asj: target/release/asj
	@cp $< $@

out/asj-debug: target/debug/asj
	@cp $< $@

target/release/asj: $(ASSEMBLER_SOURCES)
	cargo build --release

target/debug/asj: $(ASSEMBLER_SOURCES)
	cargo build

assembler/%.clx: assembler/%.lx
	beans compile lexer $<

assembler/%.cgr: assembler/%.gr assembler/%.clx
	beans compile parser --lexer $(word 2,$^) $<

check/asj: $(ASSEMBLER_SOURCES)
	cargo clippy
.PHONY: check/asj

test/asj: out/asj
	@assembler/run-tests
.PHONY: test/asj

## Instruction set
out/%.pdf out/%.aux out/%.log &: docs/%.tex | out
	$(LATEX) $(LATEX_FLAGS) $<
