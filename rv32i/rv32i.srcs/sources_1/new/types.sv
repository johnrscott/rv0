package types;

   typedef enum bit [2:0] {
      FUNCT3_ADD = 3'b000, // Also sub
      FUNCT3_SLL = 3'b001,
      FUNCT3_SLTU = 3'b010,
      FUNCT3_SLT = 3'b011,
      FUNCT3_XOR = 3'b100,
      FUNCT3_SRL = 3'b101, // Also sra
      FUNCT3_OR = 3'b110,
      FUNCT3_AND = 3'b111
   } funct3_t;

   typedef struct {
      bit op_mod; // Changes add to sub, or srl to sra
      funct3_t op;
   } alu_op_t; 
   
   /// Pick the sources for the inputs to
   /// the main ALU.
   typedef enum bit [2:0] {
      RS1_RS2,
      RS1_IMM,
      PC_IMM,
      RS1_CSR,
      IMM_CSR,
      NOT_RS1_CSR,
      NOT_IMM_CSR
   } alu_arg_sel_t;
   
   /// Selects signal source for writes to rd
   /// (Vivado does not support non-integral enums)
   typedef enum bit [2:0] {
      MAIN_ALU_RESULT,
      DATA_MEM_RDATA,
      CSR_RDATA,
      PC_PLUS_4,
      LUI_IMM
   } rd_data_sel_t;

   /// Instruction formats
   /// (Vivado does not support non-integral enums)
   typedef enum bit [2:0] {
      R_TYPE,
      I_TYPE,
      S_TYPE,
      B_TYPE,
      U_TYPE,
      J_TYPE,
      CSR_R_TYPE,
      CSR_I_TYPE
   } instr_format_t;
   
   /// Control unit to data path signals
   typedef struct {
      logic        mret;			    // whether the data path should execute an mret
      instr_format_t imm_gen_sel;           // select which immediate format to extract
      alu_arg_sel_t alu_arg_sel;	    // pick the ALU operation
      bit [1:0]	 data_mem_width;	    // pick the load/store access width
      bit [1:0]	 pc_sel;		    // choose how to calculate the next program counter
      bit [1:0]	 csr_wdata_sel;             // pick write data source for CSR bus
      bit	 register_file_write_en;    // whether to write to rd
      bit [2:0]	 register_file_rd_data_sel; // select source for write to rd
      bit	 data_mem_write_en;	    // whether to write to data memory bus
      bit	 csr_write_en;		    // whether to write to CSR bus
      logic	 trap;			    // whether to execute an (interrupt or exception) trap
      bit [31:0] exception_mcause;	    // for an exception, what is the mcause value
   } control_lines_t;
   
   /// Data path outputs for control unit
   typedef struct {
      bit [31:0] instr;				// instruction at current program counter
      //bit	 illegal_instr;			// illegal instruction exception
      bit	 instr_addr_mis;		// instruction address misaligned
      bit	 instr_access_fault;		// instruction access fault
      bit	 interrupt;			// is an interrupt pending?	 
      bit	 data_mem_claim;		// has any device claimed data read/write?
      bit	 csr_claim;			// has any device claimed CSR bus read/write?
      bit	 main_alu_result;               // bit 0 used for conditional branch
      bit	 main_alu_zero;                 // used for conditional branch
   } data_path_status_t;

   typedef struct packed {
      bit [31:25] funct7;
      bit [24:20] rs2;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7] rd;
      bit [6:0]	 opcode;
   } r_type_t;

   typedef struct packed {
      bit [31:20] imm11_0;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7] rd;      
      bit [6:0] opcode;
   } i_type_t;

   /// Same as I-type, but imm fields is replaced
   /// with CSR address. Used for csrrw, etc.
   typedef struct packed {
      bit [31:20] csr_addr;      
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7] rd;
      bit [6:0] opcode;
   } csr_r_type_t;

   /// Same as I-type, but imm fields is replaced
   /// with CSR address and rs1 holds the uimm field.
   /// Used for csrrwi etc.
   typedef struct packed {
      bit [31:20] csr_addr;      
      bit [19:15] uimm;
      funct3_t funct3;
      bit [11:7]  rd;
      bit [6:0]	  opcode;
   } csr_i_type_t;
   
   typedef struct packed {
      bit [31:25] imm11_5;      
      bit [24:20] rs2;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7]  imm4_0;
      bit [6:0]	  opcode;
   } s_type_t;
   
   typedef struct packed {
      bit	  imm12;
      bit [30:25] imm10_5;
      bit [24:20] rs2;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:8]  imm4_1;
      bit	  imm11;
      bit [6:0]	  opcode;
   } b_type_t;
   
   typedef struct packed {
      bit [31:12] imm31_12;
      bit [11:7] rd;
      bit [6:0]	 opcode;
   } u_type_t;
   
   typedef struct packed {
      bit	  imm20;
      bit [30:21] imm10_1;
      bit	  imm11;
      bit [19:12] imm19_12;
      bit [11:7]  rd;      
      bit [6:0]	  opcode;
   } j_type_t;

   typedef union packed {
      r_type_t r_type;
      i_type_t i_type;
      s_type_t s_type;
      b_type_t b_type;
      u_type_t u_type;
      j_type_t j_type;
      csr_r_type_t csr_r_type;
      csr_i_type_t csr_i_type;
   } instr_t;
   
endpackage: types
