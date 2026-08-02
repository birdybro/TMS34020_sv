# Source conflicts

## RSC-0001: TMS34020 User's Guide publication identity

- Status: open catalog ambiguity; architectural document itself acquired
- Evidence:
  - the August 1990 guide cover reads `2564006-9721 revision` with no legible
    letter and does not visibly print SPVU019;
  - TI's *TMS340 Family Graphics Library User's Guide*, SPVU027, August 1990,
    preface page iv identifies *TMS34020 User's Guide* as SPVU019;
  - the located 1991 SDB guide is a distinct 180-page board manual whose cover
    reads 2558670-9721 revision B, while its archive filename contains 9761B.
- Decision: catalog the processor guide as `SPVU019 / 2564006-9721` and the SDB
  guide separately as `SPVU016 / 2558670-9721`. Never substitute one for the
  other. Confidence: `CORROBORATED`.

## RSC-0002: Code-generation tools literature number

- Status: partially resolved as distinct cataloged editions; actual guides
  remain missing
- Evidence:
  - August 1990 TMS34020 guide preface page iv calls the code-generation tools
    guide SPVU004;
  - August 1990 SPVU027 preface page iv calls it SPVU020.
  - TI SPVU015C, September 1990, preface page iv also calls the guide SPVU020;
    its §2.2 requires code-generation tools version 4.0 or later.
- Hypotheses: SPVU004 is an earlier edition and SPVU020 a later revision or
  replacement; a catalog renumbering cannot be excluded without title pages.
- Decision: catalog SPVU004 and SPVU020 as separate missing reference records.
  Do not collapse either identifier into the other. Confidence:
  `CORROBORATED` for distinct catalog identities, `UNKNOWN` for edition content.

## RSC-0003: MAME Midway X-unit path

- Status: resolved for the pinned commit
- Evidence: MAME git tree at
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`.
- Decision: use `src/mame/williams/midxunit.cpp`. The candidate
  `src/mame/midway/midxunit.cpp` does not exist at that commit. Confidence:
  `VERIFIED_PRIMARY` for source-tree identity.

## RSC-0004: TRAPL instruction length in pinned MAME disassembler

- Status: open secondary-reference defect; TI encoding verified
- Primary evidence: TI *TMS34020 User's Guide*, TRAPL instruction reference,
  printed page 13-256, shows first word `080Fh` followed by a 16-bit signed trap
  number. The chapter 13 summary table also lists two words.
- Secondary evidence: MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010dsm.cpp`, lines 588–598, recognizes TRAPL but
  neither reads nor advances past an extension word. The routine's consumed
  length is derived from its local `pos`, so this path reports one word.
- Decision: encode TRAPL as two words in the project ISA database. Do not change
  TI behavior to agree with MAME. Add a differential-disassembly fixture when
  the local disassembler is implemented. Confidence: `VERIFIED_PRIMARY`.

## RSC-0005: fixed-opcode low bits in pinned MAME disassembler

- Status: open secondary-reference overdecode; TI encodings verified
- Primary evidence: TI *TMS34020 User's Guide* instruction-word diagrams for
  NOP (p.13-180), CLRC (p.13-58), DINT (p.13-95), EINT (p.13-109), and SETC
  (p.13-226) show fixed zeroes in bits 4–0. The image-only DINT page was
  visually inspected in the acquired PDF.
- Secondary evidence: MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010dsm.cpp`, lines 217–227 derives `subop` with
  mask `01E0h` and dispatches the outer opcode with mask `FE00h`. The NOP,
  CLRC, and DINT cases at lines 352–369 and EINT/SETC cases at lines 855–885
  do not reject nonzero bits 4–0. The disassembler therefore labels nearby
  words such as `0301h` and `0321h` as those fixed instructions.
- Decision: use the exact TI first words and leave neighboring words
  unclassified until the complete reserved-encoding audit. The ISA suite
  guards these boundaries under `ISA-DISC-0002-fixed-low-bits`. This finding
  is limited to the pinned disassembler path; it does not establish the
  execution behavior of MAME or physical silicon for undocumented words.
  Confidence: `VERIFIED_PRIMARY` for the legal encodings and `CORROBORATED`
  for the secondary overdecode.

## RSC-0006: ORI unaligned-immediate wording

- Status: resolved by the same guide's timing table
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990, ORI,
  printed p.13-183, says both the two-state and three-state cases apply when
  immediate data is long-word aligned.
- Resolving primary text: the timing table on printed p.15-7 assigns two
  machine states when ORI immediate data is long-word aligned and three when
  it is not. The adjacent ANDI/ANDNI references on pp.13-41 and 13-43 and XORI
  on p.13-267 give the same aligned/unaligned split for the identical
  three-word layout.
- Decision: encode ORI as two states with an aligned first extension word and
  three otherwise. Cite both the instruction page and timing table so the
  correction remains auditable. Confidence: `VERIFIED_PRIMARY`.

## RSC-0007: cache address-field bit ranges

- Status: resolved from the same page's figure and structural dimensions
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990, §5.1,
  printed p.5-3, says address bits 6–8 select one of eight subsegments and
  bits 4, 5, and 6 select one of eight instruction words. Those ranges overlap
  at bit 6.
- Resolving primary evidence: Figure 5-2 on the same page shows a
  22-bit/3-bit/3-bit/4-zero partition. The documented segment size is 64
  instruction words and the subsegment size is eight instruction words.
  Together these establish SSA `[31:10]`, subsegment `[9:7]`, word `[6:4]`,
  and alignment zeroes `[3:0]` for a 32-bit bit address.
- Decision: use the figure-backed nonoverlapping partition. Preserve this
  conflict in tests and documentation rather than copying the prose typo into
  RTL. Confidence: `VERIFIED_PRIMARY`.

## RSC-0008: number of present flags cleared by cache flush

- Status: resolved from cache organization and the dedicated flush section
- Conflicting primary text: the `HSTCTLH.CF` description on printed p.4-61
  says all four cache `P` flags are forced to zero.
- Resolving primary evidence: §5.1 defines four segments with eight
  subsegments each; §5.2 says each segment has eight `P` flags; and §5.3.5,
  printed p.5-8, explicitly says all 32 `P` flags are cleared by a flush.
- Decision: `CF=1` clears/forces clear all 32 subsegment-present flags. Treat
  "all 4" on p.4-61 as a typographical error, not a four-flag cache variant.
  Confidence: `VERIFIED_PRIMARY`.

## RSC-0009: SUBI.L first example status

- Status: resolved internal example-table error
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990, SUBI
  32-bit form, printed p.13-244, gives `7FFFFFFFh - 7FFFFFFFh = 00000000h`
  but prints `NCZV=0001`.
- Resolving primary evidence: the same page defines Z as one when the result is
  zero and V as one only on overflow. The identical operands produce neither
  signed overflow nor a borrow. The remaining zero-result SUBI examples on
  pp.13-243..13-244 print `NCZV=0010`, consistent with those definitions and
  with the programmer's-model status definition in §4.1, printed pp.4-2..4-3.
- Decision: expect `NCZV=0010` for that row and preserve the printed `0001`
  value here as a source conflict. The model test names this resolution
  explicitly; the table value is not silently copied or silently corrected.
  Confidence: `VERIFIED_PRIMARY`.

## RSC-0010: ADDK and INC share one encoding

- Status: resolved primary-source alias identity
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, ADDK printed
  p.13-37 defines `000100 KKKKK R DDDD`, including K=1. INC printed p.13-134
  shows the identical K=1 bit pattern and explicitly calls INC an alternate
  mnemonic for `ADDK 1,Rd`.
- Corroboration: the pinned TMS34010 baseline decodes the full top-six-bit
  family as ADDK in `rtl/core/tms34010_decode.sv` lines 64–70 and 591–603 at
  commit `94a258e80a07ceb4303ce0b99818df832e96007f`. Pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e` executes the family with
  `addk_a/addk_b` in `src/devices/cpu/tms34010/34010ops.hxx` lines 391–403 and
  only chooses the INC spelling for K=1 in
  `src/devices/cpu/tms34010/34010dsm.cpp` lines 947–963.
