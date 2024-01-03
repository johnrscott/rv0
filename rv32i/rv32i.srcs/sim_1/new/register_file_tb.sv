`timescale 1ns / 1ps
module register_file_tb();

   reg [31:0] rd_data = 0; // data for write
    reg [4:0] rs1 = 0; // source register index A
    reg [4:0] rs2 = 0; // source register index B
    reg [4:0] rd = 0; // destination register index for write
    reg write_en = 0; // write enable
    reg clk = 0; // clock
    wire [31:0] rs1_data; // read port A
    wire [31:0] rs2_data; // read port B
    
    register_file register_file_0(
        .rs1(rs1),
        .rs2(rs2),
        .rd_data(rd_data),
        .rd(rd),
        .write_en(write_en),
        .clk(clk),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
        );

    initial begin
        // Check the initial values of the registers are all zero
        for (int n = 0; n < 32; n++) begin
            rs1 = n;
            rs2 = n;
            #1 assert (rs1_data == 0) else $error("Initial value of rs1_data is wrong");
            #1 assert (rs2_data == 0) else $error("Initial value of rs2_data is wrong");
        end
    
        // Try writing to each register in turn and reading the value back
        #1 write_en = 1; 
        for (int n = 0; n < 32; n++) begin
            // Set register write index and data
            rd = n;
            rd_data = 2*n + 3; // to ensure that x0 is written with non-zero value
            
            // Set the read address so that the output changes directly on
            // the write clk edge
            rs1 = n;
            rs2 = n;
            
            // Use rising edge of clock to write data 
            #1 clk = 1;
            #1 clk = 0;
            
            // Check that the data was written by reading both ports
            if (n == 0) begin
                // Expect x0 to always be zero
                #1 assert (rs1_data == 0) else $error("Value of rs1_data (x0) is wrong after write");
                #1 assert (rs2_data == 0) else $error("Value of rs2_data (x0) is wrong after write");
            end else begin 
                #1 assert (rs1_data == 2*n + 3) else $error("Value of rs1_data is wrong (not x0)");
                #1 assert (rs2_data == 2*n + 3) else $error("Value of rs1_data is wrong (not x0)");               
            end       
            
        end     
        
        // Now check that a register keeps its previous value after "writing"
        // when the write enable is deasserted. The last value of x1 is 
        // 5.
        rs1 = 1;
        rs2 = 1;
        #1 assert (rs1_data == 5) else $error("Value of rs1_data (x1) is not 5");
        #1 assert (rs2_data == 5) else $error("Value of rs1_data (x1) is not 5");
        
        // Deassert write enable
        #1 write_en = 0;
        
        // New data to "write"
        #1 rd_data = 6;
        
        // Rising clock edge (attempt to write)
        #1 clk = 1;
        #1 clk = 0;
        
        // Expect values to remain unchanged
        #1 assert (rs1_data == 5) else $error("Value of rs1_data (x1) did not remain 5");
        #1 assert (rs2_data == 5) else $error("Value of rs1_data (x1) did not remain 5");      
    
    end

endmodule
