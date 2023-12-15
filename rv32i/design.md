# Design

This file contains the design of the core, including the data path and control. Each part will be broken down into what modules and instances are needed, and how the instructions utilise each part of the design.

## Data path

This section describes how the instructions map to hardware requirements of the data path.

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
* route the `imm` fields of the J-type instruction through a sign-extending module
* route the sign extended result to the first port of the ALU
* route the current `pc` to the second port of the ALU
* set the ALU operation to addition
* route the `dest` field of the J-type instruction to the write address port of the register file
* set the write data port of the register file to `pc + 4`
* set the next `pc` to the output from the ALU


