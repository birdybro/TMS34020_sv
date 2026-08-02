# Multiple-register moves

MMTM and MMFM are two-word, TMS34010-compatible instructions, but their
TMS34020 execution timing and memory system cannot be inherited from a
TMS34010 state machine. Sources: TI *TMS34020 User's Guide*, August 1990,
printed pp.13-148..13-151 and 15-6; TI *TMS34010 User's Guide*, 1988,
printed pp.12-109..12-112.

## Register-list encodings

The first words are MMTM `0980h`/`FFE0h` and MMFM `09A0h`/`FFE0h`; bit 4
selects the A or B file and bits 3:0 select Rp. The second-word mask directions
are deliberately opposite:

| Instruction | Mask bit 15 | Mask bit 0 | Register traversal |
|---|---|---|---|
| MMTM | A0/B0 | shared SP | lowest selected register first |
| MMFM | shared SP | A0/B0 | highest selected register first |

MMTM predecrements Rp by 32 bit addresses before every write. Its final Rp
therefore points at the highest selected register, at the lowest memory
address. MMFM reads that highest register first, postincrements by 32 after
every read, and restores the original pointer after a matching list. Rp and
the listed registers use one file; SP belongs to either file. Including Rp in
the list has documented unpredictable results. The guide does not assign a
portable empty-list result, so the model and leaf mark both cases invalid.

## Status and timing

MMFM leaves all status bits unchanged and publishes `n+5` states for `n`
registers. Its detailed page says original Rp alignment affects timing, but
the TMS34020 timing table supplies no alignment cases; RSC-0033/OQ-0022 keeps
the model's `n+5` report provisional.

MMTM replaces only N. The primary exceptions to the sign of `0-Rp` reduce to
the exact rule `N = ~old_Rp[31]`: old Rp `00000000h` sets N and old Rp
`80000000h` clears it. C/Z/V and every lower ST bit are preserved. Its visible
state table is:

| Original Rp alignment | n=1 | General n |
|---|---:|---:|
| long-word | 4 | `4+n` |
| byte, not long-word | 4 | `6+n` |
| bit, not byte | 4 | `7+n` |

Long-word and byte cases publish one hidden trailing write state. Bit-aligned
lists through four registers publish two; the general-n column publishes one.
A two-word MMTM whose first word is not long-word aligned adds one visible
state. These table values assume the chapter-15 cache-hit, immediate-grant,
page-mode, zero-wait, and no-retry conditions.

## Current implementation boundary

The independent model atomically captures the pointer and source values,
records one logical 32-bit transaction per register, implements pointer wrap,
mask order, status, and the published successful state classes, and rolls back
invalid lists. It marks timing incomplete because it has no external memory
controller. The `tms34020_multiple_register_control` leaf exhaustively
normalizes all 65,536 masks in both directions, counts registers, checks list
validity, computes final Rp/N, and selects the documented timing class.

Neither implementation owns actual reads/writes, hidden-write retirement,
page-mode bursts, dynamic 16-bit decomposition, waits, faults, retries,
interrupt recognition, or partial-list continuation. The execution router
keeps all 64 first words noncommitting until one architectural sequencer owns
those responsibilities.

## Page-mode requirement

The TMS34020 uses page mode for supported contiguous multiple moves. Page
addresses comprise bits 31:10, and a page-mode sequence cannot accept waits,
faults, or retries after it begins. I/O registers are not page-mode eligible.
The final implementation must prove page entry/exit, boundary splitting, and
idempotent continuation rather than treating model transactions as bus-cycle
traces. Source: User's Guide §8.7.2, printed pp.8-16..8-17.
