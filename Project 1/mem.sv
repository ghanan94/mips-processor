module memory_32bit(output reg busy, output reg [31:0] data_out, input wire clk, read_write, enable, input wire [1:0] access_size, input wire [31:0] data_in, address);

	reg [7:0] memory [0:1048575];
	reg reading;
	reg [31:0] reading_address;
	reg [3:0] read_cycles;

	always_ff @ (posedge clk) 
	begin : MEM_READ

		if (enable) 
		begin
			if (read_write && ~reading) 
			begin
				reading <= 1;
				reading_address <= address;

				case (access_size)
					00 : read_cycles <= 4'd0;
					01 : read_cycles <= 4'd3;
					10 : read_cycles <= 4'd7;
					11 : read_cycles <= 4'd15;
				endcase
			end
			else
				reading <= 0;
		end

		if (reading) 
		begin
			data_out[7:0] <= memory[reading_address + 3];
			data_out[15:8] <= memory[reading_address + 2];
			data_out[23:16] <= memory[reading_address + 1];
			data_out[31:24] <= memory[reading_address];

			if (read_cycles == 4'd0)
				reading <= 0;
			else
			begin
				reading_address <= reading_address + 4;
				read_cycles <= read_cycles - 1;
			end
		end
	end

	always_ff @ (posedge clk)
	begin : MEM_WRITE
		if (enable && ~read_write) 
		begin
			memory[address + 3] <= data_in[7:0];
			memory[address + 2] <= data_in[15:8];
			memory[address + 1] <= data_in[23:16];
			memory[address] <= data_in[31:24];
		end
	end

	always_ff @ (posedge clk)
	begin : BUSY
		if (enable || reading)
			busy <= 1;
		else
			busy <= 0;
	end
endmodule

