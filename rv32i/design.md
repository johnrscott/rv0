# Design

This file contains the design of the core, including the data path and control. Each part will be broken down into what modules and instances are needed, and how the instructions utilise each part of the design.

## Data path (Instruction Perspective)

This section describes how the instruction uses the hardware of the data path.

### Register-register instructions

The following instructions operate on two register operands and write their result into the register file: `add`, `sub`, `sll`, `slt`, `sltu`, `xor`, `srl`, `sra`, `or`, `and`. Supporting these instructions requires:
* a register file that supports two port reads (combinationally depending on the `rs1` and `rs2` fields in the R-type instruction format); and supports a single-port registered write port, with the write register index selected from the `rd` field in the R-type instruction.
* an ALU with two input ports for 32-bit operands; that supports the arithmetic and logical operations above; has inputs routable from the register file read data output ports; and has an output routable to the register file write data input port.
* the next `pc` is `pc+4`.

### Register-immediate instructions

The following instructions operate on a register operand and an immediate encoded in the instructions: `addi`, `slti`, `sltiu`, `xori`, `ori`, `andi`, `slli`, `srli`, `srai`. Supporting these instructions requires:
* a way to route the `imm[11:0]` field of the I-type instruction to the second input operand of the ALU (the first input operand comes from the `rs1` output of the register file)
* in the case of `slli`, `srli`, and `srai`, the `imm[11:0]` fields must be masked to the lower 5 bits, and bit 30 of the instruction should be used to control the type of right shift operation in the ALU (1 for arithmetic shift, 0 for logical).
* routing the output of the ALU to the write port of the register file, with register index from the `rd` field of the I-type instruction.
* the next `pc` is `pc+4`.

### Branch instructions

The following instructions operate on two register operands, and take a pc-relative branch if a condition is satisfied: `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`. Supporting these instructions requires:
* routing the two register operands to the ALU, the same as the register-register instructions
* setting the operation of the ALU depending on the instruction:
  * `beq`: subtract
  * `bne`: subtract
  * `blt`: use `slt`
  * `bge`: use `slt`
  * `bltu`: use `sltu`
  * `bgeu`: use `sltu`
* creating a `branch_taken` signal from the output of the ALU depending on the instruction:
  * `beq`: `zero`
  * `bne`: `!zero`
  * `blt`: `alu_result[0]`
  * `bge`: `!alu_result[0]`
  * `bltu`: `alu_result[0]`
  * `bgeu`: `!alu_result[0]`
* form the immediate `offset` from the `imm` fields in the B-type instruction.
* if `branch_taken` signal is set and `pc + offset` is not four-byte aligned, raise `InstructionAddressMisaligned` exception; otherwise, next `pc` is `pc + offset`.
* if `!branch_taken`, next `pc` is `pc + 4`.

Note: does this instruction require two ALUs? One for the branch condition comparison and one for `pc + offset`? Or can we maybe use the same ALU being used for `pc + 4` to compute `pc + offset`?

### Load instructions

The following instructions read a value from memory and write it to a destination registers: `lb`, `lh`, `lw`, `lbu`, `lhu`. Supporting these instructions requires:
* routing the `base` register index from the I-type instruction to the register file
* routing the output of the register file to the first input of the ALU
* routing the `offset` stored in the instruction to the other input of the ALU
* setting the ALU operation to addition
* routing the output of the ALU to the physical memory attributes checker
* if the memory read will be invalid, raise `LoadAccessFault` exception and prevent memory read/register write.
* if read is OK, configure the memory to read a byte, halfword, or word, based on the instruction
* routing the output from the data memory through a zero-extension or sign-extension based on the instruction
* routing that result to the register file write port (write register comes from `rd` value in instruction).
* set next `pc` to `pc + 4`.

### Store instructions

The following instructions write a value from a register to a memory address: `sb`, `sh`, `sw`. Supporting these instructions requires:
* routing the `base` register index from the S-type instruction to the first read port of the register file
* routing the first output of the register file to the first input of the ALU
* obtaining the `offset` from the `imm` fields of the S-type instruction and placing the result on the second ALU 
* setting the ALU operation to addition
* routing the `src` register index from the S-type instruction to the second read port of the register file
* routing the second output port of the register file to the write input of the data memory.
* routing the output of the ALU to the physical memory attributes checker
* if the memory read will be invalid, raise `StoreAccessFault` exception and prevent memory write.
* if write is OK, configure memory to write a byte, halfword, or word, based on the instruction
* set next `pc` to `pc + 4`

