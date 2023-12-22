`timescale 1ns / 1ps

/// 32-bit Register file
///
/// There are 32 32-bit registers x0-x31, with x0 hardwired
/// to zero. This module provides two combinational output
/// ports, controlled by the two addresses rs1 and src, and
/// a single registered write (on the rising edge of the clock
/// when the write enable signal is asserted).
///
/// There is no reset; on power-on, the register values are 
/// set to zero.
///
module register_file(
    input clk, // clock
    input write_en, // write enable
	input [31:0] rd_data, // data for write
    input [4:0] rs1, // source register index A
    input [4:0] rs2, // source register index B
    input [4:0] rd, // destination register index for write
    output [31:0] rs1_data, // read port A
    output [31:0] rs2_data // read port B
    );
    
    reg [31:0] register [1:31] = '{default: '0}; // 31 32-bit registers
    assign rs1_data = (rs1 == 0)? 0 : register[rs1];
    assign rs2_data = (rs2 == 0)? 0 : register[rs2];
    
    always @(posedge clk) begin
        if ((rd != 0) && write_en) // not x0 and write is enabled
            register[rd] <= rd_data; // write data to rd
    end
endmodule
