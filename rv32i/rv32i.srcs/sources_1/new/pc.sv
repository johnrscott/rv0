import types::pc_sel_t;

/// Program counter
///
/// The program counter is updated on the rising edge
/// of the clock, and is the main sequential element
/// that controls the rest of the combinational
/// computations in the data path.
///
/// On the rising edge of the clock, pc is set to next_pc.
/// The calculation of next_pc is described below.
///
/// The control signal sel sets the calculation of
/// maybe_next_pc as follows:
///
/// 00: pc + 4
/// 01: mepc
/// 10: 32'hffff_fffe & main_alu_result
/// 11: pc + offset
///
/// The control line trap decides whether maybe_next_pc
/// becomes the next_pc or not:
///
///                       trap
///                        |
/// maybe_next_pc -------- 
///                       MUX ----- next_pc
/// trap_pc --------------
/// 
/// If the maybe_next_pc is not a multiple of 4 when adding
/// offset or using jalr_target (i.e. pc_src 01 or
/// 10), then InstructionAddressMisaligned exception
/// is raised (indicated by instr_addr_mis set). This should
/// cause an external control system to set trap. It is
/// important that the instr_addr_mis signal continues to
/// be asserted even after trap is set, which is why
/// maybe_next_pc is separate from next_pc (this allows 
/// a fully combinational single-cycle design).
///
module pc(
   input	     rstn,
   input	     clk,	      // the clock (pc updates on rising edge)	
   input	     pc_sel_t sel,    // select the next pc for normal program flow
   input [31:0]	     mepc,	      // the pc to use for mret
   input [31:0]	     trap_vector,     // next pc to use on trap
   input [31:0]	     offset,	      // offset to add to the current pc
   input [31:0]	     main_alu_result, // un-masked jalr target PC
   input	     trap,	      // 0 for normal program flow, 1 for trap
   output reg [31:0] pc,	      // the current program counter
   output [31:0]     pc_plus_4,	      // the current program counter + 4
   output	     instr_addr_mis   // flag for instruction address misaligned exception
);

   reg [31:0] maybe_next_pc;  
   
   assign pc_plus_4 = pc + 4;
   assign instr_addr_mis = (maybe_next_pc[1:0] != 2'b00);
   
   always_comb begin
      case (sel)
        types::PC_SEL_PC_PLUS_4: maybe_next_pc = pc_plus_4;
        types::PC_SEL_MEPC: maybe_next_pc = mepc;
        types::PC_SEL_MASK_ALU: maybe_next_pc = 32'hffff_fffe & main_alu_result;
        types::PC_SEL_PC_PLUS_OFFSET: maybe_next_pc = pc + offset;
      endcase
   end
   
   always_ff @(posedge clk) begin
      if (!rstn)
	pc <= 0;
      else
	if(trap)
          pc <= trap_vector;
	else
          pc <= maybe_next_pc;
   end
   
endmodule
