`default_nettype none

module InstructionPointer#(parameter
	 addr_size = 16,
	 isize = 0 // Instruction SIZE = log2(instruction width in 8-bit bytes)
	) (input clk, input rstn,
	 input             incr,
	 input             jmp,
	 input  [addr_size-1:0] jaddr,
	 output [addr_size-1:0] addr
	);
	
	wire logic[addr_size-1:0] nxtaddr;
	
	Reg#(.data_size(addr_size)) val(
		.clk, .rstn,
		.wenable(jmp || incr),
		.wdata(jmp ? jaddr : (addr + {{addr_size-isize-1{1'b0}}, 1'b1, {isize{1'b0}}})),
		.rdata(addr)
	);
endmodule
