# Notes on ALU design

This file contains notes on the operation of the ALU, including input and output signals, control, and notes on arithmetic behaviour.

## Addition and subtraction

The ALU can perform unsigned addition between the two 32-bit input operands. The carry flag is set to the carry-out from the result of the unsigned addition (the value that bit 32 would have if it existed).

Signed integers are expressed using two's complement. Two signed integers can be added by adding them up as if they were unsigned, and then interpreting the result as a signed two's complement value. In a two's complement numbers, the sign is determined by the sign bit, which is bit 30. The overflow flag is set to one if one of the following two conditions occur:
1. `a` and `b` are both positive, but `a` + `b` is negative.
2. `a` and `b` are both negative, but `a` + `b` is positive.

The ALU performs signed subtraction by negating `b` and then adding it to `a`. In that case, the overflow flag is set in the following cases (obtained by negating the sign of `b` in the rules above):
1. `a` is positive and `b` is negative, but `a` + `b` is negative.
2. `a` is negative and `b` is positive, but `a` + `b` is positive.

The ALU does not distinguish whether it is performing signed or unsigned arithmetic, and so always sets both the `carry` and `overflow` flags according to the rules above.

## ALU output flags

The ALU outputs the following flags:
* `zero`: if the output is identically zero (all 32 bits are zero)
* `sign`: equal to the sign bit of the output operand. Only meaningful if the output is interpreted as signed.
* `carry`: value of carry-out of most significant adder for the addition operation used for unsigned addition/subtraction.
* `overflow`: set if addition or subtraction overflowed as described in the previous section.

## Comparing signed and unsigned integers

The branch instructions require comparing two numbers and deciding which one is larger, in both the signed and unsigned cases. See [here](https://news.ycombinator.com/item?id=8797481); in summary, to compare `a` and `b`, subtract `a - b` using the ALU and use the flags as follows:

For unsigned numbers:
* `a == b`: `zero`
* `a < b`: `carry`
* `a >= b`: `!carry`

For signed numbers:
* `a == b`: `zero`
* `a < b`: `sign != overflow` 
* `a >= b`: `sign == overflow` 

In the RISC-V instruction set, the ALU implements `slt` and `sltu`, which sets the least significant bit of the output to the relevant calculation above. Branch instructions like `blt`, `bltu`, `bge`, and `bgeu` can use this output instead of calculation with the flags directly. (In this case it may not even be necessary to have the ALU output the flags.)
