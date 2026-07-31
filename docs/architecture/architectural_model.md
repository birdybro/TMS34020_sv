# Independent architectural model

The executable model lives in `tools/model`. It is written independently from
RTL structure and uses the canonical ISA database only for decode and metadata.
It is not a line-by-line software translation of either RTL or MAME.

## Current verified slice

Implemented:

- sparse bit-addressed memory with 1–32-bit crossing accesses;
- 15 physical A registers, 15 physical B registers, and shared A15/B15 SP;
- 32-bit ST and bit-addressed, 16-bit-aligned PC;
- verified reset-vector low-nibble loading into CONFIG and PC alignment;
- deterministic randomized state;
- program loading, single stepping, JSON snapshot/replay, and checkpoint traces;
- NOP, IDLE entry, MWAIT, ADDXYI, and RPIX.

The model uses the TI-defined status positions N=31, C=30, Z=29, V=28 and reset
ST value `00000010h`. Source: TI *TMS34020 User's Guide* §4.1, printed pages
4-2..4-3.

The ADDXYI model adds the X and Y 16-bit halves independently and implements
the instruction's unusual documented flag meanings. RPIX implements every
legal PSIZE and the page-13-225 state counts. MWAIT exposes an abstract
pending-write-state input so its minimum/remaining-state timing can be tested.
IDLE enters the documented wait state but does not yet model interrupt
recognition/completion, so it explicitly makes aggregate timing incomplete.

Decoded BLMOVE, SETCDP, SETCMP, SETCSP, TRAPL, and VLCOL entries intentionally
raise `UnsupportedInstruction` without changing state. Their presence in the
ISA database is not an implementation claim.

## Claim boundary

This is an architectural seed, not the completed model required by
`TMS20-0007`. It does not yet implement:

- the remaining instruction set;
- instruction cache state/refill/replacement;
- complete I/O/display/host state;
- 16/32-bit/page-mode transaction targets;
- bus fault, retry, and continuation;
- interrupts and IDLE wakeup;
- graphics arrays and special VRAM cycles;
- multiprocessor or coprocessor handshakes;
- cycle-accurate pipeline overlap.

The default zeroed A/B values are a deterministic constructor convenience, not
a silicon-reset claim. `reset_from_vector` deliberately leaves A/B/SP values
unchanged because the TI reset reference card marks general registers
uninitialized.

## Verification

Run:

```sh
make model-tests
```

Directed tests cover SP aliasing, crossing bit memory, reset vector handling,
seed reproducibility, instruction PC increments, ADDXYI edge behavior and
flags, all RPIX sizes/cycles, invalid PSIZE rejection, MWAIT pending states,
IDLE claim boundaries, no mutation on unsupported instructions, and
snapshot/replay equivalence.
