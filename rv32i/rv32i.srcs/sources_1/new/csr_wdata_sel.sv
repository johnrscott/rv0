import types::csr_wdata_sel_t;

/// CSR write data source selection
///
/// Depending on the value of sel, the CSR write data
/// source is chosen as follows:
/// 
/// 00: rs1_data, for csrrw
/// 01: main_alu_result, for csrrs, csrrc, csrrsi, csrrci
/// 10: imm, for csrrwi
///
module csr_wdata_sel(
       input csr_wdata_sel_t sel,
       input [31:0] rs1_data, // from the register file
       input [31:0] main_alu_result, // from the main ALU
       input [31:0] imm, // uimm, from immediate generator
       output [31:0] csr_wdata // to the CSR bus
       );
   
   // stub implementation
   assign csr_wdata = 0;
   
endmodule
