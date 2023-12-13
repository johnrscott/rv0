# Specification

This is the initial specification for the processor and supporting board. The target for this iteration is to produce a minimal working RISC-V 32-bit microcontroller, supporting the IM (+Zicsr) instruction sets. The device takes the ESP32-C3 as a reference implementation.

The core should have the following features:

* Instruction clock rate of at least 1 MHz (picked out of the air, may need to be revised down if necessary)
* Compliant rv32im_zicsr implementation
* [Advanced Core local interrupter](https://github.com/riscv/riscv-aclint/blob/main/riscv-aclint.adoc)-compatible interrupt controller
* Minimal debugging implementation
* Capable of running FreeRTOS

The core should have at least these peripherals:

* 1 x 8-bit bidirectional GPIO peripheral
* 1 x SPI host peripheral
* 1 x UART RX/TX peripheral
