module fullAdder(a, b, cin, s, cout);
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
