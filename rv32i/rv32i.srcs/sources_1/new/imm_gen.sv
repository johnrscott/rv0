import types::instr_t;
import types::instr_format_t;

/// Extract an immediate encoded in the instruction
///
/// Each RV32I or Zicsr instruction contains at most
/// one immediate, which is extracted and converted to
/// a 32-bit format by this module. For Zicsr instructions,
/// the uimm field is also zero-extended to 32 bits, and
/// output using the same imm output.
///
/// The reference for how immediates are decoded is
/// v1_f2.4. The sel input picks the output as follows:
///
/// 000: { 21{instr[31]}, instr[30:20] }, I-type
/// 001: { 21{instr[31]}, {instr[30:25]}, instr[11:7] }, S-type
/// 010: { 20{instr[31]}, instr[7], instr[30:25], instr[11:8], 1'b0 }, B-type
/// 011: { instr[31:12], 12{1'b0} }, U-type
/// 100: { 12{instr[31]}, instr[19:12], instr[20], instr[30:21], 1'b0 }, J-type
///
/// 101: { 27{1'b0}, instr[24:20] }, Zicsr
///
module imm_gen(
   input	     instr_format_t sel, // Set immediate to extract
   input	     instr_t instr,	 // Current instruction
   output bit [31:0] imm		 // Output 32-bit immediate
);

   always_comb begin
      case (sel)
	types::I_TYPE:
	  imm = signed'(instr.i_type.imm11_0);
	types::S_TYPE:
	  imm = signed'({ 
	     instr.s_type.imm11_5,
	     instr.s_type.imm4_0
	     });
	types::B_TYPE:
	  imm = signed'({
	     instr.b_type.imm12,
	     instr.b_type.imm11,
	     instr.b_type.imm10_5,
	     instr.b_type.imm4_1,
	     1'b0
	     });
	types::U_TYPE:
	  imm = instr.u_type.imm31_12 << 12;
	types::J_TYPE:
	  imm = signed'({
	     instr.j_type.imm19_12,
	     instr.j_type.imm11,
	     instr.j_type.imm10_1,
	     1'b0
	     });
	types::CSR_I_TYPE:
	  imm = instr.csr_i_type.uimm; // zero-extended
	default: imm = 0;
      endcase
   end
   
endmodule
