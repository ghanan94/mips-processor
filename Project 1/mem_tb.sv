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
		clk = 1;
		enable = 0;
		read_write = 0;
		data_in = 32'd0;
		address = 32'd0;
		access_size = 2'd0;
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
			access_size = 2'd0;
			data_in = 32'd234;
			address = 32'd0;
		end

		// Read from address 0 (should be value 234)
		#500 begin 
			read_write = 1;
		end

		// Write alue 1537628013 to address 4
		#500 begin
			read_write = 0;
			data_in = 32'd1537628013;
			address = 32'd4;
		end

		// Read from adress 1 (should be value 1537628013)
		#500 begin
			read_write = 1;
		end

		// Write alue 537628013 to address 8
		#500 begin
			read_write = 0;
			data_in = 32'd537628013;
			address = 32'd8;
		end

		// Read from adress 1 (should be value 537628013)
		#500 begin
			read_write = 1;
		end

		// Write alue 2537628013 to address 12
		#500 begin
			read_write = 0;
			data_in = 32'd2537628013;
			address = 32'd12;
		end

		// Read from adress 1 (should be value 2537628013)
		#500 begin
			read_write = 1;
		end

		// read from address 0 through 15 (should return 234, 1537628013, 537628013, 2537628013)
		#500 begin
			address = 32'd0;
			access_size = 2'd1;
		end

		// Should have no effect
		#1000 begin
			enable = 0;
		end

		#2000 begin
			enable = 1;
			read_write = 0;
			address = 32'd1048572;
			data_in = 32'd10448573;
			access_size = 2'd0;
		end

		#500 begin
			read_write = 1;
		end

		#500 begin
			read_write = 0;
			address = 32'd1048576;
			data_in = 32'd910448573;
		end

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

