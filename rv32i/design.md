# Design

This file contains the design of the core, including the data path and control. Each part will be broken down into what modules and instances are needed, and how the instructions utilise each part of the design.

## Data path (instructions)

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
* routing the `base` (`rs1`) register index from the I-type instruction to the register file
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
* routing the `base` (`rs1`) register index from the S-type instruction to the first read port of the register file
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
* combine the `imm` field of the U-type instruction with 12 low zeros; route it to port 2 of the ALU
* set the ALU operation to addition
* if the instruction is `auipc`, route the current `pc` to port 1 of the ALU; else 0 for `lui`.
* route the output of the ALU to the write data port of the register file
* set next `pc` to `pc + 4`

### Jump and link

The `jal` instruction is implemented by:
* routing the `imm` fields of the J-type instruction through a sign-extending module
* routing the sign extended result to the second port of the ALU
* routing the current `pc` to the first port of the ALU
* setting the ALU operation to addition
* checking the result from the ALU is four-byte aligned. If not, raise `InstructionAddressMisaligned` exception and do not perform the register writes below.
* setting the next `pc` to the output from the ALU.
* route the `dest` field of the J-type instruction to the write address port of the register file
* setting the write data port of the register file to `pc + 4`

### Jump and link register

The `jalr` instruction is implemented by:
* routing the `imm` fields of the I-type instruction to a sign extension module
* routing the result of the sign extension to the second port of the ALU
* routing the `base` field of the I-type instruction to the first read port of the register file
* routing the first output port of the register file to the first port of the ALU
* setting the ALU operation to addition
* routing the output of the ALU through a mask to set the low bit to zero
* checking the result is four-byte aligned. If not, raise `InstructionAddressMisaligned` exception and do not perform the register writes below.
* routing the result to the next `pc`.
* route the `dest` field of the J-type instruction to the write address port of the register file
* setting the write data port of the register file to `pc + 4`

### Control and status register instructions

The instructions `csrrw`, `csrrs`, `csrrc`, `csrrwi`, `csrrsi`, and `csrrci` read and write CSRs. The `*rw*` instructions always write irrespective of arguments, and the `*rs*/*rc*` instructions always read irrespective of arguments. These instructions are implemented by:
* routing the CSR address to the CSR address bus (which specifies a CSR to both read and write)
* if the CSR does not exist, raise an illegal instruction exception and do not perform the operations below.
* routing the destination register index `rd` of the instruction to the write data address port of the register file.
* routing the data output of the CSR to the write data input port of the register file.
* routing the data output of the CSR to the first port of the ALU
* configure the ALU operation to be OR (`csrrs(i)`) or AND (`csrrc(i)`) depending on the instruction
* route the `rs1` field to the first read port of the register file (this can be done even for immediate instructions; the output of the register file is unused)
* select the second port of the ALU from: 
  * the output of the first read port on the register file (`csrrs`)
  * the negated output of the first read port on the register file (`csrrc`)
  * the `uimm` instruction field (zero-extended) (`csrrsi`)
  * the `!uimm` field (zero-extended) (`csrrci`)
* select the CSR write data line from
  * the first read output from the register file (`csrrw`)
  * the `uimm` field from the instruction (`csrrwi`)
  * the output of the ALU (the rest of the instructions)
* set the CSR bus write enable signal depending on the instruction and whether `rs1` is zero, or `uimm` is zero.
* if the attempted write to the CSR is read-only, raise an illegal instruction exception, and prevent the CSR data being written to `rd`.

In the CSR bus, if a write is performed, ensure this prevents any automatic updating action the CSR may take when it is not written. Each CSR module on the CSR bus is responsible for only updating its writable fields (and masking out attempted changes to non-writable fields, or WARL fields where the written value is not legal).

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

## Data path (modules)

This presents a draft of the different components of the data path, focusing on what they will do while different instructions are executing. 

### Raising an exception

The exception mechanism is partly implemented in the data path and partly in the control unit. The policy for raising an exception in this single-cycle design is that no combinational calculation which caused the exception to be raised can be modified by the exception (otherwise there would be a circular dependency in the calculation). As a result, extra logic may need to be implemented that disables any actions that would be taken where there is no exception, in cases where disabling an action would also de-assert the exception itself.

