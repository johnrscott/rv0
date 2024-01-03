module data_path_tb;

   timeunit 1ns;
   timeprecision 10ps;

   control_bus bus();
   
   data_path dut(.bus);

   initial begin

      // Initialise control signals
      bus.control_lines.mret = 0;
      bus.control_lines.imm_gen_sel = 0;
      bus.control_lines.alu_arg_sel = 0;
      bus.control_lines.data_mem_width = 0;
      bus.control_lines.pc_sel = 0;
      bus.control_lines.csr_wdata_sel = 0;
      bus.control_lines.register_file_write_en = 0;
      bus.control_lines.register_file_rd_data_sel = 0;
      bus.control_lines.data_mem_write_en = 0;
      bus.control_lines.csr_write_en = 0;
      bus.control_lines.trap = 0;
      bus.control_lines.exception_mcause = 0;

      #10;
      
      
   end

endmodule
