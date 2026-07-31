# Binary register arithmetic

## Verified family

The current common-instruction slice implements five one-word,
one-machine-state register/register operations. Bits 8–5 select Rs, bit 4
selects the common A or B file, and bits 3–0 select Rd. Register 15 denotes the
shared SP alias in either file.

| Instruction | Base / mask | Operation | Register write |
|---|---:|---|---|
| ADD | `4000h / FE00h` | `Rd + Rs` | Rd |
| ADDC | `4200h / FE00h` | `Rd + Rs + C` | Rd |
| SUB | `4400h / FE00h` | `Rd - Rs` | Rd |
| SUBB | `4600h / FE00h` | `Rd - Rs - C` | Rd |
| CMP | `4800h / FE00h` | flags from `Rd - Rs` | none |

All five write N, C, Z, and V. ADD/ADDC define C as carry; SUB/SUBB/CMP
define C as borrow. In ADDC, C is also the carry input. In SUBB, C is the
borrow input.

Sources: TI *TMS34020 User's Guide*, August 1990, ADD printed p.13-33,
ADDC printed p.13-34, CMP printed p.13-80, SUB printed p.13-241, and SUBB
printed p.13-242. The word diagrams and example tables were visually checked
against the scan.

## Arithmetic implementation

`rtl/execute/tms34020_binary_arithmetic.sv` uses explicit 33-bit unsigned
addition for carry and borrow. Subtraction is formed as
`Rd + NOT Rs + NOT borrow_in`; the inverse of its carry-out is the architectural
borrow. Signed overflow is the carry into bit 31 XOR the carry out of bit 31,
computed for both carry/borrow-input variants. CMP uses the same subtract path
but deasserts register write enable.

The independent model executes the same documented operations using separate
Python arithmetic and instruction-boundary state. Its tests include every ADD
and CMP example row plus directed ADDC, SUB, and SUBB carry, borrow, zero, sign,
and overflow boundaries. The RTL testbench independently checks all five data
paths and that CMP inhibits writeback.

## Implementation boundary

The module is a combinational semantic leaf. It does not select physical
registers, merge flags into architectural ST, perform writeback, or establish
fetch/pipeline timing. The RTL repository still has no executable processor
sequencer.
