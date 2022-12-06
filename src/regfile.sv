`default_nettype none

module Regfile
  (input logic clk,
   input logic			reset_n,
   input logic [addr_size-1:0]	r1,
   input logic [addr_size-1:0]	r2,
   input logic [addr_size-1:0]	rd,
   input logic [cell_size-1:0]	rddata,
   input logic			we,
   output logic [cell_size-1:0]	r1data,
   output logic [cell_size-1:0]	r2data);
   
   logic [cell_size-1:0]	regfile [2**addr_size] = '{ default: 0 };
   
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n)
	regfile = '{ default: 0 };
      else begin
	 r1data <= regfile[r1];
	 r2data <= regfile[r2];
	 if (we)
	   regfile[rd] <= rddata;
      end
   end
endmodule // Ram    
