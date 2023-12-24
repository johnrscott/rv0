`timescale 1ns / 1ps

/// Selects the signal input for port a of the main ALU
///
/// The sel argument selects between the inputs (sel is in binary):
///  00: rs1_data, for register-register, register-immediate,
///  branch, load, store instructions
///  01: pc, for auipc and jal instructions
///  10: 0, for lui
///  11: csr_rdata, for CSR instructions 
///
module main_alu_a_sel(
	input [1:0] sel, // chooses the output signal
	input [31:0] rs1_data, // the value of rs1 from the register file
	input [31:0] pc, // for current program counter
	input [31:0] csr_rdata, // CSR-bus read data
	output [31:0] a // the main ALU a signal
	);
	
endmodule
