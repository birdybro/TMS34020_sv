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