Due to the results of calculations performed in the combinational work of an instruction, the data path may need to raise an exception. When this happens, the instruction should be prevented from registering the results of the instruction that would occur if no exception occurred, by having the control unit disable these writes. In addition, the following actions take place when an exception is raised:
* the `mepc` CSR is set to `pc`
* the `mcause` register is set to be written with the exception cause
* the `MIE` bit is saved to `MPIE` in the `mstatus` CSR, and the `MIE` bit itself is cleared.
* the next `pc` is set to the exception `BASE` address stored in `mtvec` (this can be hardwired in this design)

Note that many of these steps also happen for an `interrupt` (they are generic trap steps). However, an interrupt sets a different `mepc` value and `mcause`, and jumps to a vectored interrupt).

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

#### Notes

Maybe this is more like a physical memory attributes checker module, not the actual data memory. Ideally, the I/O region (with the memory-mapped CSRs and in the future, other peripherals) should be independent of the data memory. Probably a bus architecture of some kind is more appropriate, where the bus itself is the physical address space, but devices attached to the bus can opt to service the request if the address is within their memory range. There could be a data bus that contains the output, driven by whichever module is servicing the request. The physical memory attributes checker could also be attached to this bus.

Possible there is no need for a PMA checker at all -- if each peripheral connected to the bus "claims" the read or write by asserting a signal, then the PMA check could be as simple as checking that at least one device as claimed the read/write (a peripheral would only claim it if the entirety of the read/write falls within it's valid address range).

Any device on the data memory physical address bus could have the following signature:

```verilog
/// Example device connected to data memory bus
///
/// For this bus, only a single read or write is allowed at once. This
/// is fine, because only a load or store instruction is being executed
/// at once, and these are the only ways the CPU can access the data memory
/// (note that "back-channel" accesses, like updating memory mapped registers
/// like mtime internall, do not use the data memory bus for the access).
///
/// A device like this "claims" a read/write by asserting the "claim" signal,
/// depending on whether it "owns" the address range (determined from the
/// addr and width). By design, only a single device on the bus can claim
/// a read/write. Externally, all the claim signals are ORed together, and if
/// no device claims the read/write, an access fault occurs. (The write_en
/// signal is also shared between all devices, and this can be used in 
/// combination with the ORed claim signals to distinguish a load/store
/// access fault.)
///
/// If a write is claimed, the write is performed on the rising edge of the
/// clock. If a read is claimed, then the data_out line is set to the
/// result of the read. If the read is not claimed, the data_out line is
/// guaranteed to be zero. This means these lines can be ORed externally
/// to form the data_out bus.
module example_device(
	input clk, // if the device can be written to, it needs a clock
	input [31:0] addr, // the read/write address bus 
	input [1:0] width, /// the width of the read/write
	input [31:0] data_in, // data to be written on rising clock edge
	input write_en, // 1 to perform write, 0 otherwise
	output [31:0] data_out, // data out
	
	// other signals specific to the device
	);
```

Devices that are needed on the bus include:

* `main_memory`: fixed block of contiguous memory; claims reads/writes contained in the range `0x2000_0000 - 0x2000_0400`.
* `msip`: memory-mapped register, claims reads/writes in the range `0x1000_0000 - 0x1000_0004 `. Only the lowest bit is writable. Attempts to write other bits are ignored, and other bits always read as zero.
* `mtimecmp`: memory-mapped register, claims reads/writes in the range `0x1000_4000 - 0x1000_4008`.
* `mtime`: memory-mapped register, claims reads/writes in the range `0x1000_bff8 - 0x1000_c000`. Automatically increment on each clock cycle.

### Control and Status Register Bus

The CSR registers are attached to an address space which is different from the data memory physical address space, but which can be implemented in the same way. Each CSR is represented as a device attached to the bus (similar CSRs can be grouped into a single module), with the following signature:

```verilog
module csr_module(
	input clk, // clock for writing on the rising edge
	input [11:0] addr, // CSR address. Used to claim a CSR read/write.
	input [31:0] write_data, // data to write to the CSR
	input write_en, // 1 to write on rising clock edge
	output read_data, //
	output claim, // 1 if this module owns the CSR addr
	output illegal_instr, // 1 if illegal instruction should be raised
	
	// Other arguments not related to CSR bus (e.g. memory mapping,
	// hardware access, etc.)
	);
```

Modules will be designed so that a given register is controlled by only a single module. These are the kinds of modules that will be present:
* read-only zero CSR modules: these only need a single CSR-bus port which always returns zero on reads or illegal instruction on writes. Examples include `mvendorid`, `marchid`, `mimpid`, `mhartid`, `mconfigptr`, `misa`, `mhpmcountern`, `mhpmcounternh`, `mhpmevent`, `hpmcountern`, `hpmcounternh`, `mtval` (these can all be collected into a single module)
* read/write CSRs which are not used by hardware: these require a read/write CSR-bus interface only. Examples are `mscratch`.
* read/write CSRs which can only be read by hardware: these need a read/write CSR-bus port, and access for hardware to read the bits. Examples include `mie`.
* read-only non-zero CSR modules: these return a non-zero value, but cause illegal instruction on writes. Examples include `mtvec`, 
* read/write CSRs which can also be written by hardware: these need a CSR-bus port for read/write, and also a direct-hardware port for the CPU to read/update the bits in the CSRs. Examples include `mstatus` and `mstatush` (note that this is a read/write register, even though all fields are read-only zero), `mcycle`, `mcycleh`, `minstret`, `minstreth`, `mcause`, `mepc`. These modules should also provide access to read-only shadows of these registers (like `cycle`, `cycleh`, `instret`, `instreth`).
* read-only memory-mapped CSRs updated by hardware: these require a CSR-bus supporting reads (writes return illegal instruction), and also a data memory bus for access via the physical address space. In addition, hardware requires a read/write port for reading and updating the values. Examples include `time` and `timeh` (i.e. 64-bit `mtime`)


### Trap module (sequential)

This module is responsible for controlling interrupts and exceptions. It holds the following state of the architecture:
* `mtime`: 64-bit real-time register
* `mtimecmp`: defines the trigger for a timer interrupt in relation to `mtime`
* `mie`: global interrupt enable bit in `mstatus`
* `mpie`: previous `mie` in `mstatus`
* `msie`, `mtie`, `meie`: software, timer and external interrupt enable bits in `mie`
* `msip`, `mtip`, `meip`: software, timer and external interrupt pending bits in `mip`
* `mepc`: return address after trap
* `mcause`: the cause of the trap
* `mtvec`: defines the location and type of trap handler vectors (this is hardcoded in this design)

The module serves the `mtime` and `mtimecmp` registers memory-mapped onto the data memory bus.

The module serves the following CSR registers on the CSR bus:
* 


### Main ALU (combinational)

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
/// The operation depends on the 4-bit alu_op as
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
/// The separation in alu_op indicates that the top bit
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
    input [3:0] alu_op, // ALU control signals (see comments above)
    output [31:0] r, // 32-bit result
    output zero // 1 if r is zero, 0 otherwise
    );
