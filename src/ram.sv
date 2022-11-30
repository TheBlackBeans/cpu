`default_nettype none

module Ram #(parameter addr_size = 4, parameter cell_size = 16)
   (input logic clk,
    input logic			 reset_n,
    input logic [addr_size-1:0]	 ra,
    input logic [addr_size-1:0]	 wa,
    input logic [cell_size-1:0]	 data,
    input logic			 we,
    output logic [cell_size-1:0] result);
   
   logic [cell_size-1:0]	 ram [2**addr_size] = '{ default: 0 };
   
   always @(posedge clk or negedge reset_n) begin
      if (!reset_n)
	ram = '{ default: 0 };
      else begin
	 result <= ram[ra];
	 if (we)
	   ram[wa] <= data;
      end
   end
endmodule // Ram    
