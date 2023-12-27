`timescale 1ns / 1ps

/// Write data for rd in register file
///
/// The rd_data_sel arguments selects between the inputs:
///
/// 000: main_alu_result,
/// for register-register, register-immediate, and auipc instructions
///
/// 001: data_mem_rdata
/// for load instructions
///
/// 010: csr_rdata
/// for Zicsr instruction
///
/// 011: pc_plus_4
/// for unconditional jump instructions
///
/// 100: { instr[31:12], 12{1'b0} } (from instr input)
/// for lui instruction
///
module register_file_wrapper(
  input 	clk, // for writing
  input 	write_en, // 1 to write data to rd; 0 otherwise
  input [2:0] 	rd_data_sel, // pick what to write to rd	
  input [31:0] 	main_alu_result, // the output from the main ALU
  input [31:0] 	data_mem_rdata, // data output from data memory bus
  input [31:0] 	csr_rdata, // data output from CSR bus
  input [31:0] 	pc_plus_4, // current pc + 4, from pc module
  input [31:0] 	instr, // current instruction
  output [31:0] rs1_data, // read port for rs1
  output [31:0] rs2_data // read port for rs2
    );

   reg [31:0] 	rd_data;
   wire [4:0] 	rs1, rs2, rd; 	
   wire [31:0] 	lui_imm;
   
   assign rs1 = instr[19:15];
   assign rs2 = instr[24:20];
   assign rd = instr[11:7];
   assign lui_imm = { instr[31:12], {12{1'b0}} };
   
   always @* begin
    case(rd_data_sel)
      3'b000: rd_data = main_alu_result;
      3'b001: rd_data = data_mem_rdata;
      3'b010: rd_data = csr_rdata;
      3'b011: rd_data = pc_plus_4;
      3'b100: rd_data = lui_imm;
      default: rd_data = 0;
     endcase
   end
   
   register_file register_file_0(
     .clk(clk),
     .write_en(write_en),
     .rd_data(rd_data),
     .rd(rd),
     .rs1(rs1),
     .rs2(rs2),
     .rs1_data(rs1_data),
     .rs2_data(rs2_data)
     );
   
endmodule
