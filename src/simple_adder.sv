module simple_adder
	#(parameter bits = 32)
	(input [bits-1:0] a, input [bits-1:0] b, input cin, output [bits-1:0] s, output cout);
	wire cint;
	generate
		if (bits == 1) begin
			wire ab, aob;
			assign ab = a & b;
			assign aob = a | b;
			
			assign cout = ab | (aob & cin);
			assign s = a ^ b ^ cin;
		end else begin
			simple_adder#(.bits(bits / 2)) alo(.a(a[(bits/2)-1:0]), .b(b[(bits/2)-1:0]), .cin, .s(s[(bits/2)-1:0]), .cout(cint));
			simple_adder#(.bits(bits / 2)) ahi(.a(a[bits-1:bits/2]), .b(b[bits-1:bits/2]), .cin(cint), .s(s[bits-1:bits/2]), .cout);
		end
	endgenerate
endmodule
