`timescale 1ns / 1ps

/// Immediate generation for ALU operand b
///
/// Generate a 32-bit immediate for use in calculations
/// with the ALU. This includes register-immediates,
/// upper-immediates, loads, and stores, but does not
/// include any control flow instructions (which use
/// a dedicated ALU for adding to the program counter).
/// The sel input is used to pick the output immediate
/// as follows:
///
/// 000: { 20{instr[31]}, instr[31:20] }
/// for register-immediates, loads, stores, jalr
///
/// 001: { 27'b0, instr[24:20] }
/// for register-immediate shift instructions
///
/// 010: { instr[31:12], 12'b0 }
/// for upper-immediate instructions
///
/// 011: { 12{instr[31]}, instr[19:12], instr[20], instr[30:21], 1'b0 }
/// for jal instruction
///
/// 100: { 27'b0, instr[19:15] }
/// uimm, for CSR instructions
///
module main_alu_b_imm_sel(
       input [2:0] sel, // pick immediate calculation
       input [31:0] instr, // fetched instruction
       output [31:0] imm // output 32-bit immediate for calculation
       );

endmodule
