module single_register
	#(parameter bits = 32)
	(input clk, input rstn,
	 input             wenable,
	 input  [bits-1:0] wdata,
	 output reg[bits-1:0] rdata);
	
	always @(posedge clk or negedge rstn) begin
		if (rstn) begin
			if (wenable) begin
				rdata <= wdata;
			end
		end else begin
			rdata <= 0;
		end
	end
endmodule
