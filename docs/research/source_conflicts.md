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

- Status: unresolved
- Evidence:
  - August 1990 TMS34020 guide preface page iv calls the code-generation tools
    guide SPVU004;
  - August 1990 SPVU027 preface page iv calls it SPVU020.
- Hypotheses: separate editions, a catalog renumbering, or a publication typo.
- Decision: retain both identifiers and mark the manual missing until an actual
  title page/revision is acquired. Confidence: `UNKNOWN`.

## RSC-0003: MAME Midway X-unit path

- Status: resolved for the pinned commit
- Evidence: MAME git tree at
  `a562e947b22f4f5acff0c182c26fd649d72dad0e`.
- Decision: use `src/mame/williams/midxunit.cpp`. The candidate
  `src/mame/midway/midxunit.cpp` does not exist at that commit. Confidence:
  `VERIFIED_PRIMARY` for source-tree identity.
