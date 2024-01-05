package types;

   typedef enum bit [6:0] {
      OP_LUI = 7'b0110111,
      OP_AUIPC = 7'b0010111,
      OP_JAL = 7'b1101111,
      OP_JALR = 7'b1100111,
      OP_IMM = 7'b0010011,
      OP_IMM_32 = 7'b0011011,
      OP = 7'b0110011,
      OP_32 = 7'b0111011,
      OP_BRANCH = 7'b1100011,
      OP_LOAD = 7'b0000011,
      OP_STORE = 7'b0100011,
      OP_MISC_MEM = 7'b0001111,
      OP_SYSTEM = 7'b1110011
   } opcode_t;
   
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

   /// Picks the source for the next program counter
   typedef enum bit [1:0] {
      PC_SEL_PC_PLUS_4,
      PC_SEL_MEPC,
      PC_SEL_MASK_ALU,
      PC_SEL_PC_PLUS_OFFSET
   } pc_sel_t;
   
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

   typedef enum bit [1:0] {
      WIDTH_BYTE,
      WIDTH_HALFWORD,
      WIDTH_WORD
   } width_t;

   typedef enum bit [1:0] {
      CSR_WDATA_RS1,
      CSR_WDATA_ALU,
      CSR_WDATA_IMM
   } csr_wdata_sel_t;
   
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
   ///
   /// If this is not packed, I get errors assigning
   /// to the fields via a clocking block in the
   /// data_path_tb testbench. This might be related
   /// to this issue (maybe a Vivado bug):
   ///
   /// https://support.xilinx.com/s/question/
   /// 0D54U00007ZIGfXSAX/xsim-bug-xsim-does-
   /// not-simulate-struct-assignments-in-c
   /// locking-blocks-correctly?language=en_US
   ///

   typedef struct packed {
      bit [31:25] funct7;
      bit [24:20] rs2;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7] rd;
      opcode_t opcode;
   } r_type_t;

   typedef struct packed {
      bit [31:20] imm11_0;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7] rd;      
      opcode_t opcode;
   } i_type_t;

   /// Same as I-type, but imm fields is replaced
   /// with CSR address. Used for csrrw, etc.
   typedef struct packed {
      bit [31:20] csr_addr;      
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7] rd;
      opcode_t opcode;
   } csr_r_type_t;

   /// Same as I-type, but imm fields is replaced
   /// with CSR address and rs1 holds the uimm field.
   /// Used for csrrwi etc.
   typedef struct packed {
      bit [31:20] csr_addr;      
      bit [19:15] uimm;
      funct3_t funct3;
      bit [11:7]  rd;
      opcode_t opcode;
   } csr_i_type_t;
   
   typedef struct packed {
      bit [31:25] imm11_5;      
      bit [24:20] rs2;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:7]  imm4_0;
      opcode_t opcode;
   } s_type_t;
   
   typedef struct packed {
      bit	  imm12;
      bit [30:25] imm10_5;
      bit [24:20] rs2;
      bit [19:15] rs1;
      funct3_t funct3;
      bit [11:8]  imm4_1;
      bit	  imm11;
      opcode_t opcode;
   } b_type_t;
   
   typedef struct packed {
      bit [31:12] imm31_12;
      bit [11:7] rd;
      opcode_t opcode;
   } u_type_t;
   
   typedef struct packed {
      bit	  imm20;
      bit [30:21] imm10_1;
      bit	  imm11;
      bit [19:12] imm19_12;
      bit [11:7]  rd;      
      opcode_t opcode;
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
