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

      clk = 0;
      
      // Check that initial values in memory are zero
      data_mem_width = 0; // set width to read a byte
      for(int addr = 'h2000_0000; addr < 'h2000_0400; addr += 1) begin
	 data_mem_addr = addr;
         #1 assert (data_mem_claim == 1)
           else $error("data_mem_claim not 1 in initial zero check");
         #1 assert (data_mem_rdata == 0)
           else $error("Expected initial state zero");
      end

      // Write values 0, 1, 2, 3, ... to all memory locations
      data_mem_write_en = 1;
      for(int addr = 'h2000_0000; addr < 'h2000_0400; addr += 1) begin

	 // Set the write address and data
	 data_mem_addr = addr;
	 data_mem_wdata = addr - 'h2000_0000; // will write 0, 1, 2, 3, ...

	 // Expect the write to be valid (the signal is
	 // asserted before the write actually happens).
         #1 assert (data_mem_claim == 1)
           else $error("data_mem_claim not 1 in write block 1");

	 // Check the read-data is zero before the write
         #1 assert (data_mem_rdata == 0)
           else $error("data_mem_rdata not 0 before write in write block 1");
	 
	 // Perform the write
	 #1 clk = 1;
	 #1 clk = 0;

	 // Check the read-data is non-zero after the write (mask to
	 // 1 byte)
         #1 assert (data_mem_rdata == ('hff & (addr - 'h2000_0000)))
           else $error("data_mem_rdata is %x, ", data_mem_rdata,
		  "expected %x in write block 1", 'hff & (addr - 'h2000_0000));
      end

      // Check aligned reads of halfwords using current state of memory
      data_mem_write_en = 0;
      data_mem_width = 1;
      for (int addr = 'h2000_0000; addr < 'h2000_0400; addr += 2) begin	 

	 int low_byte, high_byte, halfword;
	 
	 // Set the write address
	 data_mem_addr = addr;

	 // Expect the read to be valid
         #1 assert (data_mem_claim == 1)
           else $error("data_mem_claim not 1 in aligned halfword read");

	 // Check the data is correct
	 low_byte = 'hff & (addr - 'h2000_0000);
	 high_byte = 'hff & (addr + 1 - 'h2000_0000);
	 halfword = (high_byte << 8) | low_byte;
         #1 assert (data_mem_rdata == halfword)
           else $error("data_mem_rdata is %x, ", data_mem_rdata,
		  "expected %x in aligned halfword read", halfword);
	 
      end
      
      // Check aligned reads of words using current state of memory
      data_mem_write_en = 0;
      data_mem_width = 2;
      for (int addr = 'h2000_0000; addr < 'h2000_0400; addr += 4) begin	 

	 int byte_0, byte_1, byte_2, byte_3, word;
	 
	 // Set the write address
	 data_mem_addr = addr;

	 // Expect the read to be valid
         #1 assert (data_mem_claim == 1)
           else $error("data_mem_claim not 1 in aligned halfword read");

	 // Check the data is correct
	 byte_0 = 'hff & (addr - 'h2000_0000);
	 byte_1 = 'hff & (addr + 1 - 'h2000_0000);
	 byte_2 = 'hff & (addr + 2 - 'h2000_0000);
	 byte_3 = 'hff & (addr + 3 - 'h2000_0000);

	 word = (byte_3 << 24) | (byte_2 << 16) | (byte_1 << 8) | byte_0;
         #1 assert (data_mem_rdata == word)
           else $error("data_mem_rdata is %x, ", data_mem_rdata,
		  "expected %x in aligned word read", word);
	 
      end

      // Check non-aligned reads of halfwords

      // Check non-aligned reads of words

      // Check non-aligned write of halfword

      // Check non-aligned write of word

      // Check attempt to write outside valid address range

      // Check attempt to reads outside valid address range


   end
   
endmodule
