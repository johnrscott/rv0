import types::alu_op_t;

/// Arithmetic Control Unit
///
/// This is a purely combinational ALU implementation.
///
/// The operation depends on the 4-bit alu_op as
/// follows: 
///
/// 0_000: r = a + b
/// 1_000: r = a - b
/// 0_001: r = a << b
/// x_010: r = a < b ? 1 : 0
/// x_011: r = signed(a) < signed(b) ? 1 : 0
/// x_100: r = a ^ b
/// 0_101: r = a >> b
/// 1_101: r = signed(a) >>> signed(b)
/// x_110: r = a | b
/// x_111: r = a & b
///
/// The separation in alu_op indicates that the top bit
/// comes form bit 30 of the instruction, and the bottom
/// 3 bits come from funct3, in R-type register-register
/// instructions.
///
/// For I-type register-immediate instructions, ensure
/// that the top bit is 0 for addi, slti, sltiu, xori
/// ori, and andi. For slli, srli, and srai, set the top
/// bit to bit 30 of the instruction, and set b to the
/// shift amount (shamt) field. Set the low three
/// bits to funct3 in all cases.
///
module alu(
   input [31:0]	     a,		      // First 32-bit operand
   input [31:0]	     b,		      // Second 32-bit operand
   input	     alu_op_t alu_op, // ALU control signals (see comments above)
   output bit [31:0] r,		      // 32-bit result
   output	     zero	      // 1 if r is zero, 0 otherwise
);    
   
   wire [31:0] r_shift;
   wire	       right;
   wire	       arith;
   wire [4:0]  shamt;
   
   assign right = (alu_op.op == types::FUNCT3_SRL);
   assign arith = (alu_op.op_mod == 1);
   assign shamt = b[4:0];
   assign zero = ~|r;
   
   shift shift_0(
      .d(a), // a is the operand to be shifted
      .shamt, // b is the shift amount
      .right,
      .arith,
      .shifted(r_shift) // shifted result
   );
   
   /// Note: this uses combinational arithmetic which is not
   /// recommended by Xilinx for optimal use of DSP blocks.
   /// To fix in next iteration of design.
   always_comb begin
      case (alu_op.op)
        types::FUNCT3_ADD: r = alu_op.op_mod ? a - b : a + b;
        types::FUNCT3_SLL, types::FUNCT3_SRL: r = r_shift;
        types::FUNCT3_SLTU: r = a < b ? 1 : 0;
        types::FUNCT3_SLT: r = $signed(a) < $signed(b) ? 1 : 0;
        types::FUNCT3_XOR: r = a ^ b;
        types::FUNCT3_OR: r = a | b;
        types::FUNCT3_AND: r = a & b;
      endcase
   end
   
endmodule