- Decision: keep one canonical ADDK database record with mask `FC00h`, record
  INC as the conditional K=1 alias, and decode `1020h`–`103Fh` as ADDK. This
  replaces the earlier narrow INC-only extraction without changing its
  semantics. Confidence: `VERIFIED_PRIMARY`.

## RSC-0011: SUBK and DEC share one encoding

- Status: resolved primary-source alias identity
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, SUBK printed
  p.13-245 defines `000101 KKKKK R DDDD`, including K=1. DEC printed p.13-94
  shows the identical K=1 bit pattern and explicitly calls DEC an alternate
  mnemonic for `SUBK 1,Rd`.
- Corroboration: the pinned TMS34010 baseline decodes the full top-six-bit
  family as SUBK in `rtl/core/tms34010_decode.sv` lines 64–70 and 606–617 at
  commit `94a258e80a07ceb4303ce0b99818df832e96007f`. Pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e` executes the family with
  `subk_a/subk_b` in `src/devices/cpu/tms34010/34010ops.hxx` lines 1025–1036
  and only chooses the DEC spelling for K=1 in
  `src/devices/cpu/tms34010/34010dsm.cpp` lines 966–980.
- Decision: keep one canonical SUBK database record with mask `FC00h`, record
  DEC as the conditional K=1 alias, and decode `1420h`–`143Fh` as SUBK. This
  replaces the earlier narrow DEC-only extraction without changing its
  semantics. Confidence: `VERIFIED_PRIMARY`.

## RSC-0012: MOVI.W status labels contradict its examples

- Status: resolved internal instruction-page error
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990, MOVI
  16-bit form, printed p.13-167, says Z is unaffected and V becomes one when
  the moved data is zero.
- Resolving primary evidence: every zero-valued example on that same page
  prints `NCZV=0x10`, which means Z=1 and V=0. The adjacent 32-bit MOVI form on
  printed p.13-168 explicitly defines Z as the zero indicator and V as zero.
  The programmer's-model status definition in §4.1, printed pp.4-2..4-3,
  assigns the conventional zero and overflow meanings to Z and V.
- Corroboration: the pinned TMS34010 baseline sets the MOVI.W and MOVI.L
  writeback mask to N/Z/V in `rtl/core/tms34010_decode.sv` lines 541–575 at
  commit `94a258e80a07ceb4303ce0b99818df832e96007f`. Pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e` clears and recomputes N/Z/V for
  both forms in `src/devices/cpu/tms34010/34010ops.hxx` lines 1079–1099.
- Decision: both MOVI forms update N and Z from the moved result, clear V, and
  preserve C. The contradictory p.13-167 labels remain recorded here and are
  covered by directed zero-result tests. Confidence: `VERIFIED_PRIMARY`.

## RSC-0013: RL count-30 example carry contradicts its result and definition

- Status: resolved internal example-table error
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990, RL
  constant, printed p.13-222, gives `RL 30,A1` with input `F0000000h`, result
  `3C000000h`, and `C=1`.
- Resolving primary evidence: the same page defines C as original bit
  `[32-constant]` and says it is also the result LSB. For count 30 that is
  original bit 2, which is zero in `F0000000h`; the published result
  `3C000000h` likewise has LSB zero. All three statements agree on C=0 except
  the example's printed status digit.
