`default_nettype none

module Ram #(parameter addr_size = 4,
	     parameter cell_size = 16,
	     parameter size = 2**addr_size)
   (input logic clk,
    input logic			 reset_n,
    input logic [addr_size-1:0]	 ra,
    input logic [addr_size-1:0]	 wa,
    input logic [cell_size-1:0]	 data,
    input logic			 we,
    output logic [cell_size-1:0] result);
   
   logic [cell_size-1:0]	 ram [size];
   
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n)
	for (int i = 0; i < size; i++)
	  ram[i] <= 0;
      else begin
	 result <= ram[ra];
	 if (we)
	   ram[wa] <= data;
      end
   end
endmodule // Ram    
