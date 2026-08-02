# ISA database

The canonical instruction metadata is
[`docs/generated/tms34020_isa.yaml`](../generated/tms34020_isa.yaml). It is the
only table from which project-local decode, assembler, disassembler,
documentation, and generated coverage will be derived.

## Current coverage

The database is deliberately marked `INCOMPLETE_PRIMARY_EXTRACTION`. Its first
slice contains 144 page-verified encoding records and covers 48,222 of 65,536
first words without collisions:

| Mnemonic | First-word pattern | Words | TI source |
|---|---:|---:|---|
| NOP | `0300h` | 1 | p.13-180 |
| REV | `0020h`, mask `FFE0h` | 1 | p.13-221 |
| TRAP | `0900h`, mask `FFE0h` | 1 | pp.13-253..13-255 |
| CALL | `0920h`, mask `FFE0h` | 1 | p.13-48 |
| CALLA | `0D5Fh` plus low/high target words | 3 | p.13-49 |
| CALLR | `0D3Fh` plus signed word displacement | 2 | p.13-50 |
| RETM | `0860h` | 1 | p.13-219 |
| RETI | `0940h` | 1 | pp.13-217..13-218 |
| RETS | `0960h`, mask `FFE0h` | 1 | p.13-220 |
| ABS | `0380h`, mask `FFE0h` | 1 | p.13-32 |
| NEG | `03A0h`, mask `FFE0h` | 1 | p.13-178 |
| NEGB | `03C0h`, mask `FFE0h` | 1 | p.13-179 |
| NOT | `03E0h`, mask `FFE0h` | 1 | p.13-181 |
| CLRC | `0320h` | 1 | p.13-58 |
| DINT | `0360h` | 1 | p.13-95 |
| DIVS | `5800h`, mask `FE00h` | 1 | pp.13-96..13-97 |
| DIVU | `5A00h`, mask `FE00h` | 1 | pp.13-98..13-99 |
| MPYS | `5C00h`, mask `FE00h` | 1 | pp.13-172..13-174 |
| MPYU | `5E00h`, mask `FE00h` | 1 | pp.13-175..13-176 |
| SWAPF | `7E00h`, mask `FE00h` | 1 | pp.13-247..13-248 |
| MMTM | `0980h`, mask `FFE0h` | 2 | pp.13-150..13-151 |
| MMFM | `09A0h`, mask `FFE0h` | 2 | pp.13-148..13-149 |
| MODS | `6C00h`, mask `FE00h` | 1 | p.13-152 |
| MODU | `6E00h`, mask `FE00h` | 1 | p.13-153 |
| EINT | `0D60h` | 1 | p.13-109 |
| JUMP | `0160h`, mask `FFE0h` | 1 | p.13-141 |
| JACC / JAcondition | `C080h`, mask `F0FFh` | 3 | pp.13-135..13-136 |
| JR.L / long JRcc | `C000h`, mask `F0FFh` | 2 | pp.13-139..13-140 |
| GETST | `0180h`, mask `FFE0h` | 1 | p.13-132 |
| PUTST | `01A0h`, mask `FFE0h` | 1 | p.13-216 |
| POPST | `01C0h` | 1 | p.13-214 |
| PUSHST | `01E0h` | 1 | p.13-215 |
| ADDK / INC alias when K=1 | `1000h`, mask `FC00h` | 1 | pp.13-37, 13-134 |
| SUBK / DEC alias when K=1 | `1400h`, mask `FC00h` | 1 | pp.13-94, 13-245 |
| MOVK | `1800h`, mask `FC00h` | 1 | p.13-169 |
| MOVI.W / MOVI | `09C0h`, mask `FFE0h` | 2 | p.13-167 |
| MOVI.L / MOVI | `09E0h`, mask `FFE0h` | 3 | p.13-168 |
| MOVE | `4C00h`, mask `FC00h` | 1 | p.13-158 |
| MOVE.RM / `MOVE Rs,*Rd[,F]` | `8000h`, mask `FC00h` | 1 | p.13-159 |
| MOVE.MR / `MOVE *Rs,Rd[,F]` | `8400h`, mask `FC00h` | 1 | pp.13-160, 13-163 |
| MOVE.MM / `MOVE *Rs,*Rd[,F]` | `8800h`, mask `FC00h` | 1 | p.13-160 |
| MOVE.RM.POST / `MOVE Rs,*Rd+[,F]` | `9000h`, mask `FC00h` | 1 | p.13-160 |
| MOVE.MR.POST / `MOVE *Rs+,Rd[,F]` | `9400h`, mask `FC00h` | 1 | p.13-161 |
| MOVE.MM.POST / `MOVE *Rs+,*Rd+[,F]` | `9800h`, mask `FC00h` | 1 | p.13-161 |
| MOVE.RM.PRE / `MOVE Rs,-*Rd[,F]` | `A000h`, mask `FC00h` | 1 | p.13-160 |
| MOVE.MR.PRE / `MOVE -*Rs,Rd[,F]` | `A400h`, mask `FC00h` | 1 | pp.13-161, 13-163 |
| MOVE.MM.PRE / `MOVE -*Rs,-*Rd[,F]` | `A800h`, mask `FC00h` | 1 | pp.13-161..13-162 |
| MOVE.RM.OFFSET / `MOVE Rs,*Rd(offset)[,F]` | `B000h`, mask `FC00h` | 2 | p.13-160 |
| MOVE.MR.OFFSET / `MOVE *Rs(offset),Rd[,F]` | `B400h`, mask `FC00h` | 2 | pp.13-162..13-163 |
| MOVE.MM.OFFSET / `MOVE *Rs(SOffset),*Rd(DOffset)[,F]` | `B800h`, mask `FC00h` | 3 | p.13-162 |
| MOVE.MM.SOFF_POST / `MOVE *Rs(offset),*Rd+[,F]` | `D000h`, mask `FC00h` | 2 | pp.13-162, 13-166 |
| MOVE.RM.ABS / `MOVE Rs,@DAddress[,F]` | `0580h`, mask `FDE0h` | 3 | pp.13-159..13-160 |
| MOVE.MR.ABS / `MOVE @SAddress,Rd[,F]` | `05A0h`, mask `FDE0h` | 3 | pp.13-162..13-163 |
| MOVE.MM.SABS_POST / `MOVE @SAddress,*Rd+[,F]` | `D400h`, mask `FDE0h` | 3 | p.13-163 |
| MOVE.MM.ABS / `MOVE @SAddress,@DAddress[,F]` | `05C0h`, mask `FDFFh` | 5 | p.13-163 |
| MOVB.RM / `MOVB Rs,*Rd` | `8C00h`, mask `FE00h` | 1 | p.13-154 |
| MOVB.RM.OFFSET / `MOVB Rs,*Rd(offset)` | `AC00h`, mask `FE00h` | 2 | p.13-154 |
| MOVB.RM.ABS / `MOVB Rs,@DAddress` | `05E0h`, mask `FFE0h` | 3 | p.13-154 |
| MOVB.MR / `MOVB *Rs,Rd` | `8E00h`, mask `FE00h` | 1 | pp.13-155..13-156 |
| MOVB.MR.OFFSET / `MOVB *Rs(offset),Rd` | `AE00h`, mask `FE00h` | 2 | pp.13-155..13-156 |
| MOVB.MR.ABS / `MOVB @SAddress,Rd` | `07E0h`, mask `FFE0h` | 3 | p.13-156 |
| MOVB.MM / `MOVB *Rs,*Rd` | `9C00h`, mask `FE00h` | 1 | p.13-155 |
| MOVB.MM.OFFSET / `MOVB *Rs(SOffset),*Rd(DOffset)` | `BC00h`, mask `FE00h` | 3 | p.13-156 |
| MOVB.MM.ABS / `MOVB @SAddress,@DAddress` | `0340h` | 5 | p.13-156 |
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
| DSJ | `0D80h`, mask `FFE0h` | 2 | p.13-103 |
| DSJEQ | `0DA0h`, mask `FFE0h` | 2 | pp.13-104..13-105 |
| DSJNE | `0DC0h`, mask `FFE0h` | 2 | pp.13-106..13-107 |
| DSJS | `3800h`, mask `F800h` | 1 | p.13-108 |
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
| CMPXY | `E400h`, mask `FE00h` | 1 | p.13-84 |
| CPW | `E600h`, mask `FE00h` | 1 | pp.13-85..13-86 |
| CVDXYL | `0A80h`, mask `FFE0h` | 1 | pp.13-87..13-88 |
| CVMXYL | `0A60h`, mask `FFE0h` | 1 | pp.13-89..13-90 |
| CVSXYL | `EA00h`, mask `FE00h` | 1 | p.13-91 |
| CVXYL | `E800h`, mask `FE00h` | 1 | pp.13-92..13-93 |
| AND | `5000h`, mask `FE00h` | 1 | p.13-40 |
| ANDN | `5200h`, mask `FE00h` | 1 | p.13-42 |
| OR | `5400h`, mask `FE00h` | 1 | p.13-182 |
| XOR / CLR when Rs=Rd | `5600h`, mask `FE00h` | 1 | pp.13-57, 13-266 |
| ANDNI / ANDI alias | `0B80h`, mask `FFE0h` | 3 | pp.13-41, 13-43 |
| ORI | `0BA0h`, mask `FFE0h` | 3 | p.13-183 |
| XORI | `0BC0h`, mask `FFE0h` | 3 | p.13-267 |
| IDLE | `0040h` | 1 | p.13-133 |
| MWAIT | `0080h` | 1 | p.13-177 |
| ADDXYI | `0C00h`, mask `FFE0h` | 3 | p.13-39 |
| BLMOVE | `00F0h`, mask `FFFCh` | 1 | pp.13-44..13-45 |
| CEXEC.L | exact `0600h` plus command/size and ID/command words | 3 | pp.13-51..13-52 |
| CEXEC.S | `D800h`, mask `FF80h`, plus ID/command word | 2 | pp.13-53..13-54 |
| CLIP | `08F2h` | 1 | pp.13-55..13-56 |
| FPIXEQ | `0ABBh` | 1 | pp.13-126..13-127 |
| FPIXNE | `0ADBh` | 1 | pp.13-128..13-129 |
| CMOVGC.1 | `0620h`, mask `FFE0h`, plus command and ID/command words | 3 | pp.13-67..13-68 |
| CMOVGC.2 | `0640h`, mask `FFE0h`, plus command/size/Rs2 and ID/command words | 3 | pp.13-69..13-70 |
| CMOVCG / CMOVCS packet refinement | `0660h`, mask `FFE0h`, plus command/size/Rd2 and ID/command words | 3 | CMOVCG pp.13-59..13-60; CMOVCS p.13-66 |
| CMOVMC.POST.C | `0680h`, mask `FFE0h`, plus command/size/Rs and ID/command words | 3 | pp.13-71..13-73 |
| CMOVCM.POST.C | `06A0h`, mask `FFE0h`, plus command/size/count and ID/command words | 3 | pp.13-61..13-62; RSC-0042/RSC-0043 |
| CMOVCM.PRE.C | `06C0h`, mask `FFE0h`, plus command/size/count and ID/command words | 3 | pp.13-63..13-65; RSC-0042/RSC-0043 |
| CMOVMC.POST.R | `06E0h`, mask `FFE0h`, plus command/size/Rs and ID/command words | 3 | pp.13-78..13-79 |
| CMOVMC.PRE.C | `0820h`, mask `FFE0h`, plus command/size/Rs and ID/command words | 3 | pp.13-74..13-77 |
| RPIX | `0280h`, mask `FFE0h` | 1 | p.13-225 |
| CMPK | `3400h`, mask `FC00h` | 1 | p.13-83 |
| EXGPS | `02A0h`, mask `FFE0h` | 1 | p.13-113 |
| GETPS | `02C0h`, mask `FFE0h` | 1 | p.13-131 |
| LINIT | `0C57h` | 1 | p.13-146 |
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

