module single_pg_adder(input a, input b, input cin, output s, output g, output p);
	assign g = a & b;
	assign p = ~g & (a | b);
	assign s = p ^ cin;
endmodule

module pg_adder_inner
	#(parameter bits = 32)
	(input [bits-1:0] a, input [bits-1:0] b, input cin, output [bits-1:0] s, output g, output p, output cout);
	generate
		if (bits == 1) begin
			single_pg_adder adder(.a, .b, .cin, .s, .g, .p);
		end else begin
			wire logic glo, plo, ghi, phi, clo;
			
			pg_adder_inner#(.bits(bits / 2))
				lo(.a(a[(bits/2)-1:0]), .b(b[(bits/2)-1:0]), .cin, .s(s[(bits/2)-1:0]), .g(glo), .p(plo), .cout(clo)),
				hi(.a(a[bits-1:bits/2]), .b(b[bits-1:bits/2]), .cin(clo), .s(s[bits-1:bits/2]), .g(ghi), .p(phi));
			
			assign g = ghi | (phi & glo);
			assign p = phi & plo;
		end
	endgenerate
	assign cout = g | (p & cin);
endmodule

module pg_adder
	#(parameter bits = 32)
	(input [bits-1:0] a, input [bits-1:0] b, input cin, output [bits-1:0] s, output cout);
	pg_adder_inner#(.bits(bits)) pga(.a, .b, .cin, .s, .cout);
endmodule
