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
- NOP, ABS, NEG, NEGB, NOT, CLRC, DINT, DSJ, DSJEQ, DSJNE, DSJS, EINT, EXGF,
  EXGPC, GETPC, GETST, CALL, CALLA, CALLR, JACC, JR.L, JUMP, POPST, PUSHST,
  PUTST, RETI/RETM (normal contexts), RETS, MMFM, MMTM,
  ADDK/INC,
  SUBK/DEC, MOVK, MOVI.W, MOVI.L, MOVE, MOVX, MOVY, RL.K, RL.R, SETC,
  BTST.K, BTST.R, SETF, SEXT, ZEXT,
  SLA.K, SLA.R, SLL.K, SLL.R, SRA.K, SRA.R, SRL.K, SRL.R,
  ADD, ADDC, ADDXY, ADDI.W, ADDI.L, SUB, SUBB, SUBXY, SUBI.W, SUBI.L, CMP,
  CMPI.W, CMPI.L, CMPXY, CPW, CVDXYL, CVMXYL, CVSXYL, CVXYL, DIVS, DIVU,
  MODS, MODU, MPYS, MPYU, SWAPF,
  AND, ANDN, OR, XOR, ANDNI/ANDI-encoded operation, BLMOVE, ORI, XORI,
  IDLE entry,
  MWAIT, ADDXYI, CMPK, EXGPS, GETPS, LMO, RMO, RPIX, SETCDP, SETCMP, SETCSP,
  TRAP, TRAPL, and VLCOL.

These handlers cover 103 of 104 currently extracted database forms for their
documented operand domains. REV is
decoded but deliberately has no handler: its complete result is a physical-
device profile value, and exact target-board silicon identity is not yet
verified. A directed test proves that attempting REV raises
`UnsupportedInstruction` and restores the complete preinstruction model/cache
snapshot. This is coverage of a current partial extraction, not instruction
completeness.

MMTM/MMFM cover both operation-specific second-word mask directions, every
register index in both files, shared SP, ascending-store/descending-load
order, 32-bit pointer steps and wrap, MMTM's N-only update, matching-list
round trips, and the published successful state classes. Pointer-in-list and
empty-list inputs roll back because their results are not portable. Abstract
transactions preserve register number, address, value, and direction. Global
timing is marked incomplete: no page-mode, dynamic-width, wait, fault/retry,
partial-list continuation, hidden-write retirement, or physical memory owner
exists. MMFM's `n+5` count also remains provisional under RSC-0033/OQ-0022.
Sources: TMS34020 User's Guide printed pp.8-16..8-17, 13-148..13-151, and
15-6.

SWAPF covers all FS0 widths and valid field positions within a single 32-bit
word, FE0 sign/zero extension, A/B/shared-SP aliases, captured replacement
data, exact N/Z/V and preserved C, five base states, and an ordered abstract
locked read/write trace. Crossing fields roll back because the instruction
page prohibits them without assigning a portable result. This is successful
instruction-boundary evidence only and marks global timing incomplete despite
recording the documented five-state base count: physical lock ownership, waits,
refresh/grant interruption, fault/retry, dynamic 16-bit targets, I/O routing,
and host exclusion remain unimplemented. Source: TMS34020 User's Guide,
printed pp.13-247..13-248, 8-13, 8-26, and 15-9.

TRAP shares the model's independently implemented atomic software-trap helper
with TRAPL while retaining its own unsigned five-bit vector number and
trap-zero exception. All 32 vector numbers are tested. TRAP 0 performs no
stack write, leaves SP unchanged, replaces ST with `0000_0010h`, and reports
seven states. Nonzero traps save the next PC then old ST through two 32-bit
predecrements, report 10/12 aligned/unaligned states, and align the fetched
target PC. This is an instruction-boundary success abstraction; stack/vector
fault, retry, width, page, and pin transactions remain unmodeled. Source:
TMS34020 User's Guide, printed pp.13-253..13-255.

