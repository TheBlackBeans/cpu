`default_nettype none

module BasicRAM;
   logic clk;
   logic rstn;
   logic [3:0] ra;
   logic [3:0] wa;
   logic [15:0]	data;
   logic	we;
   wire [15:0]	result;

   Ram ram (.clk, .rstn, .ra, .wa, .data, .we, .result);

   initial begin
      rstn = 0;
      #0 rstn = 1;
      
      clk = 0;
      we = 0;
      data = 0;
      
      for (int i = 0; i < 16; i++) begin
	 ra = i;
	 #1 clk = 1;
	 #1 $display("%0d", result);
	 clk = 0;
      end

      we = 1;
      for (int i = 0; i < 16; i++) begin
	 ra = i;
	 wa = i;
	 data = i;
	 #1 clk = 1;
	 #1 $display("%0d", result);
	 clk = 0;
      end

      we = 0;
      for (int i = 0; i < 16; i++) begin
	 ra = i;
	 #1 clk = 1;
	 #1 $display("%0d", result);
	 clk = 0;
      end
	 
   end
endmodule // BasicRAM
