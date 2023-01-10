`default_nettype none

module BasicRAM;
   logic clk;
   logic rstn;
   logic [3:0] ra;
   logic [3:0] wa;
   logic [15:0]	data;
   logic	we;
   wire [15:0]	result;

   RAM ram (.clk, .rstn, .raddr(ra), .waddr(wa), .wdata(data), .wenable(we), .rdata(result));

   initial begin
      rstn = 0;
      #0 rstn = 1;
      
      clk = 1;
      we = 0;
      data = 0;
      
      for (int i = 0; i < 16; i++) begin
	 ra = i;
	 #1 clk = 0;
	 $display("%0d", result);
	 #1 clk = 1;
      end

      we = 1;
      for (int i = 0; i < 16; i++) begin
	 ra = i;
	 wa = i;
	 data = i;
	 #1 clk = 0;
	 $display("%0d", result);
	 #1 clk = 1;
      end

      we = 0;
      for (int i = 0; i < 16; i++) begin
	 ra = i;
	 #1 clk = 0;
	 $display("%0d", result);
	 #1 clk = 1;
      end
	 
   end
endmodule // BasicRAM
