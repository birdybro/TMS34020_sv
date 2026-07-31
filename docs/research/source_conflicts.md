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
