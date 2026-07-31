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
- an instruction-fetch-integrated transaction-level cache model with four
  SSAs, 32 present flags, move-to-front LRU, demand-longword-last refills,
  `CD` bypass, `CF` flush, stale self-modifying-code behavior, retry, fault
  pause/resume, abort, and pending-refill snapshot/replay;
- NOP, ABS, NEG, NEGB, NOT, CLRC, DINT, EINT, GETST, ADDK/INC, SUBK/DEC, MOVK,
  MOVI.W, MOVI.L, SETC,
  ADD, ADDC, ADDI.W, ADDI.L, SUB, SUBB, SUBI.W, SUBI.L, CMP, CMPI.W, CMPI.L,
  AND, ANDN, OR, XOR, ANDNI/ANDI-encoded operation, ORI, XORI, IDLE entry,
  MWAIT, ADDXYI, CMPK, EXGPS, GETPS, RMO, and RPIX.

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

ADDK adds the unsigned embedded constant 1–32 in one state and replaces NCZV;
an all-zero five-bit K field represents 32. INC is the documented assembler
alias for the K=1 encoding, not a separate object-code family. The model
executes the canonical ADDK record while preserving every published INC
example. Sources: the same guide, printed pp.13-37 and 13-134 and timing-table
p.15-2.

SUBK subtracts the unsigned embedded constant 1–32 in one state and replaces
NCZV; an all-zero five-bit K field represents 32. DEC is the documented
assembler alias for the K=1 encoding, not a separate object-code family. The
model executes the canonical SUBK record while preserving every published DEC
example. Sources: the same guide, printed pp.13-94 and 13-245 and timing-table
p.15-2.

MOVK zero-extends the unsigned embedded constant 1–32 into the selected
destination without changing ST; an all-zero five-bit K field represents 32.
It takes one documented state. Source: the same guide, printed p.13-169 and
timing-table p.15-6.

MOVI.W sign-extends its 16-bit extension word; MOVI.L consumes low then high
extension words without conversion. Both write N and Z from the moved result,
preserve C, and clear V. The short form takes two states; the long form takes
two when its first extension word is long-word aligned and three otherwise.
Sources: the same guide, printed pp.13-167..13-168 and timing-table p.15-6.
The p.13-167 Z/V label defect is resolved explicitly in
`docs/research/source_conflicts.md` RSC-0012.

The two ADDI encoding forms add either a sign-extended 16-bit word or a full
32-bit immediate and replace NCZV. The short form takes two documented states;
the long form takes two states when its first extension word is long-word
aligned and three otherwise. `ADDI.W` and `ADDI.L` are database form names;
the TI assembly mnemonic for both remains `ADDI`. Source: TI *TMS34020 User's
Guide*, August 1990, printed pp.13-35..13-36.

The two SUBI encoding forms recover the source immediate from the documented
one's-complement extension word or words, subtract it from Rd, and replace
NCZV with N, borrow, zero, and signed overflow. The short form takes two
states; the long form uses the same aligned two-state/unaligned three-state
split as ADDI.L. `SUBI.W` and `SUBI.L` are database form names; TI uses `SUBI`
for both. Source: the same guide, printed pp.13-243..13-244. The inconsistent
first long-form example flag is resolved explicitly in
`docs/research/source_conflicts.md` RSC-0009.

CMPI.W and CMPI.L use the same complemented immediate recovery, subtraction
flags, and short/long alignment cases as SUBI, but do not write Rd. The model
traces therefore contain no register write for either form, including shared
SP. `CMPI.W` and `CMPI.L` are database form names; TI uses `CMPI` for both.
Source: the same guide, printed pp.13-81..13-82 and timing-table p.15-4.

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
complete ST value without modifying it. ADDK/INC and SUBK/DEC implement the
documented one-state result and N/C/Z/V behavior, including carry, borrow, and
signed overflow edges. Sources: TI *TMS34020 User's Guide*, August 1990, §4.1
printed pp.4-2..4-3 and instruction pages 13-37, 13-58, 13-94, 13-109, 13-132,
13-134, 13-226, and 13-245. DINT is on printed p.13-95; that scanned page is
image-only in the acquired PDF and was visually inspected rather than inferred
from failed OCR. Interrupt recognition around DINT/EINT remains outside this
instruction-boundary model slice.

