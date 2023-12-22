/// Fetch an instruction from program memory
///
/// The instruction memory is preloaded with instructions at
/// synthesis time in this design. It is combinational, so the
/// output changes directly with the input pc. No checking is
/// performed for pc 4-byte alignment (the lower 2 bits of pc
/// are just ignored).
///
/// An InstructionAccessFault exception is raised if the pc is 
/// out of range for the valid program memory addresses. In 
/// this design, the program memory is 1024 bytes, so that
/// occurs if pc > 1020. If the exception is raised, the instr
/// output has an unspecified value.
///
module instr_mem(
  input [31:0] 	pc, // current pc
  output [31:0] instr, // the instruction at pc
  output 	instr_access_fault // flag for instruction access fault exception
  );
   
