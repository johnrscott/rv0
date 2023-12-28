`timescale 1ns / 1ps

/// Trap control (interrupts and exceptions)
///
/// This module holds the following status of the core:
///
/// mie: global interrupt enable bit in mstatus
/// mpie: previous mie in mstatus
/// msie, mtie, meie: software, timer and external 
/// interrupt enable bits in mie
/// msip, mtip, meip: software, timer and external
/// interrupt pending bits in mip
///
/// It holds the following memory-mapped registers
/// related to interrupt control:
///
/// mtime: 64-bit real-time register
/// mtimecmp: defines the trigger for a timer 
/// interrupt in relation to mtime
/// msip: register containing the software read/writable
/// msip bit
///
/// It manages/exposes the following control and status
/// registers:
///
/// mstatus: contains the mie, mpie and mpp bits
/// mepc: return address after trap
/// mcause: the cause of the trap
/// mtvec: defines the location and type of trap
/// handler vectors (this is hardcoded in this design)
///
/// In normal instruction execution, mtime is incremented
/// on the rising clock edge.
///
/// On Interrupts
/// ~~~~~~~~~~~~~
///
/// Interrupts are checked at the beginning of each 
/// execution cycle, "logically" before instruction
/// execution begins (therefore interrupts take priority
/// over exceptions). An interrupt trap occurs if:
///
/// 1) interrupts are globally enabled (mie set in mstatus)
/// AND
/// 2) external interrupt is enabled and pending (meie and meip)
/// OR software interrupt is enabled and pending (msie and msip)
/// OR timer interrupt is enabled and pending (mtie and mtip)
///
/// Interrupts in 2) are checked in the order given, and the
/// first enabled and pending interrupt is the one that traps.
///
/// The mcause register is set to (0x8000_0000 | code), where
/// code is 3 for software interrupt, 7 for timer interrupt,
/// or 11 for external interrupt. The interrupt_offset is set
/// to (code << 2). 
///
/// On Exceptions
/// ~~~~~~~~~~~~~
///
/// An exception is raised "mid" instruction (in the single-cycle
/// design, this means some combinational element will raise an
/// exception bit for the currently fetched instruction and core
/// state). All these bits are fed into an exception encoder,
/// which produces an exception bit and the mcause values.
/// These are used as input to this module.
///
/// As a result, an exception trap will occur. The mcause
/// register is set to the value of the mcause input. The
/// interrupt_offset is set to 0.
///
/// On Any Trap
/// ~~~~~~~~~~~~
/// 
/// On any trap (interrupts or exceptions), the mie bit is
/// copied to mpie in mstatus, and the mie bit is set to zero.
/// The exception_vector is set to the base address stored in
/// mtvec (this is hard-coded in this design). The current
/// program counter is copied to mepc
///
/// Any other instruction that may have executed on this clock
/// cycle must be disabled. This is achieved by disabling any
/// action that would change the core's state. This is the write
/// enable for the register file, the memory, and the CSR bus.
/// The design can use the trap ouptut to determine whether to
/// do this.
///
/// On Return From Trap
/// ~~~~~~~~~~~~~~~~~~~
///
/// If a return from trap is requested by setting the mret
/// input, then the mstatus mpie bit is copied to mie, and
/// the mpie bit is set to 1. (The mepc output is to be used by 
/// the next_pc_sel multiplexer to set the return address.)
///
module trap_ctrl(
       	input 	      clk, // clock for updating registers
	
	input 	      meip, // external interrupt source (from PLIC)
	input 	      mret, // set to perform a return from trap
	input 	      trap, // has a trap occurred 
	input [31:0]  exception_mcause, // the cause of the exception
	input [31:0]  pc, // used for setting mepc on exception
	
	output 	      interrupt, // set if an interrupt is detected
	output [31:0] mepc, // exception pc for use by next_pc_sel
	output [31:0] exception_vector, // for use by next_pc_set
	output [31:0] interrupt_offset, // for use by next_pc_set

	// Data memory read/write port
	input [31:0]  data_mem_addr, // the read/write address bus 
	input [1:0]   data_mem_width, /// the width of the read/write
	input [31:0]  data_mem_wdata, // data to be written on rising clock edge
	input 	      data_mem_write_en, // 1 to perform write, 0 otherwise
	output [31:0] data_mem_rdata, // data out	
	output 	      data_mem_claim, // set if this module claims the data memory access
	
	// CSR bus read/write port
	input [11:0]  csr_addr, // CSR address. Used to claim a CSR read/write.
	input [31:0]  csr_wdata, // data to write to the CSR
	input 	      csr_write_en, // 1 to write on rising clock edge
	output [31:0] csr_rdata, // CSR read data
	output 	      csr_claim, // 1 if this module owns the CSR addr
	output 	      illegal_instr // 1 if illegal instruction should be raised
	);

endmodule
