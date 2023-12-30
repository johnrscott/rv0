package types;

   /// Control unit to data path signals
   typedef struct {
      bit        mret;			    // whether the data path should execute an mret
      bit [2:0]	 imm_gen_sel;		    // select which immediate format to extract
      bit [2:0]	 alu_arg_sel;		    // pick the ALU operation
      bit [1:0]	 data_mem_width;	    // pick the load/store access width
      bit [1:0]	 pc_sel;		    // choose how to calculate the next program counter
      bit [1:0]	 trap_ctrl_csr_wdata_sel;   // pick write data source for CSR bus
      bit	 register_file_write_en;    // whether to write to rd
      bit [2:0]	 register_file_rd_data_sel; // select source for write to rd
      bit	 data_mem_write_en;	    // whether to write to data memory bus
      bit	 csr_write_en;		    // whether to write to CSR bus
      bit	 trap;			    // whether to execute an (interrupt or exception) trap
      bit [31:0] exception_mcause;	    // for an exception, what is the mcause value
   } control_lines_t;
   
   /// Data path outputs for control unit
   typedef struct {
      bit [31:0] instr;				// instruction at current program counter
      bit	 illegal_instr;			// illegal instruction exception
      bit	 instr_addr_mis;		// instruction address misaligned
      bit	 instr_access_fault;		// instruction access fault
      bit	 interrupt;			// is an interrupt pending?	 
      bit	 data_mem_claim;		// has any device claimed data read/write?
      bit	 csr_claim;			// has any device claimed CSR bus read/write?
   } data_path_status_t;

   typedef struct packed {
      bit [6:0] opcode;
      bit [11:7] rd;
      bit [14:12] funct3;
      bit [19:15] rs1;
      bit [24:20] rs2;
      bit [31:25] funct7;
   } r_type_t;

   typedef struct packed {
      bit [6:0] opcode;
      bit [11:7] rd;
      bit [14:12] funct3;
      bit [19:15] rs1;
      bit [31:20] imm11_0;      
   } i_type_t;

   typedef struct packed {
      bit [6:0] opcode;
      bit [11:7] imm4_0;
      bit [14:12] funct3;
      bit [19:15] rs1;
      bit [24:20] rs2;
      bit [31:25] imm11_5;      
   } s_type_t;

   typedef struct packed {
      bit [6:0] opcode;
      bit imm11;
      bit [11:8] imm4_1;
      bit [14:12] funct3;
      bit [19:15] rs1;
      bit [24:20] rs2;
      bit [30:25] imm10_5;
      bit	  imm12;
   } b_type_t;

   typedef struct packed {
      bit [6:0] opcode;
      bit [11:7] rd;
      bit [31:12] imm31_12;
   } u_type_t;

   typedef struct packed {
      bit [6:0] opcode;
      bit [11:7] rd;
      bit [19:12] imm19_12;
      bit	  imm11;
      bit [30:21] imm10_1;
      bit	  imm_20;
   } j_type_t;

   typedef union packed {
      r_type_t r_type;
      i_type_t i_type;
      s_type_t s_type;
      b_type_t b_type;
      u_type_t u_type;
      j_type_t j_type;
   } rv32_instr_t;
   
endpackage: types