LINIT is the exact one-word `0C57h` TMS34020-only line-setup operation. Its
operands are implied B2/B7 endpoints and B5/B6 signed inclusive window bounds;
it overwrites B0/B7/B10/B11/B12 and NCZV together, performs no data-memory
transaction, and takes nine machine states. Endpoint and window inputs must be
captured before B7 writeback. Sources: User's Guide §12.7.5.2 printed p.12-26,
LINIT printed p.13-146, FLINE setup printed pp.13-121..13-123, and timing table
p.15-6.

CLIP is the exact one-word `08F2h` TMS34020-only common-rectangle operation.
For positive unsigned B7 dimensions it intersects the array beginning at
signed-XY B2 with inclusive signed B5/B6 bounds using an extended endpoint,
so a coordinate overflow cannot wrap back into the window. A nonempty
intersection replaces B2/B7; a wholly outside array preserves them. Only Z/V
change, no data-memory cycle occurs, and timing is documented as complex.
OQ-0029 retains the unspecified Z/V result for a zero width or height. Sources:
User's Guide DYDX printed pp.4-50..4-51, §12.7.4.4 p.12-23, CLIP
pp.13-55..13-56, and timing p.15-2.

FPIXEQ/FPIXNE are the exact one-word `0ABBh`/`0ADBh` TMS34020-only pixel
searches. Signed B11/MPTCH selects postincrement for positive counts and
predecrement for negative counts; its magnitude decreases after each checked
PSIZE-bit pixel. A plane-masked memory pixel is compared with the aligned
B8/COLOR0 lane for equality or inequality. B10/MADDR and B11 retain the
remaining scan checkpoint, while only Z changes. TI specifies complex timing
and a special interrupt restart that backs up PC and resets operands without
saving internal temporaries. The model implements only an uninterrupted,
successful logical scan; physical read grouping, waits, page mode, fault/retry
and continuation remain absent. RSC-0044 resolves the general plane-mask
section's omission using both instruction-specific enable statements. Sources:
User's Guide FPIXEQ pp.13-126..13-127, FPIXNE pp.13-128..13-129, interrupt
exception p.6-14, and plane masking pp.12-39..12-40.

