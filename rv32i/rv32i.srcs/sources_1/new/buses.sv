import types::control_lines_t;
import types::data_path_status_t;
   
interface control_bus();
   
   control_lines_t control_lines;
   data_path_status_t data_path_status;
   
   modport control (
      output control_lines,
      input  data_path_status
   );

   modport status (
      output data_path_status,
      input  control_lines
   );
   
endinterface: control_bus
