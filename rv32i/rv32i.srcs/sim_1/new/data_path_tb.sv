module data_path_tb;

   timeunit 1ns;
   timeprecision 10ps;

   parameter TB_ROM_FILE = "../../../../rv32i.srcs/sources_1/new/data_path_tb_rom_image.dat";
   
   bit clk;
   control_bus bus(.clk);
   
   data_path #(.ROM_FILE(TB_ROM_FILE)) dut(.bus);

   initial begin
      clk = 0;
      forever begin
	 #5 clk = ~clk;
      end
   end
   
   // Stimulus
   initial begin

      // Initialise control signals
      /*
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
       */
      
      // Do lui
      @(bus.status_cb)
	bus.status_cb.control_lines.imm_gen_sel <= types::U_TYPE;
	//bus.status_cb.control_lines.mret <= 1'b1;
	//bus.status_cb.test <= 1;
      
      @(bus.status_cb);
      
   end

endmodule
