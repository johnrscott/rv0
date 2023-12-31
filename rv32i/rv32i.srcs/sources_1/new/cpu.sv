`define ROM_MEM_FILE "rom_image.mem"

module cpu #(parameter string ROM_FILE = "rom_image.mem") (
   input clk, meip
);

   control_bus bus();
   control_unit control_unit(.bus);
   data_path #(.ROM_FILE(ROM_FILE)) data_path (.clk, .meip, .bus);

endmodule
