module memory #(
	parameter benchmark = "",
	parameter depth = 1048576
)(
	output reg busy, 
	output reg [31:0] data_out, 
	input wire clk, rd_wr, enable, 
	input wire [1:0] access_size, 
	input wire [31:0] data_in, addr
);

	reg [31:0] memory [0:(depth >> 2)-1];
	reg reading;
	reg [31:0] reading_address;
	reg [3:0] read_cycles;

	initial
	begin
		$readmemh(benchmark, memory);
	end

	always_ff @ (posedge clk) 
	begin : MEM_READ

		if (enable) 
		begin
			if (rd_wr && ~reading) 
			begin
				reading <= 1;
				reading_address <= addr >> 2;

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
			data_out <= memory[reading_address];

			if (read_cycles == 4'd0)
				reading <= 0;
			else
			begin
				reading_address <= reading_address + 1;
				read_cycles <= read_cycles - 1;
			end
		end
	end

	always_ff @ (posedge clk)
	begin : MEM_WRITE
		if (enable && ~rd_wr) 
		begin
			memory[addr >> 2] <= data_in;
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

