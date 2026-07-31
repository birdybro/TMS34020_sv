# ISA database

The canonical instruction metadata is
[`docs/generated/tms34020_isa.yaml`](../generated/tms34020_isa.yaml). It is the
only table from which project-local decode, assembler, disassembler,
documentation, and generated coverage will be derived.

## Current coverage

The database is deliberately marked `INCOMPLETE_PRIMARY_EXTRACTION`. Its first
slice contains 72 page-verified encoding records and covers 23,088 of 65,536
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
| PUTST | `01A0h`, mask `FFE0h` | 1 | p.13-216 |
| ADDK / INC alias when K=1 | `1000h`, mask `FC00h` | 1 | pp.13-37, 13-134 |
| SUBK / DEC alias when K=1 | `1400h`, mask `FC00h` | 1 | pp.13-94, 13-245 |
| MOVK | `1800h`, mask `FC00h` | 1 | p.13-169 |
| MOVI.W / MOVI | `09C0h`, mask `FFE0h` | 2 | p.13-167 |
| MOVI.L / MOVI | `09E0h`, mask `FFE0h` | 3 | p.13-168 |
| MOVE | `4C00h`, mask `FC00h` | 1 | p.13-158 |
| RL.K / RL constant | `3000h`, mask `FC00h` | 1 | p.13-222 |
| RL.R / RL register | `6800h`, mask `FE00h` | 1 | p.13-223 |
| BTST.K / BTST constant | `1C00h`, mask `FC00h` | 1 | p.13-46 |
| BTST.R / BTST register | `4A00h`, mask `FE00h` | 1 | p.13-47 |
| SETF | `0540h`, mask `FDC0h` | 1 | pp.13-230..13-231 |
| SEXT | `0500h`, mask `FDE0h` | 1 | p.13-232 |
| ZEXT | `0520h`, mask `FDE0h` | 1 | p.13-268 |
| EXGF | `D500h`, mask `FDE0h` | 1 | p.13-111 |
| SLA.K / SLA constant | `2000h`, mask `FC00h` | 1 | p.13-233 |
| SLA.R / SLA register | `6000h`, mask `FE00h` | 1 | p.13-234 |
| SLL.K / SLL constant | `2400h`, mask `FC00h` | 1 | p.13-235 |
| SLL.R / SLL register | `6200h`, mask `FE00h` | 1 | p.13-236 |
| SRA.K / SRA constant | `2800h`, mask `FC00h` | 1 | p.13-237 |
| SRA.R / SRA register | `6400h`, mask `FE00h` | 1 | p.13-238 |
| SRL.K / SRL constant | `2C00h`, mask `FC00h` | 1 | p.13-239 |
| SRL.R / SRL register | `6600h`, mask `FE00h` | 1 | p.13-240 |
| MOVX | `EC00h`, mask `FE00h` | 1 | p.13-170 |
| MOVY | `EE00h`, mask `FE00h` | 1 | p.13-171 |
| SETC | `0DE0h` | 1 | p.13-226 |
| ADD | `4000h`, mask `FE00h` | 1 | p.13-33 |
| ADDC | `4200h`, mask `FE00h` | 1 | p.13-34 |
| ADDXY | `E000h`, mask `FE00h` | 1 | p.13-38 |
| ADDI.W / ADDI | `0B00h`, mask `FFE0h` | 2 | p.13-35 |
| ADDI.L / ADDI | `0B20h`, mask `FFE0h` | 3 | p.13-36 |
| CMPI.W / CMPI | `0B40h`, mask `FFE0h` | 2 | p.13-81 |
| CMPI.L / CMPI | `0B60h`, mask `FFE0h` | 3 | p.13-82 |
| SUBI.W / SUBI | `0BE0h`, mask `FFE0h` | 2 | p.13-243 |
| SUBI.L / SUBI | `0D00h`, mask `FFE0h` | 3 | p.13-244 |
| SUB | `4400h`, mask `FE00h` | 1 | p.13-241 |
| SUBB | `4600h`, mask `FE00h` | 1 | p.13-242 |
| SUBXY | `E200h`, mask `FE00h` | 1 | p.13-246 |
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
| LMO | `6A00h`, mask `FE00h` | 1 | p.13-147 |
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