- Corroboration: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e` derives C after the first
  `count-1` shifts, then completes the rotate in
  `src/devices/cpu/tms34010/34010ops.hxx` lines 862–882. That algorithm also
  selects original bit 2 and produces C=0 for this case.
- Decision: follow the instruction definition and the example result, expecting
  C=0 for this row. The model checks the corrected `NCZV=x00x` result and all
  other published RL rows. This is a documentation resolution, not
  physical-hardware evidence. Confidence: `VERIFIED_PRIMARY` for the bit
  relation and `CORROBORATED` for the secondary implementation.

## RSC-0014: pinned MAME SETC-pitch conversion is incomplete and misencoded

- Status: resolved secondary-reference defects; TI behavior implemented
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, CONVxP register
  description and Figure 12-20, printed pp.4-28..4-29 and 12-49, define each
  conversion field as the five-bit one's complement of the corresponding
  power-of-two shift count. SETCDP/SETCMP/SETCSP, printed
  pp.13-227..13-229, give `1000h -> 0013h`, `0400h -> 0015h`,
  `1400h -> 1513h`, and arbitrary `19h -> 0000h`.
- Secondary conflict: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 2437–2468 stores
  `std::bit_width` values directly for SETCDP. For `1000h`, that expression is
  decimal 13 (`000Dh`), rather than TI's complemented `0013h`. Lines
  2470–2478 implement SETCMP and SETCSP only as log messages and do not update
  their conversion registers.
- Decision: derive all three conversion registers from the primary field
  definition and example rows. One set bit uses one complemented shift field;
  two set bits place the greater-power field low and lesser-power field in bits
  12–8; other pitches use zero and the arbitrary-pitch path. A zero
  conversion-value-1 is retained as the documented multiplication sentinel.
  MAME remains a differential target, not the expected result for these
  instructions. Confidence: `VERIFIED_PRIMARY`.

## RSC-0015: pinned MAME VLCOL handler has no architectural effect

- Status: open secondary-reference implementation gap; bounded TI success path
  modeled
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, §8.12.3 printed
  p.8-38 defines a load-color-register local-memory cycle with status `0111b`,
  nominal all-zero address, and all 32 COLOR1 bits on LAD. VLCOL printed
  pp.13-264..13-265 requires that cycle, ignores field size, preserves status,
  and reports `2 (1)` states.
- Secondary evidence: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 2514–2519 contains only a log
  call; its COLOR1 diagnostic is commented out and no color-latch or bus state
  changes.
- Decision: the model follows TI for the successful special-cycle transaction
  and external color-latch result. MAME cannot be used as a differential
  expected value here. BUSFLT/LRDY sampling, retry, and pin timing remain
  unimplemented and explicitly outside the current model claim. Confidence:
  `VERIFIED_PRIMARY` for the success path and `UNKNOWN` for unresolved fault
  timing.

## RSC-0016: TRAPL prose formula conflicts with TI vector maps and examples

- Status: primary conflict resolved provisionally from repeated same-guide
  evidence; successful path modeled
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990, TRAPL
  printed p.13-256 says the trap address is made by shifting signed immediate
  `N` left five and sign-extending it. Taken literally, `N=-1` produces
  `FFFF_FFE0h` and `N=0` produces zero.
- Resolving primary evidence: Figure 6-1 on printed p.6-8 and Figure 13-13 on
  p.13-257 both map `N=-1` to `0000_0000h`, `N=0` to `FFFF_FFE0h`, and
  increasing nonnegative traps downward through memory. The examples on
  p.13-258 use entries `0000_0000h`, `FFFF_FFE0h`, `FFFF_FC00h`, and
  `FFFF_FBC0h` for `N=-1`, 0, 31, and 33. All of that evidence agrees with
  `FFFF_FFE0h - (sign_extend(N) << 5)` modulo `2^32`.
- Secondary evidence: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 2495–2498 implements TRAPL
  only as a log message. Its disassembler also omits the extension word as
  recorded separately in RSC-0004, so it cannot resolve the formula.
- Decision: the ISA database, model, and tests follow the two vector-map
  figures and all worked examples. Tests cover both signed extremes, zero,
  representative positive and negative values, and the four published vector
  results. Another TI guide revision, erratum, or hardware trace is still
  desirable. Confidence: `VERIFIED_PRIMARY` for the table/example mapping and
  `PROVISIONAL` for explaining the defective prose.

## RSC-0017: pinned MAME BLMOVE alignment and continuation are incomplete

- Status: open secondary-reference implementation gap; bounded TI success
  boundary modeled
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, BLMOVE printed
  pp.13-44..13-45 requires 32-bit long-word alignment whenever S or D is zero.
  It defines S/D-specific intermediate B0/B2 updates, decrements B7 as bits are
  moved, and restarts the opcode after interruption.
- Secondary evidence: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 2047–2092 checks
  `address & 0xF`, which is only 16-bit alignment, and transfers 16-bit words
  regardless of S/D. Lines 2078–2082 explicitly mark the B0/B2
  mid-instruction update policy TODO.
- Decision: the model enforces TI's 32-bit alignment requirements and verifies
  only the successful final B0/B2/B7/ST state for non-overlapping ranges. It
  does not copy MAME's request width, timing, or continuation behavior.
  Overlap, intermediate checkpoints, page-mode transactions, dynamic sizing,
  faults, and retries remain unresolved. Confidence: `VERIFIED_PRIMARY` for
  the alignment and final state, `UNKNOWN` for omitted physical sequencing.

## RSC-0018: one BTST register example contradicts the bit definition

- Status: resolved internal example-table error
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990, BTST
  register, printed p.13-47, gives source `FFFF_FF8Fh`, destination
  `FFFF_7FFFh`, and `Z=0`. The source's low five bits select bit 15, which is
  zero in the destination, so that row conflicts with the same page's rule
  that a zero tested bit sets Z.
- Repeated primary evidence: every other BTST.K/R example on printed
  pp.13-46..13-47 follows the stated bit rule. The independently acquired TI
  *TMS34010 User's Guide*, 1988, printed pp.12-46..12-47 repeats both the rule
  and the same contradictory register row.
- Secondary corroboration: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 438–462 selects the
  complemented destination bit using the decoded constant or source low five
  bits. It produces Z=1 for this row. MAME's cycle counts are not used here.
- Decision: implement the explicit bit definition and expect Z=1 for the
  contradictory row. The independent model tests all 25 published input rows,
  with only this status digit corrected, and separately checks upper-source-bit
  truncation, both register files, same-register use, and shared SP. This is a
  documentation resolution, not physical-hardware evidence. Confidence:
  `VERIFIED_PRIMARY` for the bit relation and `CORROBORATED` for the secondary
  implementation.

## RSC-0019: pinned MAME undercounts EXGF field-one timing

- Status: resolved secondary-reference timing defect
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, EXGF, printed
  p.13-111, and the chapter-15 table on printed p.15-4 specify one machine
  state for `F=0` and two for `F=1`. The instruction diagram defines bit 9 as
  the field-bank selector.
- Compatibility evidence: TI *TMS34010 User's Guide*, 1988, EXGF printed
  p.12-78 and the timing summary on p.12-17 specify the same object-code
  operation but one cache-hit execution state for either field bank.
- Secondary conflict: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 612–625 uses one shared macro
  for both processors and both field banks; line 620 charges one cycle
  unconditionally.
- Decision: record the TMS34020's field-dependent one-/two-state timing in the
  ISA database and treat MAME's `F=1` count as a differential-reference defect.
  Semantics remain object-code compatible with the TMS34010. No current RTL
  handshake is assigned either architectural count. Confidence:
  `VERIFIED_PRIMARY`.

## RSC-0020: short JR range text includes the JAcc escape encoding

- Status: unresolved primary encoding-domain ambiguity; exact long-JR and JAcc
  forms classified independently
- Conflicting primary text: TI *TMS34020 User's Guide*, August 1990,
  short `JRcondition`, printed p.13-137, describes an eight-bit signed word
  offset and calls its assembler range “±128 words (excluding 0).” An offset
  byte of `80h`, however, makes the exact first word `Ccode80h`.
- Resolving boundary evidence: `JAcondition`, printed p.13-135, assigns
  `Ccode80h` to the three-word absolute conditional jump for every condition
  code. The long relative form on printed p.13-139 separately assigns
  `Ccode00h`. The 1988 TMS34010 guide printed pp.12-92..12-94 gives the same
  exact JAcc encoding and describes the short-relative range as ±127 words,
  excluding zero.
- Decision: classify all 16 exact `C?80h` words as JACC and all 16 exact
  `C?00h` words as JR.L. Leave the remaining short-relative domain
  unclassified until another TMS34020 primary source, assembler behavior, or
  hardware test establishes whether any nonzero byte other than `80h` is
  illegal. In particular, do not let a broad short-JR mask shadow JACC.
  Confidence: `VERIFIED_PRIMARY` for the exact JACC/JR.L forms and `UNKNOWN`
  for the remaining hardware-domain exclusion policy.

## RSC-0021: pinned MAME returns the TMS34010 identity for TMS34020 REV

- Status: open secondary-reference device-identity defect; decode classified,
  execution deliberately blocked pending a selected physical profile
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, REV, printed
  p.13-221 defines bits `[2:0]` as the silicon revision, bit 3 as the
  TMS34010 family tag, bit 4 as the TMS34020 family tag, and bits `[23:16]`
  as the spin-off identity. Its TMS34020 revision-1.0 and revision-2.0
  examples return `0000_0010h` and `0000_0011h`. The same page specifies
  one machine state and no status changes.
- Compatibility boundary: TI *TMS34010 User's Guide*, 1988, REV, printed
  p.12-233 assigns the same `0020h`/`FFE0h` register encoding but returns
  `0000_0008h` in its TMS34010 example and publishes `1,4` timing.
- Secondary conflict: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 1887–1893 uses one shared
  REV macro for both processor classes, always writes `0000_0008h`, and
  charges one cycle. Its disassembler correctly recognizes the `0020h`
  register form in `34010dsm.cpp`, lines 217–235.
- Decision: classify all 32 REV words from the primary encoding, but do not
  execute them in the model or RTL until a device profile supplies an
  evidence-backed complete revision word. Tests require atomic rejection
  rather than a guessed result. Pinned MAME is not a valid TMS34020
  differential oracle for this instruction. Confidence: `VERIFIED_PRIMARY`
  for encoding, layout, examples, status, and timing; `UNKNOWN` for the
  exact target-board silicon and spin-off fields.

## RSC-0022: pinned MAME applies one shared TRAP cycle count

- Status: resolved secondary-reference timing defect; successful architectural
  entry modeled, physical stack/vector cycles still pending
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, TRAP and
  Figure 13-12, printed pp.13-253..13-255 specifies 7 machine states for
  TRAP 0, 10 for a nonzero trap whose saved-ST address is 32-bit aligned,
  and 12 otherwise. TRAP 0 saves neither PC nor ST and leaves SP unchanged;
  all nonzero traps push the next PC and complete ST before fetching the
  vector.
- Compatibility evidence: TI *TMS34010 User's Guide*, 1988, TRAP, printed
  pp.12-253..12-254 gives the same encoding and visible entry rules but
  substantially different `16,19` aligned and `30,33` unaligned timing.
- Secondary conflict: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 1895–1907 uses the same
  handler for both processor classes and charges 16 cycles for every trap,
  including TRAP 0 and unaligned frames.
- Decision: follow the TMS34020's three primary timing cases in the independent
  model and retain the common visible semantics. The RTL execution router
  rejects all TRAP packets until stack/vector memory ownership, fault/retry,
  and physical timing exist. MAME remains useful for state comparison but not
  TRAP timing. Confidence: `VERIFIED_PRIMARY` for the instruction-boundary
  state and three timing cases; `UNKNOWN` for unimplemented physical-cycle
  decomposition.

## RSC-0023: pinned MAME applies TMS34010 RETS timing to TMS34020

- Status: resolved secondary-reference timing defect; instruction-boundary
  success modeled, physical stack-read timing still pending
- Primary TMS34020 evidence: TI *TMS34020 User's Guide*, August 1990, RETS,
  printed p.13-220 specifies 5 machine states when the old-SP stack-read
  address is 32-bit aligned and 6 otherwise. It reads a 32-bit PC at old SP,
  increments SP by `32 + 16N` bit addresses, and preserves ST.
- Compatibility evidence: TI *TMS34010 User's Guide*, 1988, RETS, printed
  p.12-232 and Appendix A p.A-16 specifies the same `0960h`/`FFE0h` object form
  and visible state but minimum 7 aligned and 9 unaligned machine states.
- Secondary conflict: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 1874–1885 shares one handler
  between device classes and charges 7 cycles without an alignment case.
- Decision: follow the TMS34020's 5/6 instruction-boundary cases in the
  independent model. Keep RETS noncommitting in RTL until a TMS34020-owned
  stack-read, redirect, fault/retry, and timing sequencer exists. MAME remains
  useful for visible-state comparison but is not a RETS timing oracle.
  Confidence: `VERIFIED_PRIMARY` for encoding, visible state, and documented
  timing cases; `UNKNOWN` for the external-cycle decomposition.

## RSC-0024: CALL-family secondary timing and CALLA primary grammar

- Status: CALL/CALLR resolved from primary evidence; CALLA timing unresolved
- Primary TMS34020 evidence: TI *TMS34020 User's Guide*, August 1990, CALL,
  CALLA, and CALLR, printed pp.13-48..13-50, with the repeated timing table on
  printed p.15-3. CALL and CALLR each specify three visible states plus one
  hidden stack-write state for aligned SP or four for unaligned SP. CALLA's
  four printed clauses—3, 4, 3+(3), and 4+(3)—refer to immediate-data and SP
  alignment, but their grammar does not uniquely identify a four-cell matrix.
- Compatibility evidence: TI *TMS34010 User's Guide*, 1988, printed
  pp.12-48..12-50 specifies the same object forms and visible operations but
  materially different timing: CALL `3+(3),9`/`3+(9),15`, CALLA
  `4+(2),15`/`4+(8),21`, and CALLR `3+(2),11`/`3+(8),17` for aligned/unaligned
  stack cases.
- Secondary conflict: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 1428–1451 shares CALL-family
  handlers between processor classes and charges fixed visible values without
  the documented TMS34020 hidden/alignment cases.
- Decision: implement CALL/CALLR visible state and their documented 3+(1)/
  3+(4) abstract timing. Implement CALLA's exact architectural state but mark
  machine-state timing incomplete; do not infer a case mapping from TMS34010
  or MAME. Keep all three noncommitting in RTL until stack-write, redirect,
  fault/retry, and timing ownership exists. OQ-0015 tracks the missing timing
  evidence. Confidence: `VERIFIED_PRIMARY` for all encodings and visible
  state, and for CALL/CALLR's instruction-boundary timing; `UNKNOWN` for the
  CALLA timing mapping and physical-cycle decomposition.

## RSC-0025: three CVXYL example rows omit the documented X term

- Status: open primary example-table defect; equation implemented, physical
  confirmation pending
- Primary equation evidence: TI *TMS34020 User's Guide*, August 1990,
  XY-to-linear conversion §12.12.1, printed p.12-47, defines the linear bit
  address as `(Y × array pitch) + (X × pixel size) + offset`. The CVXYL
  instruction page, printed p.13-92, repeats that execution equation and says
  PSIZE supplies the X shift. X is `0030h` in every example on p.13-93.
- Conflicting primary rows: the p.13-93 PSIZE=`0004h` rows report
  `0002_0000h`, `0002_8000h`, and `0F02_0000h`. The stated equation instead
  gives `0002_00C0h`, `0002_80C0h`, and `0F02_00C0h`, because
  `0030h × 4 = 00C0h`. The adjacent PSIZE 1, 2, 8, and 16 rows do include the
  X term. TI's independently acquired 1988 *TMS34010 User's Guide*, printed
  pp.12-59..12-60, contains the same equation and repeats the same three
  inconsistent result rows.
- Secondary corroboration: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 21–23 and 182–190 adds the
  shifted X term for CVXYL. This supports the equation but is not hardware
  evidence. Its other TMS34020 conversion handlers are incomplete and are not
  used as an oracle.
- Decision: implement the repeated equation and retain corrected expected
  values for those three rows. Do not introduce a PSIZE=4 exception that no
  prose, figure, or adjacent example defines. OQ-0016 tracks the remaining
  silicon/errata confirmation. Confidence: `VERIFIED_PRIMARY` for the equation
  and all nonconflicting rows, `UNKNOWN` for whether an unlocated erratum
  explicitly corrects the table.

## RSC-0026: CVXYL arbitrary-pitch timing is 14 or 15 states

- Status: open primary timing contradiction; instruction-page value selected
  provisionally
- Primary instruction-page evidence: TI *TMS34020 User's Guide*, August 1990,
  CVXYL, printed p.13-92 specifies 3 states for a power-of-two pitch, 4 for a
  sum of two powers, and 14 for an arbitrary pitch.
- Conflicting primary summary: the consolidated instruction-timing table on
  printed p.15-4 repeats 3 and 4 for the first two classes but specifies 15 for
  the arbitrary-pitch class. The adjacent CVDXYL, CVMXYL, and CVSXYL entries
  agree with their instruction pages at 2/3/14, so the conflict is isolated to
  CVXYL arbitrary pitch.
- Compatibility evidence: TI *TMS34010 User's Guide*, 1988, CVXYL, printed
  pp.12-59..12-60 and Appendix A p.A-13 publishes the older power-of-two-only
  `3,6` timing and cannot resolve the TMS34020 arbitrary path.
- Decision: retain 14 states in the current model and semantic RTL leaf because
  it is the instruction-specific value, but classify that choice as
  `PROVISIONAL`, encode both primary values in the ISA database, and make no
  cycle-accuracy claim for this case. OQ-0017 tracks evidence capable of
  resolving the discrepancy. Confidence: `VERIFIED_PRIMARY` that the two
  publications conflict; `UNKNOWN` for real-device arbitrary-pitch timing.

## RSC-0027: DIVS even-destination early-overflow timing scope

- Status: open primary wording ambiguity; chapter-15 condition implemented
  provisionally
- Primary instruction-page evidence: TI *TMS34020 User's Guide*, August 1990,
  DIVS, printed p.13-96 lists even-Rd timing as 40 states normally, 41 when
  the result is `80000000h`, and 7 when Rs is zero. It does not separately
  name a nonzero-divisor quotient-overflow timing case.
- Primary timing-table evidence: the consolidated table on printed p.15-4
  gives the same three numbers but expands the 7-state even-Rd condition to
  `Rs = 0 or Rs <= Rd`. The status rules on p.13-97 likewise mention even Rd
  and `Rd >= Rs`, but the prose does not state whether that comparison is
  applied to raw signed words or the magnitude-normalized operands used by a
  signed divider. A raw signed or unsigned comparison contradicts successful
  mixed-sign example rows; a magnitude high-half comparison matches the
  mathematical condition for a quotient of at least 2^32.
- Compatibility evidence: TI *TMS34010 User's Guide*, 1988, DIVS, printed
  p.12-63 explicitly lists its even-Rd `Rd >= Rs` case as a short path, but its
  alignment-dependent 7/10-state timing is not TMS34020 timing. The pinned
  TMS34010 RTL is therefore only a semantic cross-check.
- Decision: the independent model and restoring-divider leaf use the
  magnitude-normalized high-half comparison for the raw early-overflow path
  and select the TMS34020 timing table's 7 states. Destination preservation
  and N/Z/V follow the quotient-range rules. This selection is
  `PROVISIONAL`; no cycle-accuracy claim is made for the nonzero early path.
  OQ-0018 tracks a diagnostic or hardware discriminator.

## RSC-0028: MODU Z prose names quotient instead of stored remainder

- Status: resolved for the model/RTL contract from the primary operation,
  description, and discriminator example
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, MODU, printed
  p.13-153 defines `Rd mod Rs -> Rd`, repeatedly calls Rd the returned
  remainder, but says Z is 1 if the "quotient" is zero. The `8 mod 4` example
  returns zero and prints Z=1 even though its quotient is 2. The corresponding
  TMS34010 page 12-114 repeats the word "quotient" and the same discriminator.
- Secondary evidence: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 697–729, MODU handler, sets Z
  from the value written back after `%`. This corroborates but does not
  override the primary evidence.
- Decision: Z follows the stored remainder. This is the only interpretation
  consistent with the defined operation and the primary `8 mod 4` row. The
  contradictory noun is retained here rather than propagated into metadata or
  tests. Confidence: `VERIFIED_PRIMARY` for remainder-derived Z.

## RSC-0029: MODS result-80000000h timing class is unreachable

- Status: open provenance/timing-table question; no undocumented operand case
  invented
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, MODS, printed
  p.13-152 and timing p.15-5 publish 41 states when the result is
  `80000000h`. The operation is a signed 32-bit remainder with the dividend's
  sign. For a nonzero divisor, remainder magnitude is strictly less than the
  divisor magnitude. A signed 32-bit divisor has magnitude at most 2^31, and
  divisor `80000000h` yields either a smaller dividend unchanged or remainder
  zero; therefore a remainder of -2^31 cannot occur. The TMS34010 page 12-112
  prints the same condition with alignment variants.
- Decision: the condition remains machine-readable as published, but tests do
  not fabricate an operand row. The model and divider leaf retain a defensive
  result-word check that is unreachable for legal nonzero operands. OQ-0019
  tracks whether this was a copied divide timing row, silicon-internal state,
  or an omitted special case. No cycle-accuracy claim is made for it.

## RSC-0030: MPYS/MPYU detailed pages and timing table swap a state case

- Status: unresolved; detailed instruction-page behavior selected provisionally
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, MPYS printed
  p.13-173 gives `5 + FS1/2` states without a sign case. MPYU printed p.13-176
  gives `5 + FS1/2` when Rs is nonnegative and `6 + FS1/2` when Rs is
  negative. Chapter 15 printed p.15-6 instead assigns the sign-dependent pair
  to MPYS (`5 +` for negative, `6 +` for positive) and gives MPYU the constant
  `5 + FS1/2` rule. These cannot both describe the same executions.
- Cross-generation primary evidence: the 1988 TMS34010 guide printed
  pp.12-165 and 12-167 places the sign-dependent case on MPYU, matching the
  TMS34020 detailed instruction pages, while also publishing separate older
  destination-parity timings.
- Secondary evidence: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010ops.hxx`, lines 731–768, uses constant 20/21
  cycle charges and cannot discriminate either documented rule.
