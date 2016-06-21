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

enum bit [5:0] {
	SPECIAL = 'b000000,
	JAL     = 'b000011,
	BEQ     = 'b000100,
	BNE     = 'b000101,
	ADDIU   = 'b001001,
	SLTI		= 'b001010,
	LW      = 'b100011,
	SW      = 'b101011
} MIPS_OPCODE;

enum bit [5:0] {
	SLL     = 'b000000,
	JR      = 'b001000,
	ADDU    = 'b100001,
	SUBU    = 'b100011
} MIPS_SPECIAL_FUNCT_OPCODE;

enum bit [1:0] {
	ADD,
	SUB,
	SHIFT_LEFT_LOGICAL,
	LESS_THAN
} ALU_OP_TYPE;

module mips #(
	parameter [31:0] pc_init = 0,
	parameter [31:0] sp_init = 0,
	parameter [31:0] ra_init = 0
)(
	input wire clk, reset,
	input wire [31:0] instr_in, data_in,
	output reg data_rd_wr,
	output reg [31:0] data_out, data_addr,
	output wire [31:0] instr_addr
);
	reg [4:0] stage;

	// Fetch signals
	reg [31:0] f_pc, f_instruction_register;

	// Decode signals
	reg [31:0] d_pc, d_signed_extended_offset, d_rd0, d_rd1, d_jal_target;
	reg [4:0] d_wb_register;
	// A (0: pc; 1: rs); B (0: rt; 1: offset)
	reg d_muxA_sel, d_muxB_sel, d_jumping, d_jal, d_branch, d_rf_wr_en, d_data_rd_wr, d_wb_sel; // (d_wb_sel (0: alu_out, 1: mem_out))
	reg [1:0] d_ALU_sel;

	// Execute stage
	reg e_rf_wr_en, e_data_rd_wr, e_wb_sel;
	reg [4:0] e_wb_register;
	reg [31:0] e_alu_out, e_mem_data_to_store, e_alu_iA, e_alu_iB;

	// Memory stage
	reg m_rf_wr_en, m_wb_sel;
	reg [4:0] m_wb_register;
	reg [31:0] m_alu_out;
	reg [31:0] temp_data;

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


	// FETCH
	always_ff @ (posedge clk)
	begin : FETCH_FF
		if (reset == 'b1) begin
			// Reset PC
			f_pc <= pc_init;
		end else if (reset_return_address_register == 'b1) begin

		end else begin
			f_instruction_register <= instr_in;

			if ((stage[2] == 1) && (d_jumping == 1)) begin
				f_pc <= rf_rd0_data;
			end else if ((stage[2] == 1) && (d_jal == 1)) begin
				f_pc <= d_jal_target;
			end else if ((stage[2] == 1) && (d_branch == 1)) begin
				f_pc <= f_pc + d_signed_extended_offset;
			end else if (stage[0] == 1) begin
				f_pc <= f_pc + 'd4;
			end
		end
	end
	assign instr_addr = f_pc;


	// DECODE
	always_comb
	begin : DECODE_COMB
		rf_rd0_num <= f_instruction_register[25:21]; // rs
		rf_rd1_num <= f_instruction_register[20:16]; // rt
		d_jal_target <= {f_pc[31:28], f_instruction_register[25:0], 2'b00};
	end

	always_ff @ (posedge clk)
	begin : DECODE_FF
		if (reset == 1) begin
			// Reset
			d_branch <= 0;
			d_jal <= 0;
			d_jumping <= 0;
			d_rf_wr_en <= 0;
			d_data_rd_wr <= 1;
		end else if (reset_return_address_register == 1) begin

		end else if (stage[1] == 1) begin
			d_pc <= f_pc;

			case (f_instruction_register[31:26])
				SPECIAL : begin
					case (f_instruction_register[5:0])
						SLL: begin
							d_ALU_sel <= SHIFT_LEFT_LOGICAL;
							d_muxA_sel <= 1; // rt
							d_muxB_sel <= 1; // offset
							d_signed_extended_offset <= {27'b0, f_instruction_register[10:6]};
							d_rd0 <= rf_rd1_data; // rt

							d_wb_register <= f_instruction_register[15:11]; // rd
							d_wb_sel <= 0;

							d_branch <= 0;
							d_jal <= 0;
							d_jumping <= 0;
							d_data_rd_wr <= 1;
							d_rf_wr_en <= 1;
						end
						JR   : begin
							d_branch <= 0;
							d_jal <= 0;
							d_jumping <= 1;
							d_data_rd_wr <= 1;
							d_rf_wr_en <= 0;
						end
						ADDU   : begin
							d_ALU_sel <= ADD;
							d_muxA_sel <= 1; // rs
							d_muxB_sel <= 0; // rt
							d_rd0 <= rf_rd0_data; // rs
							d_rd1 <= rf_rd1_data; // rt

							d_wb_register <= f_instruction_register[15:11]; // rt
							d_wb_sel <= 0;

							d_branch <= 0;
							d_jal <= 0;
							d_jumping <= 0;
							d_data_rd_wr <= 1;
							d_rf_wr_en <= 1;
						end
						SUBU   : begin
							d_ALU_sel <= SUB;
							d_muxA_sel <= 1; // rs
							d_muxB_sel <= 0; // rt
							d_rd0 <= rf_rd0_data; // rs
							d_rd1 <= rf_rd1_data; // rt

							d_wb_register <= f_instruction_register[15:11]; // rt
							d_wb_sel <= 0;

							d_branch <= 0;
							d_jal <= 0;
							d_jumping <= 0;
							d_data_rd_wr <= 1;
							d_rf_wr_en <= 1;
						end
						default: begin
							d_branch <= 0; // no branching
							d_jal <= 0; // no jump and link
							d_jumping <= 0; // no jumping
							d_data_rd_wr <= 1; // no write to mem
							d_rf_wr_en <= 0; // no updating reg file
						end
					endcase
				end
				JAL    : begin
					d_ALU_sel <= ADD;
					d_muxA_sel <= 0; // d_pc
					d_muxB_sel <= 1; // offset
					d_signed_extended_offset <= 32'd4;

					d_wb_register <= 'd31; // write to return address regiester
					d_wb_sel <= 0;

					d_branch <= 0;
					d_jal <= 1;
					d_jumping <= 0;
					d_data_rd_wr <= 1;
					d_rf_wr_en <= 1;
				end
				BEQ    : begin
					d_signed_extended_offset <= {{14{f_instruction_register[15]}}, f_instruction_register[15:0], 2'b00};

					d_branch <= rf_rd0_data == rf_rd1_data; // branch if rs == rt
					d_jal <= 0;
					d_jumping <= 0;
					d_data_rd_wr <= 1;
					d_rf_wr_en <= 0;
				end
				BNE    : begin
					d_signed_extended_offset <= {{14{f_instruction_register[15]}}, f_instruction_register[15:0], 2'b00};

					d_branch <= rf_rd0_data != rf_rd1_data; // branch if rs != rt
					d_jal <= 0;
					d_jumping <= 0;
					d_data_rd_wr <= 1;
					d_rf_wr_en <= 0;
				end
				ADDIU  : begin
					d_ALU_sel <= ADD;
					d_muxA_sel <= 1; // rs
					d_muxB_sel <= 1; // offset
					d_signed_extended_offset <= {{16{f_instruction_register[15]}}, f_instruction_register[15:0]};
					d_rd0 <= rf_rd0_data; // rs

					d_wb_register <= f_instruction_register[20:16]; // rt
					d_wb_sel <= 0;

					d_branch <= 0;
					d_jal <= 0;
					d_jumping <= 0;
					d_data_rd_wr <= 1;
					d_rf_wr_en <= 1;
				end
				SLTI   : begin
					d_ALU_sel <= LESS_THAN;
					d_muxA_sel <= 1; // rs
					d_muxB_sel <= 1; // offset
					d_signed_extended_offset <= {{16{f_instruction_register[15]}}, f_instruction_register[15:0]};
					d_rd0 <= rf_rd0_data; // rs

					d_wb_register <= f_instruction_register[20:16]; // rt
					d_wb_sel <= 0;

					d_branch <= 0;
					d_jal <= 0;
					d_jumping <= 0;
					d_data_rd_wr <= 1;
					d_rf_wr_en <= 1;
				end
				LW     : begin
					d_ALU_sel <= ADD;
					d_muxA_sel <= 1; // rs
					d_muxB_sel <= 1; // offset
					d_signed_extended_offset <= {{16{f_instruction_register[15]}}, f_instruction_register[15:0]};
					d_rd0 <= rf_rd0_data; // rs

					d_wb_register <= f_instruction_register[20:16]; // rt
					d_wb_sel <= 1;

					d_branch <= 0;
					d_jal <= 0;
					d_jumping <= 0;
					d_data_rd_wr <= 1;
					d_rf_wr_en <= 1;
				end
				SW     : begin
					d_ALU_sel <= ADD;
					d_muxA_sel <= 1; // rs
					d_muxB_sel <= 1; // offset
					d_signed_extended_offset <= {{16{f_instruction_register[15]}}, f_instruction_register[15:0]};
					d_rd0 <= rf_rd0_data; // rs
					d_rd1 <= rf_rd1_data; // rt

					d_branch <= 0;
					d_jal <= 0;
					d_jumping <= 0;
					d_data_rd_wr <= 0;
					d_rf_wr_en <= 0;
				end
				default: begin
					d_branch <= 0; // no branching
					d_jal <= 0; // no jump and linking
					d_jumping <= 0; // no jumping
					d_data_rd_wr <= 1; // no write to mem
					d_rf_wr_en <= 0; // no updating reg file
				end
			endcase
		end
	end


	// EXECUTE
	always_comb
	begin : EXECUTE_COMB
		e_alu_iA <= (d_muxA_sel == 1) ? d_rd0 : d_pc;
		e_alu_iB <= (d_muxB_sel == 1) ? d_signed_extended_offset : d_rd1;
	end

	always_ff @ (posedge clk)
	begin : EXECUTE_FF
		if (reset == 1) begin
			// Reset
			e_rf_wr_en <= 0;
			e_data_rd_wr <= 1;
		end else if (reset_return_address_register == 1) begin

		end else if (stage[2] == 1) begin
			e_rf_wr_en <= d_rf_wr_en;
			e_data_rd_wr <= d_data_rd_wr;
			e_wb_sel <= d_wb_sel;
			e_mem_data_to_store <= d_rd1;
			e_wb_register <= d_wb_register;

			case (d_ALU_sel)
				ADD                 : e_alu_out <= e_alu_iA + e_alu_iB;
				SUB                 : e_alu_out <= e_alu_iA - e_alu_iB;
				SHIFT_LEFT_LOGICAL  : e_alu_out <= e_alu_iA << e_alu_iB;
				LESS_THAN           : e_alu_out <= e_alu_iA < e_alu_iB;
				default             : e_alu_out <= 'd0;
			endcase
		end
	end


	// MEMORY
	always_comb
	begin : MEMORY_COMB
		data_addr <= e_alu_out;
		data_out <= e_mem_data_to_store;

		if (reset == 1) begin
			// Reset
			data_rd_wr <= 1;
		end else if (reset_return_address_register == 1) begin
			data_rd_wr <= 1;
		end else begin
			data_rd_wr <= e_data_rd_wr;
		end
	end

	always_ff @ (posedge clk)
	begin : MEMORY_FF
		if (reset == 1) begin
			// RESET
			m_rf_wr_en <= 0;
		end else if (reset_return_address_register == 1) begin

		end else if (stage[3] == 1) begin
			m_alu_out <= e_alu_out;
			m_wb_sel <= e_wb_sel;
			m_rf_wr_en <= e_rf_wr_en;
			m_wb_register <= e_wb_register;
		end
	end


	// WRITEBACK
	always_comb
	begin : WRITEBACK_COMB
		rf_wr_en <= reset | reset_return_address_register | (m_rf_wr_en & stage[4]);

		if (reset == 1) begin
			rf_wr_num <= 'd29;
			rf_wr_data <= sp_init;
		end else if (reset_return_address_register == 1) begin
			rf_wr_num <= 'd31;
			rf_wr_data <= ra_init;
		end else begin
			rf_wr_num <= m_wb_register;
			rf_wr_data <= (m_wb_sel == 1) ? data_in : m_alu_out;
		end
	end

endmodule
