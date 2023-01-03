`default_nettype none

module Regfile
  (input logic clk,
   input logic	       rstn,
   input logic [3:0]   r1,
   input logic [3:0]   r2,
   input logic [3:0]   rd,
   input logic [15:0]  rddata,
   input logic	       we,
   output logic [15:0] r1data,
   output logic [15:0] r2data);
   
   logic [15:0]	regfile [16];
   
   always @(posedge clk or negedge rstn) begin
      if (!rstn)
	for (int i = 0; i < 16; i++)
	  regfile[i] <= 0;
      else begin
	 r1data <= regfile[r1];
	 r2data <= regfile[r2];
	 if (we && !rd)
	   regfile[rd] <= rddata;
      end
   end
endmodule // Regfile
