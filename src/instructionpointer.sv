`default_nettype none

module InstructionPointer
	#(parameter bits = 32, isize = 2) // Instruction SIZE = log2(instruction width in 8-bit bytes)
	(input clk, input rstn,
	 input             incr,
	 input             jmp,
	 input  [bits-1:0] jaddr,
	 output [bits-1:0] addr);
	
	wire logic[bits-1:0] nxtaddr;
	
	Reg#(.bits(bits)) val(
		.clk,
		.rstn,
		.wenable(1'b1),
		.wdata(jmp ? jaddr : (incr ? addr + {{bits-isize-1{1'b0}}, 1'b1, {isize{1'b0}}} : addr)),
		.rdata(addr)
	);
endmodule
