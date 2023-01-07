`default_nettype none

module Reg
	#(parameter
	 data_size = 16
	) (
	 input logic clk, input logic rstn,
	 input  logic                wenable,
	 input  logic[data_size-1:0] wdata,
	 output   reg[data_size-1:0] rdata
	);
	
	always @(posedge clk or negedge rstn) begin
		if (rstn) begin
			// $display("[  REG  ] Clock went to 1, writing: %b, %016b -> %016b", wenable, rdata, wdata);
			if (wenable) begin
				rdata <= wdata;
			end
		end else begin
			// $display("[  REG  ] Rstn went to 0, clearing memory");
			rdata <= 0;
		end
	end
endmodule
