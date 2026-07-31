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
| Absolute branch (`TRAP`, `TRAPL`, `CALLA`, `JAcc`) | Absolute target with bits `[3:0]` forced to zero |
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

TRAPL obtains its target indirectly through a 32-bit vector-table entry. For
signed 16-bit trap number `N`, Figure 6-1 and Figure 13-13 place that entry at
`FFFF_FFE0h - (sign_extend(N) << 5)`, modulo `2^32`. The conflicting prose
formula on printed p.13-256 is resolved in favor of both figures and the
worked examples under RSC-0016. The successful model boundary and its explicit
fault exclusions are documented in `interrupts.md`.

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

GETPC and EXGPC require the execution boundary to carry both:

- the instruction's sequential next address, for the register result; and
- a possible aligned redirect address, for the architectural PC.

Using a free-running speculative fetch address as the `GETPC` value would be
incorrect if it had advanced beyond this instruction.

`JUMP Rs` has first-word form `0000_0001_011R_SSSS` (`0160h` base, mask
`FFE0h`). It captures the selected A/B register or shared SP, loads PC from
that value with bits `[3:0]` cleared, leaves status and the source unchanged,
and takes two machine states. Sources: User's Guide `JUMP`, printed p.13-141,
and §4.2, printed p.4-4; compatibility cross-check: TMS34010 User's Guide
printed p.12-98 and its instruction summary. The independent model implements
this successful instruction boundary. The bounded RTL direct-PC owner reads
the old selected register, emits its aligned target without a register or
status write, and holds that target through frontend completion. This is a
functional serialized redirect boundary, not the documented two-state
retirement timing.

The bounded RTL implements this data-ordering boundary in
`tms34020_pc_execute.sv`: the complete packet supplies its sequential address,
while the commit composition reads the old destination and atomically writes
the sequential address for EXGPC. For EXGPC and JUMP,
`tms34020_scalar_slice.sv` holds the aligned target until the
packet-completion handshake redirects the frontend. Directed simulation
reaches GETPC at a nonsequential EXGPC target and then uses the sequential
address captured in A0 as a JUMP target.
This proves functional ordering in the serialized FPGA handshake only; it does
not reproduce GETPC's documented one machine state, EXGPC's two machine states,
JUMP's two machine states, or speculative pipeline overlap.

## Conditional absolute jumps

`JAcondition`/JAcc uses the exact first-word form
`1100_CCCC_1000_0000`, followed by the absolute address low 16 bits and then
high 16 bits. It evaluates the same 16 condition codes listed below for
`JRcc`. A true condition loads `{third_word, second_word}` into PC with bits
`[3:0]` forced to zero; a false condition continues at the sequential address
after all three words. Registers and ST are unchanged. The false/taken cases
require three/four machine states. Sources: TI *TMS34020 User's Guide*, August
1990, `JAcondition` printed pp.13-135..13-136 and timing table p.15-5.

The 1988 TMS34010 guide printed pp.12-92..12-93 gives the same encoding and
programmer-visible operation but different alignment-dependent state cases.
That establishes semantic/object compatibility without making its timing
sequencer reusable. The generated decoder now classifies all 16 exact
`C?80h` first words and assembles their three-word packets. The independent
model executes all conditions with exact target assembly, alignment, state
preservation, and three-/four-state instruction-boundary counts. The bounded
RTL direct-PC owner and commit path consume the full 32-bit extension, preserve
registers/ST, and hold either the aligned absolute redirect or sequential
fallthrough through scalar completion. This functional path does not implement
the documented three-/four-state retirement.

## Conditional relative jumps

The long `JRcc` first word is `1100_CCCC_0000_0000`, followed by a signed
16-bit word displacement. With `PC'` equal to the address after the extension
word, a satisfied condition loads:

`PC = PC' + (sign_extend(displacement) << 4) mod 2^32`

An unsatisfied condition leaves PC at `PC'`. The 16 condition codes are:

