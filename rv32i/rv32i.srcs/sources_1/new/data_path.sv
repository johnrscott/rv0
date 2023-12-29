`timescale 1ns / 1ps

/// Data path
module data_path
  #(parameter string ROM_FILE)
  (
  input 	clk,
  
  /// External interrupt pending
  input 	meip,

  /// Whether a return-from-trap
  /// should be performed
  input 	mret,

  /// Immediate generation
  input [2:0] 	imm_gen_sel,
  
  /// Set main ALU behaviour
  input [2:0] 	alu_arg_sel,

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
  input [2:0] 	register_file_rd_data_sel,
  
  // Whether to write data to the data memory
  // bus (for loads/stores). This will be
  // overridden if a trap occurs.
  input 	data_mem_write_en,

  // Whether to write data to the CSR bus.
  // Overridden if a trap occurs.
  input 	csr_write_en,

  // Set for transfer to trap (next pc selection)
  input 	trap,

  // If an exception was raised, what is the mcause
  input [31:0] 	exception_mcause,
		 
  // Fetched instruction for use by the
  // control unit.
  output [31:0] instr,

  // Exception flags
  output 	illegal_instr,
  output 	instr_addr_mis, 
  output 	instr_access_fault,

  // Interrupt flag
  output 	interrupt,
		 
  // Bus claim signals, used to trigger
  // load/store access faults
  output 	data_mem_claim, csr_claim
		 
  );

   // Fixed instruction fields
   wire [6:0]  opcode;
   wire [4:0]  rd, rs1, rs2;
   wire [2:0]  funct3;
   wire [6:0]  funct7;
   wire [4:0]  uimm;

   // 32-bit sign- or zero-extended immediate
   wire [31:0] imm;
   
   // Main ALU signals
   wire [31:0] main_alu_result, a, b, main_alu_b_imm;
   wire        main_alu_zero;
   wire [3:0]  alu_op;
   
   // Register file signals
   wire [31:0] rd_data, rs1_data, rs2_data;

   // Trap controller signals
   wire [31:0] mcause, mepc, trap_vector,
	       data_mem_rdata_trap_ctrl, csr_rdata_trap_ctrl,
	       csr_wdata_trap_ctrl;
   wire        data_mem_claim_trap_ctrl, csr_claim_trap_ctrl;

   // Main memory signals
   wire [31:0] data_mem_rdata_main_mem;
   wire        data_mem_claim_main_mem;
   
   // Program counter signals
   wire [31:0] pc, pc_plus_4;
   
   // Provides and updates the program counter   
   pc pc_0(
     .clk(clk),
     .sel(pc_sel),
     .mepc(mepc),
     .trap_vector(trap_vector),
     .offset(imm),
     .main_alu_result(main_alu_result),
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
   //wire        data_mem_write_en;
   wire [31:0] data_mem_rdata;
   //wire        data_mem_claim;
   
   assign data_mem_addr = main_alu_result;
   assign data_mem_wdata = rs1_data;
   assign data_mem_claim = data_mem_claim_trap_ctrl |
			   data_mem_claim_main_mem;
   
   // Combine outputs from all data memory bus devices
   assign data_mem_rdata = data_mem_rdata_trap_ctrl |
			   data_mem_rdata_main_mem;
   
   // CSR bus
   wire [11:0] csr_addr;
   wire [31:0] csr_wdata;
   //wire        csr_write_en;
   wire [31:0] csr_rdata;
   //wire        csr_claim;

   assign csr_addr = instr[31:20];
   // Combine outputs from all CSR devices
   assign csr_rdata = csr_rdata_trap_ctrl;

   assign csr_claim = csr_claim_trap_ctrl;
   
   // Derive exception flags from individual modules. If
   // no device on the CSR bus "claims" the read/write, then
   // that CSR does not exist and an illegal instruction is
   // raised   
   assign illegal_instr = illegal_instr_trap_ctrl;

   // CSR write data for trap controller
   trap_ctrl_csr_wdata_sel trap_ctrl_csr_wdata_sel_0(
     .sel(trap_ctrl_csr_wdata_sel),
     .rs1_data(rs1_data),
     .main_alu_r(main_alu_result),
     .uimm(imm[4:0]),
     .csr_wdata(csr_wdata_trap_ctrl)
     );
   
   // Trap controller
   trap_ctrl trap_ctrl_0(
     .clk(clk),

     .meip(meip),
     .mret(mret),
     .trap(trap),
     .exception_mcause(exception_mcause),
     .pc(pc),
     .interrupt(interrupt),
     .mepc(mepc),
     .trap_vector(trap_vector),
	 
     // Data memory bus
     .data_mem_addr(data_mem_addr),
     .data_mem_width(data_mem_width),
     .data_mem_wdata(data_mem_wdata),
     .data_mem_write_en(data_mem_write_en),
     .data_mem_rdata(data_mem_rdata_trap_ctrl),
     .data_mem_claim(data_mem_claim_trap_ctrl),

     // CSR bus
     .csr_addr(csr_addr),
     .csr_wdata(csr_wdata_trap_ctrl),
     .csr_write_en(csr_write_en),
     .csr_rdata(csr_rdata_trap_ctrl),
     .csr_claim(csr_claim_trap_ctrl),
     .illegal_instr(illegal_instr_trap_ctrl)
     );
     
   // Instruction memory
   instr_mem #(.ROM_FILE(ROM_FILE)) instr_mem_0 (
     .pc(pc),
     .instr(instr),
     .instr_access_fault(instr_access_fault)
     );
   
   // Main memory
   main_mem main_mem_0(
     .data_mem_addr(data_mem_addr),
     .data_mem_width(data_mem_width),
     .data_mem_wdata(data_mem_wdata),
     .data_mem_write_en(data_mem_write_en),
     .data_mem_rdata(data_mem_rdata_main_mem),
     .data_mem_claim(data_mem_claim_main_mem)
     );
   
   // Register file
   register_file_wrapper register_file_wrapper_0(
     .clk(clk),
     .write_en(register_file_write_en),
     .rd_data_sel(register_file_rd_data_sel),
     .main_alu_result(main_alu_result),
     .data_mem_rdata(data_mem_rdata),
     .csr_rdata(csr_rdata),
     .pc_plus_4(pc_plus_4),
     .instr(instr),
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
