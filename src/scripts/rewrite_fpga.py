#!/usr/bin/env python

import sys

header = """`timescale   1ns / 1ps

module cpu(
	 input  logic      clk,
	 input  logic      reset,
	 input  logic      select_hhmmss,
	 input  logic      select_yymmdd,
	 input  logic      select_yyyymm,
	 input  logic[2:0] buttons,
	 output logic[6:0] display0,
	 output logic[5:0] display1,
	 output logic[6:0] display2,
	 output logic[6:0] display3,
	 output logic[6:0] display4,
	 output logic[6:0] display5
	);
	
	wire rstn;
	logic [31:0] rom[2**8];
	
	logic [15:0] ip;
	
	assign rstn = ~reset;
	
	wire write_out;
	wire [3:0] out_port;
	wire [15:0] out_data;
	
	Driver#(.rom_size(2**8)) driver(.rom, .clk, .rstn, .ip, .write_out, .out_port, .out_data, .in_data(buttons));
	
	logic [7:0] seconds;
	logic [7:0] minutes;
	logic [7:0] hours;
	logic [7:0] days;
	logic [7:0] months;
	logic [15:0] years;
   
	wire [3:0] years_thousands = years / 'd1000;
	wire [3:0] years_hundreds  = (years / 'd100) % 'd10;
	wire [3:0] years_tens      = (years /  'd10) % 'd10;
	wire [3:0] years_ones      = years   % 'd10;
	wire [3:0] months_tens     = months  / 'd10;
	wire [3:0] months_ones     = months  % 'd10;
	wire [3:0] days_tens       = days    / 'd10;
	wire [3:0] days_ones       = days    % 'd10;
	wire [3:0] hours_tens      = hours   / 'd10;
	wire [3:0] hours_ones      = hours   % 'd10;
	wire [3:0] minutes_tens    = minutes / 'd10;
	wire [3:0] minutes_ones    = minutes % 'd10;
	wire [3:0] seconds_tens    = seconds / 'd10;
	wire [3:0] seconds_ones    = seconds % 'd10;
	
	logic [3:0] digit0, digit1, digit2, digit3, digit4, digit5;
	
	assign display0 = to_7_segment(digit0);
	assign display1 = to_reduced_7_segment (digit1);
	assign display2 = to_7_segment(digit2);
	assign display3 = to_7_segment(digit3);
	assign display4 = to_7_segment(digit4);
	assign display5 = to_7_segment(digit5);
	
	assign digit5 = select_yyyymm ? years_thousands : select_yymmdd ? years_tens  : select_hhmmss ? hours_tens   : 'd10;
	assign digit4 = select_yyyymm ? years_hundreds  : select_yymmdd ? years_ones  : select_hhmmss ? hours_ones   : 'd10;
	assign digit3 = select_yyyymm ? years_tens      : select_yymmdd ? months_tens : select_hhmmss ? minutes_tens : 'd10;
	assign digit2 = select_yyyymm ? years_ones      : select_yymmdd ? months_ones : select_hhmmss ? minutes_ones : 'd10;
	assign digit1 = select_yyyymm ? months_tens     : select_yymmdd ? days_tens   : select_hhmmss ? seconds_tens : 'd10;
	assign digit0 = select_yyyymm ? months_ones     : select_yymmdd ? days_ones   : select_hhmmss ? seconds_ones : 'd10;
	always @(negedge clk) begin
		if (write_out) begin
			case (out_port)
			0: begin
				seconds = out_data;
			end
			1: begin
				minutes = out_data;
			end
			2: begin
				hours = out_data;
			end
			3: begin
				days = out_data;
			end
			4: begin
				months = out_data;
			end
			5: begin
				years = out_data;
			end
			endcase
		end
	end
	
	function logic [6:0] to_7_segment(input logic [3:0] digit);
		return digit == 0 ? 'b1000000 :
			   digit == 1 ? 'b1111001 :
			   digit == 2 ? 'b0100100 :
			   digit == 3 ? 'b0110000 :
			   digit == 4 ? 'b0011001 :
			   digit == 5 ? 'b0010010 :
			   digit == 6 ? 'b0000010 :
			   digit == 7 ? 'b1111000 :
			   digit == 8 ? 'b0000000 :
			   digit == 9 ? 'b0010000 :
							'b0000110 ;
	endfunction
	
	function logic [5:0] to_reduced_7_segment(input logic [3:0] digit);
		return to_7_segment(digit)[6:1];
	endfunction
	
	initial begin
"""
trailer = """	end
endmodule
"""

def hexl(n):
	s = hex(n)[2:]
	if len(s) < 8:
		return "0" * (8 - len(s)) + s
	else:
		return s

def main(inf, outf):
	binfile = []
	with open(inf, 'rb') as f:
		while (txt := f.read(4)) != b'':
			binfile.append(int.from_bytes(txt, 'little'))
	with open(outf, 'w') as f:
		f.write(header)
		for i, insn in enumerate(binfile):
			f.write(f"\t\trom[{i}] = 'h{hexl(insn)};\n")
		f.write(trailer)

if __name__ == '__main__':
	if len(sys.argv) == 2:
		main(sys.argv[1], "src/fpga/cpu_FPGA.v")
	elif len(sys.argv) == 3:
		main(sys.argv[1], sys.argv[2])
	else:
		print(f"Usage: {sys.argv[0]} <binary> [<output filename>]")
