import types::rd_data_sel_t;
import types::instr_t;

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
   input	 rstn,
   input	 clk,			    // for writing
   input	 write_en,		    // 1 to write data to rd; 0 otherwise
   input	 rd_data_sel_t rd_data_sel, // pick what to write to rd	
   input [31:0]	 main_alu_result,	    // the output from the main ALU
   input [31:0]	 data_mem_rdata,	    // data output from data memory bus
   input [31:0]	 csr_rdata,		    // data output from CSR bus
   input [31:0]	 pc_plus_4,		    // current pc + 4, from pc module
   input	 instr_t instr,		    // current instruction
   input [31:0]	 lui_imm,		    // Immediate to store in rd
   output [31:0] rs1_data,		    // read port for rs1
   output [31:0] rs2_data		    // read port for rs2
);

   bit [31:0] 	rd_data;
   
   register_file register_file_0(
      .rstn,
      .clk,
      .write_en,
      .rd_data,
      .rs1_data,
      .rs2_data,
      .rd(instr.r_type.rd),
      .rs1(instr.r_type.rs1),
      .rs2(instr.r_type.rs2)
   );
   
   always_comb begin
      case (rd_data_sel)
	types::MAIN_ALU_RESULT: rd_data = main_alu_result;
	types::DATA_MEM_RDATA: rd_data = data_mem_rdata;
	types::CSR_RDATA: rd_data = csr_rdata;
	types::PC_PLUS_4: rd_data = pc_plus_4;
	types::LUI_IMM: rd_data = lui_imm;
	default: rd_data = 0;
      endcase
   end
      
endmodule
