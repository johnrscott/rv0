import types::instr_t;

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
module instr_mem #(
   parameter string ROM_FILE
) (
   input [31:0]	pc,		   // current pc
   output	instr_t instr,	   // the instruction at pc
   output	instr_access_fault // raised for out-of-range pc
);
   
   instr_t instr_words[256];

   // Extract word address form program counter (ignoring
   // the low two bits)
   logic [20:0]	word_addr;
   
   assign word_addr = pc[31:2];
   assign instr = instr_words[word_addr];
   
   // Instruction access fault occurs if pc > 'h400
   assign instr_access_fault = (pc[31:11] != 0);
   
   // Load instructions from a file
   initial begin
      instr_words = '{default: '0};
      $display("Loading rom.");
      $readmemh(ROM_FILE, instr_words);
   end
   
endmodule
