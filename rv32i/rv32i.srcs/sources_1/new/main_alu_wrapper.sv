import types::alu_arg_sel_t;
import types::alu_op_t;

/// Main ALU Wrapper Module
///
/// This module routes input operands to the
/// main ALU depending on the instruction
/// being executed.
///
/// The arguments for the ALU are selected
/// by arg_sel as follows:
///
/// 000: rs1_data OP rs2_data
/// for register-register and conditional branch instructions
///
/// 001: rs1_data OP imm
/// for register-immediate, load/store, and jalr instructions
///
/// 010: pc + imm
/// for jal and auipc
///
/// 011: rs1_data OR csr_rdata
/// for csrrs
/// 
/// 100: imm OR csr_rdata
/// for csrrsi
///
/// 101: !rs1_data AND csr_rdata
/// for csrrc
/// 
/// 110: { 27{1'b1}, !imm[4:0] } AND csr_rdata
/// for csrrci
/// 
/// Whenever OP is used above, alu_op is used to
/// select the ALU operation following the comments
/// in the alu module.
///
/// Ensure that the imm input is consistent with the
/// operation being implemented (depending on the
/// instruction format).
///
/// In this design, the lui instruction bypasses the ALU.
module main_alu_wrapper(
   input	 alu_arg_sel_t arg_sel,	// Select the ALU arguments
   input	 alu_op_t alu_op,	// Select the ALU operation (when required)
   input [31:0]	 rs1_data,		// Value of rs1 register
   input [31:0]	 rs2_data,		// Value of rs2 register
   input [31:0]	 imm,			// 32-bit immediate
   input [31:0]	 pc,			// Current program counter
   input [31:0]	 csr_rdata,		// Read-data for CSR bus
   output [31:0] main_alu_result,	// ALU output
   output	 main_alu_zero		// ALU zero flag output
);
   
   bit [31:0] a, b;
   alu_op_t  alu_op_internal;
   
   always_comb begin
      alu_op_internal = alu_op;
      case (arg_sel)
	types::RS1_RS2: begin 
 	   // for register-register and conditional branch instructions
	   a = rs1_data;
	   b = rs2_data;
	end
	types::RS1_IMM: begin
	   // for register-immediate, load/store, and jalr instructions
	   a = rs1_data;
	   b = imm;
	end
	types::PC_IMM: begin
	   // for jal and auipc
	   a = pc;
	   b = imm;
	   alu_op_internal = { 1'b0, types::FUNCT3_ADD };
	end
	types::RS1_CSR: begin
	   // for csrrs
	   a = rs1_data;
	   b = csr_rdata;
	   alu_op_internal = { op_mod:1'b0, op:types::FUNCT3_OR };
	end
	types::IMM_CSR: begin
	   // for csrrsi
	   a = imm;
	   b = csr_rdata;
	   alu_op_internal = { op_mod:1'b0, op:types::FUNCT3_OR };
	end
	types::NOT_RS1_CSR: begin
	   // for csrrc
	   a = ~rs1_data;
	   b = csr_rdata;
	   alu_op_internal = { op_mod:1'b0, op:types::FUNCT3_AND };
	end
	types::NOT_IMM_CSR: begin
	   // for csrrci
	   a = { {27{1'b1}}, ~imm[4:0] };
	   b = csr_rdata;
	   alu_op_internal = { op_mod:1'b0, op:types::FUNCT3_AND };
	end
	default: begin
	   a = 0;
	   b = 0;
	end
      endcase

   end
   
   alu alu(
     .a,
     .b,
     .alu_op(alu_op_internal),
     .r(main_alu_result),
     .zero(main_alu_zero)
     );
   

endmodule
