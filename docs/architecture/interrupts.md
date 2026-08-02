# Interrupt and software-trap architecture

## Evidence and implementation boundary

This document records the primary-source interrupt-entry contract needed by
the current TRAPL architectural-model slice and the normal RETI return
contract. The complete interrupt system,
including every source, enable, priority, recognition boundary, continuation
frame, bus-fault frame, return, and cycle case, remains `TMS20-0023`.

Sources are the August 1990 TI *TMS34020 User's Guide*
(`SPVU019 / 2564006-9721`), §3.7 on printed pp.3-29..3-30,
§6.4–§6.6 on printed pp.6-7..6-14, RETI on printed pp.13-217..13-218,
TRAPL on printed pp.13-256..13-258, and timing table pp.15-8..15-9.

## Vector table

Each vector-table entry is a 32-bit instruction address stored in
bit-addressed external memory. Figure 6-1 and Figure 13-13 define the TRAPL
entry address for signed 16-bit trap number `N` as:

```text
vector_entry_address =
    (FFFF_FFE0h - (sign_extend_16(N) << 5)) mod 2^32
```

Representative table points are:

| N | Vector entry address |
|---:|---:|
| -32768 | `000F_FFE0h` |
| -1 | `0000_0000h` |
| 0 | `FFFF_FFE0h` |
| 1 | `FFFF_FFC0h` |
| 32767 | `FFF0_0000h` |

The prose on p.13-256 instead describes shifting and sign-extending `N`
without the table's complement/descending offset. That formula conflicts with
both vector-map figures and all worked examples. The project follows the
repeated map and examples; the contradiction and secondary-reference gaps are
preserved as RSC-0016 in `docs/research/source_conflicts.md`.

The fetched 32-bit vector value becomes PC with bits `[3:0]` forced to zero,
consistent with the general PC alignment rule in §4.2, printed p.4-4.

## TRAPL entry frame

TRAPL is exactly two instruction words: fixed opcode `080Fh` followed by the
signed 16-bit trap number. Let `PC'` be the address after both words and let
`SP0` and `ST0` be the entry values. A successful instruction performs:

```text
memory[SP0 - 32, width 32] = PC'
memory[SP0 - 64, width 32] = ST0
SP = SP0 - 64
ST = 0000_0010h
PC = align16(memory[vector_entry_address, width 32])
```

The execution notation on p.13-256 orders `PC -> -*SP` before
`ST -> -*SP`. This places the saved ST at the final SP and the return PC at
`SP + 32`, matching RETI/RETM's ST-then-PC pop order in Figure 6-3.

TRAPL 0 is not the TRAP 0/reset exception: it creates the ordinary two-longword
frame before loading vector zero. TI explicitly calls out this distinction on
p.13-256.

TRAPL consumes 10 machine states when the saved-ST address is long-word
aligned and 12 otherwise. Source: p.13-257 and the chapter-15 table on printed
p.15-9.

## RETI normal frame

For a saved ST with both IX (bit 25) and BF (bit 26) clear, RETI pops exactly
the ordinary two-longword frame:

```text
ST = memory[old SP, width 32]
PC = align16(memory[old SP + 32, width 32])
SP = old SP + 64
```

The system-stack description on printed pp.3-29..3-30 and interrupt-return
Figure 6-3 on p.6-10 agree on this ST-then-PC order. RETI takes seven machine
states in the normal case (instruction page p.13-217 and timing table p.15-8).
Restored IE is effective by the final RETI state, so an already pending enabled
interrupt may be recognized immediately after completion.

The model implements that successful boundary atomically and records two
ordered `data_read` transactions named `return_interrupt_st` and
`return_interrupt_pc`. Tests cover aligned and unaligned old SP, 32-bit address
wrap, saved-PC alignment, arbitrary restored status values including both IE
states, and a TRAP-to-RETI round trip.

## IX and BF continuation frames

Figure 6-2 on p.6-9 specifies 24 stacked internal-state words for an
interrupted interruptible instruction (IX=1), with a possible additional
alignment word, and 31 words for a local-memory bus fault (BF=1). Figure 6-3
requires RETI to restore those internal words in addition to ST and PC. The
published RETI counts are 38 states for IX and 52 for BF.

