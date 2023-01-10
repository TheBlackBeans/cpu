`default_nettype none

module RAM
	#(parameter
	 addr_size = 16,
	 data_size = 16
	) (
	 input logic clk, input logic rstn,
	 input  logic                wenable,
	 input  logic[addr_size-1:0] waddr,
	 input  logic[data_size-1:0] wdata,
	 input  logic[addr_size-1:0] raddr,
	 output logic[data_size-1:0] rdata
	);
	
	logic [data_size-1:0] ram[1 << addr_size];
	
	assign rdata = ram[raddr];
	
	always @(negedge clk or negedge rstn) begin
		if (rstn) begin
			if (wenable) ram[waddr] <= wdata;
		end else begin
			for (int i = 0; i < (1 << addr_size); i++)
				ram[i] <= 0;
		end
	end
endmodule // RAM
