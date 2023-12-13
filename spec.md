# Specification (RV0)

This is the initial specification for the processor. The target for this iteration is to produce a minimal working RISC-V 32-bit microcontroller, supporting the 32-bit base integer and M (multiplication/division) (+Zicsr) instruction sets. Some aspects of the device are based on the ESP32-C3 as a reference.

This design targets the Arty A7 development board only, and will not include a custom board design. The main purpose is to establish a working core and basic peripherals.

The core should have the following features:

* Instruction clock rate of at least 1 MHz (picked out of the air, may need to be revised if necessary)
* Compliant rv32im_zicsr implementation (M-mode only)
* [Advanced Core local interrupter](https://github.com/riscv/riscv-aclint/blob/main/riscv-aclint.adoc)-compatible interrupt controller.
* Minimal debugging implementation
* On-chip SRAM (400 KiB)

The core should have at least these peripherals (no pin remapping for simplicity -- mapping to be handled at the FPGA pin mapping level):

* 1 x 8-bit bidirectional GPIO peripheral
* 1 x SPI host peripheral
* 1 x UART RX/TX peripheral