RETS reads a 32-bit return PC at old SP, aligns the redirected PC, and advances
SP by `32 + 16N` bit addresses without changing ST. All 32 encoded argument
counts, aligned and unaligned old SP, exact read traces, PC alignment, and SP
wrap are tested. The model reports TI's 5/6-state alignment cases. This is an
instruction-boundary success abstraction; stack-read width, page mode, waits,
faults, retries, and redirect pipeline timing remain unmodeled. Source:
TMS34020 User's Guide, printed p.13-220.

RETI implements the successful normal interrupt return when the stacked ST has
IX=BF=0. It reads the complete saved ST at old SP and the saved PC at old
SP+32, then atomically restores ST, the aligned PC, and SP+64. Directed tests
cover both old-SP alignment classes, address wrap, restored IE clear/set,
ordered transaction traces, saved-PC alignment, and a TRAP/RETI round trip.
The model reports the documented seven normal states. A stacked IX or BF
selects a 24- or 31-word internal continuation frame and is deliberately
rejected with complete pre-step rollback; those hidden frames are not guessed.
Physical stack waits, dynamic width, page mode, bus faults/retry, pending-
interrupt recognition at restored IE, and redirected fetch timing remain
unmodeled. Sources: TMS34020 User's Guide printed pp.3-29..3-30, Figure 6-3
p.6-10, RETI pp.13-217..13-218, and timing p.15-8; OQ-0023/RSC-0034.

RETM shares that independently written normal-frame helper, reports ten
states, and arms `force_next_instruction_bypass`. The following `step()` uses
native memory bypass for every word in exactly one instruction packet, then
clears the flag; rollback and version-3 snapshots preserve the one-shot state.
A directed stale-cache three-word MOVI.L case proves that opcode/extensions
are fetched from memory without replacing the cached copy and that ordinary
cache lookup resumes for the next instruction. RETM restores IE exactly but
the model has no interrupt/single-step scheduler, so the documented one-
instruction recognition delay remains metadata rather than executable timing.
IX/BF contexts are atomically rejected with RETI. Sources: User's Guide Figure
6-3 p.6-10, RETM p.13-219, comparison p.6-32, and timing p.15-8; RSC-0035.

CALL, CALLA, and CALLR share an independently written atomic success helper
that captures the post-instruction return PC, predecrements SP by 32 bit
addresses, writes the return PC, and commits an aligned redirect without
changing ST. CALL captures its A/B/shared-SP target before the predecrement;
CALLR sign-extends and scales its extension word relative to the sequential
PC; CALLA assembles its low/high target words. Directed tests cover every CALL
register file/index class, the old-SP hazard, signed CALLR extremes and PC
wrap, both stack alignment classes, instruction alignment combinations, exact
write traces, and status preservation. CALL/CALLR report three visible plus
one/four hidden write states. CALLA returns `machine_states=None` and marks
timing incomplete because its primary timing clauses are ambiguous under
RSC-0024/OQ-0015. All three remain success-only abstractions without external
stack fault/retry, width, page, wait, or pin transactions. Sources: TMS34020
User's Guide, printed pp.13-48..13-50 and timing table p.15-3.

JACC tests cover all 16 condition codes, a taken case for every code and a
false case for every conditional code, low-word/high-word target assembly,
forced target alignment, false-path sequential-PC wrap, exact instruction
words/next PC, complete ST/register preservation, cache-only transaction
classes, and the documented three-/four-state boundary cases. Sources: TI
*TMS34020 User's Guide*, August 1990, `JAcondition` printed
pp.13-135..13-136 and timing table p.15-5.

JR.L tests cover all 16 condition codes, a taken case for every code and a
false case for every conditional code, signed `+1`, `+32767`, `-32768`, and
PC-wrapping displacements, exact instruction words/next PC, complete
ST/register preservation, cache-only transaction classes, and the documented
two-/three-state boundary cases. Sources: TI *TMS34020 User's Guide*, August
1990, condition table printed pp.13-27 and 13-138, instruction reference
printed pp.13-139..13-140, and timing table p.15-5.

DSJ/DSJEQ/DSJNE tests reproduce all 15 published example rows, both condition
outcomes, decrement-to-zero suppression, zero-to-`FFFFFFFFh` wrap, signed
forward/backward extremes, PC wrap, A/B files, shared SP, unchanged ST, exact
register-write traces, and the documented two-/three-state instruction
boundary cases. Sources: TI *TMS34020 User's Guide*, August 1990, printed
pp.13-103..13-107.