| Code | Name | Condition |
|---:|---|---|
| `0` | U | true |
| `1` | P | `!N && !Z` |
| `2` | LS | `C || Z` |
| `3` | HI | `!C && !Z` |
| `4` | LT | `N != V` |
| `5` | GE | `N == V` |
| `6` | LE | `(N != V) || Z` |
| `7` | GT | `(N == V) && !Z` |
| `8` | C | `C` |
| `9` | NC | `!C` |
| `A` | EQ | `Z` |
| `B` | NE | `!Z` |
| `C` | V | `V` |
| `D` | NV | `!V` |
| `E` | N | `N` |
| `F` | NN | `!N` |

ST is read but not changed. The false/taken cases require two/three machine
states. Sources: TI *TMS34020 User's Guide*, August 1990, condition table
printed pp.13-27 and 13-138, long JR reference printed pp.13-139..13-140, and
timing table p.15-5. TMS34010 User's Guide printed pp.12-96..12-97 gives the
same object format and visible behavior but materially different timing.

The current generated decoder classifies the exact 16 long-form first words
(`C?00h`) and the exact 16 JAcc words (`C?80h`). Short `JRcc` occupies the
remaining surrounding `CcodeXXh` region but remains unclassified pending an
explicit exclusion-capable decode representation and resolution of RSC-0020.
The independent model implements all 16 long-form
conditions, both possible outcomes, signed displacement extremes, PC wrap,
complete ST/register preservation, and two-/three-state instruction-boundary
counts. The bounded RTL evaluates the same predicates with a shared
synthesizable condition function, preserves all register/status state, and
holds either the signed redirect or sequential fallthrough through frontend
completion. Its serialized handshake does not implement the documented
two-/three-state schedule.

## Decrement-and-jump instructions

`DSJ`, `DSJEQ`, and `DSJNE` occupy the adjacent `0D80h`, `0DA0h`, and `0DC0h`
ranges with mask `FFE0h`; each is followed by a signed 16-bit word
displacement. `DSJ` always decrements its selected A/B/shared-SP register.
`DSJEQ` does so only when Z is one, and `DSJNE` only when Z is zero. If the
operation is enabled and the modulo-`2^32` decrement result is nonzero, the PC
becomes:

`PC_after_extension + (sign_extend(displacement) << 4)`

Otherwise execution continues at `PC_after_extension`. ST is never changed.
The nonredirect and redirect cases take two and three machine states,
respectively. Sources: TI *TMS34020 User's Guide*, August 1990, DSJ printed
p.13-103, DSJEQ printed pp.13-104..13-105, and DSJNE printed
pp.13-106..13-107. TMS34010 User's Guide printed pp.12-69..12-74 corroborates
the encoding and visible semantics without authorizing timing-RTL reuse.

The independent model reproduces every published input row, conditional
suppression, signed displacement extremes, register-file/shared-SP selection,
and PC wrap. The bounded RTL performs the same functional ordering and holds a
taken target through frontend completion. Two runtime assertions require the
conditioned decrement/redirect relationship and exact signed-word target.

`DSJS` occupies the complete `3800h`–`3FFFh` range (`F800h` mask). It embeds
direction `D` in bit 10 and a five-bit unsigned magnitude in bits `[9:5]`;
bits 4 and `[3:0]` select the A/B file and destination/shared-SP alias. It
always decrements the destination modulo `2^32`. A nonzero result redirects to
`PC_after_instruction + magnitude×16` for `D=0`, or
`PC_after_instruction - magnitude×16` for `D=1`; zero falls through and ST is
unaffected. The primary guide's −30..+32-word range is relative to the
instruction address, not the already-advanced `PC'`. Sources: TMS34020 User's
Guide printed pp.13-12 and 13-108; TMS34010 User's Guide printed
pp.12-74..12-75. The independent model implements the successful instruction
boundary, including both direction and magnitude endpoints. The bounded RTL
always commits the modulo-`2^32` decrement, preserves ST, and holds the exact
encoded forward or backward target through frontend completion when the result
is nonzero. Two runtime assertions require the unconditional destination-write
and conditioned-redirect relationship plus the exact unsigned-magnitude
target. The RTL still lacks the documented two-/three-state scheduling.

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
