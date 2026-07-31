# TMS340 toolchain acquisition

## Primary document identities

The original TMS34020 user guide identifies the *TMS340 Family
Code-Generation Tools User's Guide* as SPVU004. Source: TI *TMS34020 User's
Guide*, August 1990, preface p.iv.

Two other contemporary TI publications identify a guide of the same title as
SPVU020:

- TI *TMS340 Family Graphics Library User's Guide*, SPVU027, August 1990,
  preface p.iv;
- TI *TMS340 Interface User's Guide*, SPVU015C, September 1990, preface p.iv.

This repository therefore catalogs SPVU004 and SPVU020 separately. The evidence
supports different catalog identities, but does not establish whether the
change was a new edition, replacement, or renumbering. Neither guide's title
page or full text was located in the TI, Bitsavers, Internet Archive, or general
web searches performed on 2026-07-31.

## Acquired TIGA evidence

The official TI-hosted SPVU015C scan is hash-pinned as
`TI-TMS340-INTERFACE-SPVU015C`. It states that TIGA development requires
TMS340 Family Code Generation Tools version 4.0 or later (§2.2, printed p.2-3)
and describes TMS340 COFF dynamic-load modules and assembly section conventions
in chapter 8. These are supporting toolchain facts, not a substitute for the
missing assembler/linker/COFF guide.

SPVU015C remains in the gitignored reference cache because redistribution
permission has not been established. Its catalog metadata and SHA-256 are
committed in `docs/references/manifest.yaml`.

## Secondary assembler evidence

A community-maintained GSPA command synopsis describes a TMS340 COFF macro
assembler reported as version 6.10 and explicitly states that its author could
not locate SPVU020. This is useful only as a future discovery lead. It is not
used as the authority for syntax, object format, or instruction encoding.
Source: Jeremy Palmer, `GSPA_CLI_DOCS.txt`, retrieved 2026-07-31,
<https://gist.github.com/palmerj/49ddf25fac0abc3bed2375a47f6507bf>.

No legacy assembler executable was downloaded or run. If one is lawfully
acquired later, it must be hashed and executed only in the isolated environment
required by `AGENTS.md`; it must not be committed unless redistribution rights
are explicit.

## Current consequence

`TMS20-0008` remains unstarted. The local assembler/disassembler can be
developed from primary instruction encodings in SPVU019, but full TI syntax,
directives, macro behavior, relocation, and COFF compatibility remain blocked
on SPVU004/SPVU020 or independently documented project-local choices.