EXGF atomically exchanges the selected six-bit FS/FE status bank with the low
six bits of an A/B/shared-SP destination and clears the register's upper
26 bits. Its `D500h`/`FDE0h` pattern covers both field banks and both register
files. TI specifies one TMS34020 state for field bank zero and two for field
bank one; pinned MAME charges one for both, as recorded in RSC-0019. Source:
TMS34020 User's Guide printed p.13-111 and timing table p.15-4.

PUTST copies all 32 source-register bits into ST and takes three machine
states. Its `01A0h`/`FFE0h` range covers A/B and the shared-SP alias. The
adjacent `01C0h` POPST encoding is not classified by this record. The same
encoding and full-register copy appear in the TMS34010 guide, establishing
semantic compatibility without inferring broader status or pipeline
equivalence. Sources: TMS34020 User's Guide printed pp.4-2..4-3 and 13-216,
timing table p.15-7; TMS34010 User's Guide printed p.12-229 and its instruction
summary.

LMO uses a same-file register pair, returns the number of leading zero bits
for a nonzero source, and returns zero for a zero source. It writes only Z and
takes one state. The exact `6A00h`/`FE00h` encoding and semantics are present
in both the TMS34020 guide, printed p.13-147, and the independently acquired
1988 TMS34010 guide, printed p.12-108. This establishes the database's
compatibility classification; neither MAME nor the pinned RTL is the source of
that claim.

BTST.K stores the one's complement of the bit number in its five-bit K field.
BTST.R obtains the bit number from the low five bits of a same-file source
register and ignores that source's upper 27 bits. Both forms read but do not
write the destination, set Z when the selected destination bit is zero, clear
Z when it is one, preserve every other ST field, and take one TMS34020 machine
state. Sources: TMS34020 guide printed pp.13-46..13-47 and summary p.13-30.
The acquired TMS34010 guide, printed pp.12-46..12-47, independently confirms
object-code and semantic compatibility, but reports older timing cases;
compatibility does not assert equal timing. At the current model checkpoint the
independent model executes both forms and tests all 25 published input rows,
with the single contradictory p.13-47 status digit resolved in RSC-0018. The
RTL executes both forms through an independent bit-test leaf, the register
router, atomic Z-only commit, and the bounded scalar slice. Directed RTL tests
cover all 25 primary input rows, complemented constant recovery, low-five-bit
register counts with upper-bit truncation, A/B selection, same-register
operands, shared-SP access, and dependent commits.

SETF embeds a five-bit field size, field-extension bit, and field-bank
selector. Size zero encodes 32 bits; F selects either the FS0/FE0 or FS1/FE1
six-bit ST bank, and the other 26 ST bits remain unchanged. SEXT and ZEXT select
FS0 or FS1 with the same F bit and operate on a right-justified field in an
A/B/SP destination. SEXT sign-extends and replaces N/Z in two TMS34020 machine
states; ZEXT zero-extends and replaces only Z in one state. SETF itself takes
one state. Sources: TMS34020 guide printed pp.4-2..4-3, 13-230..13-232, and
13-268. The 1988 TMS34010 guide printed pp.12-237..12-238 and 12-257 confirms
compatible encodings and results but documents different timing; this is
recorded as the first quantified instruction-specific timing delta. The
independent model and bounded RTL implement all three forms across both banks,
all field sizes, A/B, and shared SP. Their serialized commit edge is not
architectural machine-state timing.

