# TMS34020-specific graphics-support operations

This document tracks only the TMS34020-specific operations whose behavior has
been extracted and tested so far. It is not a complete graphics-instruction
inventory or conformance claim.

## Pitch conversion setup

SETCSP, SETCDP, and SETCMP derive a 16-bit conversion value from an implied
32-bit pitch register and schedule that value for an internal I/O-register
write:

| Instruction | Pitch source | Conversion destination |
|---|---|---|
| SETCSP | B1 / SPTCH | CONVSP, `C0000130h` |
| SETCDP | B3 / DPTCH | CONVDP, `C0000140h` |
| SETCMP | B11 / MPTCH | CONVMP, `C0000180h` |

For a power-of-two pitch, conversion value 1 in bits 4–0 is the five-bit one's
complement of the shift count. For a sum of two powers, that field represents
the greater power and conversion value 2 in bits 12–8 represents the lesser
power. Conversion value 1 equal to zero selects the arbitrary-pitch multiply
path. Other pitches therefore produce `0000h`.

Visible execution consumes four states for one power, six for two powers, or
three for an arbitrary pitch. Each case also has one parenthesized hidden
internal-write state, so dependent use requires the documented MWAIT ordering.

Sources: TI *TMS34020 User's Guide*, August 1990, CONVxP description printed
pp.4-28..4-29; implied operands §12.11, p.12-43; Figure 12-20, p.12-49;
SETCDP/SETCMP/SETCSP, pp.13-227..13-229; timing table p.15-8.

## Implemented boundary

The independent model implements all three instructions, their implied
register mappings, conversion-register writes, visible state classes, and an
abstract pending hidden-write state.

`rtl/graphics/tms34020_pitch_conversion.sv` implements the shared
combinational conversion and visible-state classifier. Directed RTL tests
cover the four primary example rows, zero, every one-bit pitch, and every
two-bit pitch pair. The SETC-pitch opcodes remain blocked in the bounded scalar
slice because conversion-register storage, hidden-write retirement, MWAIT
ordering, and dependent conversion instructions do not yet have a verified RTL
owner.

Pinned MAME is not the oracle for this family. Its SETCDP conversion fields
disagree with TI and its SETCMP/SETCSP handlers are stubs; see
`docs/research/source_conflicts.md` RSC-0014.

The dependent CVDXYL, CVMXYL, CVSXYL, and CVXYL conversion operations now
have instruction-boundary model semantics and a shared standalone RTL
arithmetic/classification leaf. They consume the CONVxP encoding produced by
this setup family, select the appropriate B1/B3/B11 arbitrary-pitch source and
offset rule, preserve ST, and report their documented pitch-class timing. The
full RTL path remains blocked until conversion-register/PSIZE storage and
simultaneous implied-register capture have a verified owner. RSC-0025 records
the guide's inconsistent CVXYL PSIZE=4 examples.

## VRAM color-register load

VLCOL copies the full 32-bit B9/COLOR1 value to the color registers in all
external VRAMs. It ignores field size, drives nominal address zero, and uses
special local-cycle status `0111b`. Its timing is `2 (1)`: two visible states
and one hidden write state. ST is unchanged. Sources: the same guide,
§8.12.3 printed p.8-38 and VLCOL printed pp.13-264..13-265.

The independent model records a successful `special_vram_color_load`
transaction and updates an explicit external color-latch abstraction. It does
not yet model LRDY/BUSFLT handling or pin phases for the special cycle. No RTL
VLCOL request owner exists. Pinned MAME's VLCOL handler is a logging stub; see
RSC-0015.

## Continuous bit-block move

BLMOVE and the four S/D alignment/update modes are documented in
`array_operations.md`. The independent model covers only an atomic,
non-overlapping successful boundary. Interrupt continuation, overlap results,
physical requests, page mode, dynamic sizing, faults, retries, and timing
remain open.

## Fast linear line draw

FLINE is the TMS34020-only one-word pair `DE1Ah`/`DE9Ah`. Bit 7 selects
whether a zero decision variable takes the diagonal path: algorithm 0 uses
`d >= 0`, while algorithm 1 uses `d > 0`. The instruction consumes a linear
B2/DADDR, B0 decision variable, B7 minor:major dimensions, converted XY B11
and B12 increments, B8/B9 colors, B10 count, and B13 pattern. Each drawn pixel
decrements COUNT, selects COLOR0 or COLOR1 from the current PATTERN LSB,
applies pixel processing, transparency, and PMASK, rotates PATTERN right, then
updates the decision and pointer. It does not perform window checking and can
be interrupted at a pixel boundary through the general graphics continuation
sequence.

The independent model currently implements only atomic little-endian,
replace-PPOP, transparency-off logical writes, including every legal PSIZE,
aligned color and mask lanes, all three pitch-conversion classes, and the
published `12 + 3CD + (2+P)E + 3` no-wait formula. The standalone RTL leaf
implements one step after XY increments have already been converted to linear
form. Neither boundary implements a physical memory sequencer, other PPOP or
transparency modes, page/wait/fault/retry handling, or interrupt continuation.

Sources: TI *TMS34020 User's Guide*, August 1990, XY conversion §3.6 printed
pp.3-15..3-16; FLINE printed pp.13-121..13-125; graphics interruption printed
pp.6-13..6-14; timing Table 15-1 and FLINE formula printed pp.15-2 and 15-5.
Pinned MAME commit `a562e947b22f4f5acff0c182c26fd649d72dad0e`
corroborates the two encodings in
`src/devices/cpu/tms34010/34010dsm.cpp` lines 1537–1553, but its execution
handler in `34010ops.hxx` lines 2309–2313 only logs a stub. It therefore
provides no independent semantic or timing evidence for this implementation.