`CLR Rd` is the documented alternate mnemonic for `XOR Rd,Rd`, not a separate
decode range. Its instruction word repeats the same four-bit register number
in source bits `[8:5]` and destination bits `[3:0]`; bit 4 selects the shared
A/B file for both fields. Consequently only the 32 same-number words in the
existing `5600h`/`FE00h` XOR range are CLR spellings. Mismatched words such as
`5620h` remain ordinary XOR operations. The TMS34020 guide specifies one
machine state, a zero destination, Z set, and N/C/V unchanged; the TMS34010
guide gives the same encoding and visible behavior but different clock-count
notation. Sources: TMS34020 User's Guide printed pp.13-57 and 13-266;
TMS34010 User's Guide printed p.12-51.

CMPXY is the nondestructive same-file XY compare at `E400h`/`FE00h`. It
subtracts the signed 16-bit X and Y halves independently for status only:
N reports X equality, C is the sign of the wrapped Y-half difference, Z
reports Y equality, and V is the sign of the wrapped X-half difference.
Despite the conventional flag names, CMPXY performs no overflow detection and
writes no register. The TMS34020 page specifies one machine state; the
TMS34010 page documents identical encoding and visible behavior with `1,4`
timing, so the compatibility classification does not authorize reuse of the
older sequencer. Sources: TMS34020 User's Guide printed p.13-84; TMS34010
User's Guide printed p.12-56.

