import types::instr_t;
import types::alu_op_t;

/// Data path
module data_path #(parameter string ROM_FILE = "rom_image.mem") (
   input	      meip, // External interrupt pending   
   control_bus.status bus
);
   
   bit clk;
   assign clk = bus.clk;
   
   // 32-bit sign- or zero-extended immediate
   bit [31:0] imm;
   
   // Main ALU signals
   bit [31:0] main_alu_result, a, b, main_alu_b_imm;
   bit	      main_alu_zero;
   alu_op_t alu_op;

   assign bus.main_alu_result = main_alu_result;
   assign bus.main_alu_zero = main_alu_zero;
   
   // Register file signals
   wire [31:0] rd_data, rs1_data, rs2_data;
   
   // Trap controller signals
   wire [31:0] mcause, mepc, trap_vector;
   
   // Program counter signals
   wire [31:0] pc, pc_plus_4;
   
   // Provides and updates the program counter   
   pc pc_wrapper(
      .clk,
      .rstn(bus.rstn),
      .sel(bus.pc_sel),
      .mepc,
      .trap_vector,
      .offset(imm),
      .main_alu_result,
      .trap(bus.trap),
      .pc,
      .pc_plus_4,
      .instr_addr_mis(bus.instr_addr_mis)
   );
   
   instr_t instr;
   
   assign bus.instr = instr;
   
   assign alu_op = { op_mod:instr[30], op:instr.r_type.funct3 };
   
   bit [31:0] data_mem_rdata;
   
   // Data memory bus
   data_mem_bus #(.NUM_DEVICES(2)) dm_bus (
      .clk,
      .rdata(data_mem_rdata),
      .claim(bus.data_mem_claim),
      .addr(main_alu_result),
      .width(bus.data_mem_width),
      .wdata(rs2_data)
   );
   
   wire [31:0] csr_rdata;
   
   csr_bus #(.NUM_DEVICES(1)) csr_bus (
      .clk,
      .rdata(csr_rdata),
      .addr(instr[31:20]),
      .wdata(csr_wdata),
      .claim(bus.csr_claim)
   );
   
   // Select CSR write data source
   csr_wdata_sel csr_wdata_sel(
      .sel(bus.csr_wdata_sel),
      .rs1_data,
      .main_alu_result,
      .imm,
      .csr_wdata
   );
   
   // Trap controller
   trap_ctrl trap_ctrl(
      .clk,
      .meip,
      .mret(bus.mret),
      .trap(bus.trap),
      .exception_mcause(bus.exception_mcause),
      .pc,
      .interrupt(bus.interrupt),
      .mepc,
      .trap_vector,
      .dm_bus(dm_bus.dev[0].device), // Data memory bus
      .csr_bus(csr_bus.dev[0].device) // CSR bus
   );
   
   // Instruction memory
   instr_mem #(.ROM_FILE(ROM_FILE)) instr_mem (
      .pc(pc),
      .instr(instr),
      .instr_access_fault(bus.instr_access_fault)
   );
   
   // Main memory
   main_mem main_mem(.bus(dm_bus.dev[1].device));
   
   // Register file
   register_file_wrapper register_file_wrapper(
      .clk,
      .write_en(bus.register_file_write_en),
      .rd_data_sel(bus.register_file_rd_data_sel),
      .main_alu_result,
      .data_mem_rdata,
      .csr_rdata,
      .pc_plus_4,
      .instr,
      .lui_imm(imm),
      .rs1_data,
      .rs2_data
   );
   
   // Immediate generation for all instruction formats
   imm_gen imm_gen(
      .sel(bus.imm_gen_sel),
      .instr,
      .imm
   );
   
   // Main arithmetic logic unit
   main_alu_wrapper main_alu_wrapper(
      .arg_sel(bus.alu_arg_sel),
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
