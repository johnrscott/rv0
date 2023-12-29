`define ROM_MEM_FILE "rom_image.mem"

module cpu #(
  parameter string ROM_FILE = "rom_image.mem")
   (
  input clk, meip
		   );
   
   logic [31:0] instr;
   
   logic 	data_mem_claim, csr_claim, data_path_illegal_instr,
		instr_addr_mis, instr_access_fault, mret,
		register_file_write_en, dtaa_mem_write_en, csr_write_en;
   
   logic [1:0] 	data_mem_width, pc_sel,
		trap_ctrl_csr_wdata_sel;
   
   logic [2:0] 	imm_gen_sel, alu_arg_sel, register_file_rd_data_sel;

   logic [31:0] exception_mcause;

   control_unit control_unit_0(
     .instr(instr),
     .data_mem_claim(data_mem_claim),
     .csr_claim(csr_claim),
     .illegal_instr(data_path_illegal_instr),
     .instr_addr_mis(instr_addr_mis),
     .instr_access_fault(instr_access_fault),
     .mret(mret),
     .imm_gen_sel(imm_gen_sel),
     .alu_arg_sel(alu_arg_sel),
     .data_mem_width(data_mem_width),
     .pc_sel(pc_sel),
     .trap_ctrl_csr_wdata_sel(trap_ctrl_csr_wdata_sel),
     .register_file_write_en(register_file_write_en),
     .register_file_rd_data_sel(register_file_rd_data_sel),
     .data_mem_write_en(data_mem_write_en),
     .csr_write_en(csr_write_en),
     .trap(trap),
     .exception_mcause(exception_mcause),
     .interrupt(interrupt)
     );

   data_path #(.ROM_FILE(ROM_FILE)) data_path_0 (
     .clk(clk),
     .mret(mret),
     .imm_gen_sel(imm_gen_sel),
     .alu_arg_sel(alu_arg_sel),
     .data_mem_width(data_mem_width),
     .pc_sel(pc_sel),
     .trap_ctrl_csr_wdata_sel(trap_ctrl_csr_wdata_sel),
     .register_file_write_en(register_file_write_en),
     .register_file_rd_data_sel(register_file_rd_data_sel),
     .data_mem_write_en(data_mem_write_en),
     .csr_write_en(csr_write_en),
     .trap(trap),
     .exception_mcause(exception_mcause),
     .instr(instr),
     .illegal_instr(data_path_illegal_instr),
     .instr_addr_mis(instr_addr_mis),
     .instr_access_fault(instr_access_fault),
     .interrupt(interrupt),
     .data_mem_claim(data_mem_claim),
     .csr_claim(csr_claim),
     .meip(meip)
     );
     
   
endmodule
