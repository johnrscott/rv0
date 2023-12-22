/// Write data for rd in register file
///
/// The sel arguments selects between the inputs (sel is in binary):
///  00: main_alu_r, for register-register, register-immediate, 
///  and lui/auipc instructions
///  01: for load instructions
///  10: csr_bus_out, for all CSR instructions
///  11: pc + 4, for jal/jalr instructions
///
module register_file_rd_data_sel(
  input [1:0]  sel, // choose the output signal
  input [31:0] main_alu_r, // the output from the main ALU
  input [31:0] data_mem_rdata, // data output from data memory bus
  input [31:0] csr_rdata, // data output from CSR bus
  input [31:0] pc_plus_4, // current pc + 4, from next_pc_sel
  output       rd_data // output data for writing to register rd
  );
