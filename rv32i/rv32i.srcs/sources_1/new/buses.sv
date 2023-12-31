import types::control_lines_t;
import types::data_path_status_t;
   
interface control_bus();
   
   control_lines_t control_lines;
   data_path_status_t data_path_status;
   
   modport control (
      output control_lines,
      input  data_path_status
   );

   modport status (
      output data_path_status,
      input  control_lines
   );
   
endinterface: control_bus

interface data_mem_bus();

   bit [31:0] addr; // the read/write address
   bit [1:0]  width; // the width of the read/write (byte, halfword, word)
   bit [31:0] rdata; // read-data returned from device
   bit [31:0] wdata; // write-data passed to device
   bit	      write_en; // whether to perform a write (or just a read)
   bit	      claim; // devices will claim read/write based on address/width


endinterface: data_mem_bus
