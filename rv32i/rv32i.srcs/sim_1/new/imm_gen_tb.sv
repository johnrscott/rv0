import types::instr_format_t;

module imm_gen_tb;

   int fd, scanned;
   bit [31:0] instr;
   bit [31:0] imm;
   string     instr_type;
   instr_format_t sel;

   imm_gen dut(.sel, .instr, .imm);

   always_comb begin
      case (instr_type)
	"u_type": sel = types::U_TYPE;
	default: sel = types::I_TYPE;
      endcase
   end
   
   initial begin
      fd = $fopen("imm_gen_tb_vectors.csv", "r");
      while ((fd != 0) && !$feof(fd)) begin
	 scanned = $fscanf(fd, "%s %h %h", instr_type, instr, imm);
	 if (scanned == 0) begin
	    
	    $fclose(fd);
	    $finish();   
	 end
	 else begin
	    
	    $display("Checking instruction %h (%s)", instr, instr_type);
	    
	 end
      end
   end
   
endmodule