CPW compares a signed XY point in a same-file source register against the
inclusive signed XY bounds in implied B5/WSTART and B6/WEND. It writes a
zero-extended outcode into destination bits `[8:5]`: left, right, above, and
below occupy bits 5, 6, 7, and 8 respectively. V is set when any outcode bit is
set; N/C/Z and all non-V status fields are preserved. Its `E600h`/`FE00h`
range takes one TMS34020 machine state. The independent model covers all 16
published point/window rows, signed discriminators, A/B/shared-SP operands,
and B5/B6 read-before-write hazards. A standalone synthesizable leaf implements
the signed comparisons; the scalar router deliberately rejects CPW until it
can read both implied registers atomically. Sources: TMS34020 User's Guide
printed pp.13-85..13-86 and p.15-4; TMS34010 User's Guide printed
pp.12-57..12-58 and Appendix A p.A-13.

CVDXYL, CVMXYL, CVSXYL, and CVXYL implement the three CONVxP pitch classes
defined by §12.12 and Figure 12-20. Conversion value 1 selects a signed
arbitrary-pitch multiply when zero, one signed-Y shift when nonzero, or two
signed-Y shifts when conversion value 2 is also nonzero. CVDXYL uses Rd as XY,
same-file R4 as OFFSET, B3/DPTCH for arbitrary pitch, CONVDP, and PSIZE.
CVMXYL uses Rd, B11/MPTCH, and CONVMP, with unscaled X and no offset in its
published execution equation. CVSXYL uses Rd as XY, explicit Rs as offset,
B1/SPTCH, CONVSP, and PSIZE. CVXYL uses explicit Rs as XY with implied B3,
B4/OFFSET, CONVDP, and PSIZE. All preserve ST. The first three take 2/3/14
states for one-power/two-power/arbitrary pitch. CVXYL takes 3/4 for the first
two classes; its own page says 14 for arbitrary pitch while the consolidated
timing table says 15, and the model provisionally uses 14. RSC-0025 records
three PSIZE=4 example rows that omit the X term required by the repeated
equation; the equation is implemented without inventing a special case.
RSC-0026 tracks the timing contradiction. Sources: TMS34020 User's Guide
printed pp.4-28..4-29, 12-47..12-49, 13-87..13-93, and timing p.15-4; CVXYL
compatibility cross-check: TMS34010 User's Guide printed pp.12-59..12-60.