- Decision: semantic results are primary-verified. Model/metadata provisionally
  use the detailed pages: MPYS `5 + FS1/2`; MPYU adds one state when raw Rs bit
  31 is set. This is not a cycle-accuracy claim. OQ-0020 tracks hardware or
  erratum evidence, including whether “Rs negative” observes ignored high bits
  when FS1 is smaller than 32.

## RSC-0031: MPYS Example 1 transposes a multiplicand digit

- Status: resolved for executable fixtures by the companion example and exact
  arithmetic; the printed error remains recorded
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, MPYS Example 1,
  printed p.13-173, gives A0=`8040156Fh`, A1=`7FF3B074h`, and product
  `C0262CDCh:53E486F8h`. Signed multiplication of those printed operands is
  `C0262F68h:9523064Ch`. Example 2 on p.13-174 uses A1=`80401056h` with
  source A0=`7FF3B074h` and prints the same product; those operands calculate
  exactly to `C0262CDCh:53E486F8h`. Every variable-FS1 result in the two tables
  likewise agrees when `80401056h` is the multiplicand.
- Decision: fixtures use `80401056h` and retain the printed product. No
  undocumented arithmetic exception is introduced.

## RSC-0032: TMS34010 odd-product flags disagree across secondary references

- Status: open only for the TMS34010 compatibility boundary; TMS34020 behavior
  is explicit and implemented
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, MPYS printed
  p.13-173 and MPYU p.13-175 explicitly say odd-Rd N/Z are set from the full
  product, including discarded MSBs. The 1988 TMS34010 guide printed
  pp.12-164..12-167 describes the same storage rule but does not repeat that
  explicit odd-result status sentence, leaving the older flag source ambiguous.
