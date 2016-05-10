module fullAdder2_1bit(a, b, cin, s, cout);
	input a;
	input b;
	input cin;
	output s;
	output cout;

	wire aXORb;
	wire cANDaXORb;
	wire aANDb;

	xor2_1bit XORgate1 (a, b, aXORb);
	xor2_1bit XORgate2 (aXORb, cin, s);
	and2_1bit ANDgate1 (cin, aXORb, cANDaXORb);
	and2_1bit ANDgate2 (a, b, aANDb);
	or2_1bit ORgate1 (cANDaXORb, aANDb, cout);
endmodule

module fullAdder2_4bit(a, b, cin, s, cout);
	input [3:0] a;
	input [3:0] b;
	input cin;
	output [3:0] s;
	output cout;

	wire cout0;
	wire cout1;
	wire cout2;

	fullAdder2_1bit FullAdder1 (a[0], b[0], cin, s[0], cout0);
	fullAdder2_1bit FullAdder2 (a[1], b[1], cout0, s[1], cout1);
	fullAdder2_1bit FullAdder3 (a[2], b[2], cout1, s[2], cout2);
	fullAdder2_1bit FullAdder4 (a[3], b[3], cout2, s[3], cout);
endmodule
