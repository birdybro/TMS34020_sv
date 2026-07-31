# Program counter and control flow

## Evidence boundary

This document records the programmer-visible program-counter contract from the
August 1990 *TMS34020 User's Guide* (`SPVU019 / 2564006-9721`). The alignment,
sequential-advance, branch-address, reset-vector, `GETPC`, `EXGPC`, and `IDLE`
rules below are `VERIFIED_PRIMARY`.

The guide describes instruction-fetch overlap, but it does not expose a named
set of speculative pipeline registers or a branch-recovery implementation.
Any RTL fetch cursor or instruction packet described below is therefore a
portable implementation mechanism, not a claim about inaccessible silicon
state.

## Address unit and alignment

The PC is a 32-bit **bit address**. It points to the next 16-bit instruction
word, so bits `[3:0]` are always zero. An instruction consists of one opcode
word followed by zero or more extension words. Each fetched word advances the
next-word address by 16 bit addresses. Source: User's Guide §4.2, printed
p.4-4, Figure 4-2 and Table 4-2.

For an instruction beginning at bit address `S` with `L` 16-bit words, the
sequential architectural result is:

```text
sequential_next_pc = (S + 16 * L) mod 2^32
```

The fetched extension words are part of the same instruction. They are not
independently retired instructions.

The guide says both that the PC increments as each instruction word is fetched
and, in Table 4-2, that a nonbranch instruction increments the PC at the end of
the instruction. These statements agree on the programmer-visible
instruction-boundary value. They do not establish when an implementation must
expose an internal increment relative to overlapped execution. The portable
RTL must keep its fetch cursor separate from its architectural completion
checkpoint until interrupt, fault, and branch-recovery ordering is verified.

## Redirect rules

User's Guide §4.2, printed p.4-4, Table 4-2 defines these address operations:

| Control-flow class | Architectural next PC |
|---|---|
| No branch | Sequential address after all instruction words |
| Absolute branch (`TRAP`, `CALLA`, `JAcc`) | Absolute target with bits `[3:0]` forced to zero |
| Relative branch (`CALLR`, `JRcc`, `DSJcc`) | Current post-instruction PC plus a signed 8- or 16-bit **word** displacement shifted left four |
| Indirect branch (`JUMP`, `CALL`) | Register target with bits `[3:0]` forced to zero |
| Interrupt | Vector value becomes the PC through the interrupt-entry sequence |

The individual instruction page remains authoritative for the base PC and
encoded width of each relative form. For example, the `DSJ` reference uses the
address immediately following its second word as `PC'` before adding the
signed 16-bit word displacement. Source: User's Guide `DSJ`, printed p.13-103.
The complete branch family and condition-code extraction remains part of
`TMS20-0006`; this table must not be used as a substitute for those entries.

All architecturally loaded instruction addresses are word aligned. An RTL
redirect must explicitly clear target bits `[3:0]`; it must not rely on a
software convention.

## Direct PC instructions

`GETPC Rd` has first-word form `0000_0001_010R_DDDD` (`0140h` base, mask
`FFE0h`). It copies `PC'`, the address of the instruction immediately following
`GETPC`, into `Rd`, leaves status unchanged, and consumes one machine state.
Source: User's Guide `GETPC`, printed p.13-130. That page is image-only in the
acquired scan and was visually checked against the chapter 13 summary table on
printed p.13-12.

`EXGPC Rd` exchanges the sequential `PC'` with `Rd`: the register receives the
address following `EXGPC`, while the PC receives the old register value with
bits `[3:0]` cleared. Status is unchanged and the instruction consumes two
machine states. Source: User's Guide `EXGPC`, printed p.13-112.

These instructions require the execution boundary to carry both:

- the instruction's sequential next address, for the register result; and
- a possible aligned redirect address, for the architectural PC.

Using a free-running speculative fetch address as the `GETPC` value would be
incorrect if it had advanced beyond this instruction.

## Reset entry

Reset does not define an ordinary fixed PC reset value. In self-bootstrap mode,
after the documented initialization refresh sequence, the processor reads the
level-0 vector from bit address `FFFF_FFE0h`. The vector contains the first
instruction address. Vector bits `[3:0]` are copied to `CONFIG[3:0]`, and the
PC receives the vector with those four bits cleared. Sources: User's Guide
§§6.12.3.1 and 6.12.4, printed pp.6-25–6-26.

Host-present mode remains halted until the host clears `HLT`; it must not begin
ordinary instruction fetch merely because reset deasserted. Source: User's
Guide §6.12.3.2, printed p.6-25.

A portable deterministic PC register may clear its storage during FPGA reset,
but that internal value is invalid until reset-vector or host-start sequencing
loads a documented address. It is not a silicon-visible PC reset claim.

## Interrupt and continuation checkpoints

An enabled interrupt is accepted at the end of the current instruction cycle
or at the next documented interruptible point inside an interruptible
instruction. Interrupt entry pushes continuation temporaries when required,
then PC and ST, before fetching the vector. Sources: User's Guide §6.5,
printed p.6-9, Figure 6-2; §6.6, printed pp.6-13–6-14.

Consequently, a future sequencer cannot equate “instruction words fetched”
with “instruction completed.” It must retain enough state to select the
documented PC checkpoint:

- the next instruction at an ordinary boundary;
- the current long instruction plus internal continuation state when `IX=1`;
- the bus-fault continuation defined by `BF`; or
- instruction-specific restart behavior such as `FPIXEQ`/`FPIXNE`.

The exact checkpoint values for every interruptible and faultable instruction
remain unresolved under `TMS20-0017`, `TMS20-0018`, and `TMS20-0023`.

## Bounded portable RTL vocabulary

The project uses these unambiguous names for the first executable composition:

| Name | Meaning | Silicon claim? |
|---|---|---|
| `instruction_start_pc` | Bit address of the opcode word being assembled | No; implementation checkpoint |
| `fetch_word_address` | Address currently presented to the instruction cache | No; implementation cursor |
| `sequential_next_pc` | `instruction_start_pc + 16 * length_words` | Yes, at the documented architectural boundary |
| `redirect_address` | Aligned branch/return/vector target | Yes, when the corresponding operation completes |
| `packet_valid` | Opcode and all known extension words are buffered | No; handshake mechanism |
| `retire` | State change accepted at the currently bounded completion point | No general timing claim until per-instruction tests exist |

The initial RTL fetches one instruction packet at a time to establish
correctness and backpressure behavior. This serialization does not reproduce
the documented fetch/execute overlap and therefore cannot support a
cycle-accuracy claim. See `instruction_fetch.md`.
