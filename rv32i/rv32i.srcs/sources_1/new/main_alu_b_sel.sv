/// Selects the signal input for port b of the main ALU
///
/// The sel argument selects between the inputs (sel is in binary):
///  00: rs2_data, for register-register, branch instructions
///  01: imm, for register-immediate, load, store, jal, jalr, 
///  10: csr_read_data, for CSR instructions 
///
/// The imm argument above needs generating according to whichever
/// instruction is being implemented; different instructions have
/// different formats for the immediate, and need it to be processsed
/// in different ways. The imm argument will be passed straight
/// through to b unprocessed.
module main_alu_b_sel(
  input [1:0]  sel, // chooses the output signal
  input [31:0] rs2_data, // the value of rs2 from the register file
  input [31:0] imm, // immediate field, already extracted/sign-extended
  output       b // the main ALU b signal
  );

endmodule
