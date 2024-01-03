import types::alu_op_t;

module alu_tb();
   
   reg [31:0] a = 32'h4321_dcba; // First 32-bit operand
   reg [31:0] b = 32'h1234_abcd; // Second 32-bit operand
   alu_op_t alu_op = {op_mod:0, op:0}; // ALU control signals (see comments above)
   wire [31:0] r; // 32-bit result
   wire	       zero; // 1 if r is zero, 0 otherwise
   
   alu alu_0(
      .a(a),
        .b(b),
        .alu_op(alu_op),
        .r(r),
        .zero(zero)
        );
    
    initial begin
    
        // Check addition works
        alu_op = { op_mod:0, op:types::FUNCT3_ADD };
        #1 assert (r == 32'h5556_8887)
            else $error("Addition result is wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");
        
        // Check subtraction works
        alu_op = { op_mod:1, op:types::FUNCT3_ADD };
        #1 assert (r == 32'h30ed_30ed)
            else $error("Subtraction result is wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");
                             
        // Check logical and
        alu_op = { op_mod:0, op:types::FUNCT3_AND };
        #1 assert (r == 32'h0220_8888)
            else $error("AND result is wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");        
          
        // Check logical or
        alu_op = { op_mod:0, op:types::FUNCT3_OR };
        #1 assert (r == 32'h5335_ffff)
            else $error("OR result is wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");    
              
        // Check logical xor
        alu_op = { op_mod:0, op:types::FUNCT3_XOR };
        #1 assert (r == 32'h5115_7777)
            else $error("XOR result is wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");           
             
        // Check set-if-less-than unsigned (not less than)
        alu_op = { op_mod:0, op:types::FUNCT3_SLTU };
        #1 assert (r == 0)
            else $error("set-if-less-than (unsigned) result is wrong");
        #1 assert (zero == 1)
            else $error("Expected zero to be asserted");
            
        // Check set-if-less-than unsigned (is less than)
        a = 1;
        b = 2;
        alu_op = { op_mod:0, op:types::FUNCT3_SLTU };
        #1 assert (r == 1)
            else $error("set-if-less-than (unsigned) result is wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");                     
        
        // Check set-if-less-than signed (not less than)
        a = -1;
        b = -2;
        alu_op = { op_mod:0, op:types::FUNCT3_SLT };
        #1 assert (r == 0)
            else $error("set-if-less-than (signed) result is wrong");
        #1 assert (zero == 1)
            else $error("Expected zero to be asserted");
            
        // Check set-if-less-than signed (is less than)
        a = -5;
        b = 4;
        alu_op = { op_mod:0, op:types::FUNCT3_SLT };
        #1 assert (r == 1)
            else $error("set-if-less-than (signed) result is wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");        
             
        // Check shifts (duplicates the shift test bench
        // but tests the ALU control signals)
        a = 32'h0000_0f00; // data to be shifted
        b = 0; // shift amount
        alu_op = { op_mod:0, op:types::FUNCT3_SLL };
        
        // Check the output is unshifted
        #1 assert (r == 32'h0000_0f00)
            else $error("Ushifted output wrong");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");
    
        // Update the shift amount to 8 bits and test output
        b = 8;
        #1 assert (r == 32'h000f_0000)
            else $error("wrong after left shift by 8");
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");
    
        // Now set the right shift input and check result
        b = 8;
        alu_op = { op_mod:0, op:types::FUNCT3_SRL };
        #1 assert (r == 32'h0000_000f)
            else $error("wrong after left shift by 8");       
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");
    
        // Check a logical right shift
        a = 32'h8000_0000;
        b = 3;
        alu_op = { op_mod:0, op:types::FUNCT3_SRL };
        #1 assert (r == 32'h1000_0000)
            else $error("wrong after logical right shift by 3");  
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");
            
        // Check an arithmetic right shift         
        a = 32'h8000_0000;
        b = 3;
        alu_op = { op_mod:1, op:types::FUNCT3_SRL };
        #1 assert (r == 32'hf000_0000)
            else $error("wrong after arithmetic right shift by 3");  
        #1 assert (zero == 0)
            else $error("Unexpected zero asserted");
            
        
        
    end
    
endmodule
