all:

COMPILER?=iverilog

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

out:
	@mkdir out

out/cpu: src/main.sv | out
	@echo "Compiling the CPU"
	@$(COMPILER) -o $@ $^