DSJS tests reproduce all three published input rows, both directions, zero and
maximum magnitudes, A/B/shared-SP selection, instruction-address range
endpoints, PC wrap, unchanged ST, exact register-write traces, and the
documented two-/three-state cases. The direction bit controls add/subtract of
an unsigned magnitude; it does not use the signed-extension path of DSJ.
Source: TI *TMS34020 User's Guide*, August 1990, printed p.13-108.

The model uses the TI-defined status positions N=31, C=30, Z=29, V=28 and reset
ST value `00000010h`. Source: TI *TMS34020 User's Guide* §4.1, printed pages
4-2..4-3.

ADDXY and ADDXYI add the X and Y 16-bit halves independently and implement
their unusual documented flag meanings. SUBXY independently subtracts the
source halves from the destination halves; N/Z report X/Y equality while V/C
report unsigned X/Y borrows. The source and destination are both captured
before writeback, including same-register and shared-SP aliases. All three XY
arithmetic operations leave lower ST fields intact. Sources: TI *TMS34020
User's Guide*, August 1990, printed pp.13-38..13-39 and 13-246; ADDXY/SUBXY
compatibility cross-check: TI *TMS34010 User's Guide*, 1988, printed pp.12-41
and 12-251..12-252.

CMPXY is separately implemented as a nondestructive compare because its C/V
definitions differ from SUBXY: the model computes the wrapped 16-bit
destination-minus-source result for each half, places X/Y equality in N/Z,
and places the Y/X result sign bits in C/V. It does not use unsigned borrow or
signed overflow. Tests reproduce all nine published rows and cover cases where
result sign differs from borrow, plus A/B, same-register, and both shared-SP
operand positions. Source: TMS34020 User's Guide printed p.13-84.

CPW captures its explicit point plus implied B5/WSTART and B6/WEND before
writing the destination, compares signed X/Y halves against inclusive bounds,
writes the four-bit outcode into bits `[8:5]`, and changes only V. Model tests
reproduce all 16 primary rows, signed negative/positive boundary
discriminators, A/B/shared-SP forms, implied-register hazards, and the
documented one-state boundary. The standalone RTL leaf covers the signed
comparison semantics, but the scalar owner remains absent because the current
two-read register composition cannot simultaneously acquire Rs, B5, and B6.
Sources: TMS34020 User's Guide printed pp.13-85..13-86 and p.15-4.

The four XY-to-linear handlers share equation-level arithmetic but retain
their distinct explicit and implied operands. Signed X/Y halves and signed
arbitrary pitches produce a modulo-32-bit linear result; encoded one- and
two-power CONVxP fields select one or two signed-Y shifts. CVDXYL uses
same-file R4/OFFSET, CVMXYL uses unscaled X with no offset, CVSXYL takes its
offset from explicit Rs, and CVXYL uses B4/OFFSET. All operands are captured
before destination writeback, including same-register and implied-register
aliases, and ST is unchanged. Directed tests cover the primary equations,
every pitch category, signed wrap, all PSIZE values represented by the guide,
and the published pitch-class state cases. CVXYL arbitrary pitch provisionally
uses the instruction page's 14 states; the chapter-15 table's conflicting 15
remains RSC-0026/OQ-0017, so that case is not timing-verified. The three
inconsistent CVXYL PSIZE=4 table rows are corrected according to the repeated
equation under RSC-0025. Sources: TMS34020 User's Guide printed pp.4-28..4-29,
12-47..12-49, 13-87..13-93, and 15-4.

DIVS and DIVU capture Rs, Rd, and conditional Rd+1 before any write. Odd Rd
uses a 32-bit dividend; even Rd forms a 64-bit pair and returns the remainder
to Rd+1. Python integer arithmetic is explicitly conditioned to signed
truncation toward zero, and quotient overflow suppresses every destination
write while still updating the documented status subset. Directed cases cover
the primary tables, both register files through decode, shared-SP pair/source
aliasing, divisor zero, valid `80000000h`, positive and negative signed-range
overflow, raw high-half overflow, remainder sign, and 5/7/37/39/40/41-state
classes. The nonzero signed early-overflow 7-state selection is marked timing
incomplete under RSC-0027/OQ-0018. Sources: TMS34020 User's Guide printed
pp.13-96..13-99 and 15-4; compatibility cross-check: TMS34010 User's Guide
printed pp.12-63..12-66 and Appendix A p.A-15.

