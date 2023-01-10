`default_nettype none

module AdditionALU;
  logic [2:0] op;
  logic signed [15:0] lhs;
  logic signed [15:0] rhs;
  logic signed [15:0] result;

  ALU alu (.op, .lhs, .rhs, .result);

  initial begin
    op = 3'd0;
    for (int left = 2; left < 30; left++) begin
      lhs = left;
      for (int right = 2; right < 30; right++) begin
        rhs = right;
        #0 $display("%0d `%b` %0d = %0d", lhs, op, rhs, result);
      end
    end
  end
endmodule // AdditionALU
