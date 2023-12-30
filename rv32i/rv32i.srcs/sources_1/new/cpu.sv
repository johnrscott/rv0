import types::control_lines_t;

`define ROM_MEM_FILE "rom_image.mem"

module cpu #(
  parameter string ROM_FILE = "rom_image.mem")
   (
  input clk, meip
		   );
   
   logic [31:0] instr;   
   logic	data_mem_claim, csr_claim, data_path_illegal_instr,
		instr_addr_mis, instr_access_fault;

   control_lines_t control_lines;
   data_path_status_t data_path_status;
   
   control_unit control_unit_0(
      .data_path_status(data_path_status),
      .control_lines(control_lines)
   );

   data_path #(.ROM_FILE(ROM_FILE)) data_path_0 (
      .clk(clk),
      .meip(meip),
      .control_lines(control_lines),
      .data_path_status(data_path_status)
   );
     
   
endmodule