MODS/MODU capture the same-file Rs divisor and Rd dividend before writing the
remainder, including same-register and shared-SP aliases. Signed division uses
truncation toward zero so the remainder has the dividend's sign. Directed
tests reproduce every primary row, zero-divisor value/status behavior,
minimum signed values, quotient-overflow-with-valid-remainder, alias ordering,
C preservation, and the 35/40/3-state cases. The published MODS 41-state
result cannot be generated by the documented operand domain and is not claimed
as tested; RSC-0029/OQ-0019 records that boundary. Sources: TMS34020 User's
Guide printed pp.13-152..13-153 and 15-5.

MPYS/MPYU capture Rs, Rd, and the old Rd+1 alias before any even-destination
pair write. They extract low FS1, sign- or zero-extend it, multiply by signed or
unsigned 32-bit Rd, write the full pair for even Rd or only the low word for
odd Rd, and derive N/Z from the full product in both cases. Tests reproduce all
arithmetic-consistent primary rows for every published FS1, distinguish full
from truncated odd-result flags in three ways, cover source=destination,
source=Rd+1/shared-SP pairing, C/V preservation, and reject undocumented odd
FS1 atomically. RSC-0031 records the corrected primary operand. Timing follows
the detailed pages provisionally—MPYS `5+FS1/2`, MPYU plus one when raw Rs bit
31 is set—because chapter 15 swaps that case under RSC-0030/OQ-0020. Sources:
TMS34020 User's Guide printed pp.13-172..13-176 and 15-6.

BTST.K recovers the selected bit from the one's-complement object field.
BTST.R uses only the low five bits of its same-file source. Both preserve every
register and every ST bit except Z, set Z for a zero tested bit, and take one
TMS34020 machine state. Tests cover all 25 published input rows plus A/B,
same-register, and source/destination shared-SP cases. One p.13-47 example
prints the opposite Z digit from its own operands and bit definition; RSC-0018
records the evidence and corrected expectation. Sources: TI *TMS34020 User's
Guide*, August 1990, printed pp.13-46..13-47.

SETF atomically replaces only the selected six-bit FS/FE bank in ST; an
encoded FS value of zero represents 32 bits. SEXT and ZEXT select FS0 or FS1
independently from their A/B/shared-SP destination, operate on the
right-justified low field, and preserve every status bit except SEXT's N/Z or
ZEXT's Z. Directed tests cover all 32 encoded sizes in both banks, every
published result row, both register files, and the shared-SP alias. The model
reports the TMS34020's one-state SETF, two-state SEXT, and one-state ZEXT
counts; these differ from the compatible TMS34010 instruction timings.
Sources: TI *TMS34020 User's Guide*, August 1990, printed pp.13-230..13-232
and 13-268, status layout pp.4-2..4-3, and timing summary pp.13-17..13-18;
compatibility timing cross-check: TI *TMS34010 User's Guide*, 1988, printed
pp.12-237..12-238 and 12-257.

EXGF captures the selected six-bit FS/FE bank and the destination register's
low six bits before atomically exchanging them. The register result is
zero-extended, so its upper 26 bits clear; every nonselected ST bit is
preserved. Directed tests reproduce both published rows and cover both banks,
both register files, ordinary destinations, and shared SP. The model reports
one state for `F=0` and two for `F=1`; RSC-0019 records pinned MAME's
field-one undercount. Sources: TMS34020 User's Guide printed pp.13-111 and
15-4; compatibility cross-check: TMS34010 User's Guide printed pp.12-17 and
12-78.

PUTST captures the complete selected A/B register, including the shared-SP
alias, and replaces all 32 ST bits without changing the source. Directed tests
cover both files, ordinary and shared-SP indices, all-zero/all-one/mixed
patterns, and the three documented machine states. The mixed pattern exercises
reserved positions as part of the documented full-width transfer; it is model
semantics, not evidence for silicon-revision-specific reserved-bit readback.
Sources: TMS34020 User's Guide printed pp.4-2..4-3, 13-216, and 15-7;
compatibility cross-check: TMS34010 User's Guide printed p.12-229 and its
instruction summary.

