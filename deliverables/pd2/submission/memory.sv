/*
 * MODULE: memory
 *
 * DESCRIPTION: Implementation of a memory module. Data
 *              is stored in 32 bit words, adddressed by
 *              word's byte address.
 *
 * PARAMETERS:
 *   benchmark String
 *     - String value for name of file with data to
 *       intially load into memory.
 *   depth Integer
 *     - Size of memory in bytes.
 *   offset Integer
 *     - Offset for memory address.
 *
 * INPUTS:
 *   clk
 *     - Clock signal.
 *   rd_wr
 *     - Read or write signal (1 = Read; 0 = Write).
 *   enable
 *     - Enable signal. If this is 0, do nothing.
 *   access_size [1:0]
 *     - Size of data to return. Data sizes mapping:
 *       0 : 1 Word
 *       1 : 4 Words
 *       2 : 8 Words
 *       3 : 16 Words
 *   data_in [31:0]
 *     - Input data to write to memory.
 *   addr [31:0]
 *     - Byte-address in memory to either read or write.
 *
 * OUTPUTS:
 *   busy
 *     - Memory working on a multi-word read if 1, else 0.
 *   data_out [31:0]
 *     - Response from memory.
 */
module memory #(
	parameter benchmark = "",
	parameter depth = 2**20,
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
				// Output rest of the words requested
				data_out <= memory[mem_word_reading_index];
				mem_word_reading_index <= mem_word_reading_index + 1;
				remaining <= remaining - 1;
			end else if (rd_wr == 1) begin
				// Output first word requested to be read
				case (access_size)
					2'b00 : remaining <= 4'd0;
					2'b01 : remaining <= 4'd3;
					2'b10 : remaining <= 4'd7;
					2'b11 : remaining <= 4'd15;
				endcase

				data_out <= memory[mem_word_index];
				mem_word_reading_index <= mem_word_index + 1;
			end else begin
				// Write to memory
				memory[mem_word_index] <= data_in;
			end
		end
	end

	assign effective_address = addr - offset;
	assign mem_word_index = effective_address >> 2;
	assign busy = remaining > 0;
endmodule

