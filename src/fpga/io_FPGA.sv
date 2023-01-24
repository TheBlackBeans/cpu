// `timescale 10ms/100ns // #1 = 10±0.1μs


module MiscManager#(parameter
	 data_size = 16
	) (
	 input logic clk, input logic rstn,
	 input  logic                cs, // Chip Select
	 input  logic[3:0]           op,
	 input  logic[data_size-1:0] port,
	 input  logic[data_size-1:0] data,
	 input  logic[2:0]           in_data
	 output logic[data_size-1:0] result,
	 output logic                write_out,
	 output logic[3:0]           out_port,
	 output logic[15:0]          out_data,
	);
	
	assign write_out = cs && (op == 4'b0001);
	assign out_data = data;
	assign out_port = port;
	
	logic ram_write;
	logic [data_size-1:0] ram_read;
	
	RAM#(
		.addr_size(data_size),
		.data_size(data_size)
	) ram(
		.clk, .rstn,
		.wenable(ram_write),
		.waddr(port),
		.wdata(data),
		.raddr(port),
		.rdata(ram_read)
	);
	
	assign ram_write = cs && (op == 4'b0001);
	
	assign result = ~rstn        ? 0 :
	                op == 'b0000 ? ram_read :
	                op == 'b0010 ? in_data[port] :
	                               0;
endmodule