POPST reads the complete 32-bit value at the old SP, replaces all of ST, and
then advances SP by 32 bit addresses. It reports six states for an aligned old
SP and seven otherwise. PUSHST captures the complete old ST, predecrements SP
by 32, and writes the captured value at that new address without changing ST.
It reports two visible states and schedules one aligned or two unaligned hidden
write states. Directed tests cover aligned and unaligned addresses, a
bit-address-space wrap, exact data transaction traces, full-width values, SP
ordering, status preservation/replacement, and a PUSHST-to-POPST round trip.
These are successful atomic transaction abstractions: dynamic 16-bit
decomposition, page mode, waits, faults, retries, and partial-write safety are
not modeled. Sources: TMS34020 User's Guide printed pp.13-214..13-215 and
15-7; compatibility cross-check: TMS34010 User's Guide printed
pp.12-227..12-228 and its instruction summary.

RPIX implements every
legal PSIZE and the page-13-225 state counts. MWAIT exposes an abstract
pending-write-state input so its minimum/remaining-state timing can be tested.
IDLE enters the documented wait state but does not yet model interrupt
recognition/completion, so it explicitly makes aggregate timing incomplete.

GETPC writes the single-word instruction's sequential `PC'` to the selected
A/B register or shared SP without changing status. EXGPC first captures the
old selected-register value, writes the same sequential `PC'` to that
destination, and redirects PC to the captured value with bits `[3:0]` cleared.
The handlers use the instruction-boundary PC established by `step()`, not an
instruction-cache fetch cursor, and report the documented one- and two-state
counts. Source: TI *TMS34020 User's Guide*, August 1990, printed pp.13-112 and
13-130; PC alignment and increment rules in §4.2, printed p.4-4.

JUMP captures the selected A/B register or shared SP, loads PC from that value
with bits `[3:0]` cleared, and preserves the source and complete ST. Directed
tests reproduce all three published targets and cover both register files,
ordinary boundary indices, and the shared-SP alias. The handler reports the
documented two machine states. Sources: TMS34020 User's Guide printed p.13-141
and §4.2 p.4-4; compatibility cross-check: TMS34010 User's Guide printed
p.12-98 and its instruction summary.

CMPK implements the encoded-zero-means-32 constant and nondestructive
subtraction flags. EXGPS and GETPS use the internal PSIZE register; EXGPS
records its architecturally visible 16-bit internal-I/O write in the transaction
trace and schedules the one hidden write state shown by TI's `2 (1)` timing.
Subsequent modeled execution states overlap outstanding hidden writes, while
MWAIT drains them. RMO returns the least-significant set-bit number and changes
only Z. LMO returns the number of leading zero bits for a nonzero source,
returns zero for a zero source, and likewise changes only Z. Its same-file
source is captured before the destination write, including when `Rs == Rd`;
A15/B15 use the shared SP state. Source: TI *TMS34020 User's Guide*, August
1990, printed p.13-147.
SETCDP, SETCMP, and SETCSP read B3/DPTCH, B11/MPTCH, and B1/SPTCH,
respectively. They generate the documented 16-bit one's-complement shift
fields in CONVDP, CONVMP, or CONVSP for one- and two-power pitches, use zero
for arbitrary pitches, preserve ST, and schedule the parenthesized hidden
internal-I/O write state. Sources: the same guide, CONVxP description printed
pp.4-28..4-29, Figure 12-20 on p.12-49, instruction pages
13-227..13-229, and timing table p.15-8. Pinned MAME discrepancies are recorded
in `docs/research/source_conflicts.md` RSC-0014.
VLCOL emits a successful special-VRAM color-load transaction at nominal
address zero, records status code `0111b`, copies all 32 bits of B9/COLOR1 into
the external color-latch abstraction, preserves ST, and schedules the
documented hidden write state. Field size is ignored. Sources: the same guide,
§8.12.3 printed p.8-38 and VLCOL pp.13-264..13-265. Special-cycle bus
fault/retry is not modeled, and the pinned MAME handler is only a stub; see
RSC-0015.
TRAPL predecrement-pushes the two-word instruction's return PC and old ST,
sets SP to the saved-ST address, loads `00000010h` into ST, and fetches the
32-bit vector selected by the signed extension word. It records the two stack
writes and vector fetch in order and uses TI's 10/12-state saved-ST alignment
split. The vector-entry formula follows both TI vector-map figures and its
worked examples rather than contradictory prose; see
`docs/architecture/interrupts.md` and RSC-0016. Stack/vector faults and retries
are not modeled.
RETS independently covers every unsigned argument count, aligned/unaligned old
SP, PC low-nibble alignment, SP wrap, unchanged ST and general registers, and
one exact 32-bit stack-read transaction. External bus decomposition and
fault/retry remain absent.
BLMOVE validates all four S/D alignment modes, performs a bit-exact successful
non-overlapping copy, advances B0/SADDR and B2/DADDR by the original B7/DYDX,
clears B7, and preserves ST. It emits one abstract block transaction and
leaves machine-state timing incomplete because TI labels the instruction
complex. Overlapping nonidentical ranges raise `ModelError` rather than
inventing a result. Intermediate register updates, interruption, page mode,
bus decomposition, faults, retries, and continuation remain absent. Sources:
the same guide, printed pp.13-44..13-45 and §8.4 printed p.8-16; see
`docs/graphics/array_operations.md` and RSC-0017.
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

