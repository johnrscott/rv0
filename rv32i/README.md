# Single-cycle minimal RISC-V core

This is a minimal RV32I (only the base 32-bit integer ISA + Zicsr implementing only the M-mode privileged ISA) design using a single cycle architecture. Leaving out the multiplication/division ISA for this version because it would likely be unreasonable in a single cycle. Otherwise, going to try to support as much of the required privileged ISA as possible, including interrupts/exceptions.

See the following files documenting the design:

1. [Specification](spec.md)
2. [Design](design.md)
