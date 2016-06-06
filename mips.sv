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

typedef enum reg [5:0] {
	SPECIAL = 'b000000,
	ADDIU   = 'b001001,
	LW      = 'b100011,
	SW      = 'b101011
} MIPS_OPCODE;

typedef enum reg [5:0] {
	NOP     = 'b000000,
	JR      = 'b001000,
	ADDU    = 'b100001
} MIPS_SPECIAL_FUNCT_OPCODE;

typedef enum reg [1:0] {
	ADD,
	SUB
} ALU_OP_TYPE;

module mips #(
	parameter [31:0] pc_init = 0,
	parameter [31:0] sp_init = 0,
	parameter [31:0] ra_init = 0
)(
	input wire clk, reset,
	input wire [31:0] instr_in, data_in,
	output reg data_rd_wr,
	output reg [31:0] data_out,
	output wire [31:0] instr_addr, data_addr
);
	reg [4:0] stage;

	// Fetch signals
	reg [31:0] f_pc, f_instruction_register;

	// Decode signals
	reg [31:0] d_pc, d_signed_extended_offset;
	reg [4:0] d_wb_register;
	// A (0: pc; 1: rs); B (0: rt; 1: offset)
	reg d_muxA_sel, d_muxB_sel, d_jumping, d_rf_wr_en, d_data_rd_wr, d_wb_sel; // (d_wb_sel (0: alu_out, 1: mem_out))
	ALU_OP_TYPE d_ALU_sel;

	// Execute stage
	reg e_rf_wr_en, e_data_rd_wr, e_wb_sel;
	reg [4:0] e_wb_register;
	reg [31:0] e_alu_out, e_mem_data_to_store, e_alu_iA, e_alu_iB;

	// Memory stage
	reg m_rf_wr_en, m_wb_sel;
	reg [4:0] m_wb_register;
	reg [31:0] m_alu_out;

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
			f_pc <= pc_init;
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[0] == 1) begin
			f_instruction_register <= instr_in;
			
			if (d_jumping == 1) begin
				f_pc <= f_pc + rf_rd0_data;
			end else begin
				f_pc <= f_pc + 4;
			end
		end
	end

	always_ff @ (posedge clk)
	begin : DECODE
		if (reset == 1) begin
			// Reset
			d_jumping <= 0;
			d_rf_wr_en <= 0;
			d_data_rd_wr <= 1;
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[1] == 1) begin
			d_pc <= f_pc;
			rf_rd0_num <= f_instruction_register[25:21]; // rs
			rf_rd1_num <= f_instruction_register[20:16]; // rt
			d_signed_extended_offset <= {{16{f_instruction_register[15]}}, f_instruction_register[15:0]};

			case (f_instruction_register[31:25])
				SPECIAL : begin
					case (f_instruction_register[5:0])
						NOP: begin
							d_wb_register <= 'd0;
							d_jumping <= 0;
							d_rf_wr_en <= 0;
							d_data_rd_wr <= 1;
						end
						JR   : begin
							d_wb_register <= 'd0;
							d_jumping <= 1;
							d_rf_wr_en <= 0;
							d_data_rd_wr <= 1;
						end
						ADDU   : begin
							d_ALU_sel <= ADD;
							d_muxA_sel <= 1; // rs
							d_muxB_sel <= 0; // rt
							d_wb_register <= f_instruction_register[15:11]; // rd
							d_jumping <= 0;
							d_rf_wr_en <= 1;
							d_data_rd_wr <= 1;
							d_wb_sel <= 0;
						end
						default: begin
							d_wb_register <= 'd0; // no writeback
							d_jumping <= 0; // no jumping
							d_rf_wr_en <= 0; // no updating reg file
							d_data_rd_wr <= 1; // no write to mem
						end
					endcase
				end
				ADDIU  : begin
					d_ALU_sel <= ADD;
					d_muxA_sel <= 1; // rs
					d_muxB_sel <= 1; // offset
					d_wb_register <= f_instruction_register[20:16]; // rt
					d_jumping <= 0;
					d_rf_wr_en <= 1;
					d_data_rd_wr <= 1;
					d_wb_sel <= 0;
				end
				LW     : begin
					d_ALU_sel <= ADD;
					d_muxA_sel <= 1; // rs
					d_muxB_sel <= 1; // offset
					d_wb_register <= f_instruction_register[20:16]; // rt
					d_jumping <= 0;
					d_rf_wr_en <= 1;
					d_data_rd_wr <= 1;
				end
				SW     : begin
					d_ALU_sel <= ADD;
					d_muxA_sel <= 1; // rs
					d_muxB_sel <= 1; // offset
					d_wb_register <= 'd0; // no writeback
					d_jumping <= 0;
					d_rf_wr_en <= 0;
					d_data_rd_wr <= 0;
					d_wb_sel <= 1;
				end
				default: begin
					d_wb_register <= 'd0; // no writeback
					d_jumping <= 0; // no jumping
					d_rf_wr_en <= 0; // no updating reg file
					d_data_rd_wr <= 1; // no write to mem
				end
			endcase
		end
	end

	always_ff @ (posedge clk)
	begin : EXECUTE
		if (reset == 1) begin
			// Reset
			e_rf_wr_en <= 0;
			e_data_rd_wr <= 1;
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[2] == 1) begin
			e_rf_wr_en <= d_rf_wr_en;
			e_data_rd_wr <= d_data_rd_wr;
			e_wb_sel <= d_wb_sel;
			e_mem_data_to_store <= rf_rd1_data;

			case (d_ALU_sel)
				ADD     : e_alu_out <= e_alu_iA + e_alu_iB;
				default : e_alu_out <= 'd0;
			endcase
		end
	end

	always_ff @ (posedge clk)
	begin : MEMORY
		if (reset == 1) begin
			// Reset
			data_rd_wr <= 1;
		end else if (reset_return_address_register == 1) begin
			
		end else if (stage[3] == 1) begin
			data_rd_wr <= e_data_rd_wr;
			m_rf_wr_en <= e_rf_wr_en;
			m_wb_sel <= e_wb_sel;
			m_wb_register <= e_wb_register;
			m_alu_out <= e_alu_out;
			data_out <= e_mem_data_to_store;
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
			rf_wr_en <= m_rf_wr_en;
			rf_wr_num <= m_wb_register;
			rf_wr_data <= (m_wb_sel == 1) ? data_in : m_alu_out;
		end
	end

	assign instr_addr = f_pc;
	assign e_alu_iA = (d_muxA_sel == 1) ? rf_rd0_data : d_pc;
	assign e_alu_iB = (d_muxB_sel == 1) ? d_signed_extended_offset : rf_rd1_data;
	assign data_addr = m_alu_out;

endmodule
