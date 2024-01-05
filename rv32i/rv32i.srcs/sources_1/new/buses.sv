import types::instr_format_t;
import types::alu_arg_sel_t;
import types::width_t;
import types::pc_sel_t;
import types::csr_wdata_sel_t;
import types::rd_data_sel_t;

interface control_bus(input logic clk, rstn);
     
   // Originally the signals in this interface
   // were bundled into two structs (control_lines_t
   // and data_path_status_t), which makes writing
   // the modports and clocking blocks more concise.
   // However, due to a Vivado bug this causes a
   // simulation problem:
   //
   // https://support.xilinx.com/s/question/
   // 0D54U00007ZIGfXSAX/xsim-bug-xsim-does-
   // not-simulate-struct-assignments-in-c
   // locking-blocks-correctly?language=en_US
   //
   
   // Control lines
   instr_format_t imm_gen_sel;           // select which immediate format to extract
   alu_arg_sel_t alu_arg_sel;	    // pick the ALU operation
   width_t	 data_mem_width;	    // pick the load/store access width
   pc_sel_t	 pc_sel;		    // choose how to calculate the next program counter
   csr_wdata_sel_t csr_wdata_sel;             // pick write data source for CSR bus
   logic	 register_file_write_en;    // whether to write to rd
   rd_data_sel_t register_file_rd_data_sel; // select source for write to rd
   logic	 data_mem_write_en;	    // whether to write to data memory bus
   logic	 csr_write_en;		    // whether to write to CSR bus
   logic	 trap;			    // whether to execute an (interrupt or exception) trap
   logic	 mret;			    // whether the data path should execute an mret
   logic [31:0]	 exception_mcause;	    // for an exception, what is the mcause value
   
   // Data path status
   logic [31:0]	 instr;				// instruction at current program counter
   logic	 instr_addr_mis;		// instruction address misaligned
   logic	 instr_access_fault;		// instruction access fault
   logic	 interrupt;			// is an interrupt pending?	 
   logic	 data_mem_claim;		// has any device claimed data read/write?
   logic	 csr_claim;			// has any device claimed CSR bus read/write?
   logic	 main_alu_result;               // logic 0 used for conditional branch
   logic	 main_alu_zero;                 // used for conditional branch
   
   clocking status_cb @(posedge clk);
      default input #2 output #2;
      input instr, instr_addr_mis, instr_access_fault,
	    interrupt, data_mem_claim, csr_claim,
	    main_alu_result, main_alu_zero;
      output imm_gen_sel, alu_arg_sel, data_mem_width,
	     pc_sel, csr_wdata_sel, register_file_write_en,
	     register_file_rd_data_sel, data_mem_write_en,
	     csr_write_en, trap, mret, exception_mcause;
   endclocking
   
   modport control (
      output imm_gen_sel, alu_arg_sel, data_mem_width,
	     pc_sel, csr_wdata_sel, register_file_write_en,
	     register_file_rd_data_sel, data_mem_write_en,
	     csr_write_en, trap, mret, exception_mcause,
      input  instr, instr_addr_mis, instr_access_fault,
	     interrupt, data_mem_claim, csr_claim,
	     main_alu_result, main_alu_zero
   );

   modport status (
      output instr, instr_addr_mis, instr_access_fault,
	     interrupt, data_mem_claim, csr_claim,
	     main_alu_result, main_alu_zero,
      input  clk, rstn, imm_gen_sel, alu_arg_sel, data_mem_width,
	     pc_sel, csr_wdata_sel, register_file_write_en,
	     register_file_rd_data_sel, data_mem_write_en,
	     csr_write_en, trap, mret, exception_mcause
   );

   /// Set the control lines to default values (register.
   /// and memory writes disabled, but otherwise similar
   /// to register-register instruction). Used for
   /// synthesis as well as simulation.
   task reset_control;
      imm_gen_sel = types::I_TYPE; // don't care
      alu_arg_sel = types::RS1_RS2;
      data_mem_width = types::WIDTH_BYTE; // don't care
      pc_sel = types::PC_SEL_PC_PLUS_4;
      csr_wdata_sel = types::CSR_WDATA_RS1; // don't care
      register_file_write_en = 0; // write disabled
      register_file_rd_data_sel = types::MAIN_ALU_RESULT;
      data_mem_write_en = 0;
      csr_write_en = 0;
      trap = 0;
      mret = 0;
      exception_mcause = 0;
   endtask
   
endinterface: control_bus

interface data_mem_bus #(
   parameter NUM_DEVICES = 2
) (
   output bit [31:0] rdata,
   output bit	     claim,
   input bit [31:0]  addr, wdata,
   input	     width_t width,
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
