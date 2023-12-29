`timescale 1ns / 1ps

/// Fetch an instruction from program memory
///
/// The instruction memory is preloaded with instructions at
/// synthesis time in this design. It is combinational, so the
/// output changes directly with the input pc. No checking is
/// performed for pc 4-byte alignment (the lower 2 bits of pc
/// are just ignored).
/// 
/// The instruction region is from 0000_0000 to 0000_0400. 
///
/// An InstructionAccessFault exception is raised if the pc is 
/// out of range for the valid program memory addresses.
///
module instr_mem
  #(parameter string ROM_FILE)
   (
  input [31:0] 	pc, // current pc
  output [31:0] instr, // the instruction at pc
  output 	instr_access_fault // raised for out-of-range pc
		     );
   
   logic [31:0] instr_words[256];

   // Load instructions from a file
   initial begin
      instr_words = '{default: '0};
      $display("Loading rom.");
      $readmemh(ROM_FILE, instr_words);
   end
   
   // Extract word address form program counter (ignoring
   // the low two bits)
   logic 	word_addr = pc[2+:8];

   assign instr = instr_words[word_addr];
   
   // Instruction access fault occurs if pc > 'h400
   assign instr_access_fault = (pc[31:11] != 0);
   
endmodule