### Upper immediate instructions

These instruction construct upper immediates: `lui` and `auipc`; they are implemented by:
* routing the `dest` field of the U-type instruction to the write port address of the register file.
* combine the `imm` field of the U-type instruction with 12 low zeros; route it to port 1 of the ALU
* set the ALU operation to addition
* if the instruction is `auipc`, route the current `pc` to the second port of the ALU; else 0 for `lui`.
* route the output of the ALU to the write data port of the register file
* set next `pc` to `pc + 4`

### Jump and link

The `jal` instruction is implemented by:
* routing the `imm` fields of the J-type instruction through a sign-extending module
* routing the sign extended result to the first port of the ALU
* routing the current `pc` to the second port of the ALU
* setting the ALU operation to addition
* checking the result from the ALU is four-byte aligned. If not, raise `InstructionAddressMisaligned` exception and do not perform the register writes below.
* setting the next `pc` to the output from the ALU.
* route the `dest` field of the J-type instruction to the write address port of the register file
* setting the write data port of the register file to `pc + 4`

### Jump and link register

The `jalr` instruction is implemented by:
* routing the `imm` fields of the I-type instruction to a sign extension module
* routing the result of the sign extension to the first port of the ALU
* routing the `base` field of the I-type instruction to the first read port of the register file
* routing the first output port of the register file to the second port of the ALU
* setting the ALU operation to addition
* routing the output of the ALU through a mask to set the low bit to zero
* checking the result is four-byte aligned. If not, raise `InstructionAddressMisaligned` exception and do not perform the register writes below.
* routing the result to the next `pc`.
* route the `dest` field of the J-type instruction to the write address port of the register file
* setting the write data port of the register file to `pc + 4`

### Nops

The instructions `fence` and `wfi` are implemented as `nop`:
* set the next `pc` to `pc + 4`

### Environment calls

The instructions `ecall` and `ebreak` raise the exceptions `MmodeEcall` and `Breakpoint` respectively, and take no further action.

### Return from trap

The `mret` instruction is implemented by:
* restoring the `MPIE` bit to the `MIE` bit in the `mstatus` CSR
* setting the `MPIE` bit to 1 in the `mstatus` CSR
* setting the next `pc` to `mepc`

## Data path (Instance Perspective)

This presents a draft of the different components of the data path, focusing on what they will do while different instructions are executing. 

### Raising an exception

The exception mechanism is partly implemented in the data path and partly in the control unit. The policy for raising an exception in this single-cycle design is that no combinational calculation which caused the exception to be raised can be modified by the exception (otherwise there would be a circular dependency in the calculation). As a result, extra logic may need to be implemented that disables any actions that would be taken where there is no exception, in cases where disabling an action would also de-assert the exception itself.

Due to the results of calculations performed in the combinational work of an instruction, the data path may need to raise an exception. When this happens, the instruction should be prevented from registering the results of the instruction that would occur if no exception occurred, by having the control unit disable these writes. In addition, the following actions take place when an exception is raised:
* the `mepc` CSR is set to `pc`
* the `mcause` register is set to be written with the exception cause
* the `MIE` bit is saved to `MPIE` in the `mstatus` CSR, and the `MIE` bit itself is cleared.
* the next `pc` is set to the exception `BASE` address stored in `mtvec` (this can be hardwired in this design)

Note that many of these steps also happen for an `interrupt` (they are generic trap steps). However, an interrupt sets a different `mepc` value and `mcause`, and jumps to a vectored interrupt).

### Calculation of next `pc` (combinational)

The next program counter `next_pc` is either calculated directly, or is the output from an ALU, configured as an adder, whose input `B` is controlled by a multiplexer. The configuration of the calculation is as follows:
* `A = pc`, `B = 4`: most instructions
* `A = pc`, `B = offset`: control flow instructions; `offset` is
  * obtained from sign extending `imm` fields in instruction (branch instructions)
  * output from `main_alu` for `jal`
