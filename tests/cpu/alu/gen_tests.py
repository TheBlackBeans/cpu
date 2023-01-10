from operator import add, sub, mul, floordiv, mod, and_, or_, xor 
from functools import wraps

operators = [
    (add, "addition"),
    (sub, "subtraction"),
    (mul, "multiplication"),
    (floordiv, "division"),
    (mod, "modulo"),
    (and_, "bitwise and"),
    (or_, "bitwise or"),
    (xor, "bitwise xor"),
]

LOWERBOUND = 2
UPPERBOUND = 30
BITS = 16

arguments = "-g2012 ../src/alu.sv"
code_template = """`default_nettype none

module {name}ALU;
  logic [2:0] op;
  logic signed [15:0] lhs;
  logic signed [15:0] rhs;
  logic signed [15:0] result;

  ALU alu (.op, .lhs, .rhs, .result);

  initial begin
    op = 3'd{operator};
    for (int left = {lowerbound}; left < {upperbound}; left++) begin
      lhs = left;
      for (int right = {lowerbound}; right < {upperbound}; right++) begin
        rhs = right;
        #0 $display("%0d `%b` %0d = %0d", lhs, op, rhs, result);
      end
    end
  end
endmodule // {name}ALU
"""

def gen_tests(op):
    actual_op, description = operators[op]
    base_name = description.replace(" ", "_")
    with open(f"{base_name}.sv", "w") as code_file:
        code_file.write(code_template.format(
            name = description.title().replace(" ", ""),
            lowerbound = LOWERBOUND,
            upperbound = UPPERBOUND,
            operator = op,
        ))

    with open(f"{base_name}.txt", "w") as desc_file:
        for left in range(LOWERBOUND, UPPERBOUND):
            for right in range(LOWERBOUND, UPPERBOUND):
                desc_file.write(
                    f"{left} `{op:0>3b}` {right} = {actual_op(left, right)}\n"
                )
    return f"alu/{base_name}.txt@{description.title()}@alu/{base_name}.sv"

with open("description.txt", "w") as f:
    f.write(arguments+'\n')
    for op in range(len(operators)):
        f.write(gen_tests(op)+'\n')
        
