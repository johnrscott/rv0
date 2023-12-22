`timescale 1ns / 1ps

/// Data path
module data_path(
  input       clk,

  /// Set main ALU behaviour
  input [3:0] alu_op,
  input       main_alu_a_sel,
  input       main_alu_n_sel
  
  
  );
   
   // Program counter
   reg [31:0] pc;

   // Fetched instruction
   wire instr;

   // Fixed instruction fields
   assign opcode = instr[6:0];
   assign rd = instr[11:7];
   assign funct3 = instr[14:12];
   assign rs1 = instr[19:15];
   assign rs2 = instr[24:20];
   assign funct7 = instr[31:25];
   
   // Main ALU inputs 
   wire [31:0] a, b;

   // Data memory bus
   wire [31:0] data_mem_addr;
   wire [1:0]  data_mem_width;
   wire [31:0] data_mem_wdata;
   wire        data_mem_write_en;
   wire [31:0] data_mem_rdata;
   wire        data_mem_claim;
   
   // CSR bus
   wire [11:0] csr_addr;
   wire [31:0] csr_wdata;
   wire        csr_write_en;
   wire [31:0] csr_rdata;
   wire        csr_claim;

   // Trap controller
   trap_ctrl trap_ctrl_0(
     .meie(meie),
     .mret(mret),
     .exception(exception),
     .mcause(mcause),
     .pc(pc),
     .pc_plus_4(pc_plus_4),
     .trap(trap),
     .interrupt(interrupt),
     .mepc(mepc),
     .exception_vector(exception_vector),
     .interrupt_offset(interrupt_offset),

     // Data memory bus
     .data_mem_addr(data_mem_addr),
     .data_mem_width(data_mem_width),
     .data_mem_wdata(data_mem_wdata),
     .data_mem_write_en(data_mem_write_en),
     .data_mem_wdata(data_mem_rdata_trap_ctrl),
     .data_mem_claim(data_mem_claim),

     // CSR bus
     .csr_addr(csr_addr),
     .csr_wdata(csr_wdata),
     .csr_write_en(csr_write_en),
     .csr_rdata(csr_rdata_trap_ctrl),
     .csr_claim(csr_claim_trap_ctrl),
     .illegal_instr(illegal_instr_trap_ctrl)
     );
     
   // Instruction memory
   instr_mem instr_mem_0(
     .pc(pc),
     .instr(instr),
     .instr_access_fault(instr_access_fault)
     );

   // Pick the source for the register file rd write data
   register_file_rd_data_sel register_file_rd_data_sel_0(
     .sel(register_file_rd_data_sel),
     .main_alu_r(r),
     .data_mem_rdata(data_mem_rdata),
     .csr_rdata(csr_rdata),
     .pc_plus_4(pc_plus_4),
     .rd_data(rd_data)
     );
     
   // Register file
   register_file register_file_0(
     .rs1(rs1),
     .rs2(rs2),
     .rd_data(rd_data),
     .rd(rd),
     .write_en(write_en),
     .clk(clk),
     .rs1_data(rs1_data),
     .rs2_data(rs2_data)
     );
   
   // Select first input for main ALU
   main_alu_a_sel main_alu_a_sel_0 (
     .sel(main_alu_a_sel),
     .rs1_data(rs1_data),
     .pc(pc),
     .uimm(uimm),
     .a(a)
     );
   
   // Select second input for main ALU
   main_alu_b_sel main_alu_b_sel_0 (
     .sel(main_alu_b_sel),
     .rs2_data(rs2_data),
     .imm(imm),
     .b(b)
     );
     
   // Main arithmetic logic unit
   alu main_alu(
     .a(a),
     .b(b),
     .alu_op(alu_op),
     .r(r),
     .zero(zero)
     );
   
endmodule
