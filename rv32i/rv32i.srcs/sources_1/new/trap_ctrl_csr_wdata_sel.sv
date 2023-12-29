`timescale 1ns / 1ps

/// Trap controller CSR write data source selection
///
/// Depending on the value of sel, the CSR write data
/// source is chosen as follows:
/// 00: rs1_data, for csrrw
/// 01: main_alu_r, for csrrs, csrrc, csrrsi, csrrci
/// 10: { 27'b0, uimm }, for csrrwi
///
module trap_ctrl_csr_wdata_sel(
       input [1:0] sel,
       input [31:0] rs1_data,
       input [31:0] main_alu_r,
       input [4:0] uimm,
       output [31:0] csr_wdata
       );

   // stub implementation
   assign csr_wdata = 0;
   
endmodule
