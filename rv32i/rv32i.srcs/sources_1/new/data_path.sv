import types::control_lines_t;
import types::data_path_status_t;
import types::rv32_instr_t;

/// Data path
module data_path #(parameter string ROM_FILE = "rom_image.mem") (
   input	      clk,
   input	      meip, // External interrupt pending
   
   control_bus.status bus
);
   
   control_lines_t control_lines;
   data_path_status_t data_path_status;
   
   assign control_lines = bus.control_lines;
   assign data_path_status = bus.data_path_status;
   
   // 32-bit sign- or zero-extended immediate
   wire [31:0] imm;
   
   // Main ALU signals
   wire [31:0] main_alu_result, a, b, main_alu_b_imm;
   wire	       main_alu_zero;
   wire [3:0]  alu_op;
   
   // Register file signals
   wire [31:0] rd_data, rs1_data, rs2_data;
   
   // Trap controller signals
   wire [31:0] mcause, mepc, trap_vector;
   
   // Program counter signals
   wire [31:0] pc, pc_plus_4;
   
   // Provides and updates the program counter   
   pc pc_0(
      .clk,
      .sel(control_lines.pc_sel),
      .mepc,
      .trap_vector,
      .offset(imm),
      .main_alu_result,
      .trap(control_lines.trap),
      .pc,
      .pc_plus_4,
      .instr_addr_mis(data_path_status.instr_addr_mis)
   );
   
   rv32_instr_t instr;
   
   assign data_path_status.instr = instr;
   
   assign alu_op = { instr[30], instr.r_type.funct3 };
   
   bit [31:0] data_mem_rdata;
   
   // Data memory bus
   data_mem_bus #(.NUM_DEVICES(2)) dm_bus (
      .clk,
      .rdata(data_mem_rdata),
      .claim(data_path_status.data_mem_claim),
      .addr(main_alu_result),
      .width(control_lines.data_mem_width),
      .wdata(rs2_data)
   );
   
   wire [31:0] csr_rdata;
   
   csr_bus #(.NUM_DEVICES(1)) csr_bus (
      .clk,
      .rdata(csr_rdata),
      .addr(instr[31:20]),
      .wdata(csr_wdata),
      .claim(data_path_status.csr_claim)
   );
   
   // Select CSR write data source
   csr_wdata_sel csr_wdata_sel(
      .sel(control_lines.csr_wdata_sel),
      .rs1_data,
      .main_alu_result,
      .imm,
      .csr_wdata
   );
   
   // Trap controller
   trap_ctrl trap_ctrl(
      .clk,
      .meip,
      .mret(control_lines.mret),
      .trap(control_lines.trap),
      .exception_mcause(control_lines.exception_mcause),
      .pc,
      .interrupt(data_path_status.interrupt),
      .mepc,
      .trap_vector,
      .dm_bus(dm_bus.dev[0].device), // Data memory bus
      .csr_bus(csr_bus.dev[0].device) // CSR bus
     );
     
   // Instruction memory
   instr_mem #(.ROM_FILE(ROM_FILE)) instr_mem_0 (
     .pc(pc),
     .instr(instr),
     .instr_access_fault(data_path_status.instr_access_fault)
     );
   
   // Main memory
   main_mem main_mem_0(.bus(dm_bus.dev[1].device));
   
   // Register file
   register_file_wrapper register_file_wrapper_0(
     .clk,
     .write_en(control_lines.register_file_write_en),
     .rd_data_sel(control_lines.register_file_rd_data_sel),
     .main_alu_result,
     .data_mem_rdata,
     .csr_rdata,
     .pc_plus_4,
     .instr,
     .rs1_data,
     .rs2_data
     );
     
   // Immediate generation for all instruction formats
   imm_gen imm_gen_0(
     .sel(control_lines.imm_gen_sel),
     .instr,
     .imm
     );
     
   // Main arithmetic logic unit
   main_alu_wrapper main_alu_wrapper_0(
     .arg_sel(control_lines.alu_arg_sel),
     .alu_op,
     .rs1_data,
     .rs2_data,
     .imm,
     .pc,
     .csr_rdata,
     .main_alu_result,
     .main_alu_zero
     );

endmodule
