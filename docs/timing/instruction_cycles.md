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

DIVU takes 37 states normally, 7 for odd-Rd divisor zero, and 5 for even-Rd
divisor zero or high-half early overflow. DIVS takes 39 states normally for
odd Rd, 40 for even Rd, 41 when the result word is `80000000h`, and 7 for
divisor zero. Chapter 15 also assigns 7 to the signed even-Rd `Rs <= Rd`
early-overflow condition that the instruction page does not separately list;
the model/leaf provisionally interpret this as a magnitude-normalized
high-half comparison under RSC-0027/OQ-0018. The leaf's 32 FPGA iteration
clocks are an implementation handshake, not these machine states. Sources:
User's Guide printed pp.13-96..13-99 and 15-4.

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

TRAP takes 7 states for trap number zero. That reset exception does not push
PC/ST and does not change SP. A nonzero trap takes 10 states when the
post-predecrement saved-ST address is 32-bit aligned and 12 otherwise. The
TMS34010 publishes materially different aligned/unaligned timing, and pinned
MAME charges one shared 16-cycle value, so neither is a TMS34020 timing
reference. Sources: TMS34020 User's Guide printed pp.13-253..13-255;
TMS34010 User's Guide printed pp.12-253..12-254. The model reports the three
instruction-boundary cases; physical stack/vector waits, width conversion,
faults, and retries remain absent.

RETS takes 5 states when the old-SP address used for its 32-bit return-PC read
is long-word aligned and 6 otherwise. The compatible TMS34010 instruction
instead publishes minimum 7/9 aligned/unaligned states, while pinned MAME
charges a fixed 7 cycles to both devices. Sources: TMS34020 User's Guide RETS,
printed p.13-220; TMS34010 User's Guide RETS, printed p.12-232 and Appendix A
p.A-16. The model reports the two instruction-boundary cases; external
stack-read waits, dynamic width, page mode, faults, retries, and redirect
pipeline timing remain absent.

CALL and CALLR each take three visible states followed by a hidden stack write
of one state when SP is long-word aligned or four states otherwise. The model
records that hidden dependency in `pending_write_states`; it does not claim
physical bus scheduling, waits, dynamic-width, page-mode, fault, or retry
timing. Their compatible TMS34010 forms publish materially longer timing, and
pinned MAME's shared handlers omit the TMS34020 alignment/hidden cases. Sources:
TMS34020 User's Guide printed pp.13-48, 13-50, and 15-3; TMS34010 User's Guide
printed pp.12-48 and 12-50; RSC-0024.

CALLA's three-word architectural state is implemented in the model, but no
machine-state value is reported. The TMS34020 instruction page and repeated
chapter-15 table print four immediate-data/SP alignment clauses whose grammar
does not uniquely identify the four cases. Reusing TMS34010 or MAME timing
would manufacture a result. RSC-0024 records the conflict and OQ-0015 defines
the evidence needed to resolve it. Sources: TMS34020 User's Guide printed
pp.13-49 and 15-3; TMS34010 User's Guide printed p.12-49.

EXGF takes one state when exchanging FS0/FE0 (`F=0`) and two states when
exchanging FS1/FE1 (`F=1`). This is a TMS34020 timing distinction: the
TMS34010 guide lists one cache-hit state for EXGF without a field-bank split,
and pinned MAME charges one cycle for both banks. The ISA database follows the
TMS34020 primary source; RSC-0019 records the secondary discrepancy. Sources:
TMS34020 User's Guide printed pp.13-111 and 15-4; TMS34010 User's Guide
printed pp.12-17 and 12-78.

CPW takes one machine state, has no data-memory transaction, and updates only
the V status bit while writing its destination outcode. The compatible
TMS34010 page reports `1,4` in its machine-state/input-clock notation; this is
compatible evidence for this instruction only, not graphics-pipeline timing
equivalence. Sources: TMS34020 User's Guide printed pp.13-85..13-86 and
timing table p.15-4; TMS34010 User's Guide printed pp.12-57..12-58 and
Appendix A p.A-13.

CVDXYL, CVMXYL, and CVSXYL take 2 machine states for a power-of-two pitch, 3
for a sum of two powers, and 14 for an arbitrary pitch. CVXYL takes 3 and 4
states for the first two classes. Its instruction page specifies 14 for an
arbitrary pitch, while the chapter-15 table specifies 15; the model and
semantic RTL leaf provisionally select the instruction-page value, and
RSC-0026/OQ-0017 keep the real-device timing open. These are
register/internal-I/O execution cases with no data-memory transaction; an
instruction-cache miss composes separately. CVXYL's compatible TMS34010 form
publishes `3,6` under the older power-of-two-only conversion contract, so its
timing sequencer cannot be inherited. Sources: TMS34020 User's Guide printed
pp.12-47..12-49, 13-87..13-93, and timing table p.15-4; TMS34010 User's Guide
printed pp.12-59..12-60.

