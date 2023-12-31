/// Main Memory
///
/// This is the main memory devcie (RAM). It
/// is attached to the data memory bus, and
/// responds to reads/writes within the main
/// memory address range.
///
/// Read/write width is encoded as follows:
/// 0: byte
/// 1: halfword
/// 2: word
///
/// The address range for main memory in this
/// device is 2000_0000 - 2000_0400 (hex). 
/// If the read or write falls wholly within
/// this range (depending on both the address
/// and the width), then data_mem_claim is
/// asserted, and the read or write is performed.
///
/// Reads are combinational; if the address/width
/// is valid (see above), the data_mem_rdata contains
/// the output data (zero-extended). If the 
/// data_mem_claim bit is not set, the data_mem_rdata
/// output is guaranteed to be zero.
///
/// Write data is written on the rising clock edge,
/// if address/width is valid and the write enable
/// bit is set.
///
/// Reads and writes do not need to be aligned.
module main_mem(
   data_mem_bus bus
);
   
   reg [7:0] mem_bytes[1024] = '{default: '0};    
   
   reg [31:0] rdata_internal;
   
   // First byte to read/write in mem_bytes
   wire [9:0] first_byte;
   
   // Last byte to read/write
   reg [9:0]  last_byte;
   
   assign first_byte = bus.addr[9:0];
   
   // Calculate the last byte address and check
   // that the read/write is entirely inside
   // the valid address range
   always @* begin
      last_byte = first_byte;
      case(bus.width)
        1: last_byte = first_byte + 1;
        2: last_byte = first_byte + 3;
      endcase
   end
   
   // Calculate real address and read data 
   always @* begin
      rdata_internal = { 24'd0, mem_bytes[first_byte] };
      case(bus.width)
        1: begin
           rdata_internal[7:0] = mem_bytes[first_byte];
           rdata_internal[15:8] = mem_bytes[first_byte + 1];
           
        end
        2: begin
           rdata_internal[7:0] = mem_bytes[first_byte];
           rdata_internal[15:8] = mem_bytes[first_byte + 1];
           rdata_internal[23:16] = mem_bytes[first_byte + 2];
           rdata_internal[31:24] = mem_bytes[first_byte + 3];
        end
      endcase
   end
   
   // Write data provided the address is in range and write is
   // enabled
   always @(posedge bus.clk) begin
      if(bus.claim && bus.write_en) begin
         mem_bytes[first_byte] = bus.wdata[7:0];
         case(bus.width) 
           1: begin
              mem_bytes[first_byte] = bus.wdata[7:0];
              mem_bytes[first_byte + 1] = bus.wdata[15:8];
           end
           2: begin
              mem_bytes[first_byte] = bus.wdata[7:0];
              mem_bytes[first_byte + 1] = bus.wdata[15:8];         
              mem_bytes[first_byte + 2] = bus.wdata[23:16];
              mem_bytes[first_byte + 3] = bus.wdata[31:24];         
           end
         endcase        
      end
   end
   
   // The read/write is only valid if the
   // upper 22 bits of data_mem_addr are
   // correct, and last_byte is larger
   // than first_byte.
   assign bus.claim = (bus.addr[31:10] == 'h8000_0) && (first_byte <= last_byte);
   
   // Set the output read data only if data_mem_claim is set
   assign bus.rdata = bus.claim ? rdata_internal : 0;
   
endmodule