DIVS and DIVU use same-file Rs/Rd fields. Odd Rd divides one 32-bit dividend
and writes only the quotient; even Rd divides the signed or unsigned 64-bit
`Rd:Rd+1` pair, writes the quotient to Rd and the remainder to Rd+1, and can
therefore pair A14 or B14 with the shared SP. All operands are captured before
writeback, and overflow—including divisor zero—preserves the complete
destination or pair. DIVS defines N/Z/V and leaves C unchanged; DIVU defines
Z/V and leaves N/C unchanged. The model covers signed truncation toward zero,
remainder sign, primary tables, alias hazards, signed-range and raw early
overflow, and documented normal/special state classes. RSC-0027 makes the
signed nonzero early-overflow magnitude comparison/7-state choice
provisional. Sources: TMS34020 User's Guide printed pp.13-96..13-99 and
15-4; TMS34010 compatibility cross-check printed pp.12-63..12-66 and
Appendix A p.A-15.

MODS/MODU use the same same-file Rs/Rd fields but always operate on a 32-bit
dividend and store the signed or unsigned remainder in Rd. MODS gives the
remainder the dividend's sign and defines N/Z/V while preserving C; MODU
defines Z/V and preserves N/C. For a zero divisor, the resulting Rd value
equals its old dividend, MODS forces N=Z=0, MODU forces Z=0, and both set V.
RSC-0028 records that the MODU page incorrectly says Z follows the quotient:
its `8 mod 4` row proves Z follows the stored zero remainder. MODS publishes a
41-state result-`80000000h` case that cannot arise from documented signed
32-bit remainder arithmetic; it remains recorded without an invented operand
case under RSC-0029/OQ-0019. Sources: TMS34020 User's Guide printed
pp.13-152..13-153 and 15-5; TMS34010 compatibility cross-check printed
pp.12-112..12-114 and Appendix A p.A-17.

MPYS/MPYU multiply the signed/unsigned low-FS1 field of Rs by the complete
32-bit Rd. FS1 is documented only for even values 2–32; encoded zero means 32,
and odd configured sizes remain unspecified rather than being assigned guessed
arithmetic. Even Rd stores the high and low product words in `Rd:Rd+1`; odd Rd
stores only the low word, but the guide explicitly derives N/Z from the full
product including discarded high bits. Pair operands are captured before
writes, including source=destination, source=Rd+1, and the discouraged but
defined Rd=14/SP pair. RSC-0031 corrects the impossible `8040156Fh` MPYS table
operand to the companion example's arithmetic-consistent `80401056h`.
RSC-0030/OQ-0020 retain the detailed-page/chapter-15 timing swap; metadata and
model provisionally use MPYS `5+FS1/2` and MPYU `5+FS1/2` plus one when raw Rs
bit 31 is set. Sources: TMS34020 User's Guide printed pp.13-172..13-176 and
15-6; TMS34010 compatibility cross-check printed pp.12-164..12-167.

