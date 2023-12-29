`timescale 1ns / 1ps

/// Timer interrupt
///
/// This module manages the mtime and mtimecmp
/// registers, and serves the timer interrupt
/// pending bit (mtip).
///
/// The 64-bit mtime and mtimecmp registers are
/// memory mapped at 1000_bff8 and 1000_4000
/// respectively.
///
/// The mtime register is also exposed as two
/// read-only CSRs, time and timeh, at addresses
/// c01 and c81 respectively.
///
/// The timer interrupt (mtip) becomes pending exactly
/// when mtime >= mtimecmp.
///
module timer_int(

  input 	      clk, // mtime increments on rising clock edge
  
  // Data memory read/write port
  input [31:0] 	      data_mem_addr, // the read/write address bus 
  input [1:0] 	      data_mem_width, /// the width of the read/write
  input [31:0] 	      data_mem_wdata, // data to be written on rising clock edge
  input 	      data_mem_write_en, // 1 to perform write, 0 otherwise
  output logic [31:0] data_mem_rdata, // data out	
  output 	      data_mem_claim, // set if this module claims the data memory access

  // CSR bus read/write port
  input [11:0] 	      csr_addr, // CSR address. Used to claim a CSR read/write.
  input [31:0] 	      csr_wdata, // data to write to the CSR
  input 	      csr_write_en, // 1 to write on rising clock edge
  output logic [31:0] csr_rdata, // CSR read data
  output 	      csr_claim, // 1 if this module owns the CSR addr
  output 	      illegal_instr, // 1 if illegal instruction should be raised

  // Timer interrupt pending bit
  output 	      mtip

  );

   logic [63:0] mtime = 0, mtimecmp = 0;
   
   assign mtip = (mtime >= mtimecmp);

   always_ff @(posedge clk) begin
      mtime <= mtime + 1;
   end

   // CSR interface for time and timeh
   assign csr_claim = (csr_addr == 'hc01) | (csr_addr == 'hc81);
   assign illegal_instr = csr_write_en; // time/timeh are read-only

   always_comb begin
      case(csr_addr)
	'hc01: csr_rdata = mtime[31:0]; //time
	'hc81: csr_rdata = mtime[63:32]; //timeh
	default: csr_rdata = 0;
      endcase
   end

   // Address range validity
   logic addr_is_mtime, addr_is_mtimecmp;
   always_comb begin
      addr_is_mtime = 0;
      addr_is_mtimecmp = 0;
      case (data_mem_width)
	0: addr_is_mtime = (data_mem_addr >= 'h1000_bff8) && (data_mem_addr < 'h1000_c000);
	1: addr_is_mtime = (data_mem_addr >= 'h1000_bff8) && (data_mem_addr < 'h1000_bfff);
	2: addr_is_mtime = (data_mem_addr >= 'h1000_bff8) && (data_mem_addr < 'h1000_bffd);
      endcase
      case (data_mem_width)
	0: addr_is_mtimecmp = (data_mem_addr >= 'h1000_4000) && (data_mem_addr < 'h1000_4008);
	1: addr_is_mtimecmp = (data_mem_addr >= 'h1000_4000) && (data_mem_addr < 'h1000_4007);
	2: addr_is_mtimecmp = (data_mem_addr >= 'h1000_4000) && (data_mem_addr < 'h1000_4005);
      endcase
   end

   assign data_mem_claim = addr_is_mtime || addr_is_mtimecmp;
   
   // Map address range for mtime and mtimecmp
   logic [3:0] start_addr;
   always_comb begin
      if (addr_is_mtime)
	start_addr = data_mem_addr - 'h1000_bff8;
      else if (addr_is_mtimecmp)
	start_addr = data_mem_addr - 'h1000_4000;
   end

   // Map bytes of mtime/mtimecmp
   logic [7:0] reg_bytes[8];
   always_comb begin
      reg_bytes = '{default: '0};
      if (addr_is_mtime) begin
	 reg_bytes[0] = mtime[0+:8];
	 reg_bytes[1] = mtime[8+:8];
	 reg_bytes[2] = mtime[16+:8];
	 reg_bytes[3] = mtime[24+:8];
	 reg_bytes[4] = mtime[32+:8];
	 reg_bytes[5] = mtime[40+:8];
	 reg_bytes[6] = mtime[48+:8];
	 reg_bytes[7] = mtime[56+:8];
      end else if (addr_is_mtimecmp) begin
	 reg_bytes[0] = mtimecmp[0+:8];
	 reg_bytes[1] = mtimecmp[8+:8];
	 reg_bytes[2] = mtimecmp[16+:8];
	 reg_bytes[3] = mtimecmp[24+:8];
	 reg_bytes[4] = mtimecmp[32+:8];
	 reg_bytes[5] = mtimecmp[40+:8];
	 reg_bytes[6] = mtimecmp[48+:8];
	 reg_bytes[7] = mtimecmp[56+:8];
      end
   end

   // Map bytes of data_mem_rdata
   logic [7:0] rdata_bytes[4];
   assign rdata_bytes[0] = data_mem_rdata[0+:8];
   assign rdata_bytes[1] = data_mem_rdata[8+:8];
   assign rdata_bytes[2] = data_mem_rdata[16+:8];
   assign rdata_bytes[3] = data_mem_rdata[24+:8];
   
   // Read mtime and mtimecmp
   always_comb begin
      if (addr_is_mtime) begin
	 case (data_mem_width)
	   0: begin
	      rdata_bytes[0] = reg_bytes[start_addr]; 
	   end
	   1: begin
	      rdata_bytes[0] = reg_bytes[start_addr]; 
	      rdata_bytes[1] = reg_bytes[start_addr + 1];
	   end
	   2: begin
	      rdata_bytes[0] = reg_bytes[start_addr]; 
	      rdata_bytes[1] = reg_bytes[start_addr + 1];
	      rdata_bytes[2] = reg_bytes[start_addr + 2];
	      rdata_bytes[3] = reg_bytes[start_addr + 3];
	   end
	 endcase
      end
   end
	 
   
endmodule
