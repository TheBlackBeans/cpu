SOURCES := $(wildcard src/*.sv)
LATEX ?= lualatex
COMPILER ?= iverilog

all: out/cpu out/instructionset.pdf
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

check:
	@- $(foreach file,$(SOURCES),svlint $(file))
.PHONY: check

doc: out/instructionset.pdf
.PHONY: all

out:
	@mkdir out

out/%.pdf out/%.aux out/%.log &: docs/%.tex | out
	$(LATEX) -output-directory=out $<

out/cpu: src/main.sv | out
	@echo "Compiling the CPU"
	@$(COMPILER) -o $@ $^
