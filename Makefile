CC := iverilog

build: out/cpu
run: out/cpu
	@$^

clean:
	$(RM) out/*

out:
	@mkdir out

out/cpu: src/main.sv | out
	$(CC) -o $@ $^

.PHONY: clena build run
