`timescale 1ns / 1ps

/// Combinational barrel shifter
///
/// Module performing left and right shifts of a 32-bit
/// operand by up to 32 bits. For right shifts, use
/// the right input to choose between arithmetic and
/// logical right shift (i.e. pad high bits with the
/// sign bit vs. pad with zeros).
module shift(
    input [31:0] d, // 32-bit data to shift
    input [4:0] shamt, // left or right shift amount
    input right, // 1 to shift right, 0 to shift left
    input arith, // if right shift, 1 for arithmetic, 0 for logical
    output reg [31:0] shifted // shifted result
    );

    always @* begin
        if (!right) begin // if shift left
            shifted = d << shamt;
        end else if (!arith) begin // if shift right logical
            shifted = d >> shamt;
        end else begin // if arithmetic shift right
            shifted = $signed(d) >>> shamt;
        end
    end
    
endmodule
