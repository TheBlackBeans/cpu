`default_nettype none

module Main;
	reg enable, clk, rstn;
	reg [3:0] data;
	wire [3:0] out;
	
	Reg #(.bits(4)) r (.clk,
			   .rstn,
			   .wenable(enable),
			   .wdata(data),
			   .rdata(out));
	
	always #1 clk = ~clk;
	
	initial begin
		clk = 0;
		enable = 0;
		data = 4'b0000;
		rstn = 0;
		$display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		#1 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		#1 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		rstn = 1;
		#2 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		data = 4'b1111;
		#2 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		data = 4'b1010;
		#2 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		enable = 1;
		#1 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		#1 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		data = 4'b1111;
		#1 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		enable = 0;
		#1 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		#1 $display("%1b %1b %4b -> %4b", rstn, enable, data, out);
		$finish;
	end
endmodule