SWAPF exchanges the FS0/FE0-selected field at `*Rs` with low Rd bits under a
bus lock. All 512 same-file register encodings are classified. The metadata
keeps the successful five-state, 32-bit-target, word-local semantics separate
from the unimplemented physical lock owner: read/write adjacency, implicit
MWAIT, restart-from-read on retry/fault/interruption, host exclusion, and the
SIZE16/S=0 limitation remain explicit test obligations. Sources: TMS34020
User's Guide printed pp.13-247..13-248, 8-13, 8-26, and 15-9.

MMTM and MMFM retain compatible first words but use opposite second-word list
mask directions. MMTM bit 15 selects register 0 and bit 0 selects SP; MMFM bit
0 selects register 0 and bit 15 selects SP. Metadata records predecrement/
ascending-register stores, postincrement/descending-register loads, pointer
validity, MMTM's N-only result, page-mode eligibility, dynamic-width and fault
obligations, and the complete published timing tables. MMFM `n+5` remains
provisional under RSC-0033/OQ-0022 because its detailed page claims an absent
alignment discriminator. Sources: TMS34020 User's Guide printed
pp.8-16..8-17, 13-148..13-151, and 15-6.

RETI is the exact word `0940h`. Its normal frame reads saved ST at old SP and
saved PC at old SP+32, then restores ST, aligned PC, and SP+64 in seven states.
A saved IX or BF selects 24 or 31 additional internal-state words and published
38- or 52-state cases. Because the guide does not expose a sufficient
field-by-field continuation format, the database marks the complete operation
PROVISIONAL: the model executes and tests only the normal context, atomically
rejects IX/BF, and the RTL leaf only classifies the three cases. Sources:
TMS34020 User's Guide printed pp.3-29..3-30, 6-9..6-10, 13-217..13-218, and
15-8; OQ-0023/RSC-0034.

RETM is the exact TMS34020-only word `0860h`. It shares RETI's normal/IX/BF
frame selection but takes 10/38/52 states, forces the entire next instruction
packet to direct memory, and delays restored-IE/single-step recognition until
one interrupted-program instruction executes. Its normal model path and
one-shot cache bypass are tested with a stale three-word packet; IX/BF and the
interrupt scheduler remain unimplemented. Sources: User's Guide Figure 6-3
p.6-10, RETM p.13-219, comparison p.6-32, timing p.15-8; RSC-0035.

REV at `0020h`/`FFE0h` writes an architecturally visible physical-device
identity to an A/B destination or the shared SP alias without changing ST. In
the TMS34020 format, bits `[2:0]` identify the silicon revision, bit 4 is the
TMS34020 family tag, and bits `[23:16]` identify spin-offs; the guide gives
`0000_0010h` and `0000_0011h` as revision-1.0 and revision-2.0 examples. The
same TMS34010 encoding instead uses family bit 3 and its guide example returns
`0000_0008h`. Pinned MAME shares that TMS34010 constant with its TMS34020
implementation, as recorded in RSC-0021. Because the target-game silicon
steppings remain unknown, the database classifies REV but model and RTL tests
require execution to remain unsupported until an explicit evidence-backed
device profile supplies the complete result.

TRAP embeds an unsigned trap number 0–31 in bits `[4:0]` of the
`0900h`/`FFE0h` form. Nonzero traps predecrement SP twice, save the address
after the instruction followed by the complete old ST, replace ST with
`0000_0010h`, fetch the vector at `FFFF_FFE0h - (N << 5)`, and load the
aligned vector target into PC. TRAP 0 is the reset exception: it performs no
stack write and leaves SP unchanged before replacing ST and fetching vector
zero. The TMS34020 cases are 7 states for trap zero, 10 for a nonzero aligned
saved-ST address, and 12 otherwise. The independent model covers all 32 vector
numbers and both alignment classes. RTL remains noncommitting until the memory,
fault/retry, and entry sequencer own this operation. Sources: TMS34020 User's
Guide printed pp.13-253..13-255; TMS34010 User's Guide printed
pp.12-253..12-254.

