module data_path_tb;

   timeunit 1ns;
   timeprecision 10ps;

   parameter TB_ROM_FILE = "../../../../rv32i.srcs/sources_1/new/data_path_tb_rom_image.dat";
   
   bit clk, rstn;
   control_bus bus(.clk);
   
   data_path #(.ROM_FILE(TB_ROM_FILE)) dut(.bus);

   initial begin
      clk = 0;
      rstn = 1;
      forever begin
	 #5 clk = ~clk;
      end
   end
   
   // Stimulus
   initial begin

      // Reset the data path
      @(bus.status_cb) rstn = 0;
      @(bus.status_cb) rstn = 1;
      
      // Initialise control signals
      bus.reset_control();
      
      // Do lui
      @(bus.status_cb) begin
	 bus.status_cb.register_file_write_en <= 1;
	 bus.status_cb.register_file_rd_data_sel <= types::MAIN_ALU_RESULT;
      end
      
      
      
   end

endmodule
