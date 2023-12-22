`timescale 1ns / 1ps


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
    input [31:0] a, // First 32-bit operand
    input [31:0] b, // Second 32-bit operand
    input [3:0] alu_op, // ALU control signals (see comments above)
    output reg [31:0] r, // 32-bit result
    output zero // 1 if r is zero, 0 otherwise
    );    
    assign zero = ~|r;
    
    wire [31:0] r_shift;
    wire right_shift;
    wire arith_right_shift;
    wire [4:0] shamt;
    assign right_shift = (alu_op[2:0] == 3'b101);
    assign arith_right_shift = (alu_op[3] == 1);
    assign shamt = b[4:0];
    
    shift shift_0(
        .d(a), // a is the operand to be shifted
        .shamt(shamt), // b is the shift amount
        .right(right_shift),
        .arith(arith_right_shift),
        .shifted(r_shift) // shifted result
    );
    
    /// Note: this uses combinational arithmetic which is not
    /// recommended by Xilinx for optimal use of DSP blocks.
    /// To fix.
    always @* begin
        case (alu_op[2:0])
            3'b000: r = alu_op[3] ? a - b : a + b;
            3'b001, 3'b101: r = r_shift;
            3'b010: r = a < b ? 1 : 0;
            3'b011: r = $signed(a) < $signed(b) ? 1 : 0;
            3'b100: r = a ^ b;
            3'b110: r = a | b;
            3'b111: r = a & b;
        endcase
    end
    
endmodule
