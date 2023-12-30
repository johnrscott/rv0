typedef struct {
   bit           mret;			    // whether the data path should execute an mret
   bit [2:0]	 imm_gen_sel;		    // select which immediate format to extract
   bit [2:0]	 alu_arg_sel;		    // pick the ALU operation
   bit [1:0]	 data_mem_width;	    // pick the load/store access width
   bit [1:0]	 pc_sel;		    // choose how to calculate the next program counter
   bit [1:0]	 trap_ctrl_csr_wdata_sel;   // pick write data source for CSR bus
   bit		 register_file_write_en;    // whether to write to rd
   bit [2:0]	 register_file_rd_data_sel; // select source for write to rd
   bit		 data_mem_write_en;	    // whether to write to data memory bus
   bit		 csr_write_en;		    // whether to write to CSR bus
   bit		 trap;			    // whether to execute an (interrupt or exception) trap
   bit [31:0]	 exception_mcause;	    // for an exception, what is the mcause value
} control_lines_t;
  