```

An instance of the `alu` module will also be used for the `next_pc` calculation.

### Register file (sequential)

The register file has two combinational read ports and one sequential write port. The register file does not raise exceptions. The signature of the register file is shown below:

```verilog
/// 32-bit Register file
///
/// There are 32 32-bit registers x0-x31, with x0 hardwired
/// to zero. This module provides two combinational output
/// ports, controlled by the two addresses rs1 and src, and
/// a single registered write (on the rising edge of the clock
/// when the write enable signal is asserted).
///
/// There is no reset; on power-on, the register values are 
/// set to zero.
///
module register_file(
    input clk, // clock
    input write_en, // write enable
	input [31:0] write_data, // data for write
    input [4:0] rs1, // source register index A
    input [4:0] rs2, // source register index B
    input [4:0] rd, // destination register index for write
    output [31:0] rs1_data, // read port A
    output [31:0] rs2_data // read port B
    );
```

## Data path (multiplexers)

This section contains the designs for signal selection multiplexers at the inputs to most of the data path modules. They are named using the format `<module_name>_<input_name>_sel` where `<module_name>` and `<input_name>` specifies which signal of which module is being driven. The control signals for each multiplexer come from the control unit. Sometimes, the module may contain logic in addition to a multiplexer for generating the input signal.

Some signals do not require multiplexers, because they are always taken from the same source. The signals corresponding to register indices are as follows:
* `register_file_rs1` is always tied to the `rs1` field of the instructions (`instr[19:15]`)
* `register_file_rs2` is always tied to the `rs2` field of the instructions (`instr[24:20]`)
* `register_file_rd` is always tied to the `rd` field of the instructions (`instr[11:7]`)

It does not matter if these fields are not used in the instruction, and therefore contains junk; in these cases, `register_file_write_en` is de-asserted, and the combinational outputs `rs1_data` and `rs2_data` are ignored.

Only the load and store instructions can read or write to the data memory bus, which means the following signals are always routed:
* data memory bus `addr` always comes from the main ALU result `r`
* data memory bus `width` field is calculated statically from the instruction
* data memory bus `write_data` is routed from `rs2_data` from the register file

The multiplexers that select between different potential inputs are outlined below.

### Main ALU input ports

There are two multiplexers which control the input ports to the main ALU: `main_alu_a_sel` and `main_alu_b_sel`. The following guidelines have been followed when selecting which signals is routed to which port of the main ALU:
* `rs1_data` and `rs2_data` are routed to ports `a` and `b` of the ALU
* immediate fields are typically routed to port `b` of the ALU
* the `pc` is routed to the first port of the ALU if it is needed
* the CSR-bus data output is routed to port `b` of the main ALU; for CSR instructions, port `a` is used for `rs1_data`, `!rs1_data`, and the `uimm`-derived immediates.
* the CSR-bus address is always routed from the `csr` field in the CSR instruction format (`instr[31:20]`)

The signatures for the two ALU input multiplexers are as follows. The first port is controlled by:

```verilog
/// Selects the signal input for port a of the main ALU
///
/// The sel argument selects between the inputs (sel is in binary):
///  000: rs1_data, for register-register, register-immediate,
///  branch, load, store instructions
///  001: pc, for auipc and jal instructions
///  010: 0, for lui
///  011: !rs1_data, for use in CSR instructions
///  100: uimm, for use in CSR instructions
///  101: !uimm, for use in CSR instructions
///
/// When uimm is negated, the negation happens _before_ the 
/// sign-extension to 32-bits.
///
module main_alu_a_sel(
	input [2:0] sel, // chooses the output signal
	input [31:0] rs1_data, // the value of rs1 from the register file
	input [31:0] pc, // for current program counter
	input [4:0] uimm, // uimm field from CSR instructions
	output a // the main ALU a signal
	);
