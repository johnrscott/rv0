module data_path_tb;

   timeunit 1ns;
   timeprecision 10ps;

   parameter TB_ROM_FILE = "../../../../rv32i.srcs/sources_1/new/data_path_tb_rom_image.dat";
   
   logic rstn, clk;
   control_bus bus(.clk, .rstn);
   
   data_path #(.ROM_FILE(TB_ROM_FILE)) dut(.bus);

   // Clock generation
   initial begin
      clk = 0;
      forever begin
	 #5 clk = ~clk;
      end
   end

   // Asynchronous reset
   initial begin
      rstn = 1;
      #12 rstn = 0; // Random async reset
      @(bus.status_cb); // Ensure at east one clock edge
      #13 rstn = 1; // Random delay then deassert
   end
   
   // Stimulus
   initial begin

      // Initialise control signals
      bus.reset_control();
      
      // Wait to come out of reset
      @(bus.status_cb iff rstn);
      
      // Do lui (out of sync with pc?)
      bus.status_cb.register_file_write_en <= 1;
      bus.status_cb.imm_gen_sel <= types::U_TYPE;
      bus.status_cb.register_file_rd_data_sel <= types::LUI_IMM;
      
   end

   // Monitor
   initial begin
      
      // Wait to come out of reset
      @(bus.status_cb iff rstn);

   end
   
endmodule
