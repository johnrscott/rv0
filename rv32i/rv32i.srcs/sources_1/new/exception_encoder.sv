/// Converts exception bits into mcause values
module exception_encoder(
  input  instr_addr_mis, // instruction address misaligned, mcause 0
  input  instr_access_fault, // instruction access fault, mcause 1
  input  illegal_instr, // illegal instruction, mcause 2
  input  breakpoint, // breakpoint (from ebreak), mcause 3
  // load address misaligned unused in this design
  input  load_access_fault, // load access fault, mcause 5
  // store address misaligned unused in this design
  input  store_access_fault, // store access fault, mcause 7
  input  ecall_mmode, // ecall from M-mode, mcause 11
  output exception, // set on any exception
  output mcause, // what exception was raised
  );

endmodule
