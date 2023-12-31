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

interface data_mem_bus #(
   parameter NUM_DEVICES = 2
) (
   
);

   bit [31:0] addr;
   bit [1:0]  width;
   bit [31:0] rdata[NUM_DEVICES];
   bit [31:0] wdata;
   bit	      write_en;
   bit	      claim[NUM_DEVICES];

   // Expect all devices except the one that asserts
   // claim to set zero rdata output. OR together all
   // the read-data ports to get the main bus rdata.
   bit [31:0] rdata_all;
   assign rdata_all = rdata.or();

   // Expect only one device to assert the claim signal.
   // OR together the claim signals from each device
   // to get the main bus claim signal (used to determine
   // if any device responded to the read/write request).
   bit claim_all;
   assign claim_all = claim.or();
   
   // Bus controller interface
   modport host (
      output addr, width, wdata, write_en,
      input  .rdata(rdata_all), .claim(claim_all)
   );

   // Device interfaces
   generate
      for (genvar n = 0; n < NUM_DEVICES; n++) begin
	 modport device (
	    output .rdata(rdata[n]), .claim(claim[n]),
	    input  addr, width, wdata, write_en
	 );
      end
   endgenerate
   
endinterface: data_mem_bus