* `A = exception_vector`, `B = interrupt_offset`: for exceptions and interrupts
* `next_pc = 0xffff_fffe & jalr_target`: for `jalr` instructions, `jalr_target` is the output from `main_alu`. It needs the bottom bit masking out.
* `next_pc = mepc`: `mret` instruction only

The output from this adder is checked for instruction alignment (multiple of 4). If the `pc` is not four-byte aligned, an `InstructionAddressMisaligned` exception is raised.

The module that will calculate the `pc` is called `next_pc`, and has the following signature:

```verilog
/// Combinational module to calculate the next value of
/// the program counter. The control signal pc_src sets
/// the calculation of maybe_next_pc as follows:
///
/// pc_src  maybe_next_pc
///  00      pc + 4
///  01      mepc
///  10      32'hffff_fffe & jalr_target
///  11      pc + offset
///
/// The control line trap decides whether maybe_next_pc
/// becomes the next_pc or not:
///
///                       trap
///                        |
/// maybe_next_pc -------- 
///                       MUX ----- next_pc
/// trap_pc --------------
///
/// where trap_pc = exception_vector + interrupt_offset
/// 
/// If the maybe_next_pc is not a multiple of 4 when adding
/// offset or using jalr_target (i.e. pc_src 01 or
/// 10), then InstructionAddressMisaligned exception
/// is raised (indicated by instr_addr_mis set). This should
/// cause an external control system to set trap. It is
/// important that the instr_addr_mis signal continues to
/// be asserted even after trap is set, which is why
/// maybe_next_pc is separate from next_pc (this allows 
/// a fully combinational single-cycle design).
///
module next_pc(
	input [31:0] pc, // the current value of the PC
	input [31:0] mepc, // the pc to use for mret
	input [31:0] exception_vector, // from mtvec
	input [31:0] interrupt_offset, // 0 for exception; for interrupt, specify byte offset to trap vector
	input [31:0] offset, // offset to add to the current pc
	input [31:0] jalr_target, // un-masked jalr target PC
	input [2:0] pc_src, // select the next pc for normal program flow
	input trap, // 0 for normal program flow, 1 for trap
	output [31:0] next_pc, // the next value to load into pc
	output instr_addr_mis, // flag for instruction address misaligned exception
	);
```

### `pc` (sequential)

The current `pc` is a single 32-bit register, which is loaded on the rising edge of the clock from the output of `next_pc`.

```verilog
reg [31:0] pc;
wire [31:0] next_pc; // output from next_pc instance

always @(posedge clk) begin
	pc <= next_pc
end
```

No check is performed for address alignment, because that is checked in `next_pc`.

### Instruction fetch at `pc` (combinational)

The instruction memory is an instance of a `instr_mem` module, which has the following signature:

```verilog
/// Fetch an instruction from program memory
///
/// The instruction memory is preloaded with instructions at
/// synthesis time in this design. It is combinational, so the
/// output changes directly with the input pc. No checking is
/// performed for pc 4-byte alignment (the lower 2 bits of pc
/// are just ignored).
///
/// An InstructionAccessFault exception is raised if the pc is 
/// out of range for the valid program memory addresses. In 
/// this design, the program memory is 1024 bytes, so that
/// occurs if pc > 1020. If the exception is raised, the instr
/// output has an unspecified value.
///
module instr_mem(
	input [31:0] pc; // current pc
	output [31:0] instr; // the instruction at pc
	output instr_access_fault, // flag for instruction access fault exception
	);
```

### Data memory read/write (sequential)

The data memory is a byte-addressable which holds both main memory and memory-mapped I/O regions. It is sequential because write data is stored into the memory on the rising edge of the clock (read data is combinational). There is one write port and one read port. The only instructions which interact with the data memory are load and store instructions.

The signature of the `data_mem` module is as follows:

