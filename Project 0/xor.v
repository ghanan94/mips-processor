module xor2_1bit(a, b, c);
	input a;
	input b;
	output c;

	assign c = a ^ b;
endmodule

module xor2_32bit(a, b, c);
	input [31:0] a;
	input [31:0] b;
	output [31:0] c;

	assign c = a ^ b;
endmodule
