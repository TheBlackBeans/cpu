`default_nettype none

module ALU #(parameter integer CELL_SIZE = 16)
   (input logic [2:0] op,
    input logic [CELL_SIZE - 1 : 0]  lhs,
    input logic [CELL_SIZE - 1 : 0]  rhs,
    output logic [CELL_SIZE - 1 : 0] result);
   
   always @* begin
      case (op)
        3'b000:
          result = lhs + rhs;
        3'b001:
          result = lhs - rhs;
        3'b010:
          result = lhs * rhs;
        3'b011:
          result = lhs / rhs;
        3'b100:
          result = lhs % rhs;
        3'b101:
          result = lhs & rhs;
        3'b110:
          result = lhs | rhs;
        3'b111:
          result = lhs ^ rhs;
      endcase
   end

endmodule
