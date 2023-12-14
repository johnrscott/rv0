`timescale 1ns / 1ps
module register_file_tb();

    reg [31:0] d = 0; // data for write
    reg [4:0] rna = 0; // source register index A
    reg [4:0] rnb = 0; // source register index B
    reg [4:0] wn = 0; // destination register index for write
    reg we = 0; // write enable
    reg clk = 0; // clock
    wire [31:0] qa; // read port A
    wire [31:0] qb; // read port B
    
    register_file register_file_0(
        .d(d),
        .rna(rna),
        .rnb(rnb),
        .wn(wn),
        .we(we),
        .clk(clk),
        .qa(qa),
        .qb(qb)
        );

    initial begin
        // Check the initial values of the registers are all zero
        for (int n = 0; n < 32; n++) begin
            rna = n;
            rnb = n;
            #1 assert (qa == 0) else $error("Initial value of qa is wrong");
            #1 assert (qb == 0) else $error("Initial value of qb is wrong");
        end
    
        // Try writing to each register in turn and reading the value back
        #1 we = 1; 
        for (int n = 0; n < 32; n++) begin
            // Set register write index and data
            wn = n;
            d = 2*n + 3; // to ensure that x0 is written with non-zero value
            
            // Set the read address so that the output changes directly on
            // the write clk edge
            rna = n;
            rnb = n;
            
            // Use rising edge of clock to write data 
            #1 clk = 1;
            #1 clk = 0;
            
            // Check that the data was written by reading both ports
            if (n == 0) begin
                // Expect x0 to always be zero
                #1 assert (qa == 0) else $error("Value of qa (x0) is wrong after write");
                #1 assert (qb == 0) else $error("Value of qb (x0) is wrong after write");
            end else begin 
                #1 assert (qa == 2*n + 3) else $error("Value of qa is wrong (not x0)");
                #1 assert (qb == 2*n + 3) else $error("Value of qa is wrong (not x0)");               
            end       
            
        end     
        
        // Now check that a register keeps its previous value after "writing"
        // when the write enable is deasserted. The last value of x1 is 
        // 5.
        rna = 1;
        rnb = 1;
        #1 assert (qa == 5) else $error("Value of qa (x1) is not 5");
        #1 assert (qb == 5) else $error("Value of qa (x1) is not 5");
        
        // Deassert write enable
        #1 we = 0;
        
        // New data to "write"
        #1 d = 6;
        
        // Rising clock edge (attempt to write)
        #1 clk = 1;
        #1 clk = 0;
        
        // Expect values to remain unchanged
        #1 assert (qa == 5) else $error("Value of qa (x1) did not remain 5");
        #1 assert (qb == 5) else $error("Value of qa (x1) did not remain 5");      
    
    end

endmodule
