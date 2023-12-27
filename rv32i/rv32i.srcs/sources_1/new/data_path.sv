`timescale 1ns / 1ps

/// Data path
module data_path(
  input 	clk,
  
  /// External interrupt pending
  input 	meip,

  /// Whether a return-from-trap
  /// should be performed
  input 	mret,

  /// Immediate generation
  input 	imm_gen_sel,
  
  /// Set main ALU behaviour
  input [2:0] 	alu_arg_sel,

  // Signals asserted for specific
  // classes of instructions
  wire 		load_store_instr, csr_instr,
  
  // External illegal instruction flag
  // from instruction decoding (control
  // unit)
  input 	illegal_instr_ext,

  // Other external exceptions from control unit
  input 	ecall_mmode, breakpoint,
  
  // For a load/store, what width to use
  input [1:0] 	data_mem_width,

  // Multiplexer control signals
  input [1:0] 	pc_sel, 

  // Trap controller
  input [1:0] 	trap_ctrl_csr_wdata_sel,
  
  // Whether to write data back to the register
  // file. This will be overridden if a trap
  // occurs.
  input 	register_file_write_en,
  input [1:0] 	register_file_rd_data_sel,
  
  // Whether to write data to the data memory
  // bus (for loads/stores). This will be
  // overridden if a trap occurs.
  input 	data_mem_write_en,

  // Whether to write data to the CSR bus.
  // Overridden if a trap occurs.
  input 	csr_write_en,

  // Fetched instruction for use by the
  // control unit.
  output [31:0] instr
  
  );

   // Fixed instruction fields
   wire [6:0]  opcode;
   wire [4:0]  rd, rs1, rs2;
   wire [2:0]  funct3;
   wire [6:0]  funct7;
   wire [4:0]  uimm;

   // Main ALU signals
   wire [31:0] main_alu_result, a, b, main_alu_b_imm;
   wire        main_alu_zero;
   wire [3:0]  alu_op;
   
   // Register file signals
   wire [31:0] rd_data, rs1_data, rs2_data;

   // Exception signals
   wire        instr_addr_mis, instr_access_fault, illegal_instr, 
	       load_access_fault, store_access_fault;
   
   // Trap controller signals
   wire [31:0] mcause, mepc, exception_vector, interrupt_offset,
	       data_mem_rdata_trap_ctrl, csr_rdata_trap_ctrl,
	       csr_wdata_trap_ctrl;
   wire        data_mem_claim_trap_ctrl, csr_claim_trap_ctrl;

   // Program counter signals
   wire [31:0] pc, pc_plus_4, branch_offset_imm;

   // Conditional branch offset immediate generation
   branch_offset_imm_gen branch_offset_imm_gen_0(
     .instr(instr),
     .offset(branch_offset_imm)
     );
   
   // Provides and updates the program counter   
   pc pc_0(
     .clk(clk),
     .sel(pc_sel),
     .mepc(mepc),
     .exception_vector(exception_vector),
     .interrupt_offset(interrupt_offset),
     .offset(branch_offset_imm),
     .main_alu_r(main_alu_result),
     .trap(trap),
     .pc(pc),
     .pc_plus_4(pc_plus_4),
     .instr_addr_mis(instr_addr_mis)
    );

   assign opcode = instr[6:0];
   assign rd = instr[11:7];
   assign funct3 = instr[14:12];
   assign rs1 = instr[19:15];
   assign rs2 = instr[24:20];
   assign funct7 = instr[31:25];
   assign uimm = rs1;

   assign alu_op = { instr[30], funct3 };
   
   // Data memory bus
   wire [31:0] data_mem_addr;
   //wire [1:0]  data_mem_width;
   wire [31:0] data_mem_wdata;
   wire        data_mem_write_en_internal;
   wire [31:0] data_mem_rdata;
   wire        data_mem_claim;
   
   assign data_mem_addr = main_alu_result;
   assign data_mem_wdata = rs1_data;
   assign data_mem_write_en_internal = data_mem_write_en & !trap;
   assign data_mem_claim = data_mem_claim_trap_ctrl;
   
   // Load and store access faults are raised if a data
   // memory bus access is requested, but no device on
   // the bus "claims" the read/write. Loads/stores are
   // distinguished by whether the write enable signal
   // is set
   assign load_access_fault = load_store_instr &
			      !data_mem_claim &
			      !data_mem_write_en;
   assign store_access_fault = load_store_instr &
			       !data_mem_claim &
			       data_mem_write_en;

   // Combine outputs from all data memory bus devices
   assign data_mem_rdata = data_mem_rdata_trap_ctrl;
   
   // CSR bus
   wire [11:0] csr_addr;
   wire [31:0] csr_wdata;
   wire        csr_write_en_internal;
   wire [31:0] csr_rdata;
   wire        csr_claim;

   assign csr_addr = instr[31:20];
   assign csr_write_en_internal = csr_write_en & !trap;   
   // Combine outputs from all CSR devices
   assign csr_rdata = csr_rdata_trap_ctrl;

   assign csr_claim = csr_claim_trap_ctrl;
   
   // Derive exception flags from individual modules. If
   // no device on the CSR bus "claims" the read/write, then
   // that CSR does not exist and an illegal instruction is
   // raised   
   assign illegal_instr = illegal_instr_ext |
			  illegal_instr_trap_ctrl |
			  (csr_instr & !csr_claim);
   
   // Convert exception flags to exception cause
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

   // CSR write data for trap controller
   trap_ctrl_csr_wdata_sel trap_ctrl_csr_wdata_sel_0(
     .sel(trap_ctrl_csr_wdata_sel),
     .rs1_data(rs1_data),
     .main_alu_r(main_alu_result),
     .uimm(uimm),
     .csr_wdata(csr_wdata_trap_ctrl)
     );
   
   // Trap controller
   trap_ctrl trap_ctrl_0(
     .clk(clk),

     .meip(meip),
     .mret(mret),
     .exception(exception),
     .mcause(mcause),
     .pc(pc),
     .trap(trap),
     .interrupt(interrupt),
     .mepc(mepc),
     .exception_vector(exception_vector),
     .interrupt_offset(interrupt_offset),

     // Data memory bus
     .data_mem_addr(data_mem_addr),
     .data_mem_width(data_mem_width),
     .data_mem_wdata(data_mem_wdata),
     .data_mem_write_en(data_mem_write_en_internal),
     .data_mem_rdata(data_mem_rdata_trap_ctrl),
     .data_mem_claim(data_mem_claim_trap_ctrl),

     // CSR bus
     .csr_addr(csr_addr),
     .csr_wdata(csr_wdata_trap_ctrl),
     .csr_write_en(csr_write_en_internal),
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
     .main_alu_r(main_alu_result),
     .data_mem_rdata(data_mem_rdata),
     .csr_rdata(csr_rdata),
     .pc_plus_4(pc_plus_4),
     .rd_data(rd_data)
     );
     
   // Register file
   assign register_file_write_en_internal = register_file_write_en & !trap;
   register_file register_file_0(
     .rs1(rs1),
     .rs2(rs2),
     .rd_data(rd_data),
     .rd(rd),
     .write_en(register_file_write_en_internal),
     .clk(clk),
     .rs1_data(rs1_data),
     .rs2_data(rs2_data)
     );
   
   // Immediate generation for all instruction formats
   imm_gen imm_gen_0(
     .sel(imm_gen_sel),
     .instr(instr),
     .imm(imm)
     );
     
   // Main arithmetic logic unit
   main_alu_wrapper main_alu_wrapper_0(
     .arg_sel(alu_arg_sel),
     .alu_op(alu_op),
     .rs1_data(rs1_data),
     .rs2_data(rs2_data),
     .imm(imm),
     .pc(pc),
     .csr_rdata(csr_rdata),
     .main_alu_result(main_alu_result),
     .main_alu_zero(main_alu_zero)
     );
   
endmodule
