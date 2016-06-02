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
	output reg [31:0] instr_addr, data_addr, data_out
);
	// Fetch
	reg [31:0] pc;

	// Register File signals
	wire regs_wr_en;
	wire [4:0] regs_wr_num, regs_rd0_num, regs_rd1_num;
	wire [31:0] regs_wr_data;
	wire [31:0] regs_rd0_data, regs_rd1_data;

	regfile regs (
		.clk(clk),
		.wr_num(regs_wr_num),
		.wr_data(regs_wr_data),
		.wr_en(regs_wr_en),
		.rd0_num(regs_rd0_num),
		.rd1_num(regs_rd1_num),
		.rd0_data(regs_rd0_data),
		.rd1_data(regs_rd1_data)
	);

	always_ff @ (posedge clk)
	begin: MIPS
		if (reset == 1) begin
			pc <= pc_init;
			reg_wr_en <= 0;
		end
	end

endmodule
