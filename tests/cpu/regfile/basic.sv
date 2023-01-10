`default_nettype none

module BasicRegfile;
   logic clk;
   logic rstn;
   logic [3:0] waddr;
   logic [3:0] raddr1;
   logic [3:0] raddr2;
   logic [15:0]	wdata;
   logic	wenable;
   wire [15:0]	rdata1;
   wire [15:0]	rdata2;

   RegFile regs (.clk, .rstn, .waddr, .raddr1, .raddr2, .wdata, .wenable, .rdata1, .rdata2);

   initial begin
      rstn = 0;
      #0 rstn = 1;
      
      clk = 1;
      wenable = 0;
      wdata = 0;
      
      for (int i = 0; i < 8; i++) begin
         raddr1 = i;
         raddr2 = 8+i;
         #1 clk = 0;
         #1 $display("%0d %0d", rdata1, rdata2);
         clk = 1;
      end

      wenable = 1;
      for (int i = 0; i < 16; i++) begin
         raddr1 = i;
         raddr2 = 15-i;
         waddr = i;
         wdata = 32+i;
         #1 clk = 0;
         $display("%0d %0d", rdata1, rdata2);
         #1 clk = 1;
      end

      wenable = 0;
      for (int i = 0; i < 8; i++) begin
         raddr1 = i;
         raddr2 = 8+i;
         #1 clk = 0;
         #1 $display("%0d %0d", rdata1, rdata2);
         clk = 1;
      end
   end
endmodule // BasicRAM
