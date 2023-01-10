`default_nettype none

module RegFile#(parameter
	 addr_size = 4,
	 data_size = 16
	) (
	 input logic clk, input logic rstn,
	 input  logic                wenable,
	 input  logic[addr_size-1:0] waddr,
	 input  logic[data_size-1:0] wdata,
	 input  logic[addr_size-1:0] raddr1,
	 input  logic[addr_size-1:0] raddr2,
	 output logic[data_size-1:0] rdata1,
	 output logic[data_size-1:0] rdata2
	);
	
	logic [data_size-1:0] regs[1 << addr_size];
	
	assign rdata1 = raddr1 != 0 ? regs[raddr1] : 0;
	assign rdata2 = raddr2 != 0 ? regs[raddr2] : 0;
	
	always @(negedge clk or negedge rstn) begin
		if (rstn) begin
			// $display("[REGFILE] Clock went to 0, writing to %04b: %b, %016b -> %016b", waddr, wenable, regs[waddr], wdata);
			if (wenable) regs[waddr] <= wdata;
		end else begin
			// $display("[REGFILE] Rstn went to 0, clearing memory");
			for (int i = 0; i < (1 << addr_size); i++)
				regs[i] <= 0;
		end
	end
endmodule // RegFile
