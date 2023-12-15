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
* Setting the operation of the ALU depending on the instruction:
  * `beq`: subtract
  * `bne`: subtract
  * `blt`: subtract
  * `bge`: subtract
  * `bltu`: 
* creating a `branch_taken` signal from the output of the ALU depending on the instruction:
  * `beq`: `zero`
  * `bne`: `!zero`
  * `blt`: `sign`
  * `bge`: `!sign`
  
