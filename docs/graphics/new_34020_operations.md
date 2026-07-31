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
