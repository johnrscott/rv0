/// CPU Control Unit
///
/// The control unit is a purely combinational
/// module which decodes the currently fetched
/// instruction and sets control lines for the
/// data path.
///
/// If a computation in the data path causes an
/// exception, the data path will raise a flag
/// indicating the exception. The control unit will
/// then modify the control lines to transfer
/// control to an interrupt vector.
///
/// If an interrupt is pending, the data path will
/// set an interrupt flag. This will cause the
/// control unit to set control lines to transfer
/// control to an interrupt vector.
///
///
module control_unit(
  input [31:0] 	instr, // currently fetched instruction

  // Other information/flags from data path
  input 	interrupt, // is an interrupt pending
  input 	data_mem_claim, // set if data memory device claims the read/write 
  input 	csr_claim, // set if CSR device claims the read/write
  input 	illegal_instr, // data path raised illegal instruction
  input 	instr_addr_mis, // data path raised instruction address misaligned
  input 	instr_access_fault, // data path raised instruction access fault

  // Control lines  
  output 	mret, // whether the data path should execute an mret
  output [2:0] 	imm_gen_sel, // select which immediate format to extract
  output [2:0] 	alu_arg_sel, // pick the ALU operation
  output [1:0] 	data_mem_width, // pick the load/store access width
  output [1:0] 	pc_sel, // choose how to calculate the next program counter
  output [1:0] 	trap_ctrl_csr_wdata_sel, // pick write data source for CSR bus
  output 	register_file_write_en, // whether to write to rd
  output [2:0] 	register_file_rd_data_sel, // select source for write to rd
  output 	data_mem_write_en, // whether to write to data memory bus
  output 	csr_write_en, // whether to write to CSR bus
  output 	trap, // whether to execute an (interrupt or exception) trap
  output [31:0] exception_mcause // for an exception, what is the mcause value
  );

   // stub implementation
   assign trap = 0;
   assign exception_mcause = 0;
   assign csr_write_en = 0;
   assign trap_ctrl_csr_wdata_sel = 0;
   assign mret = 0;
   
endmodule