RETS embeds an unsigned argument-word discard count 0–31 in bits `[4:0]` of
the `0960h`/`FFE0h` form. It reads the 32-bit return PC at old SP, redirects
to that address with the architectural low-nibble alignment rule, then sets SP
to `old SP + 32 + 16N` bit addresses without changing ST. The TMS34020 takes
5 states for an aligned old-SP stack address and 6 otherwise; the compatible
TMS34010 form publishes minimum 7/9 states and pinned MAME charges a fixed 7.
The independent model covers all 32 N values, both alignment classes, PC
alignment, SP wrap, and exact read traces. RTL only decodes the form and proves
noncommit pending stack-read ownership. Sources: TMS34020 User's Guide printed
p.13-220 and §4.2 p.4-4; TMS34010 User's Guide printed p.12-232 and Appendix A
p.A-16.

CALL captures an A/B register or shared SP target before predecrementing SP by
32 bit addresses, writes the sequential return PC at the new SP, and redirects
to the aligned captured target. Capturing first is architecturally significant
for `CALL SP`. CALLR performs the same stack write and adds a signed 16-bit
word displacement to the address after its extension word. Both take three
visible states plus one hidden write state for aligned SP or four hidden states
for unaligned SP. CALLA consumes low then high absolute target words, saves the
address after all three words, and applies the same aligned redirect and stack
operation. Its visible state is unambiguous, but the four timing clauses on
printed pp.13-49 and 15-3 do not uniquely map immediate/SP alignment to a case;
RSC-0024 and OQ-0015 retain that uncertainty. The model therefore reports
exact CALL/CALLR timing and intentionally reports CALLA timing incomplete. RTL
classifies all forms but proves them noncommitting pending stack-write and
direct-PC ownership. Sources: TMS34020 User's Guide printed pp.13-48..13-50,
§4.2 p.4-4, and timing table p.15-3; compatibility cross-check: TMS34010
User's Guide printed pp.12-48..12-50.

JUMP reads an A/B register or the shared-SP alias, clears target bits `[3:0]`,
and redirects PC in two machine states without changing ST. Its
`0160h`/`FFE0h` range ends immediately before GETST's `0180h` range. The
TMS34010 guide gives the same encoding and programmer-visible operation, so
semantic compatibility is primary-verified without treating the TMS34010
pipeline as reusable. Sources: TMS34020 User's Guide printed p.13-141 and
§4.2 p.4-4; TMS34010 User's Guide printed p.12-98 and its instruction summary.
The independent model implements the successful redirect boundary. The bounded
RTL implements the same aligned redirect without a register or status write;
the documented two-state retirement is not implemented.

The extracted JAcc form has exact first word
`1100_CCCC_1000_0000`, followed by the absolute address low word and high
word. A satisfied condition loads the assembled 32-bit address into PC with
bits `[3:0]` forced to zero; a false condition falls through after all three
words. It reads N/C/Z/V, changes no status or register, and takes three/four
machine states for false/taken cases. Sources: TMS34020 User's Guide,
`JAcondition`, printed pp.13-135..13-136 and timing table p.15-5. The TMS34010
guide printed pp.12-92..12-93 establishes semantic/object compatibility but
has different timing. The model and bounded RTL execute all condition outcomes;
RTL uses both extension words and forces target bits `[3:0]` low. This does not
establish documented RTL retirement timing.

The extracted long `JRcc` form has first word
`1100_CCCC_0000_0000` and a signed 16-bit word displacement in its second
word. Its target is the sequential address after that word plus the
sign-extended displacement shifted left four. Condition codes 0 through F are
respectively true, P, LS, HI, LT, GE, LE, GT, C, NC, EQ, NE, V, NV, N, and NN;
they read N/C/Z/V and change no status bit. A false condition takes two machine
states and falls through; a true condition takes three and redirects. Sources:
TMS34020 User's Guide condition table, printed pp.13-27 and 13-138; long-form
JR reference, printed pp.13-139..13-140; timing table p.15-5. The TMS34010
guide printed pp.12-96..12-97 confirms the encoding and visible semantics but
publishes different timing, so no TMS34010 timing machine is reused.

