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
- NOP, ABS, NEG, NEGB, NOT, CLRC, DINT, EINT, GETST, INC, DEC, SETC, ADD,
  ADDC, SUB, SUBB, CMP, AND, ANDN, OR, XOR, ANDNI/ANDI-encoded operation,
  ORI, XORI, IDLE entry, MWAIT, ADDXYI, CMPK, EXGPS, GETPS, RMO, and RPIX.

The model uses the TI-defined status positions N=31, C=30, Z=29, V=28 and reset
ST value `00000010h`. Source: TI *TMS34020 User's Guide* §4.1, printed pages
4-2..4-3.

The ADDXYI model adds the X and Y 16-bit halves independently and implements
the instruction's unusual documented flag meanings. RPIX implements every
legal PSIZE and the page-13-225 state counts. MWAIT exposes an abstract
pending-write-state input so its minimum/remaining-state timing can be tested.
IDLE enters the documented wait state but does not yet model interrupt
recognition/completion, so it explicitly makes aggregate timing incomplete.

CMPK implements the encoded-zero-means-32 constant and nondestructive
subtraction flags. EXGPS and GETPS use the internal PSIZE register; EXGPS
records its architecturally visible 16-bit internal-I/O write in the transaction
trace and schedules the one hidden write state shown by TI's `2 (1)` timing.
Subsequent modeled execution states overlap outstanding hidden writes, while
MWAIT drains them. RMO returns the least-significant set-bit number and changes
only Z.
The common unary family implements the instruction-specific partial status
writes, including ABS preserving C and NOT preserving N/C/V. Sources: TI
*TMS34020 User's Guide*, August 1990, printed pp.13-32, 13-83, 13-113,
13-131, 13-178..13-181, and 13-224; hidden-cycle definition on printed p.15-1.

The binary register family implements ADD/ADDC carry and SUB/SUBB/CMP borrow,
including carry/borrow inputs and one-state timing. Sources: the same guide,
printed pp.13-33..13-34, 13-80, and 13-241..13-242.

The register and immediate logical families implement AND/ANDN/OR/XOR and
ANDNI/ORI/XORI while changing only Z. ANDI is the documented assembler alias
for ANDNI and complements its requested operand in the two extension words.
The model executes the encoded ANDNI operation and counts two states when the
first extension word is long-word aligned and three otherwise. Sources: TI
*TMS34020 User's Guide*, August 1990, printed pp.13-40..13-43,
13-182..13-183, 13-266..13-267, and timing-table pp.15-3, 15-7, and 15-9.
The ORI page's duplicated “aligned” wording is resolved in
`docs/research/source_conflicts.md` RSC-0006.

CLRC/SETC and DINT/EINT update only C and IE respectively. GETST copies the
complete ST value without modifying it. INC and DEC implement the documented
one-state result and N/C/Z/V behavior, including carry, borrow, and signed
overflow edges. Sources: TI *TMS34020 User's Guide*, August 1990, §4.1 printed
pp.4-2..4-3 and instruction pages 13-58, 13-94, 13-109, 13-132, 13-134, and
13-226. DINT is on printed p.13-95; that scanned page is image-only in the
acquired PDF and was visually inspected rather than inferred from failed OCR.
Interrupt recognition around DINT/EINT remains outside this
instruction-boundary model slice.

Where TI says PSIZE is assumed to be one of 1, 2, 4, 8, 16, or 32, the model
raises `ModelError` for any other current value. That is a verification guard,
not a claim that physical silicon traps or otherwise behaves the same way for
an undocumented PSIZE value.

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
flags, all TI example rows for ABS/NEG/NEGB/NOT, directed
ADD/ADDC/SUB/SUBB/CMP arithmetic boundaries and nondestructive CMP,
all TI register/immediate logical example rows, ANDI encoded-complement
behavior, aligned and unaligned immediate timing,
CLRC/SETC preservation, DINT/EINT IE changes, complete GETST transfer, all TI
INC/DEC example rows, CMPK constants/flags, PSIZE get/exchange, RMO
zero/bit-position cases, all RPIX sizes/cycles, invalid PSIZE rejection, MWAIT
pending states, IDLE claim boundaries, no mutation on unsupported
instructions, and snapshot/replay equivalence.
