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
   control_bus.control bus
);

   // Different instruction classes
   enum {
      PRIV, UP_IMM, REG_REG,
      REG_IMM, JUMP, BRANCH,
      LOAD, STORE, CSR
   } instr_type;
   
   always_comb begin
      
      // Set all control signals to default values
      bus.reset_control();
      
      case (instr_type)
	PRIV:;
	UP_IMM: begin
	   // lui and auipc
	   bus.register_file_write_en = 1;
	   bus.register_file_rd_data_sel = 3'b100;
	end
	REG_REG:;
	REG_IMM:;
	JUMP:;
	BRANCH:;
	LOAD:;
	STORE:;
	CSR:;
	default:;
      endcase
      
   end
   
endmodule
