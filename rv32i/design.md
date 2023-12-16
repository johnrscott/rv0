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

The exception mechanism is partly implemented in the data path and partly in the control unit.

Due to the results of calculations performed in the combinational work of an instruction, the data path may need to raise an exception. When this happens, the instruction should be prevented from registering the results of the instruction that would occur if no exception occurred, by having the control unit disable these writes. In addition, the following actions take place when an exception is raised:
* the `mepc` CSR is set to `pc`
* the `mcause` register is set to be written with the exception cause
* the `MIE` bit is saved to `MPIE` in the `mstatus` CSR, and the `MIE` bit itself is cleared.
* the next `pc` is set to the exception `BASE` address stored in `mtvec` (this can be hardwired in this design)

Note that many of these steps also happen for an `interrupt` (they are generic trap steps). However, an interrupt sets a different `mepc` value and `mcause`, and jumps to a vectored interrupt).

### Calculation of next `pc`

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
/// the calculation of maybe_next_pc as follows
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
