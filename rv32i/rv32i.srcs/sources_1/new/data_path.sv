`timescale 1ns / 1ps

/// Data path
module data_path(
  input 	clk,
  
  /// External interrupt pending
  input 	meip,

  /// Whether a return-from-trap
  /// should be performed
  input 	mret,
  
  /// Set main ALU behaviour
  input [3:0] 	alu_op,
  input [1:0] 	main_alu_a_sel,
  input [2:0]	main_alu_b_sel,
  input [2:0] 	main_alu_b_imm_sel,

  // External illegal instruction flag
  // from instruction decoding (control
  // unit)
  input 	illegal_instr_ext,

  // For a load/store, what width to use
  input [1:0] 	data_mem_width,

  // Whether to write data back to the register
  // file. This will be overridden if a trap
  // occurs.
  input 	ctrl_register_file_write_en,

  // Whether to write data to the data memory
  // bus (for loads/stores). This will be
  // overridden if a trap occurs.
  input 	ctrl_data_mem_write_en,

  // Whether to write data to the CSR bus.
  // Overridden if a trap occurs.
  input 	ctrl_csr_write_en,

  // Fetched instruction for use by the
  // control unit.
  output [31:0] instr
  
  );
   
   // Provides and updates the program counter
   wire [31:0] 	pc, pc_plus_4;
   pc pc_0(
     .clk(clk),
     .sel(pc_sel),
     .mepc(mepc),
     .exception_vector(exception_vector),
     .interrupt_offset(interrupt_offset),
     .offset(offset),
     .main_alu_r(main_alu_r),
     .trap(trap),
     .pc(pc),
     .pc_plus_4(pc_plus_4),
     .instr_addr_mis(instr_addr_mis)
    );

   // Fixed instruction fields
   assign opcode = instr[6:0];
   assign rd = instr[11:7];
   assign funct3 = instr[14:12];
   assign rs1 = instr[19:15];
   assign rs2 = instr[24:20];
   assign funct7 = instr[31:25];
   
   // Data memory bus
   wire [31:0] data_mem_addr;
   wire [1:0]  data_mem_width;
   wire [31:0] data_mem_wdata;
   wire        data_mem_write_en;
   wire [31:0] data_mem_rdata;
   wire        data_mem_claim;
   
   assign data_mem_addr = main_alu_r;
   assign data_mem_wdata = rs1_data;
   assign data_mem_write_en = ctrl_data_mem_write_en & !trap;
   
   // Combine outputs from all data memory bus devices
   assign data_mem_rdata = data_mem_rdata_trap_ctrl;
   
   // CSR bus
   wire [11:0] csr_addr;
   wire [31:0] csr_wdata;
   wire        csr_write_en;
   wire [31:0] csr_rdata;
   wire        csr_claim;

   assign csr_addr = instr[31:20];
   assign csr_write_en = ctrl_csr_write_en & !trap;   
   // Combine outputs from all CSR devices
   assign csr_rdata = csr_rdata_trap_ctrl;

   // Derive exception flags from individual modules
   assign illegal_instr = illegal_instr_ext |
			  illegal_instr_trap_ctrl;
   
   // Convert exception flags to exception cause
   wire [31:0] mcause;
   exception_encoder exception_encoder_0(
     .instr_addr_mis(instr_addr_mis),
     .instr_access_fault(instr_access_fault),
     .illegal_instr(illegal_instr),
     .breakpoint(breakpoint),
     .load_access_fault(load_access_fault),
     .store_access_fault(store_access_fault),
     .ecall_mmode(ecall_mmode),
     .exception(exception),
     .mcause(mcause)
     );

   // Trap controller
   trap_ctrl trap_ctrl_0(
     .clk(clk),

     .meip(meip),
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
     .data_mem_rdata(data_mem_rdata_trap_ctrl),
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
   wire [31:0] instr;
   instr_mem instr_mem_0(
     .pc(pc),
     .instr(instr),
     .instr_access_fault(instr_access_fault)
     );

   // Pick the source for the register file rd write data
   register_file_rd_data_sel register_file_rd_data_sel_0(
     .sel(register_file_rd_data_sel),
     .main_alu_r(main_alu_r),
     .data_mem_rdata(data_mem_rdata),
     .csr_rdata(csr_rdata),
     .pc_plus_4(pc_plus_4),
     .rd_data(rd_data)
     );
     
   // Register file
   assign register_file_write_en = ctrl_register_file_write_en & !trap;
   wire [31:0] rs1_data;
   wire [31:0] rs2_data;
   register_file register_file_0(
     .rs1(rs1),
     .rs2(rs2),
     .rd_data(rd_data),
     .rd(rd),
     .write_en(register_file_write_en),
     .clk(clk),
     .rs1_data(rs1_data),
     .rs2_data(rs2_data)
     );
   
   // Select first input for main ALU
   main_alu_a_sel main_alu_a_sel_0 (
     .sel(main_alu_a_sel),
     .rs1_data(rs1_data),
     .pc(pc),
     .csr_rdata(csr_rdata),
     .a(a)
     );

   // Make the immediate input for the main ALU b port
   main_alu_b_imm_sel main_alu_b_imm_sel_0(
     .sel(main_alu_b_imm_sel),
     .instr(instr),
     .imm(main_alu_b_imm)
     );
     
   // Select second input for main ALU
   main_alu_b_sel main_alu_b_sel_0 (
     .sel(main_alu_b_sel),
     .rs1_data(rs1_data),
     .rs2_data(rs2_data),
     .imm(main_alu_b_imm),
     .b(b)
     );
     
   // Main arithmetic logic unit
   wire [31:0] main_alu_r;
   wire [31:0] a, b;
   alu main_alu(
     .a(a),
     .b(b),
     .alu_op(alu_op),
     .r(main_alu_r),
     .zero(zero)
     );
   
endmodule
