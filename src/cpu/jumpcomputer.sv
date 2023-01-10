`default_nettype none

module JumpComputer#(parameter
	 addr_size = 16,
	 data_size = 16
	) (
	 input  logic       maybe_jmp,
	 input  logic[3:0]  op,
	 input  logic[addr_size-1:0] ip,
	 input  logic[data_size-1:0] arg1,
	 input  logic[data_size-1:0] arg2,
	 output logic                do_jmp,
	 output logic[addr_size-1:0] jaddr
	);
	
	logic test_step1;
	
	assign test_step1 = op[0] ? (arg2 == 0) : 1;
	assign do_jmp = (test_step1 ^ op[2]) && maybe_jmp;
	assign jaddr = op[1] ? (ip + arg1) : arg1;
	
	/* always @* begin
		$display("[  JMP  ] Update: maybe %b + op %04b + data %04b   test_step1 %b  do_jmp %b", maybe_jmp, op, arg2, test_step1, do_jmp);
	end */
endmodule // JumpComputer
