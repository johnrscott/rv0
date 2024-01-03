import types::instr_format_t;
import types::instr_t;

// This testbench reads from the file imm_gen_tb_vectors.csv,
// which has the following (space separated format):
//
// instr_type instr_hex imm_dec
//
// The instr_type field is {i,s,b,u,j,csr_i}_type, and the instr_hex
// is the 32-bit instruction. Note that the immediate is specified
// in decimal (with an optional sign).
//
// The test vectors in the file were generated using this online
// decoder: https://luplab.gitlab.io/rvcodecjs/
module imm_gen_tb;

   timeunit 1ns;
   timeprecision 10ps;
   
   int fd, scanned;
   instr_t instr;
   bit [31:0] imm, imm_true;
   string     instr_type;
   instr_format_t sel;

   imm_gen dut(.sel, .instr, .imm);

   always_comb begin
      case (instr_type)
	"i_type": sel = types::I_TYPE;
	"s_type": sel = types::S_TYPE;
	"b_type": sel = types::B_TYPE;
	"u_type": sel = types::U_TYPE;
	"j_type": sel = types::J_TYPE;
	"csr_i_type": sel = types::CSR_I_TYPE;
	default: begin
	   $error("Got unsupported instruction type.");
	   $finish();
	end
      endcase
   end
   
   initial begin
      // There must be a way to fix this path (it is relative to xsim folder)
      fd = $fopen("../../../../rv32i.srcs/sim_1/new/imm_gen_tb_vectors.csv", "r");
      while ((fd != 0) && !$feof(fd)) begin
	 scanned = $fscanf(fd, "%s %h %d", instr_type, instr, imm_true);
	 if (scanned == 0) begin
	    $fclose(fd);
	    $finish();   
	 end
	 else begin
	    $display("Checking instruction %h (%s)", instr, instr_type);
	    #10 assert(imm == imm_true) $display("Success"); 
		else begin
		   $display("Failed: expected imm = %d, got %d", imm_true, imm);
		   $finish();
		end
	    
	 end
      end
   end
   
endmodule