JUMP takes two machine states, preserves ST and its source register, and loads
an aligned PC from that register. Both processor guides give the same encoding,
operation, and two-state cache-hit summary; this isolated match is not evidence
that their branch pipelines are generally timing-equivalent. Sources: TMS34020
User's Guide printed p.13-141; TMS34010 User's Guide printed p.12-98 and its
instruction summary.

REV takes one TMS34020 machine state, writes the selected device's revision
identity to its destination register, and preserves ST. The same object-code
form has `1,4` timing and a different family-identification result on the
TMS34010, so neither its value nor timing implementation may be inherited from
the older core. Sources: TMS34020 User's Guide printed p.13-221; TMS34010
User's Guide printed p.12-233. The current model and RTL deliberately reject
execution until an explicit device profile supplies a verified revision word;
there is therefore no implemented retirement-timing claim.

JAcc takes three machine states when its condition is false and four when its
three-word absolute target is taken. It reads N/C/Z/V without changing ST or
registers. The compatible TMS34010 form has alignment-dependent published
timing, so its state machine is not reusable. Sources: TMS34020 User's Guide
printed pp.13-135..13-136 and timing table p.15-5; TMS34010 User's Guide
printed pp.12-92..12-93. The independent model reports these instruction-
boundary counts. The bounded RTL implements functional taken/fallthrough
ordering but not three-/four-state retirement, so no RTL timing claim is made.

Long `JRcc` takes two machine states when its condition is false and three when
the signed 16-bit relative redirect is taken. The condition reads N/C/Z/V and
neither case changes ST. The TMS34010 guide confirms the encoding and visible
operation but publishes alignment-dependent 34010 timing that is materially
different; it is compatibility evidence, not a reusable timing schedule.
Sources: TMS34020 User's Guide printed pp.13-138..13-140 and timing table
p.15-5; TMS34010 User's Guide printed pp.12-96..12-97. The independent model
reports these two-/three-state instruction-boundary cases for all 16 condition
codes. Bounded RTL implements predicate-controlled fallthrough/redirect
semantics but not either documented retirement case, so it makes no timing
claim.

DSJ, DSJEQ, and DSJNE each take two machine states when no jump occurs and
three when the decremented register remains nonzero and the relative redirect
is taken. DSJEQ suppresses both decrement and redirect when Z is zero; DSJNE
suppresses both when Z is one. The TMS34010 instruction pages corroborate the
visible semantics and encodings, but this project does not reuse its timing
state machine. Sources: TMS34020 User's Guide printed pp.13-103..13-107 and
timing table p.15-4; TMS34010 User's Guide printed pp.12-69..12-74 and its
instruction summary. These state counts alone do not prove branch-pipeline
timing. The independent model reports the two-/three-state instruction
boundary cases. The bounded RTL implements functional conditional decrement
and redirect ordering but not this retirement schedule.

DSJS also takes two machine states when its post-decrement result is zero and
three when the short relative jump occurs. Its instruction word embeds a
direction bit and five-bit unsigned magnitude; these cases do not imply that
its pipeline implementation is identical to the two-word DSJ family. Sources:
TMS34020 User's Guide printed p.13-108 and timing table p.15-4; TMS34010
User's Guide printed pp.12-74..12-75. The independent model reports both
instruction-boundary cases. The bounded RTL implements functional decrement
and short-relative redirect ordering, but not this retirement schedule.

PUTST takes three machine states and copies the complete source register into
ST. The same encoding, operation, and three-state summary appear in the
TMS34010 guide; this compatibility evidence does not establish general timing
equivalence between the processors. Sources: TMS34020 User's Guide printed
pp.13-216 and 15-7; TMS34010 User's Guide printed p.12-229 and its instruction
summary. The independent model reports three states. The bounded RTL implements
the full-width state update but not this retirement schedule.

POPST takes six machine states when SP is 32-bit aligned and seven when it is
not. PUSHST takes two visible states plus one parenthesized write state for an
aligned SP, or two visible plus two parenthesized write states for an
unaligned SP. The compatible TMS34010 forms have different published timings,
so no timing is reused from that core. Sources: TMS34020 User's Guide printed
pp.13-214..13-215; TMS34010 User's Guide printed pp.12-227..12-228 and its
instruction summary. Fault, retry, dynamic-width, and page-mode timing remain
pending. The independent model reports the visible 6/7 and 2-state cases and
carries PUSHST's 1/2 parenthesized states as abstract pending writes; this is not
a local-bus schedule.

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
