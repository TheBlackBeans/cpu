`default_nettype none
`timescale 10ms/100ns // #1 = 10±0.1μs

module MiscManager#(parameter
	 data_size = 16
	) (
	 input logic clk, input logic rstn,
	 input  logic                cs, // Chip Select
	 input  logic[3:0]           op,
	 input  logic[data_size-1:0] port,
	 input  logic[data_size-1:0] data,
	 output logic[data_size-1:0] result
	);
	
	logic ram_write;
	logic [data_size-1:0] ram_read;
	
	parameter integer STDIN = 32'h8000_0000;
	
	int char;
	
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
	
	assign ram_write = op == 4'b0001;
	
	always @(posedge clk or negedge rstn) begin
		if (rstn) begin
			// Note: this delay is REQUIRED for iverilog to order execution properly...
			#10 // $display("[  IO   ] Clock went to 1: op %04b + cs %b", op, cs);
			case (op)
			4'b0000: begin
				result = ram_read;
			end
			4'b0001: begin
				result = ram_read;
			end
			
			// FIXME: I/O ports
			4'b0010: begin
				if (cs) begin
					#0 $display("RECV %0d", port);
				   $fflush();
				   
					char = $fgetc(STDIN)-48;
					while (char != 0 && char != 1 && char != 2)
						char = $fgetc(STDIN)-48;
				   while ($fgetc(STDIN) != 10) ;
					if (char == 2) $finish;
					result = char;
					// $display("[  IO   ] Recv %016b from port %016b", result, port);
				end else result = 0;
			end
			4'b0011: begin
				result = 0;
				if (cs) begin
					// $display("[  IO   ] Sent %016b to port %016b", data, port);
					$display("SEND %0d %0d", port, data);
				end
			end
			
			default: begin
				result = 0;
			end
			endcase
		end
	end // always @ (posedge clk or negedge rstn)
endmodule