The exact 16 long-JR first words and 16 JAcc first words are classified. The
remaining `CcodeXXh` space is deliberately unclassified until the short
eight-bit `JRcc` form can be represented while excluding `XX=00h` and
`XX=80h`; RSC-0020 records the primary-source range ambiguity. The independent
model executes all 16 long
conditions, preserves ST/registers, applies signed displacement extremes and
PC wrap, and reports the documented two-/three-state instruction-boundary
cases. Bounded RTL direct, commit, and cache-fed tests exercise predicate-false
fallthrough and predicate-true signed redirects while requiring complete
register/status preservation. This is functional execution evidence, not the
documented retirement schedule.

DSJ, DSJEQ, and DSJNE each consume a signed 16-bit **word** displacement in
their second word. When the instruction's decrement condition is true, the
selected A/B/shared-SP register is decremented modulo `2^32`; a nonzero result
redirects to the sequential address after the second word plus the
sign-extended displacement shifted left four. DSJEQ performs that operation
only when Z is one, and DSJNE only when Z is zero. A suppressed condition
neither decrements nor redirects. ST is unchanged. Each form takes two states
without a redirect and three states with one. The TMS34010 guide documents the
same visible semantics and encodings, but its timing is not reused. Sources:
TMS34020 User's Guide printed pp.13-103..13-107 and TMS34010 User's Guide
printed pp.12-69..12-74. The independent model executes all three forms and
reports the documented two-/three-state cases. The bounded RTL conditions the
atomic decrement on Z, preserves ST, and holds any signed relative redirect
through frontend completion. Its serialized handshake is not the documented
machine-state schedule.

DSJS is the one-word short form. Its `3800h`/`F800h` pattern embeds direction
`D` in bit 10, a five-bit unsigned word magnitude in bits `[9:5]`, register
file in bit 4, and destination in bits `[3:0]`. After decrementing the selected
A/B/shared-SP register modulo `2^32`, a nonzero result redirects from the
sequential one-word `PC'` by adding the magnitude times 16 when `D=0` or
subtracting it when `D=1`; zero falls through. The offset field is not a
two's-complement value. The guide's range of −30 through +32 words is measured
from the DSJS instruction address because `PC'` is already one word ahead.
ST remains unchanged, and the no-jump/jump cases take two/three states.
Sources: TMS34020 User's Guide printed pp.13-12, 13-108, and 15-4; TMS34010
User's Guide printed pp.12-74..12-75. The independent model executes the
published rows plus direction/magnitude/file/wrap boundaries and reports the
two-/three-state cases. The bounded RTL implements the same decrement,
status-preservation, and conditional redirect ordering for A/B/shared-SP
destinations, but its serialized handshake does not implement the documented
two-/three-state schedule.

EXGF atomically exchanges the selected six-bit FS/FE status bank with the low
six bits of an A/B/shared-SP destination and clears the register's upper
26 bits. Its `D500h`/`FDE0h` pattern covers both field banks and both register
files. TI specifies one TMS34020 state for field bank zero and two for field
bank one; pinned MAME charges one for both, as recorded in RSC-0019. Source:
TMS34020 User's Guide printed p.13-111 and timing table p.15-4.

PUTST copies all 32 source-register bits into ST and takes three machine
states. Its `01A0h`/`FFE0h` range covers A/B and the shared-SP alias. The
adjacent `01C0h` POPST encoding is a separate exact record. The same encoding
and full-register copy appear in the TMS34010 guide, establishing
semantic compatibility without inferring broader status or pipeline
equivalence. Sources: TMS34020 User's Guide printed pp.4-2..4-3 and 13-216,
timing table p.15-7; TMS34010 User's Guide printed p.12-229 and its instruction
summary.

POPST reads the complete 32-bit value at the old SP into ST, then increments
SP by 32 bit addresses. It takes six states when SP is 32-bit aligned and
seven otherwise. PUSHST decrements SP by 32, writes the complete old ST at the
new address, and leaves ST unchanged. It takes two visible states with one
parenthesized write state when the original SP is aligned, or two
parenthesized write states otherwise. The corresponding TMS34010 pages confirm
semantic/object compatibility but document materially different timing.
Fault/retry and external transfer ordering remain unclassified rather than
inferred. Sources: TMS34020 User's Guide printed pp.13-214..13-215 and
pp.4-2..4-3; TMS34010 User's Guide printed pp.12-227..12-228.
The independent model implements only the successful atomic transaction
boundary; both forms remain blocked in RTL pending data-memory ownership.

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
