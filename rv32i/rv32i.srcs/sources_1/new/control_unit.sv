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
   input [31:0]	instr,			      // currently fetched instruction
   
  // Other information/flags from data path
   input	interrupt,		      // is an interrupt pending
   input	data_mem_claim,		      // set if data memory device claims the read/write 
   input	csr_claim,		      // set if CSR device claims the read/write
   input	illegal_instr,		      // data path raised illegal instruction
   input	instr_addr_mis,		      // data path raised instruction address misaligned
   input	instr_access_fault,	      // data path raised instruction access fault

   output	control_lines_t control_lines // Control lines
  );

   // Different instruction classes
   enum 	{
      PRIV, UP_IMM, REG_REG,
      REG_IMM, JUMP, BRANCH,
      LOAD, STORE, CSR
   } instr_type;
   
   always_comb begin
      
      // Set all control signals to default values
      control_lines = 0;
      
      case (instr_type)
	PRIV:;
	UP_IMM: begin
	   // lui and auipc
	   control_lines.register_file_write_en = 1;
	   control_lines.register_file_rd_data_sel = 3'b100;
	end;
	REG_REG:;
	REG_IMM:;
	JUMP:;
	BRANCH:;
	LOAD:;
	STORE:;
	CSR:;
	default
      endcase

   end
   
   // stub implementation
   assign trap = 0;
   assign exception_mcause = 0;
   assign csr_write_en = 0;
   assign trap_ctrl_csr_wdata_sel = 0;
   assign mret = 0;
   
endmodule
