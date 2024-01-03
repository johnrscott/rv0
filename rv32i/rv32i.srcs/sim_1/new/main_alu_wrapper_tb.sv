import types::alu_op_t;
import types::alu_arg_sel_t;

// This testbench reads from the file main_alu_wrapper_tb_vectors.dat,
// which is space separated and has the following fields:
//
// arg_sel: rs1_rs2, rs1_imm, pc_imm, rs1_csr, imm_csr, 
// not_rs1_csr, not_imm_csr (to pick the ALU inputs)
//
// op: add, sub, sll, sltu, slt, xor, srl, sra, or, and
//
// rs1: value of register rs1 (hex)
// rs2: value of register rs2 (hex)
// imm: 32-bit immediate (hex)
// pc: current program counter (hex)
// csr: csr data (hex)
// res: the expected result from the ALU (hex)
// zero: the expected state of the ALU zero flag (bit)
//
module main_alu_wrapper_tb;

   timeunit 1ns;
   timeprecision 10ps;
   
   int fd, scanned, line;
   alu_arg_sel_t arg_sel;
   alu_op_t alu_op;
   bit [31:0] rs1_data, rs2_data, imm, pc,
	      csr_rdata, main_alu_result,
	      main_alu_result_true;
   bit	      main_alu_zero, main_alu_zero_true;
   string     arg_sel_str, op_str;
   
   main_alu_wrapper dut(
      .arg_sel,
      .alu_op,
      .rs1_data,
      .rs2_data,
      .imm,
      .pc,
      .csr_rdata,
      .main_alu_result,
      .main_alu_zero
   );

   always_comb begin
      // These are only relevant for some arg_sel values.
      // Otherwise they are ignored. 
      case (op_str)
	"add": alu_op = {op_mod:0, op:types::FUNCT3_ADD };
	"sub": alu_op = {op_mod:1, op:types::FUNCT3_ADD };
	"sll": alu_op = {op_mod:0, op:types::FUNCT3_SLL };
	"sltu": alu_op = {op_mod:0, op:types::FUNCT3_SLTU };
	"slt": alu_op = {op_mod:0, op:types::FUNCT3_SLT };
	"xor": alu_op = {op_mod:0, op:types::FUNCT3_XOR };
	"srl": alu_op = {op_mod:0, op:types::FUNCT3_SRL };
	"sra": alu_op = {op_mod:1, op:types::FUNCT3_SRL };
	"or": alu_op = {op_mod:0, op:types::FUNCT3_OR };
	"and": alu_op = {op_mod:0, op:types::FUNCT3_AND };
      endcase
   end
   
   always_comb begin
      case (arg_sel_str)
	"rs1_rs2": arg_sel = types::RS1_RS2;
	"rs1_imm": arg_sel = types::RS1_IMM;
	"pc_imm": arg_sel = types::PC_IMM;
	"rs1_csr": arg_sel = types::RS1_CSR;
	"imm_csr": arg_sel = types::IMM_CSR;
	"not_rs1_csr": arg_sel = types::NOT_RS1_CSR;
	"not_imm_csr": arg_sel = types::NOT_IMM_CSR;
	default: begin
	   $error("Got unsupported arg sel %s", arg_sel_str);
	   $finish();
	end
      endcase
   end
   
   initial begin

      line = 1;
      
      // There must be a way to fix this path (it is relative to xsim folder)
      fd = $fopen(
	   "../../../../rv32i.srcs/sim_1/new/main_alu_wrapper_tb_vectors.dat",
	   "r"
	   );
      while ((fd != 0) && !$feof(fd)) begin
	 scanned = $fscanf(
		   fd,
		   "%s %s %h %h %h %h %h %h %b",
		   arg_sel_str,
		   op_str,
		   rs1_data,
		   rs2_data,
		   imm,
		   pc,
		   csr_rdata,
		   main_alu_result_true,
		   main_alu_zero_true
		   );
	 if (scanned == 0) begin
	    $fclose(fd);
	    $finish();   
	 end
	 else begin
	    $display("Checking %s, %s at line %d:", arg_sel_str, op_str, line);

	    #10; 
	    assert(main_alu_result == main_alu_result_true)
	      $display("main_alu_result is correct");
	    else 
	      $error("main_alu_result is %h, should be %h",
		     main_alu_result, main_alu_result_true);
	    
	    assert(main_alu_zero == main_alu_zero_true)
	      $display("main_alu_zero is correct");
	    else 
	      $error("main_alu_zero is %h, should be %h",
		     main_alu_zero, main_alu_zero_true);
	 end // else: !if(scanned == 0)

	 line++;
      end
   end
   
endmodule
