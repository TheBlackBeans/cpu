`default_nettype none

module ALU #(parameter integer CELL_SIZE = 16)
(
    input var logic clk,
    input var logic reset_n,
    input var logic op,
    input var logic [CELL_SIZE - 1 : 0] lhs,
    input var logic [CELL_SIZE - 1 : 0] rhs,
    output var logic [CELL_SIZE - 1 : 0] result
);

always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        result <= 0;
    else begin
        case (op)
            3'b000:
                result <= lhs + rhs;
            3'b001:
                result <= lhs - rhs;
            3'b010:
                result <= lhs * rhs;
            3'b011:
                result <= lhs / rhs;
            3'b100:
                result <= lhs % rhs;
            3'b101:
                result <= lhs & rhs;
            3'b110:
                result <= lhs | rhs;
            3'b111:
                result <= lhs ^ rhs;
            default:
                result <= x;
        endcase
    end
end

endmodule
