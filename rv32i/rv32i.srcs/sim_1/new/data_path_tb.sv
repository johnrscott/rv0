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
      bus.reset_control();
      
      // Do lui
      @(bus.status_cb)
	//bus.status_cb.imm_gen_sel <= types::U_TYPE;
	bus.status_cb.trap <= 1;
      
   end

endmodule
