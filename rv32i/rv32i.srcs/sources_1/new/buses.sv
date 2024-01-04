import types::control_lines_t;
import types::data_path_status_t;
   
interface control_bus(input bit clk);
   
   control_lines_t control_lines;
   data_path_status_t data_path_status;

   clocking status_cb @(posedge clk);
      default input #2 output #2;
      input data_path_status;
      output control_lines;
   endclocking
   
   modport control (
      output control_lines,
      input  data_path_status
   );

   modport status (
      output data_path_status,
      input  clk, control_lines
   );
   
endinterface: control_bus

interface data_mem_bus #(
   parameter NUM_DEVICES = 2
) (
   output bit [31:0] rdata,
   output bit	     claim,
   input bit [31:0]  addr, wdata,
   input bit [1:0]   width,
   input bit	     write_en,
   input bit	     clk
);

   bit [31:0] dev_rdata[NUM_DEVICES];
   bit	      dev_claim[NUM_DEVICES];

   // Expect all devices except the one that asserts
   // claim to set zero rdata output. OR together all
   // the read-data ports to get the main bus rdata.
   always_comb begin
      rdata = 0;
      for (int n = 0; n < NUM_DEVICES; n++) begin
	 rdata |= dev_rdata[n];
      end
   end

   // Expect only one device to assert the claim signal.
   // OR together the claim signals from each device
   // to get the main bus claim signal (used to determine
   // if any device responded to the read/write request).
   always_comb begin
      claim = 0;
      for (int n = 0; n < NUM_DEVICES; n++) begin
	 claim |= dev_claim[n];
      end
   end
   
   // Device interfaces
   generate
      for (genvar n = 0; n < NUM_DEVICES; n++) begin: dev
	 modport device (
	    output .rdata(dev_rdata[n]), .claim(dev_claim[n]),
	    input  addr, width, wdata, write_en, clk
	 );
      end
   endgenerate
   
endinterface: data_mem_bus

interface csr_bus #(
   parameter NUM_DEVICES = 2
) (
   output bit	     claim,
   output bit [31:0] rdata,
   input [11:0]	     addr,
   input bit [31:0]  wdata,
   input bit	     write_en,
   input bit	     clk
);

   bit [31:0] dev_rdata[NUM_DEVICES];
   bit	      dev_claim[NUM_DEVICES];

   // Expect all devices except the one that asserts
   // claim to set zero rdata output. OR together all
   // the read-data ports to get the main bus rdata.
   always_comb begin
      rdata = 0;
      for (int n = 0; n < NUM_DEVICES; n++) begin
	 rdata |= dev_rdata[n];
      end
   end

   // Expect only one device to assert the claim signal.
   // OR together the claim signals from each device
   // to get the main bus claim signal (used to determine
   // if any device responded to the read/write request).
   always_comb begin
      claim = 0;
      for (int n = 0; n < NUM_DEVICES; n++) begin
	 claim |= dev_claim[n];
      end
   end
   
   // Device interfaces
   generate
      for (genvar n = 0; n < NUM_DEVICES; n++) begin: dev
	 modport device (
	    output .rdata(dev_rdata[n]), .claim(dev_claim[n]),
	    input  addr, wdata, write_en, clk
	 );
      end
   endgenerate
   
endinterface: csr_bus