MOVX merges the source register's low X half into the destination's low half;
MOVY similarly merges the high Y half. Both operands use the same selected A
or B file, the other destination half and all ST bits remain unchanged, and
each takes one documented state. Shared index 15 uses the common SP owner.
Sources: the same guide, printed pp.13-170..13-171 and timing-table p.15-6.

MOVE copies a full 32-bit register, using M and R to select same-file or
cross-file A/B operands. It is the only MOVE form that may cross register
files. It sets N/Z from the copied value, preserves C, clears V, and takes one
state; index 15 on either side resolves to the shared SP owner. Source: the same
guide, printed p.13-158.

RL.K rotates Rd left by its embedded count; RL.R takes the count from the low
five bits of a same-file source register. Both forms use counts 0–31, write C
from the last bit rotated out (zero for count 0), write Z from the result,
preserve N/V, and take one state. Shared SP and same-register operands use
pre-write values. Sources: the same guide, printed pp.13-222..13-223 and
timing-table p.15-8. The count-30 example's contradictory C digit is resolved
in `docs/research/source_conflicts.md` RSC-0013.

SLA/SLL take direct five-bit left-shift counts from either the object word or
the low five bits of a same-file source register. SRA/SRL recover their
right-shift count by taking the five-bit two's complement of that field or
source value. All forms clear C at count zero and otherwise copy the last bit
shifted out. SLL/SRL preserve N/V and replace C/Z; SRA preserves V and replaces
N/C/Z; SLA replaces N/C/Z/V and takes three states. SLA overflow is set when
the new sign or any shifted-out bit differs from the original sign. Shared SP
and same-register source/destination cases use pre-write values. Sources: the
same guide, printed pp.13-233..13-240 and timing table p.15-8.

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
ANDNI/ORI/XORI while changing only Z. CLR is the documented XOR alias when
the source and destination register-number fields are equal; the model retains
the canonical XOR trace mnemonic and exhaustively checks all 32 A/B encodings,
including both encodings of the shared SP alias. ANDI is the documented
assembler alias for ANDNI and complements its requested operand in the two
extension words.
The model executes the encoded ANDNI operation and counts two states when the
first extension word is long-word aligned and three otherwise. Sources: TI
*TMS34020 User's Guide*, August 1990, printed pp.13-40..13-43, 13-57,
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
Version-3 JSON snapshots include all cache state, pending transactions, and
the RETM one-instruction bypass state. Versions 1 and 2 remain readable with
that state safely defaulted inactive.

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
seed reproducibility, instruction PC increments, all 16 ADDXY and nine SUBXY
published rows, B-file/same-register/shared-SP hazards, ADDXYI edge behavior
and flags, all TI example rows for
ABS/NEG/NEGB/NOT, directed
ADD/ADDC/SUB/SUBB/CMP arithmetic boundaries and nondestructive CMP,
all TI ADDI example rows, signed-word extension, long-immediate alignment
timing, A/B selection, and SP aliasing; all TI SUBI arithmetic rows,
one's-complement object words, borrow/overflow boundaries, alignment timing,
and SP aliasing, with the RSC-0009 status-table correction kept explicit;
all TI CMPI rows, complemented object words, nondestructive A/B/SP behavior,
lower-ST preservation, and short/long alignment timing;
all TI register/immediate logical example rows, ANDI encoded-complement
behavior, aligned and unaligned immediate timing,
CLRC/SETC preservation, DINT/EINT IE changes, GETPC/EXGPC primary rows,
A/B/shared-SP selection, sequential-PC exchange, redirect alignment and status
preservation, complete GETST and PUTST transfers, POPST/PUSHST aligned and
unaligned ordering, bit-address wrap, traces, hidden writes, and round trip,
all published JUMP targets, A/B/shared-SP selection, source/status
preservation, redirect alignment and timing,
all TI ADDK and INC-alias example rows,
all SUBK and DEC-alias example rows,
every SUBK constant, every MOVK constant, encoded-zero/B/SP cases for all three
constant families, complete MOVK status preservation, all published MOVI
short/long rows, sign extension, C preservation, the resolved Z/V behavior,
long alignment cases, A/B selection, and shared SP; all MOVE register rows,
same/cross-file selection, shared SP, same-register operation, C preservation,
and N/Z/V updates; all MOVX/MOVY example rows, half preservation, same-file
selection, shared SP, and status preservation;
every published SLA/SLL/SRA/SRL constant and register
row, all 32 counts against an independent iterative SLA overflow oracle,
direct versus two's-complement count decoding, partial status preservation,
same-register count hazards, B-file selection, and shared SP;
CMPK constants/flags; PSIZE get/exchange; RMO
zero/bit-position cases, all RPIX sizes/cycles, invalid PSIZE rejection, MWAIT
pending states, all SETCDP/SETCMP/SETCSP primary conversion rows, implied
source/destination selection, conversion-field boundaries, hidden writes,
VLCOL full-width/field-size-independent successful special-cycle traces,
TRAPL primary vector examples, signed extremes, stack order, ST/PC changes,
aligned/unaligned timing, and vector-target alignment,
all RETS argument counts, both stack alignment cases, exact PC-pop traces,
redirect alignment, SP wrap, and status preservation,
normal RETI ordered ST/PC pops, status and IE restoration, PC alignment, SP
wrap, TRAP round trip, plus atomic IX/BF refusal,
normal RETM restore, 10 states, snapshotted one-shot full-packet memory bypass,
stale-cache discrimination, and atomic IX/BF refusal,
all CALL A/B/shared-SP target classes, old-SP capture ordering, aligned and
unaligned hidden writes, CALLR signed extremes and PC wrap, and CALLA
low/high-word target assembly with explicitly incomplete timing,
all 16 CPW primary outcodes, signed/inclusive bounds, V-only status, explicit
operand aliases, and implied B5/B6 read-before-write hazards,
all four XY-to-linear forms, one-/two-power and arbitrary-pitch paths, signed
coordinates/pitches, PSIZE/offset variants, aliases, unchanged ST, and the
published state cases plus provisional CVXYL arbitrary-pitch selection,
all BLMOVE S/D modes, alignment guards, zero/self/wrapping ranges, abstract
transactions, overlap refusal, and final B0/B2/B7/ST state;
IDLE claim boundaries, no mutation on unclassified instructions, and
snapshot/replay equivalence.

The cache tests independently cover reset metadata, the Figure 5-2
address partition, every demand-longword-last refill rotation, segment and
subsegment misses, all LRU stack positions, `CD` preservation, `CF` flush,
self-modifying-code staleness, current-cycle-only retry, fault pause/resume,
fault abort without `P` commit, pending-refill replay, cold opcode fetch,
same-subsegment hits, an extension-word subsegment crossing, three-word
disabled fetch, flush-visible code modification, and cache rollback on
unclassified execution.
