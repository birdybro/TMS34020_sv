# Unary register instructions

## Verified family

The current common-instruction slice implements four one-word, one-machine-
state register operations. Bit 4 selects the A or B register file and bits 3–0
select the destination; register 15 is the shared SP alias.

| Instruction | Base / mask | Result | Status written |
|---|---:|---|---|
| ABS | `0380h / FFE0h` | absolute value of Rd, with `80000000h` retained | N, Z, V |
| NEG | `03A0h / FFE0h` | `0 - Rd` | N, C, Z, V |
| NEGB | `03C0h / FFE0h` | `0 - Rd - C` | N, C, Z, V |
| NOT | `03E0h / FFE0h` | one's complement of Rd | Z |

Sources: TI *TMS34020 User's Guide*, August 1990, ABS printed p.13-32,
NEG printed p.13-178, NEGB printed p.13-179, and NOT printed p.13-181.
The instruction-word diagrams were checked visually against the scanned pages;
the encodings were not inferred from emulator source.

## Flag details

The four-bit implementation result is ordered N, C, Z, V and is accompanied by
a write mask in that same order.

- ABS computes N from the sign of `0 - Rd`, not from the sign of the final
  absolute-value result. Thus ABS of a positive nonzero value sets N, ABS of an
  ordinary negative value clears N, and ABS of `80000000h` sets both N and V.
  C is unaffected.
- NEG sets C when the original Rd is nonzero and sets V only for
  `80000000h`.
- NEGB consumes C as a borrow input. Its output C indicates an unsigned borrow
  from `0 - Rd - C`; signed overflow follows the subtraction operands and
  result.
- NOT preserves N, C, and V and updates only Z.

These per-flag distinctions are verified against every example row on the four
TI instruction pages in both the independent model and the SystemVerilog leaf
testbench.

## Implementation boundary

`rtl/execute/tms34020_unary.sv` is a combinational semantic leaf. It does not
read the register file, merge status into architectural ST, perform writeback,
fetch instructions, or establish pipeline timing. The independent model
executes these four instructions at instruction boundaries, but the RTL still
has no processor sequencer.