- Secondary disagreement: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`, `34010ops.hxx` lines 731–768,
  derives flags from the full product. Pinned TMS34010 RTL commit
  `94a258e80a07ceb4303ce0b99818df832e96007f` documents and tests flags from the
  retained low word in `docs/instruction_coverage.md` rows 87–88 and
  `sim/tb/tb_mpy_flags.sv` lines 99–146.
- Decision: the TMS34020 model and leaf follow their explicit primary pages.
  Odd-Rd discriminators cover a nonzero full product with zero low word and
  signed products whose full and low-word signs differ. Upstream flag fixtures
  are not imported as compatible evidence. OQ-0021 tracks the older device.

## RSC-0033: Multiple-register pages retain contradictory labels and MMFM timing prose

- Status: data-direction/list-order contradictions resolved from the primary
  descriptions and examples; MMFM alignment timing remains provisional
- Primary MMFM evidence: TI *TMS34020 User's Guide*, August 1990, printed
  pp.13-148..13-149 defines memory-to-register transfers, postincrementing Rp,
  highest-register-first order, and a direct mask (`bit n` selects register n).
  Its example list names B3 and B7 but the result table labels their values B4
  and B8. The same pages say original Rp alignment affects timing, while the
  only TMS34020 timing table on printed p.15-6 publishes `n+5` without an
  alignment discriminator.
- Primary MMTM evidence: printed pp.13-150..13-151 repeatedly defines
  register-to-memory predecrement stores, ascending register-number order, and
  the reversed mask (`bit 15` selects register 0, `bit 0` selects SP). The
  execution line instead prints data at the address in Rn moving to Rp, and
  one mask paragraph says selected registers are "restored". Those phrases
  contradict the operation title, full description, mask diagram, memory
  table, and pointer result on the same pages.
- Cross-generation evidence: TI *TMS34010 User's Guide*, 1988, printed
  pp.12-109..12-112 defines the same directions and list orders. Its timings
  are explicitly cache/alignment dependent and are not substituted for the
  TMS34020 table.
- Decision: model/metadata use the unambiguous operation descriptions, mask
  diagrams, and memory ordering; fixtures do not propagate the mislabeled
  MMFM result registers. Successful MMFM reports `n+5` as the sole published
  TMS34020 value but marks timing incomplete and confidence provisional.
  OQ-0022 tracks the missing alignment discriminator. No cycle-accuracy claim
  follows from the selected table.

## RSC-0034: RETI page calls the bus-fault context bit SF

- Status: resolved as a local terminology error; continuation layout remains
  open under OQ-0023
- Primary evidence: the status-register definition in Figure 4-1/Table 4-1,
  printed pp.4-2..4-3, names bit 26 `BF`. Interrupt-entry Figure 6-2 on p.6-9
  also says the bus-fault path sets `BF`, and Figure 6-3 on p.6-10 selects the
  bus-fault restore from that saved context. The RETI execution/timing text on
  pp.13-217..13-218 instead labels the 52-state selection `BF/SF` in adjacent
  presentations even though no corresponding ST `SF` bit is defined.
- Decision: metadata and the classification leaf use ST.BF bit 26. No `SF`
  status bit is invented. This resolves only the selector name, not the hidden
  31-word continuation format or nested-fault behavior.

## RSC-0035: RETM boxed note reverses its cache behavior

- Status: resolved from repeated primary context; pin timing remains pending
- Primary contradiction: the RETM main description and execution contract on
  printed p.13-219 say the next interrupted-program instruction is read
  directly from memory, not cache. Figure 6-3 on p.6-10 says RETM delays
  acceptance so that instruction executes, and the RETI/RETM comparison on
  p.6-32 repeats that RETM permits one instruction before the single-step
  trap. The boxed note on p.13-219 instead says `RETM uses the cache read
  mechanism`, then concludes it is unsuitable when the next opcode is absent
  from cache. That warning describes RETI and contradicts the rest of the
  RETM page.
- Decision: RETM arms a one-shot direct-memory bypass for the entire next
  instruction packet and does not fill or consume the stale cached packet.
  The note is treated as a RETI/RETM name transposition. Directed tests use a
  stale three-word cached instruction to distinguish all extension fetches.
  This decision does not establish local-bus phases, page mode, waits, or
  fault/retry behavior of the forced access.

## RSC-0036: Postincrement field load does not state same-register priority

- Status: open; bounded model behavior is CORROBORATED, not primary-verified
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, printed p.13-161
  says `MOVE *Rs+,Rd[,F]` loads the extended field into Rd and increments Rs,
  but does not state which architectural write wins when both operands name
  the same physical register. The compatible 1988 TMS34010 page at printed
  pp.12-139..12-140 has the same omission.
- Corroborating implementations: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`, `34010ops.hxx` lines
  1269–1283, increments Rs before assigning captured data to Rd, so data wins.
  Pinned TMS34010 RTL commit
  `94a258e80a07ceb4303ce0b99818df832e96007f`,
  `docs/instruction_coverage.md` row 98, independently documents and tests the
  same priority.