Where TI says PSIZE is assumed to be one of 1, 2, 4, 8, 16, or 32, the model
raises `ModelError` for any other current value. That is a verification guard,
not a claim that physical silicon traps or otherwise behaves the same way for
an undocumented PSIZE value.

Decoded BLMOVE, SETCDP, SETCMP, SETCSP, TRAPL, and VLCOL entries intentionally
raise `UnsupportedInstruction` without changing state. Their presence in the
ISA database is not an implementation claim.

The cache model is in `tools/model/cache.py` and follows the primary contract
in `docs/cache/instruction_cache.md` and
`docs/memory/bus_fault_retry.md`. It exposes 16-bit direct instruction-fetch
requests and four ordered 32-bit cache-fill requests. Successful prior refill
beats survive a retry or fault; the current native request alone is reissued,
and `P` is committed only after all four long words succeed. This is a
transaction-level restart model, not a local-clock waveform or a cache-miss
cycle count.

`Tms34020Model.step()` fetches each opcode and extension word through this
cache. Each instruction trace records lookup classification and every native
cache-fill or disabled-fetch read. `CONTROL.CD` and `HSTCTLH.CF` are taken from
their architectural I/O addresses. A miss or bypass leaves the instruction's
documented execution-state count intact but marks aggregate timing incomplete
and records why; no unverified refill overlap is added. Decode or execution
failure rolls processor and cache state back to the pre-step checkpoint.
Version-2 JSON snapshots include all cache state and pending transactions.

`load_program()` flushes the cache by default because it is a test/program
loader, not a modeled CPU data write. Tests of self-modifying code write
`BitMemory` directly or request `flush_cache=False`.

## Claim boundary

This is an architectural seed, not the completed model required by
`TMS20-0007`. It does not yet implement:

- the remaining instruction set;
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
all TI ADDI example rows, signed-word extension, long-immediate alignment
timing, A/B selection, and SP aliasing; all TI SUBI arithmetic rows,
one's-complement object words, borrow/overflow boundaries, alignment timing,
and SP aliasing, with the RSC-0009 status-table correction kept explicit;
all TI CMPI rows, complemented object words, nondestructive A/B/SP behavior,
lower-ST preservation, and short/long alignment timing;
all TI register/immediate logical example rows, ANDI encoded-complement
behavior, aligned and unaligned immediate timing,
CLRC/SETC preservation, DINT/EINT IE changes, complete GETST transfer, all TI
ADDK and INC-alias example rows, all SUBK and DEC-alias example rows,
every SUBK constant, every MOVK constant, encoded-zero/B/SP cases for all three
constant families, complete MOVK status preservation, all published MOVI
short/long rows, sign extension, C preservation, the resolved Z/V behavior,
long alignment cases, A/B selection, shared SP, CMPK
constants/flags, PSIZE get/exchange, RMO
zero/bit-position cases, all RPIX sizes/cycles, invalid PSIZE rejection, MWAIT
pending states, IDLE claim boundaries, no mutation on unsupported
instructions, and snapshot/replay equivalence.

The cache tests independently cover reset metadata, the Figure 5-2
address partition, every demand-longword-last refill rotation, segment and
subsegment misses, all LRU stack positions, `CD` preservation, `CF` flush,
self-modifying-code staleness, current-cycle-only retry, fault pause/resume,
fault abort without `P` commit, pending-refill replay, cold opcode fetch,
same-subsegment hits, an extension-word subsegment crossing, three-word
disabled fetch, flush-visible code modification, and cache rollback on
unsupported execution.
