/* 
 * MODULE: mips
 *
 * DESCRIPTION: Implementation of the 5 stages of a non-piplined
 *		MIPS Proceessor. 
 *
 * PARAMETERS:
 *   pc_init [31:0]
 *     - Initial value for program counter.
 *   sp_init [31:0]
 *     - Initial value for stack pointer.
 *   ra_init [31:0]
 *     - Initial value for return address register.
 *
 * INPUTS:
 *   clk
 *     - Clock signal.
 *   reset
 *     - Reset signal.
 *   instr_in [31:0]
 *     - Input for data from instruction memory.
 *   data_in [31:0]
 *     - Input for data from data memory.
 *
 * OUTPUTS:
 *   data_rd_wr
 *     - Read or write signal for data memory.
 *   instr_addr [31:0]
 *     - Address for next instruction to be fetched from 
 *       instruction memory/
 *   data_addr [31:0]
 *     - Address for the next data to be fetched or written to
 *       data memory.
 *   data_out [31:0]
 *     - Data output.
 */

module mips #(
	parameter [31:0] pc_init = 0,
	parameter [31:0] sp_init = 0,
	parameter [31:0] ra_init = 0
)(
	input wire clk, reset,
	input wire [31:0] instr_in, data_in,
	output reg data_rd_wr,
	output reg [31:0] data_addr, data_out,
	output wire [31:0] instr_addr
);
	reg [4:0] stage;
	reg [31:0] pc;
	reg [31:0] instruction_register;

	// Register File signals
	reg rf_wr_en;
	reg [4:0] rf_wr_num, rf_rd0_num, rf_rd1_num;
	reg [31:0] rf_wr_data;
	wire [31:0] rf_rd0_data, rf_rd1_data;

	// This signal will be used to reset R31 (return address register)
	reg reset_return_address_register;

	regfile regs (
		.clk(clk),
		.wr_num(rf_wr_num),
		.wr_data(rf_wr_data),
		.wr_en(rf_wr_en),
		.rd0_num(rf_rd0_num),
		.rd1_num(rf_rd1_num),
		.rd0_data(rf_rd0_data),
		.rd1_data(rf_rd1_data)
	);

	always_ff @ (posedge clk)
	begin: MIPS
		if (reset == 1) begin
			// Reset Processor
			stage <= 'h1;

			// Reset the return address register in next clock cycle
			reset_return_address_register <= 1;
		end else if (reset_return_address_register == 1) begin
			reset_return_address_register <= 0;
		end else begin
			stage[4:1] <= stage[3:0];
			stage[0] <= stage[4];
		end
	end

	always_ff @ (posedge clk)
	begin : FETCH
		if (reset == 1) begin
			// Reset PC
			pc <= pc_init;
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[0] == 1) begin
			instruction_register <= instr_in;
			pc <= pc + 4;
		end
	end

	always_ff @ (posedge clk)
	begin : DECODE
		if (reset == 1) begin
			// Reset
			
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[1] == 1) begin
			
		end
	end

	always_ff @ (posedge clk)
	begin : EXECUTE
		if (reset == 1) begin
			// Reset
			
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[2] == 1) begin
			
		end
	end

	always_ff @ (posedge clk)
	begin : MEMORY
		if (reset == 1) begin
			// Reset
			data_rd_wr <= 1;
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[3] == 1) begin
			
		end
	end

	always_ff @ (posedge clk)
	begin : WRITEBACK
		if (reset == 1) begin
			// Reset
			// Reset the stack pointer register
			rf_wr_en <= 1;
			rf_wr_num <= 'd29;
			rf_wr_data <= sp_init;
		end else if (reset_return_address_register == 1) begin
			// Reset the return address register
			rf_wr_num <= 'd31;
			rf_wr_data <= 'h0;
		end else if (stage[4] == 1) begin
			
		end
	end

	assign instr_addr = pc;

endmodule