```

The second port is controlled by:

```verilog
/// Selects the signal input for port b of the main ALU
///
/// The sel argument selects between the inputs (sel is in binary):
///  00: rs2_data, for register-register, branch instructions
///  01: imm, for register-immediate, load, store, jal, jalr, 
///  10: csr_read_data, for CSR instructions 
///
/// The imm argument above needs generating according to whichever
/// instruction is being implemented; different instructions have
/// different formats for the immediate, and need it to be processsed
/// in different ways. The imm argument will be passed straight
/// through to b unprocessed.
module main_alu_b_sel(
	input [1:0] sel, // chooses the output signal
	input [31:0] rs2_data, // the value of rs2 from the register file
	input [31:0] imm, // immediate field, already extracted/sign-extended
	output b // the main ALU b signal
	);
```

### Register file write data

The `write_data` signal for writing to `rd` is selected from multiple sources depending on the instruction. The module is given below

```verilog
/// Write data for rd in register file
///
/// The sel arguments selects between the inputs (sel is in binary):
///  00: main_alu_r, for register-register, register-immediate, 
///  and lui/auipc instructions
///  01: for load instructions
///  10: csr_bus_out, for all CSR instructions
///  11: pc + 4, for jal/jalr instructions
///
module register_file_write_data_sel(
	input [1:0] sel, // choose the output signal
	input [31:0] main_alu_r, // the output from the main ALU
	input [31:0] data_mem_out, // data output from data memory bus
	input [31:0] csr_bus_out, // data output from CSR bus
	input [31:0] pc_plus_4, // current pc + 4, from next_pc_sel
	output write_data //
	);
```

### Next program counter

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
/// the program counter. The control signal sel sets
/// the calculation of maybe_next_pc as follows:
///
/// 00: pc + 4
/// 01: mepc
/// 10: 32'hffff_fffe & jalr_target
/// 11: pc + offset
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
module next_pc_sel(
	input [1:0] sel, // select the next pc for normal program flow
	input [31:0] pc, // the current value of the PC
	input [31:0] mepc, // the pc to use for mret
	input [31:0] exception_vector, // from mtvec
	input [31:0] interrupt_offset, // 0 for exception; for interrupt, specify byte offset to trap vector
	input [31:0] offset, // offset to add to the current pc
	input [31:0] jalr_target, // un-masked jalr target PC
	input trap, // 0 for normal program flow, 1 for trap
	output [31:0] pc_plus_4, // this signal is written to rd for jal/jalr
	output [31:0] next_pc, // the next value to load into pc
	output instr_addr_mis, // flag for instruction address misaligned exception
	);
```
