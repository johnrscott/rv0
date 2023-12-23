`timescale 1ns / 1ps

/// Program counter
///
/// The program counter is updated on the rising edge
/// of the clock, and is the main sequential element
/// that controls the rest of the combinational
/// computations in the data path.
///
/// On the rising edge of the clock, pc is set to next_pc.
/// The calculation of next_pc is described below.
///
/// The control signal sel sets the calculation of
/// maybe_next_pc as follows:
///
/// 00: pc + 4
/// 01: mepc
/// 10: 32'hffff_fffe & main_alu_r
/// 11: pc + offset
///
/// The control line trap decides whether maybe_next_pc
/// becomes the next_pc or not:
///
///                       trap
///                        |
/// maybe_next_pc -------- 
///                       MUX ----- next_pc
/// trap_pc --------------
///
/// where trap_pc = exception_vector + interrupt_offset
/// 
/// If the maybe_next_pc is not a multiple of 4 when adding
/// offset or using jalr_target (i.e. pc_src 01 or
/// 10), then InstructionAddressMisaligned exception
/// is raised (indicated by instr_addr_mis set). This should
/// cause an external control system to set trap. It is
/// important that the instr_addr_mis signal continues to
/// be asserted even after trap is set, which is why
/// maybe_next_pc is separate from next_pc (this allows 
/// a fully combinational single-cycle design).
///
module pc(
    input clk, // the clock (pc updates on rising edge)	
	input [1:0] sel, // select the next pc for normal program flow
	input [31:0] mepc, // the pc to use for mret
	input [31:0] exception_vector, // from mtvec
	input [31:0] interrupt_offset, // 0 for exception; for interrupt, specify byte offset to trap vector
	input [31:0] offset, // offset to add to the current pc
	input [31:0] main_alu_r, // un-masked jalr target PC
	input trap, // 0 for normal program flow, 1 for trap
	output [31:0] pc, // the current program counter
	output [31:0] pc_plus_4, // the current program counter + 4
	output instr_addr_mis // flag for instruction address misaligned exception
	);

endmodule
