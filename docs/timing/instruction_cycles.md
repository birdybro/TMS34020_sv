# Instruction-cycle evidence and interpretation

## Timing unit

The TMS34020 machine state is one local-clock period, equal to four `CLKIN`
periods. Instruction references and chapter 15 report execution in machine
states. Source: TI *TMS34020 User's Guide*, August 1990, architecture
overview, printed p.1-7.

This repository reserves the term **machine state** for that documented unit.
An FPGA implementation clock, a ready/valid handshake cycle, a Verilator clock
edge, and a TMS34020 machine state are not interchangeable unless a specific
clock-enable mapping has been verified.

## Chapter 15 assumptions

The tables in chapter 15 assume:

- the instruction cache is enabled;
- all instruction words hit in cache;
- all memory requests are granted immediately;
- requested page-mode access is granted;
- no wait states occur; and
- no retries occur.

Source: User's Guide chapter 15 introduction, printed p.15-1.

Therefore a table entry is not, by itself, an end-to-end time from an arbitrary
PC request to completion. Cache miss/fill, disabled-cache fetch, local-memory
arbitration, wait, retry, and dynamic-width costs must be composed from their
own documented cases.

## Hidden trailing writes

Parenthesized states in chapter 15 are hidden memory-write states at the end of
an instruction. The following instruction can execute while those writes
continue. If a following instruction needs the local bus before all hidden
states have been overlapped, it waits for the remainder. Source: User's Guide
chapter 15 introduction, printed p.15-1.

The architectural model's `pending_write_states` field is a disclosed abstract
counter for the few extracted cases that need this dependency. It is not a
complete memory-controller schedule. `MWAIT` consumes the abstract pending
states; full request-by-request validation remains pending.

SETCDP, SETCMP, and SETCSP take `4(1)` states for a power-of-two pitch,
`6(1)` for a sum of two powers, and `3(1)` for an arbitrary pitch. The model
records 4/6/3 visible states and one pending hidden internal-I/O write state.
Source: User's Guide instruction pages 13-227..13-229 and timing table p.15-8.

VLCOL takes `2 (1)` states: two visible instruction states and one hidden
load-color-register write state. Source: User's Guide VLCOL printed p.13-264
and timing table p.15-8. The model carries the hidden state abstractly; no
special-cycle pin timing or fault/retry cycle count is claimed.

TRAPL takes 10 states when the saved-ST stack address is long-word aligned and
12 otherwise. The successful model uses the address after both 32-bit
predecrements to select the case; subtracting 64 preserves the initial SP's
alignment class. Sources: User's Guide TRAPL printed p.13-257 and timing table
p.15-9. These counts assume successful memory cycles under the chapter-15
conditions; stack/vector wait, retry, and fault timing is not implemented.

EXGF takes one state when exchanging FS0/FE0 (`F=0`) and two states when
exchanging FS1/FE1 (`F=1`). This is a TMS34020 timing distinction: the
TMS34010 guide lists one cache-hit state for EXGF without a field-bank split,
and pinned MAME charges one cycle for both banks. The ISA database follows the
TMS34020 primary source; RSC-0019 records the secondary discrepancy. Sources:
TMS34020 User's Guide printed pp.13-111 and 15-4; TMS34010 User's Guide
printed pp.12-17 and 12-78.

PUTST takes three machine states and copies the complete source register into
ST. The same encoding, operation, and three-state summary appear in the
TMS34010 guide; this compatibility evidence does not establish general timing
equivalence between the processors. Sources: TMS34020 User's Guide printed
pp.13-216 and 15-7; TMS34010 User's Guide printed p.12-229 and its instruction
summary.

BLMOVE is labeled only `complex instruction` on its instruction page and in
the chapter-15 table. The guide states that B7 decrements as the move proceeds
and that B0/B2 intermediate updates depend on S/D, making an instruction-level
fixed count inappropriate. Source: User's Guide printed pp.13-44..13-45 and
p.15-3. The model therefore reports no state count; no BLMOVE timing,
page-mode, width, wait, interrupt, fault, or retry case is claimed.

## Cache-fetch interaction

A cache hit reads an instruction word in one machine state, normally overlapped
with preceding completion for effective zero fetch overhead. A disabled-cache
instruction-word fetch with no waits adds three machine states. An example
page-mode refill loads four long words in five states and then uses one
additional state to begin instruction processing. Sources: User's Guide
§5.3.1, printed p.5-5; §5.4, printed p.5-9.

These are bounded facts, not a universal cache timing formula. The exact
dynamic-16-bit, non-page, wait, retry, branch, line-crossing, and interrupt
cases remain unqualified.

## Required machine-readable timing work

Every ISA database entry must ultimately identify:

- its base cache-hit execution cases;
- first-word and extension alignment cases;
- visible and hidden states separately;
- local-memory reads and writes;
- interruptible checkpoints;
- cache-miss and bypass-fetch composition;
- 16-bit and 32-bit transfer effects;
- page-mode eligibility and loss;
- wait and retry extension; and
- source page/table/formula.

The current database includes only the timing information extracted alongside
its partial instruction set. It is not a complete timing database, and no
aggregate cycle-accuracy claim is permitted.
