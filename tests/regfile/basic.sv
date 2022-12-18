`default_nettype none

module BasicRegfile;
   logic clk;
   logic rstn;
   logic [3:0] rd;
   logic [3:0] r1;
   logic [3:0] r2;
   logic [15:0]	rddata;
   logic	we;
   wire [15:0]	r1data;
   wire [15:0]	r2data;

   Regfile regs (.clk, .rstn, .rd, .r1, .r2, .rddata, .we, .r1data, .r2data);

   initial begin
      rstn = 0;
      #0 rstn = 1;
      
      clk = 0;
      we = 0;
      rddata = 0;
      
      for (int i = 0; i < 8; i++) begin
	 r1 = i;
	 r2 = 8+i;
	 #1 clk = 1;
	 #1 $display("%0d %0d", r1data, r2data);
	 clk = 0;
      end

      we = 1;
      for (int i = 0; i < 16; i++) begin
	 r1 = i;
	 r2 = 15-i;
	 rd = i;
	 rddata = 32+i;
	 #1 clk = 1;
	 #1 $display("%0d %0d", r1data, r2data);
	 clk = 0;
      end

      we = 0;
      for (int i = 0; i < 8; i++) begin
	 r1 = i;
	 r2 = 8+i;
	 #1 clk = 1;
	 #1 $display("%0d %0d", r1data, r2data);
	 clk = 0;
      end
   end
endmodule // BasicRAM
