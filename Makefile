SOURCES := $(wildcard src/*.sv)
ASSEMBLER_SOURCES := $(wildcard assembler/*.rs)
ASSEMBLER_SOURCES += assembler/asj.clx assembler/asj.cgr
LATEX ?= lualatex
LATEX_FLAGS ?= -interaction=batchmode -output-directory=out
COMPILER ?= iverilog
COMPILER_FLAGS ?= -g2012 -gsupported-assertions

build: out/cpu
.PHONY: build

all: build doc out/asj
.PHONY: all

run: out/cpu
	@out/cpu
.PHONY: run

clean:
	$(RM) out/*
	$(RM) target/*
.PHONY: clean

check/cpu:
	@-$(foreach file,$(SOURCES),svlint $(file); $(COMPILER) $(COMPILER_FLAGS) -t null $(file);)
.PHONY: check/cpu

check/asj:
	cargo clippy
.PHONY: check/asj

check: check/cpu
.PHONY: check

test/asj: out/asj
	@assembler/run-tests
.PHONY: test/asj

test: test/asj
.PHONY: test

doc: out/instructionset.pdf

out:
	@mkdir out

out/%.pdf out/%.aux out/%.log &: docs/%.tex | out
	$(LATEX) $(LATEX_FLAGS) $<

out/asj: target/release/asj
	@cp $< $@

out/asj-debug: target/debug/asj

target/release/asj: $(ASSEMBLER_SOURCES)
	cargo build --release

target/debug/asj: $(ASSEMBLER_SOURCES)
	cargo build

assembler/%.clx: assembler/%.lx
	beans compile lexer $<

assembler/%.cgr: assembler/%.gr assembler/%.clx
	beans compile parser --lexer $(word  2,$^) $<

out/cpu: src/main.sv | out
	@echo "Compiling the CPU"
	@$(COMPILER) $(COMPILER_FLAGS) -o $@ $^
