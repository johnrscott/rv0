/// Extract and sign-extend the offset field from B-type
/// instructions:
///
/// offset = { 20{instr[12]}, instr[7], instr[30:25], instr[11:8], 1'b0 }
module branch_offset_imm_gen(
  input [31:0] 	instr,
  output [31:0] offset
  );
   
endmodule