ADDXY and SUBXY operate on the X and Y 16-bit halves independently, without
carry or borrow propagation between halves. ADDXY derives N from X-result
zero, C from Y-result bit 15, Z from Y-result zero, and V from X-result bit 15.
SUBXY derives N/Z from equal X/Y halves and V/C from unsigned X/Y borrows,
respectively. Both use a same-file register pair, replace NCZV, and take one
state. The encodings and semantics agree between the TMS34020 guide, printed
pp.13-38 and 13-246, and the independently acquired TMS34010 guide, printed
pp.12-41 and 12-251..12-252. They are therefore classified compatible from
primary sources. The independent model executes every published row and
same-register/B/shared-SP hazards. At this model checkpoint they decode in the
generated RTL and execute through the shared XY leaf, register router, atomic
commit owner, and bounded scalar slice. RTL tests cover all 25 published rows
plus same-register, B-file, shared-SP, and dependent-commit hazards.

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

The `.W` and `.L` MOVI form names distinguish the sign-extended 16-bit and
full 32-bit object encodings; TI uses `MOVI` for both. Both forms update N and
Z from the moved result, preserve C, and clear V. Printed p.13-167 incorrectly
labels Z unaffected and V as the zero indicator, but its own examples, the
adjacent long-form definition, and §4.1 show the reverse. This resolution is
preserved in `docs/research/source_conflicts.md` RSC-0012 rather than silently
correcting the source.

MOVX and MOVY are same-register-file half merges. MOVX replaces the
destination's 16 LSBs and preserves its 16 MSBs; MOVY replaces the 16 MSBs and
preserves the 16 LSBs. Both leave ST unaffected and take one state. Sources:
printed pp.13-170..13-171 and timing table p.15-6.

Full-register `MOVE` uses M in bit 9 and R in bit 4. R selects the source file;
M=0 keeps the destination in that file, while M=1 selects the opposite file.
It is the sole MOVE form that crosses A/B files, copies all 32 bits, derives N/Z
from that value, preserves C, clears V, and takes one state. Source: printed
p.13-158.

The eight SLA/SLL/SRA/SRL records distinguish constant and same-register-file
source-count forms. SLA and SLL encode left-shift counts directly. SRA and SRL
encode a constant count as its five-bit two's complement and take the two's
complement of a register source's low five bits at execution. All four define
count zero as no data shift with C cleared. SLA alone takes three machine
states and replaces N/C/Z/V with overflow detection; SLL and SRL replace only
C/Z, while SRA replaces N/C/Z. Sources: printed pp.13-233..13-240 and timing
table p.15-8. The independent model and bounded RTL execute all eight forms
and check every published example row plus all 32 SLA counts against an
iterative overflow oracle.

The RL form names distinguish the embedded five-bit count (`RL.K`) from the
same-file register count (`RL.R`); TI uses `RL` for both. Each form rotates Rd
left, replaces C/Z, preserves N/V, and takes one state. Count zero clears C.
Sources: printed pp.13-222..13-223 and timing table p.15-8. The p.13-222
count-30 example's C digit conflicts with both its published result and the
page's bit definition; RSC-0013 records the resolution.

SETCDP, SETCMP, and SETCSP are fixed one-word TMS34020 operations. They read
the implied DPTCH (B3), MPTCH (B11), or SPTCH (B1) register and write CONVDP,
CONVMP, or CONVSP through a hidden internal-I/O state. Their conversion fields
are the five-bit one's complements of the represented shift counts; arbitrary
pitches select zero. Sources: printed pp.4-28..4-29, Figure 12-20 on p.12-49,
instruction pages 13-227..13-229, and timing table p.15-8. RSC-0014 records
why the pinned MAME implementation is not used as the oracle.

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

RSC-0013 records that the RL count-30 example prints C=1 even though its own
result has LSB zero and the page defines C as that bit. The database and model
follow the bit definition and published result by expecting C=0.

## Validation

Run:

```sh
make isa-tests
```

The suite validates every required metadata field, exact primary-source seed
fixtures, non-alias cases around fixed opcodes, unique decode across all 65,536
first words, the disclosed partial coverage count, and the TRAPL discrepancy
guard.
