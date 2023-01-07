`default_nettype none
`timescale 10ms/100ns // #1 = 10±0.1μs

module MiscManager#(parameter
	 data_size = 16
	) (
	 input logic clk, input logic rstn,
	 input  logic                 cs, // Chip Select
	 input  logic[3:0]            op,
	 input  logic[data_size-1:0]  port,
	 input  logic[data_size-1:0]  data,
	 output logic [data_size-1:0] result
	);
	
	logic ram_write;
	logic [data_size-1:0] ram_read;
	
	parameter integer STDIN = 32'h8000_0000;
	
	bit [data_size-1:0] seconds; // Port 0
	bit [data_size-1:0] minutes; // Port 1
	bit [data_size-1:0] hours;   // Port 2
	bit [data_size-1:0] days;    // Port 3
	bit [data_size-1:0] months;  // Port 4
	bit [data_size-1:0] years;   // Port 5
	
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
					//#0 $display("%0d> ", port);
					char = $fgetc(STDIN)-48;
					while (char != 0 && char != 1 && char != 2)
						char = $fgetc(STDIN)-48;
					if (char == 2) $finish;
					result = char;
					// $display("[  IO   ] Recv %016b from port %016b", result, port);
				end else result = 0;
			end
			4'b0011: begin
				result = 0;
				if (cs) begin
					case (port)
					3'd0: seconds = data;
					3'd1: minutes = data;
					3'd2: hours   = data;
					3'd3: days    = data;
					3'd4: months  = data;
					3'd5: years   = data;
					endcase; // case (port)
					// $display("[  IO   ] Sent %016b to port %016b", data, port);
					$display("          %02d/%02d/%04d %02dh%02d'%02d\"", days, months, years, hours, minutes, seconds);
				end
			end
			
			default: begin
				result = 0;
			end
			endcase
		end else begin
			seconds = 0;
			minutes = 0;
			hours = 0;
			days = 0;
			months = 0;
			years = 0;
		end
	end // always @ (posedge clk or negedge rstn)
endmodule