- Provisional decision: the model captures the memory field, writes the
  pointer update, then writes the extended field, so loaded data wins. The ISA
  and delta records remain CORROBORATED and OQ-0024 requires primary or
  hardware confirmation before this corner can be called verified.

## RSC-0037: Paired postincrement sources disagree on final aliased pointer

- Status: open; bounded model behavior is CORROBORATED, not primary-verified
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, printed p.13-161
  says the contents of both registers are incremented by the field size and
  says an Rs=Rd copy writes to the incremented value, but it does not state the
  final shared-register value explicitly. The compatible TMS34010 execution
  sequence on printed pp.12-140..12-141 separately assigns `Rs + field size`
  to Rs and `Rd + field size` to Rd. Applied sequentially to one physical
  register, that sequence leaves two increments while using the value after
  the first increment as the destination address.
- Conflicting implementations: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`, `34010ops.hxx` lines
  1311–1324, reads the source, increments Rs, writes through Rd, then
  increments Rd. Aliased operands therefore write at original plus one field
  size and finish at original plus two field sizes. Pinned TMS34010 RTL commit
  `94a258e80a07ceb4303ce0b99818df832e96007f`,
  `docs/instruction_coverage.md` row 101, instead suppresses the destination
  writeback when Rs=Rd and documents a once-incremented final pointer.
- Provisional decision: the model and clean-room address leaf follow the two
  explicit logical increments and pinned MAME: the source read uses the
  original pointer, the destination write uses original plus one field size,
  and the final shared pointer is original plus two field sizes. The ISA and
  delta records remain CORROBORATED. OQ-0025 requires another primary revision,
  erratum, diagnostic, XDS trace, or physical hardware discriminator before
  this legal alias corner can be called verified.

## RSC-0038: Reference RTL suppresses a TMS34020 paired predecrement update

- Status: resolved for TMS34020 from explicit primary text; the TMS34010-only
  silicon corner is not independently qualified
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, printed
  pp.13-161..13-162 explicitly says that when Rs=Rd for
  `MOVE -*Rs,-*Rd[,F]`, the final register value is its original value minus
  twice the field size. The compatible TMS34010 execution sequence on printed
  pp.12-138..12-139 decrements/captures Rs before decrementing/writing Rd, but
  does not separately spell out the final alias value.
- Conflicting implementation: pinned TMS34010 RTL commit
  `94a258e80a07ceb4303ce0b99818df832e96007f`,
  `docs/instruction_coverage.md` row 102, explicitly calls its alias handling a
  documented deviation and leaves the shared register only once-decremented
  despite using the twice-decremented write address.
- Decision: do not reuse that writeback suppression. The TMS34020 model and
  clean-room address leaf read at original minus one field size, write at
  original minus two, and leave the shared pointer at the explicitly specified
  twice-decremented value. This is VERIFIED_PRIMARY for TMS34020 and does not
  claim physical TMS34010 silicon behavior beyond its published sequence.

## RSC-0039: Offset MOVB case E contradicts the published write-cycle count

- Status: open; the literal timing-table cell is implemented provisionally
- Primary contradiction: TI *TMS34020 User's Guide*, August 1990, Table 15-2
  on printed p.15-10 says destination alignment case 5 requires five write
  cycles. Table 15-3 on printed p.15-12 maps source cases 1/2 plus destination
  case 5 to column E. On that same page, every fixed-byte destination-case-5
  cell has four hidden write states except `MOVB *Rs(SOffset),
  *Rd(DOffset)` column E, which uniquely prints `5(2)`. Column F for the same
  instruction prints `6(4)`, and the corresponding indirect and absolute
  byte-move rows also print four hidden states for destination case 5.
- Provisional decision: preserve the literal `5(2)` result in the ISA ledger,
  model, and clean-room timing leaf rather than silently normalize it to the
  geometrically expected `5(4)`. Mark that one cell PROVISIONAL and expose an
  explicit case-E override so tests distinguish it. OQ-0026 requires another
  guide revision, erratum, diagnostic/XDS trace, or physical timing evidence
  before the two-versus-four hidden-state question can be resolved. This does
  not alter the documented five visible states or any byte-copy semantics.

## RSC-0040: Pinned MAME mispacks the short CEXEC command

- Status: resolved for this implementation from explicit primary diagrams and
  prose; no silicon ambiguity remains
- Primary evidence: TI *TMS34020 User's Guide*, August 1990, short CEXEC
  printed pp.13-53..13-54 says the short form specifies 19 of 21 command bits,
  forces LAD bits 14 and 15 to zero, labels the extension field as the 13 MSBs
  and the first-word field as the 6 LSBs, and says assembler selection depends
  on coprocessor-command bits 6 and 7 being zero. Since the 21-bit command
  occupies LAD28:8 under Figure 10-1 on p.10-5, the extension is command
  `[20:8]`, the first word is command `[5:0]`, and command `[7:6]` is zero.
- Secondary disagreement: pinned MAME commit
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
  `src/devices/cpu/tms34010/34010dsm.cpp` lines 1527–1534 reconstructs the
  extension with a five-bit shift and masks only five low first-word bits.
  That drops first-word bit 6 and specifies only 18 distinct command bits,
  contrary to the primary 13-plus-6 layout. Its execution handlers are stubs,
  so they provide no independent semantic discriminator.
- Decision: the ISA database, independent model and clean-room formatter use
  `{extension[12:0], 2'b00, first_word[6:1]}`. Directed discriminators require
  all six low bits, all thirteen high bits, and zero command bits `[7:6]`.
  MAME remains a secondary differential reference and its short-CEXEC
  disassembly formula is not copied.