```verilog
/// Data memory module with one write and one read port
///
/// To read, set the read_addr and read data from the
/// read_data output (valid if no load exception occurred).
///
/// To write, set the write_addr and write_data, and set
/// the write_en. Data will be written on the rising clock
/// edge.
///
/// For both reads and writes, the width is specified using
/// the write_width or read_width input, which has the following
/// encoding (binary):
///
///  00: read/write a byte (8 bits)
///  01: read/write a half word (16 bits)
///  10: read/write a word (32 bits)
///
/// On a non-word read, the high bits of the output contain
/// zeros. On a non-word write, the high bits of the input are
/// ignored.
///
/// Both reads and writes of main memory and I/O memory
/// can use any alignment and width, so {load,store} address
/// misaligned exceptions do not occur in this design.
///
/// Access fault exceptions occur based on the read or write
/// address. On a load access fault, the read_data is unspecified.
/// On a store access fault, no data is written, even if write_en
/// is set. The flags for access faults are both combinational;
/// they are set immediately based on the address (a store access
/// fault does not wait until the rising clock edge).
///
/// The memory map for this data memory is as follows (hexadecimal
/// ranges a - b mean the region starts at a, and the first byte outside
/// the region is b):
///
/// I/O region: 
///    1000_0000 - 1000_0004 (msip)
///    1000_4000 - 1000_4008 (mtimecmp)
///    1000_bff8 - 1000_c000 (mtime)
///
/// Main memory:
///    2000_0000 - 2000_0400
///
/// Only read/writes to the regions above are allowed. Any read or
/// write that falls partially or completely outside the ranges
/// will generate an access fault.
module data_mem(
	input clk, // clock (write on rising edge)
	input [31:0] write_addr, // write port address
	input [1:0] write_width, // write width
	input [31:0] write_data, // write port data
	input write_en, // 1 to write on rising clock edge, else 0 for no write
	input [31:0] read_addr, // read port address
	input [1:0] read_width, // read width
	output [31:0] read_data, // read port data output
	output load_access_fault, // set on LoadAccessFault exception
	output store_access_fault, // set on StoreAccessFault exception
	);
```

### Main ALU

The main ALU is responsible for register-register calculation, register-immediate calculations, and address calculations. It does not raise any exceptions. The ALU should be able to perform the following operations on its operands `a` and `b`, to produce result `r`:

* addition: `r = a + b`
* subtraction: `r = a - b`
* and: `r = a & b`
* or: `r = a | b`
* xor: `r = a ^ b`
* shift left: `r = a << b`
* shift right (logical): `r = a >> b`
* shift right (arithmetic): `r = a >>> b`
* set if less than (unsigned): `r = a < b (unsigned)? 1 : 0`
* set if less than (signed): `r = a < b (signed)? 1 : 0`

The only required flag is `zero`, for use by `beq` and `bne` instructions. Other conditional branch instructions can use `r[0]` with the operation set-if-less-than (signed/unsigned). 

The signature for the `alu` module used for the `main_alu` component is shown below:

```verilog
/// Arithmetic Control Unit
///
/// This is a purely combinational ALU implementation.
///
/// The operation depends on the 4-bit aluc as
/// follows: 
///
/// 0_000: r = a + b
/// 1_000: r = a - b
/// 0_001: r = a << b
/// x_010: r = a < b ? 1 : 0
/// x_011: r = signed(a) < signed(b) ? 1 : 0
/// x_100: r = a ^ b
/// 0_101: r = a >> b
/// 1_101: r = signed(a) >>> signed(b)
/// x_110: r = a | b
/// x_111: r = a & b
///
/// The separation in aluc indicates that the top bit
/// comes form bit 30 of the instruction, and the bottom
/// 3 bits come from funct3, in R-type register-register
/// instructions.
///
/// For I-type register-immediate instructions, ensure
/// that the top bit is 0 for addi, slti, sltiu, xori
/// ori, and andi. For slli, srli, and srai, set the top
/// bit to bit 30 of the instruction, and set b to the
/// shift amount (shamt) field. Set the low three
/// bits to funct3 in all cases.
///
module alu(
    input [31:0] a, // First 32-bit operand
    input [31:0] b, // Second 32-bit operand
    input [3:0] aluc, // ALU control signals (see comments above)
    output reg [31:0] r, // 32-bit result
    output zero // 1 if r is zero, 0 otherwise
    );
```

