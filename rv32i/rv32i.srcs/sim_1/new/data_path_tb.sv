import types::control_lines_t;
import types::data_path_status_t;

module data_path_tb;

   timeunit 1ns;
   timeprecision 10ps;

   parameter TB_ROM_FILE = "data_path_tb_rom_file.mem";
   
   control_lines_t control_lines;
   data_path_status_t data_path_status;
   
   control_bus bus();

   assign control_lines = bus.control_lines;
   assign data_path_status = bus.data_path_status;
   
   data_path #(.ROM_FILE(TB_ROM_FILE)) dut(.bus);

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

      
   end

endmodule
