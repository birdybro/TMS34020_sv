# ISA database

The canonical instruction metadata is
[`docs/generated/tms34020_isa.yaml`](../generated/tms34020_isa.yaml). It is the
only table from which project-local decode, assembler, disassembler,
documentation, and generated coverage will be derived.

## Current coverage

The database is deliberately marked `INCOMPLETE_PRIMARY_EXTRACTION`. Its first
slice contains 45 page-verified encoding records and covers 9,808 of 65,536
first words without collisions:

| Mnemonic | First-word pattern | Words | TI source |
|---|---:|---:|---|
| NOP | `0300h` | 1 | p.13-180 |
| ABS | `0380h`, mask `FFE0h` | 1 | p.13-32 |
| NEG | `03A0h`, mask `FFE0h` | 1 | p.13-178 |
| NEGB | `03C0h`, mask `FFE0h` | 1 | p.13-179 |
| NOT | `03E0h`, mask `FFE0h` | 1 | p.13-181 |
| CLRC | `0320h` | 1 | p.13-58 |
| DINT | `0360h` | 1 | p.13-95 |
| EINT | `0D60h` | 1 | p.13-109 |
| GETST | `0180h`, mask `FFE0h` | 1 | p.13-132 |
| ADDK / INC alias when K=1 | `1000h`, mask `FC00h` | 1 | pp.13-37, 13-134 |
| SUBK / DEC alias when K=1 | `1400h`, mask `FC00h` | 1 | pp.13-94, 13-245 |
| MOVK | `1800h`, mask `FC00h` | 1 | p.13-169 |
| SETC | `0DE0h` | 1 | p.13-226 |
| ADD | `4000h`, mask `FE00h` | 1 | p.13-33 |
| ADDC | `4200h`, mask `FE00h` | 1 | p.13-34 |
| ADDI.W / ADDI | `0B00h`, mask `FFE0h` | 2 | p.13-35 |
| ADDI.L / ADDI | `0B20h`, mask `FFE0h` | 3 | p.13-36 |
| CMPI.W / CMPI | `0B40h`, mask `FFE0h` | 2 | p.13-81 |
| CMPI.L / CMPI | `0B60h`, mask `FFE0h` | 3 | p.13-82 |
| SUBI.W / SUBI | `0BE0h`, mask `FFE0h` | 2 | p.13-243 |
| SUBI.L / SUBI | `0D00h`, mask `FFE0h` | 3 | p.13-244 |
| SUB | `4400h`, mask `FE00h` | 1 | p.13-241 |
| SUBB | `4600h`, mask `FE00h` | 1 | p.13-242 |
| CMP | `4800h`, mask `FE00h` | 1 | p.13-80 |
| AND | `5000h`, mask `FE00h` | 1 | p.13-40 |
| ANDN | `5200h`, mask `FE00h` | 1 | p.13-42 |
| OR | `5400h`, mask `FE00h` | 1 | p.13-182 |
| XOR | `5600h`, mask `FE00h` | 1 | p.13-266 |
| ANDNI / ANDI alias | `0B80h`, mask `FFE0h` | 3 | pp.13-41, 13-43 |
| ORI | `0BA0h`, mask `FFE0h` | 3 | p.13-183 |
| XORI | `0BC0h`, mask `FFE0h` | 3 | p.13-267 |
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

The `.W` and `.L` suffixes on the ADDI, CMPI, and SUBI record pairs are
canonical database encoding-form names. TI's source mnemonics remain `ADDI`,
`CMPI`, and `SUBI` in the respective aliases. The form names keep different
first words, lengths, immediate widths, object encodings, and timing cases
unambiguous without inventing source-level opcode distinctions. CMPI and SUBI
store the one's complement of their source immediate in each extension word,
as shown on pp.13-81..13-82 and 13-243..13-244.

ADDK is the canonical record for the complete `000100 KKKKK R DDDD`
encoding. Its embedded unsigned K field represents 1–31 directly and uses
encoded zero for 32. TI explicitly defines INC as an alternate mnemonic for
ADDK 1,Rd, so `1020h`–`103Fh` decode as ADDK with the conditional INC alias
rather than as an overlapping instruction record. Sources: printed pp.13-37
and 13-134. The decision is recorded in
`docs/research/source_conflicts.md` RSC-0010.

SUBK is the canonical record for the complete `000101 KKKKK R DDDD`
encoding. Its embedded unsigned K field has the same 1–31/encoded-zero-means-32
mapping. TI explicitly defines DEC as an alternate mnemonic for SUBK 1,Rd, so
`1420h`–`143Fh` decode as SUBK with the conditional DEC alias rather than as
an overlapping instruction record. Sources: printed pp.13-94 and 13-245. The
decision is recorded in `docs/research/source_conflicts.md` RSC-0011.

MOVK uses the adjacent `000110 KKKKK R DDDD` encoding and the same unsigned
1–31/encoded-zero-means-32 K mapping. It zero-extends that constant into the
selected A/B destination, leaves every ST bit unaffected, and takes one
documented machine state. Sources: printed p.13-169 and timing-table p.15-6.

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

`ISA-DISC-0002-fixed-low-bits` records that the pinned MAME disassembler
ignores bits 4–0 for several fixed no-operand instructions, while TI's
instruction diagrams specify those bits as zero. The database follows the
exact TI words and keeps the neighboring encodings unclassified. See
`docs/research/source_conflicts.md` RSC-0005 for pinned lines and scope.

RSC-0006 records an internal wording error on the ORI page: both timing cases
say “aligned.” The same guide's chapter 15 timing table distinguishes two
states for aligned immediate data and three for unaligned data. The database
cites both primary locations and uses the timing-table distinction.

RSC-0009 records that the first SUBI.L example prints `NCZV=0001` for a zero
result without signed overflow. The model follows the same page's flag
definitions and the other zero-result rows by expecting `0010`.

## Validation

Run:

```sh
make isa-tests
```

The suite validates every required metadata field, exact primary-source seed
fixtures, non-alias cases around fixed opcodes, unique decode across all 65,536
first words, the disclosed partial coverage count, and the TRAPL discrepancy
guard.
