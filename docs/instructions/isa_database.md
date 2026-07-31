# ISA database

The canonical instruction metadata is
[`docs/generated/tms34020_isa.yaml`](../generated/tms34020_isa.yaml). It is the
only table from which project-local decode, assembler, disassembler,
documentation, and generated coverage will be derived.

## Current coverage

The database is deliberately marked `INCOMPLETE_PRIMARY_EXTRACTION`. Its first
slice contains nineteen page-verified instructions and covers 1,804 of 65,536
first words without collisions:

| Mnemonic | First-word pattern | Words | TI source |
|---|---:|---:|---|
| NOP | `0300h` | 1 | p.13-180 |
| ABS | `0380h`, mask `FFE0h` | 1 | p.13-32 |
| NEG | `03A0h`, mask `FFE0h` | 1 | p.13-178 |
| NEGB | `03C0h`, mask `FFE0h` | 1 | p.13-179 |
| NOT | `03E0h`, mask `FFE0h` | 1 | p.13-181 |
| IDLE | `0040h` | 1 | p.13-133 |
| MWAIT | `0080h` | 1 | p.13-177 |
| ADDXYI | `0C00h`, mask `FFE0h` | 3 | p.13-39 |
| BLMOVE | `00F0h`, mask `FFFCh` | 1 | pp.13-44..13-45 |
| RPIX | `0280h`, mask `FFE0h` | 1 | p.13-225 |
| CMPK | `3400h`, mask `FC00h` | 1 | p.13-83 |
| EXGPS | `02A0h`, mask `FFE0h` | 1 | p.13-113 |
| GETPS | `02C0h`, mask `FFE0h` | 1 | p.13-131 |
| RMO | `7A00h`, mask `FE00h` | 1 | p.13-224 |
| SETCDP | `0273h` | 1 | p.13-227 |
| SETCMP | `02FBh` | 1 | p.13-228 |
| SETCSP | `0251h` | 1 | p.13-229 |
| TRAPL | `080Fh` plus signed 16-bit word | 2 | pp.13-256..13-257 |
| VLCOL | `0A00h` | 1 | pp.13-264..13-265 |

Source: TI *TMS34020 User's Guide*, August 1990, chapter 13. Each database entry
also carries instruction length, operand layout, register selection, status
reads/writes, memory transactions, graphics dependencies, cache/pipeline
interaction, interrupt/restart/fault behavior, documented cycle cases,
16/32-bit/page effects, compatibility, citations, and confidence.

Unmatched words are unclassified, **not** presumed reserved or illegal. The
project cannot claim decode or instruction completeness until the database
covers every legal instruction and explicitly classifies the remainder.

## Extraction method

For each instruction:

1. inspect the chapter 13 summary entry;
2. visually verify the instruction-word diagram on its alphabetical-reference
   page rather than trusting OCR;
3. record length, operands, status, cycles, implicit state, interrupts, and
   memory effects from that page;
4. correlate chapters 4–12 and 15 for registers, interfaces, graphics, cache,
   continuation, and timing;
5. use pinned MAME and the pinned TMS34010 reference only to find discrepancies
   or missing coverage;
6. add independent first-word and boundary fixtures;
7. run the complete 65,536-word collision sweep.

This is intentionally slower than copying an emulator table: it preserves TI
as authority and reveals secondary-reference bugs.

## Known discrepancy

`ISA-DISC-0001-TRAPL-length` records that TI defines TRAPL as a two-word
instruction while the pinned MAME disassembler path recognizes the opcode
without consuming the signed extension word. The evidence and exact source
lines are in `docs/research/source_conflicts.md` RSC-0004. The project follows
the TI encoding.

## Validation

Run:

```sh
make isa-tests
```

The suite validates every required metadata field, exact primary-source seed
fixtures, non-alias cases around fixed opcodes, unique decode across all 65,536
first words, the disclosed partial coverage count, and the TRAPL discrepancy
guard.
