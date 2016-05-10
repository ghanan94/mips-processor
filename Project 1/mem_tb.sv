module memory_32bit_tb;
	logic clk;
	logic enable;
	logic read_write;
	logic [31:0] data_in;
	logic [31:0] address;
	logic [1:0] access_size;
	logic [31:0] data_out;
	logic busy;

	initial begin
		clk = 0;
		enable = 0;
		read_write = 0;
		data_in = 32'd0;
		address = 32'd0;
		access_size = 2'b0;
	end

	always
	begin : CLOCK
		#250 clk = ~clk;
	end

	always
	begin : TEST_BENCH
	
		// Write value 234 to address 0
		#500 begin
			enable = 1; 
			read_write = 0;
			data_in = 32'd234;
			address = 32'd0;
		end

		// Read from address 0 (should be value 234)
		#500 begin 
			read_write = 1;
		end
	end


	memory_32bit memory (
		.busy(busy), 
		.data_out(data_out), 
		.clk(clk), 
		.read_write(read_write), 
		.enable(enable), 
		.access_size(access_size),
		.data_in(data_in), 
		.address(address)
	);

		
endmodule

