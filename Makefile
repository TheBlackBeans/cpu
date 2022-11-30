all:

COMPILER ?= iverilog

# Meta targets
all: out/cpu
.PHONY: all

build: out/cpu
.PHONY: build

run: out/cpu
	@out/cpu
.PHONY: run

clean:
	@echo "Removing out/*"
	@$(RM) out/*
.PHONY: clean

# Directories
out:
	@mkdir out

# CPU-relevant stuff
CPU_SOURCES := \
	src/ip.sv \
	src/reg.sv \
	src/main.sv # Last one

out/cpu: $(CPU_SOURCES) | out
	@echo "Compiling the CPU"
	@$(COMPILER) -o $@ $^

lint:
	@echo "Calling svlint (if it exists)"
	@if which svlint >/dev/null 2>&1; then $(foreach file,$(CPU_SOURCES),svlint $(file);) fi
	@echo "Checking test decriptions"
	@cd tests; for f in *; do if [[ -f "$$f/description.txt" ]]; then ./read_description.sh --lint "$$f"; fi; done
.PHONY: lint

check: lint
	@echo "Running tests"
	@tests/run_tests.sh
.PHONY: check
