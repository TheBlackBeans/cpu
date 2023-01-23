`default_nettype none

module Comparator#(parameter
	 data_size = 16
	) (
	 input  logic[2:0]           instr,
	 input  logic[data_size-1:0] lhs,
	 input  logic[data_size-1:0] rhs,
	 output logic[data_size-1:0] result
	);
	
	logic [data_size-1:0] tmpres;
	
	always @* begin
		// instr = nul Negate Unsigned Less than
		case (instr[1:0])
		2'b00: tmpres = $unsigned(lhs) == $unsigned(rhs);
		2'b01: tmpres = $unsigned(lhs) <  $unsigned(rhs);
		2'b10: tmpres =   $signed(lhs) ==   $signed(rhs);
		2'b11: tmpres =   $signed(lhs) <    $signed(rhs);
		endcase // case (instr)
		result = {{data_size-1{1'b0}}, instr[2] ^ tmpres};
		// $display("[ COMP  ] Update: op %3b with %016b %016b --> %b->%b", instr, lhs, rhs, tmpres, result);
	end
endmodule
