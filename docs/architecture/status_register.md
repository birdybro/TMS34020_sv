# Status register

## Programmer-visible layout

ST is a 32-bit special-purpose register. TI specifies reset value
`00000010h`.

| Bits | Name | Meaning |
|---:|---|---|
| 4–0 | FS0 | field 0 size; encoded 0 means 32, 1–31 mean 1–31 |
| 5 | FE0 | field 0 zero/sign extension |
| 10–6 | FS1 | field 1 size; encoded 0 means 32, 1–31 mean 1–31 |
| 11 | FE1 | field 1 zero/sign extension |
| 20–12 | reserved | not used; reset to zero |
| 21 | IE | global maskable-interrupt enable |
| 22 | SS | single-step enable |
| 24–23 | reserved | not used; reset to zero |
| 25 | IX | interrupt occurred within an interruptible instruction |
| 26 | BF | local-memory bus fault occurred |
| 27 | reserved | not used; reset to zero |
| 28 | V | overflow |
| 29 | Z | zero |
| 30 | C | carry or borrow, as defined by the instruction |
| 31 | N | negative |

Source: TI *TMS34020 User's Guide*, August 1990, §4.1, Figure 4-1 and
Table 4-1, printed pp.4-2..4-3.

TI says software should write zero to reserved bits for compatibility. PUTST's
primary instruction page says the complete source register is copied into ST
and depicts the reserved positions as part of that 32-bit destination, but this
does not establish arbitrary reserved-bit readback on every silicon revision.
The new PUTST decode record therefore specifies the documented full-width copy
while silicon-revision readback remains an explicit qualification question.

## Implemented state owner

`rtl/core/tms34020_status.sv` owns a 32-bit state value and supports synchronous
masked writes:

```text
new ST = (old ST AND NOT mask) OR (write data AND mask)
```

Reset has priority and loads `00000010h`. This interface supports exact partial
updates such as:

- ABS writing N/Z/V while preserving C;
- NOT writing only Z;
- arithmetic instructions writing all N/C/Z/V;
- SETF writing only FS0/FE0 or FS1/FE1;
- EXGF atomically exchanging one FS/FE bank with a register's low six bits;
- SEXT writing N/Z and ZEXT writing only Z;
- SETC and CLRC changing only C;
- EINT and DINT changing only IE.

The synchronous `reset_i` is an FPGA architectural-state event, not a claim
about the electrical RESET pin timing. Original-pin assertion/release timing
remains `TMS20-0029`/`TMS20-0030`.

## Verification

`make rtl-leaf-tests` verifies:

- reset value, reset priority, and hold without write enable;
- all defined control/fault/flag bit positions;
- the complete reserved-bit mask;
- full N/C/Z/V replacement;
- N/Z/V replacement preserving C;
- Z-only replacement preserving N/C/V;
- isolated IE set and C clear;
- isolated SETF updates of both six-bit field banks, followed by SEXT/ZEXT
  consumers with preservation of unowned status fields; and
- PUTST full-width replacement from ordinary and shared-SP sources, including
  exact data and `FFFFFFFFh` ownership masks.

The module is also included in warning-free Cyclone V leaf Analysis &
Synthesis.

The independent software model additionally verifies the successful TRAPL
boundary: the complete old ST is stored at the final predecremented SP before
ST becomes `00000010h`. This does not add an RTL interrupt owner or establish
faulted-stack behavior. Source: User's Guide TRAPL, printed pp.13-256..13-258.

The model and bounded RTL also verify EXGF's atomic selected-bank exchange,
upper-register clearing, nonselected-ST preservation, both register files, and
shared SP. The RTL exposes simultaneous register and selected-bank masked write
intents; its FPGA commit edge is not evidence for EXGF's documented one- or
two-machine-state timing.

The independent model and bounded RTL verify PUTST as a complete 32-bit
source-to-ST copy from both files and shared SP. Mixed reserved-bit patterns
are tested at the architectural-model and RTL write-intent boundaries; this is
not silicon readback evidence. The model reports the documented three-state
count, while the serialized RTL commit edge is not architectural timing.

## Incomplete behavior

The following are not yet implemented:

- PUTST's three-state RTL retirement is not implemented; PUSHST and POPST
  primary semantics/timing are classified but remain atomic non-execution
  boundaries in the model and RTL; EXGF architectural retirement timing also
  remains;
- retirement/timing and interrupt-recognition ordering for the model and
  write-intent paths for GETST, SETC, CLRC, EINT, and DINT;
- interrupt/fault ownership of IX and BF;
- general interrupt/fault status save/restore ordering beyond the successful
  TRAPL model boundary;
- single-step recognition;
- pipeline hazards and same-state priority among multiple architectural
  writers;
- documented or measured reserved-bit behavior.

The generic masked-write port is not evidence that those operations are
complete.
