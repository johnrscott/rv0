`timescale 1ns / 1ps

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
  input [2:0]	    sel, // Set immediate to extract
  input [31:0] 	    instr, // Current instruction
  output reg [31:0] imm // Output 32-bit immediate
  );

   always @* begin
      case(sel)
	   3'b000: imm = { {21{instr[31]}}, instr[30:20] };
	   3'b001: imm = { {21{instr[31]}}, {instr[30:25]}, instr[11:7] };
	   3'b010: imm = { {20{instr[31]}}, instr[7],
	       instr[30:25], instr[11:8], 1'b0 };
	   3'b011: imm = { instr[31:12], {12{1'b0}} };
	   3'b100: imm = { {12{instr[31]}}, instr[19:12],
	       instr[20], instr[30:21], 1'b0 };
	   3'b101: imm = { {27{1'b0}}, instr[24:20]};
	   default: imm = 0;
      endcase // case (sel)
   end

endmodule
