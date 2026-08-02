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
