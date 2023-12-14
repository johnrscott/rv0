`timescale 1ns / 1ps

module shift_tb();

    reg [31:0] d = 32'h0000_0f00; // 32-bit data to shift
    reg [4:0] shamt = 0; // left or right shift amount
    reg right = 0; // 1 to shift right, 0 to shift left
    reg arith = 0; // if right shift, 1 for arithmetic, 0 for logical
    wire [31:0] shifted; // shifted result

    shift shift_0 (
        .d(d),
        .shamt(shamt),
        .right(right),
        .arith(arith),
        .shifted(shifted)
        );
       
    initial begin
    
        // For the arguments with their initial values,
        // check the output is unshifted
        #1 assert (shifted == 32'h0000_0f00)
            else $error("Initial shifted output wrong");
    
        // Update the shift amount to 8 bits and test output
        shamt = 8;
        # 1 assert (shifted == 32'h000f_0000)
            else $error("wrong after right shift by 8");
    
        // Now set the right shift input and chek result
        shamt = 8;
        right = 1;
        # 1 assert (shifted == 32'h0000_000f)
            else $error("wrong after left shift by 8");       
    
        // Check a logical right shift
        d = 32'h8000_0000;
        shamt = 3;
        right = 1;
        arith = 0;
        # 1 assert (shifted == 32'h1000_0000)
            else $error("wrong after logical right shift by 3");  
            
        // Check an arithmetic right shift         
        d = 32'h8000_0000;
        shamt = 3;
        right = 1;
        arith = 1;
        # 1 assert (shifted == 32'hf000_0000)
            else $error("wrong after arithmetic right shift by 3");          
    
    end

endmodule
