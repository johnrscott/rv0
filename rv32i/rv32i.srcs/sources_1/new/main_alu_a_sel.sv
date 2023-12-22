`timescale 1ns / 1ps

/// Selects the signal input for port a of the main ALU
///
/// The sel argument selects between the inputs (sel is in binary):
///  000: rs1_data, for register-register, register-immediate,
///  branch, load, store instructions
///  001: pc, for auipc and jal instructions
///  010: 0, for lui
///  011: !rs1_data, for use in CSR instructions
///  100: uimm, for use in CSR instructions
///  101: !uimm, for use in CSR instructions
///
/// When uimm is negated, the negation happens _before_ the 
/// sign-extension to 32-bits.
///
module main_alu_a_sel(
	input [2:0] sel, // chooses the output signal
	input [31:0] rs1_data, // the value of rs1 from the register file
	input [31:0] pc, // for current program counter
	input [4:0] uimm, // uimm field from CSR instructions
	output a // the main ALU a signal
	);
	
endmodule