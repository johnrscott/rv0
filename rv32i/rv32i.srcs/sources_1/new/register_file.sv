`timescale 1ns / 1ps

// 32-bit Register file
//
// There are 32 32-bit registers x0-x31, with x0 hardwired
// to zero. This module provides two combinational output
// ports, controlled by the two addresses rna and rnb, and
// a single registered write (on the rising edge of the clock
// when the write enable signal is asserted).
//
// There is no reset; on power-on, the register values are 
// set to zero.
//
module register_file(
    input [31:0] d, // data for write
    input [4:0] rna, // source register index A
    input [4:0] rnb, // source register index B
    input [4:0] wn, // destination register index for write
    input we, // write enable
    input clk, // clock
    output [31:0] qa, // read port A
    output [31:0] qb // read port B
    );
    
    reg [31:0] register [1:31] = '{default: '0}; // 31 32-bit registers
    assign qa = (rna == 0)? 0 : register[rna];
    assign qb = (rnb == 0)? 0 : register[rnb];
    
    always @(posedge clk) begin
        if ((wn != 0) && we) // not x0 and write is enabled
            register[wn] <= d; // write d to reg[wn]
    end
endmodule
