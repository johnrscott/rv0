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

   // Data memory interface for mtime and mtimecmp
   logic first_byte = data_mem_addr;
   logic last_byte;
   always_comb begin
      last_byte = first_byte;
      case(data_mem_width)
	1: last_byte = first_byte + 1;
	2: last_byte = first_byte + 3;
      endcase
   end

   logic addr_is_mtime = (first_byte >= 'h1000_bff8)
	 && (last_byte < 'h1000_c000);

   logic addr_is_mtimecmp = (first_byte >= 'h1000_4000)
	 && (last_byte < 'h1000_4008);

   assign data_mem_claim = addr_is_mtime | addr_is_mtimecmp;

   // Expose mtime bytes for convenience
   logic [7:0] mtime_bytes[8];
   assign mtime_bytes[0] = mtime[7:0];
   assign mtime_bytes[1] = mtime[15:8];
   assign mtime_bytes[2] = mtime[23:16];
   assign mtime_bytes[3] = mtime[31:24];
   assign mtime_bytes[4] = mtime[39:32];
   assign mtime_bytes[5] = mtime[47:40];
   assign mtime_bytes[6] = mtime[55:48];
   assign mtime_bytes[7] = mtime[63:56];

   // Expose mtime bytes for convenience
   logic [7:0] mtimecmp_bytes[8];
   assign mtimecmp_bytes[0] = mtimecmp[7:0];
   assign mtimecmp_bytes[1] = mtimecmp[15:8];
   assign mtimecmp_bytes[2] = mtimecmp[23:16];
   assign mtimecmp_bytes[3] = mtimecmp[31:24];
   assign mtimecmp_bytes[4] = mtimecmp[39:32];
   assign mtimecmp_bytes[5] = mtimecmp[47:40];
   assign mtimecmp_bytes[6] = mtimecmp[55:48];
   assign mtimecmp_bytes[7] = mtimecmp[63:56];
   
   // Expose data memory rdata bytes
   logic [7:0] data_mem_rdata_bytes[4];
   assign data_mem_rdata_bytes[0] = data_mem_rdata[7:0];
   assign data_mem_rdata_bytes[1] = data_mem_rdata[15:8];
   assign data_mem_rdata_bytes[2] = data_mem_rdata[23:16];
   assign data_mem_rdata_bytes[3] = data_mem_rdata[31:24];
   
   always_comb begin
      data_mem_rdata = 0;
      if(addr_is_mtime) begin
	 
      end else if(addr_is_mtimecmp) begin
	 for (int n = first_byte; n < last_byte; n++) begin
	    data_mem_rdata_bytes[n - first_byte] = mtime_bytes[n - 'h1000_4000];
	 end
      end
   end
	 
   
endmodule
