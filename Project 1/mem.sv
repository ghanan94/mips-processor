module memory #(
	parameter benchmark = "",
	parameter depth = 1048576,
	parameter offset = 'h80020000
)(
	output wire busy, 
	output reg [31:0] data_out, 
	input wire clk, rd_wr, enable, 
	input wire [1:0] access_size, 
	input wire [31:0] data_in, addr
);

	reg [31:0] memory [0:(depth >> 2)-1];
	reg [31:0] mem_word_reading_index;
	reg [3:0] remaining;
	wire [31:0] effective_address;
	wire [31:0] mem_word_index;

	initial
	begin
		$readmemh(benchmark, memory);
	end

	always_ff @ (posedge clk) 
	begin : MEM_READ

		if (enable == 1) begin
			if (remaining > 0) begin
				data_out <= memory[mem_word_reading_index];
				mem_word_reading_index <= mem_word_reading_index + 1;
				remaining <= remaining - 1;
			end else if (rd_wr == 1) begin
				case (access_size)
					2'b00 : remaining <= 4'd0;
					2'b01 : remaining <= 4'd3;
					2'b10 : remaining <= 4'd7;
					2'b11 : remaining <= 4'd15;
				endcase

				data_out <= memory[mem_word_index];
				mem_word_reading_index <= mem_word_index + 1;
			end else begin
				// WRITE
				memory[mem_word_index] <= data_in;
			end
		end
	end

	assign effective_address = addr - offset;
	assign mem_word_index = effective_address >> 2;
	assign busy = remaining > 0;
endmodule

