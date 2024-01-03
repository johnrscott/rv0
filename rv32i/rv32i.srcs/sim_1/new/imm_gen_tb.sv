import types::instr_format_t;

module imm_gen_tb;

   timeunit 1ns;
   timeprecision 10ps;
   
   int fd, scanned;
   bit [31:0] instr;
   bit [31:0] imm, imm_true;
   string     instr_type;
   instr_format_t sel;

   imm_gen dut(.sel, .instr, .imm);

   always_comb begin
      case (instr_type)
	"r_type": sel = types::R_TYPE;
	"i_type": sel = types::I_TYPE;
	"s_type": sel = types::S_TYPE;
	"b_type": sel = types::B_TYPE;
	"u_type": sel = types::U_TYPE;
	"j_type": sel = types::J_TYPE;
	"csr_r_type": sel = types::CSR_R_TYPE;
	"csr_i_type": sel = types::CSR_I_TYPE;
	default: sel = types::I_TYPE;
      endcase
   end
   
   initial begin
      // There must be a way to fix this path (it is relative to xsim folder)
      fd = $fopen("../../../../rv32i.srcs/sim_1/new/imm_gen_tb_vectors.csv", "r");
      while ((fd != 0) && !$feof(fd)) begin
	 scanned = $fscanf(fd, "%s %h %h", instr_type, instr, imm_true);
	 if (scanned == 0) begin
	    
	    $fclose(fd);
	    $finish();   
	 end
	 else begin
	    
	    $display("Checking instruction %h (%s)", instr, instr_type);
	    #10 assert(imm == imm_true) $display("Success"); 
		else $display("Failed: expected imm = %h, got %h", imm_true, imm);
	    
	 end
      end
   end
   
endmodule