The clean-room RTL classification leaf identifies normal, IX, and BF cases,
reports 0/24/31 internal words and 7/38/52 visible states, computes the normal
SP/PC result, and exposes malformed saved-PC alignment. It does not read
memory or commit state. The model rejects IX/BF frames before any architectural
change; checkpoint rollback makes the rejection atomic. This is intentional:
the guide does not disclose a field-by-field meaning and restore order for all
24/31 internal words, padding, or nested-fault checkpoints sufficient for a
real continuation sequencer. OQ-0023 tracks that missing evidence. RETI is
therefore PROVISIONAL and only its normal context is executable.

FPIXEQ and FPIXNE are explicit exceptions to the ordinary IX temporary-frame
sequence. On interruption the processor backs PC up to the search opcode and
resets MADDR/MPTCH so RETI resumes at the next pixel, but does not stack the
internal temporary registers described by the general sequence. Positive
searches retain the next address; negative searches retain the last checked
address so their predecrement resumes with the next pixel. The bounded model
executes only uninterrupted atomic scans, and the one-step RTL leaf has no
interrupt owner. Source: User's Guide interrupt exception printed p.6-14 and
FPIXEQ/FPIXNE printed pp.13-126..13-129.

FLINE follows the general graphics IX sequence rather than the FPIX exception.
It may be interrupted at a pixel boundary, requiring inaccessible temporary
state plus ST/PC to be stacked and restored before the next pixel. The atomic
model does not expose such a boundary and the one-step RTL leaf has no stack,
recognition or resume owner. B0/B2/B10/B13 alone must not be claimed as the
complete silicon continuation frame. Sources: User's Guide graphics interrupt
sequence printed pp.6-13..6-14 and FLINE printed p.13-124.

DRAV defines one pixel operation and an Rd XY advance as its architectural
effects. The current atomic model and combinational leaf have no interrupt-
recognition or hidden-write scheduler; they therefore provide no evidence for
the exact recognition state or ordering relative to the pixel write. Source:
User's Guide DRAV printed pp.13-100..13-102 and general recognition rules
printed pp.6-8..6-12.

FILL.L and FILL.XY may be interrupted at a destination word or row boundary
and use the general graphics continuation mechanism. The atomic model and
one-step leaf have no recognition, hidden-write drain, frame save, or resume
owner; their completed logical arrays are not continuation evidence. Sources:
User's Guide graphics interruption pp.6-13..6-14 and FILL pp.13-114..13-118.

## RETM monitor return

RETM is exact word `0860h` and is TMS34020-only. It restores the same
ST/PC/SP and IX/BF context classes as RETI, but its ordinary case takes ten
states rather than seven. During RETM's final state, interrupt acceptance from
restored IE is masked; the processor executes one instruction from the
interrupted program before accepting another pending interrupt or single-step
trap. The complete next instruction is fetched directly from memory rather
than from the cache. Sources: Figure 6-3, printed p.6-10; RETM p.13-219;
RETI/RETM comparison p.6-32; timing p.15-8.

The model normal path restores the ordinary frame and arms a snapshotted,
one-shot instruction-packet bypass. A stale-cache three-word MOVI.L
discriminator proves that the opcode and both extension words come from
memory and that the following instruction returns to ordinary cache lookup.
The bypass is restored if decode/execution aborts. The model preserves the
stacked IE bit but does not yet schedule pending interrupts or single-step
traps, so it cannot verify the one-instruction recognition delay. The shared
RTL leaf reports RETM's 10/38/52 states and bypass/delay intents but performs
no fetch, stack access, or interrupt arbitration.

The boxed note on p.13-219 incorrectly says RETM uses the cache mechanism and
then describes the failure mode that makes RETI unsuitable for single-step
return. This conflicts with the main description on the same page and §6.13;
RSC-0035 records the evidence and resolution.

## Model contract

The independent model implements the successful TRAPL instruction boundary
and the normal RETI/RETM returns described above.
Its trace records two `data_write` transactions with distinct
`trap_return_pc` and `trap_saved_st` purposes, followed by one
`interrupt_vector_fetch`. Directed tests cover TI's four published examples,
the signed extremes, trap zero, aligned and unaligned stacks, full old-ST
preservation in memory, next-PC saving, and vector-target alignment.

The model applies these three transactions atomically. It does not yet model a
wait, retry, or bus fault during either stack write or the vector fetch.
Consequently it is not evidence for partial-frame behavior, retry
idempotence, pin phases, `SIZE16` beat ordering, page-mode use, or nested fault
entry. Those remain `TMS20-0014`–`TMS20-0018` and `TMS20-0023`.

Pinned MAME is not a differential oracle for TRAPL: its execution handler is a
logging stub, and its disassembler does not consume the required extension
word. See RSC-0004 and RSC-0016.
