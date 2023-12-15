# Specification

This part summarises the specification for the design, including the ISA that needs supporting, the CSR registers, and the interrupts/exceptions.

## CPU State

This section contains the parts of the design that hold state, which will correspond to registered parts of the design. 

The device will need a register file of 32 32-bit registers, where x0 (the first one) is tied to zero (always reads as zero).

There is a 32-bit program counter which points to the instruction currently executing.

There will be a byte-addressable 32-bit physical address space (for use by the load and store instructions) backed by 
* a region of read/write I/O region (containing memory-mapped registers)
* a region of read/write main memory (RAM)

(The instruction memory will be separate from the other memory in this design, and will only be accessed by instruction fetch. Since instruction memory will not be writable, it will be implemented as a combinational instance, loaded with initial values at synthesis-time.)

The memory map for the physical address space is as follows (all addresses are in hexadecimal):

| Memory Name     | Start Address | Memory-mapped Register    | Size | Physical Memory Attributes    |
|-----------------|---------------|---------------------------|------|-------------------------------| 
| Instruction ROM | 0000\_0000    |                           | 1024 | Read-only (instruction fetch) |
|                 | 0000\_0000    | Reset vector (initial PC) | 4    |                               |
|                 | 0000\_0004    | NMI vector                | 4    |                               |
|                 | 0000\_0008    | Exception vector (mtvec)  | 4    |                               |
|                 | 0000\_0014    | Software interrupt vector | 4    |                               |
|                 | 0000\_0024    | Timer interrupt vector    | 4    |                               |
|                 | 0000\_0034    | External interrupt vector | 4    |                               |
| I/O             | 1000\_0000    |                           | 256  | Read/write (load/store)       |
|                 | 1000\_0000    | msip                      | 4    |                               |
|                 | 1000\_4000    | mtimecmp                  | 8    |                               |
|                 | 1000\_bff8    | mtime                     | 8    |                               |
| Main Memory     | 2000\_0000    |                           | 1024 | Read/write (load/store)       |
|

The basic interrupt mechanism follows the Core Local Interruptor (CLINT) specification, based on SiFive chips. The CLINT memory map begins at address `0x1000_0000`. The meaning of the memory-mapped I/O registers in this region are as follows:
* `msip`: write 1 to this bit to request a software interrupt, and write 0 to clear it. The value of this bit is reflected in the read-only `MSIP` field of the `mip` CSR. The register is initialised to zero.
* `mtimecmp`: this is the 64-bit timer compare register as described in the RISC-V privileged ISA specification. A timer interrupt becomes pending exactly when `mtime >= mtimecmp`. It is initialised to zero.
* `mtime`: this is the 64-bit real time register, which increments at a constant rate with wall clock time. It is initialised to zero.

There are the following minimal set of required control and status registers (CSR). Each is listed in the format "`CSR-address CSR-name`: description". 

First, there is a set of required informational registers:

* `0xf11 mvendorid`: read-only; returns 0 to indicate not implemented.
* `0xf12 marchid`: read-only; returns 0 to indicate not implemented.
* `0xf13 mimpid`: read-only; returns 0 to indicate not implemented.
* `0xf14 mhartid`: read-only; single hart system, returns 0 to indicate hart 0.
* `0xf15 mconfigptr`: read-only zero, configuration platform-specification defined
* `0x301 misa`: read/write; single legal value 0 always returned (WARL), meaning architecture is determined by non-standard means (it is rv32im_zicsr implementing M-mode only).

The state of the CPU is stored in the following status registers:

* `0x300 mstatus`: read/write, containing both WPRI and WARL fields. The bit fields which are non-zero are as follows (assumes only M-mode):
  * bit 3: MIE (interrupt enable), read/write
  * bit 7: MPIE (previous value of interrupt enable), read/write (?)
  * bits [12:11]: MPP (previous privilege mode), WARL always 0b11 (?)
* `0x310 mstatush`: upper 32-bit of status; all fields are read-only zero (only little-endian memory is supported).
  
In addition to the global bit in the status register, interrupts are controlled and monitored by these registers:

* `0x304 mie`: read/write interrupt-enable register. To enable an interrupt in M-mode, both mstatus.MIE and the bit in mie must be set. Bits corresponding to interrupts that cannot occur must be read-only zero.
* `0x344 mip`: 32-bit read/write interrupt-pending register. Since all fields are read-only, writes to this CSR are no-op. The following bits are defined:
  * bit 3: machine software interrupt pending (read-only)
  * bit 7: machine timer interrupt pending (read-only)
  * bit 11: machine-level external interrupt pending (read-only)

When a trap occurs (either due to an imprecise asynchronous interrupt or a precise synchronous exception), the following registers control where control flow is transferred to and where it returns to after the trap:

* `0x305 mtvec`: read-only, trap handler vector table base address
  * bits [1:0]: 1 (vectored mode)
  * bits [31:2]: trap vector table base address (4-byte aligned)
* `0x341 mepc`: 32-bit, read/write register, stores the return-address from trap handler. WARL, valid values are allowed physical addresses (4-byte aligned and fit within physical memory address width).

Information about the trap is obtained from these registers:

* `0x342 mcause`: 32-bit, read/write, stores exception code and bit indicating whether trap is interrupt. Exception code is WLRL.
* `0x343 mtval`: read-only zero

In addition, software may use this register in any way while processing traps:

* `0x340 mscratch`: 32-bit read/write register for use by trap handlers

The following privileged-mode registers hold performance monitoring information:

* `0xb00 mcycle`: low 32 bits of read/write 64-bit register incrementing at a constant rate
* `0xb80 mcycleh`: high 32 bits of read/write, 64-bit register containing number of clock cycles executed by the processor.
* `0xb02 minstret`: low 32 bits of read/write, 64-bit register containing number of instructions retired by the processor.
* `0xb82 minstreth`: high 64 bits of read/write, 64-bit register containing number of instructions retired by the processor.

These registers are also accessible via the following shadows (intended for use by unprivileged mode; however, there is only M-mode here, so there is no distinction between privilege levels)

* `0bc00 cycle`: read-only shadow of mcycle
* `0xc80 cycleh`: read-only shadow of mcycleh
* `0xc02 instret`: read-only shadow of minstret
* `0xc82 instreth`: read-only shadow of minstreth

The 64-bit `mtime` register is memory-mapped (it is not a CSR); however, it does have a read-only shadow as a CSR:

* `0xc01 time`: read-only shadow of lower 32 bits of memory mapped 64-bit mtime
* `0xc81 timeh`: read-only shadow of upper 32 bits of memory mapped 64-bit mtime

Finally, the following required performance monitoring counters are all implemented as read-only zero

* `(0xb00 + n) mhpmcountern`: read-only zero (`n` ranges from 3 to 32)
* `(0xb80 + n) mhpmcounternh`: read-only zero (`n` ranges from 3 to 32)
* `(0x320 + n) mhpmevent`: read-only zero (`n` ranges from 3 to 32)
* `(0xc00 + n) hpmcounter`:  read-only zero (`n` ranges from 3 to 32)
* `(0xc80 + n) hpmcounterh`: read-only zero (`n` ranges from 3 to 32)

## Instructions

The required instructions are the 32-bit base integer ISA, the Zicsr extension for CSR manipulation, and the privileged-architecture instruction `mret`.



## Exceptions

## Interrupts