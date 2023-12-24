`timescale 1ns / 1ps

/// Selects the signal input for port b of the main ALU
///
/// The sel argument selects between the inputs (sel is in binary):
///  000: rs2_data, for register-register, branch instructions
///  001: imm, for register-immediate, load, store, jal, jalr, 
///  010: rs1_data, for csrrs
///  011: !rs1_data, for csrrc
///  100: { 27'b0, imm[4:0] }, for csrrsi
///  101: { 27'b0, !imm[4:0] }, for csrrci
///
/// The imm argument above needs generating according to whichever
/// instruction is being implemented; different instructions have
/// different formats for the immediate, and need it to be processsed
/// in different ways.
///
module main_alu_b_sel(
	input [2:0] sel, // chooses the output signal
	input [31:0] rs1_data, // the value of rs1 from the register file
	input [31:0] rs2_data, // the value of rs2 from the register file
	input [31:0] imm, // immediate field, already extracted/sign-extended
	output [31:0] b // the main ALU b signal
	);

endmodule
