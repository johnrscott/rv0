`timescale 1ns / 1ps


module main_mem_tb();

   reg 	   clk;
   reg [31:0] data_mem_addr; // the read/write address bus 
   reg [1:0]  data_mem_width; /// the width of the read/write
   reg [31:0] data_mem_wdata; // data to be written on rising clock edge
   reg 	      data_mem_write_en; // 1 to perform write, 0 otherwise
   wire [31:0] data_mem_rdata; // data out	
   wire        data_mem_claim; // set if this module performed the read/write
   
   main_mem main_mem_0 (
     .clk(clk),
     .data_mem_addr(data_mem_addr),
     .data_mem_width(data_mem_width),
     .data_mem_wdata(data_mem_wdata),
     .data_mem_write_en(data_mem_write_en),
     .data_mem_rdata(data_mem_rdata),
     .data_mem_claim(data_mem_claim)
     );

   initial begin

      // Check that initial values in memory are zero
      data_mem_width = 0; // set width to read a byte
      for(int addr = 'h2000_0000; addr < 'h2000_0400; addr += 1) begin
	 data_mem_addr = addr;
         #1 assert (data_mem_claim == 1)
            else $error("data_mem_claim not 1 in initial zero check");
         #1 assert (data_mem_rdata == 0)
            else $error("Expected initial state zero");
      end

   end
   
endmodule
