# Status register

## Programmer-visible layout

ST is a 32-bit special-purpose register. TI specifies reset value
`00000010h`.

| Bits | Name | Meaning |
|---:|---|---|
| 4–0 | FS0 | field 0 size; encoded 0 means 32, 1–31 mean 1–31 |
| 5 | FE0 | field 0 zero/sign extension |
| 10–6 | FS1 | field 1 size; encoded 0 means 32, 1–31 mean 1–31 |
| 11 | FE1 | field 1 zero/sign extension |
| 20–12 | reserved | not used; reset to zero |
| 21 | IE | global maskable-interrupt enable |
| 22 | SS | single-step enable |
| 24–23 | reserved | not used; reset to zero |
| 25 | IX | interrupt occurred within an interruptible instruction |
| 26 | BF | local-memory bus fault occurred |
| 27 | reserved | not used; reset to zero |
| 28 | V | overflow |
| 29 | Z | zero |
| 30 | C | carry or borrow, as defined by the instruction |
| 31 | N | negative |

Source: TI *TMS34020 User's Guide*, August 1990, §4.1, Figure 4-1 and
Table 4-1, printed pp.4-2..4-3.

TI says software should write zero to reserved bits for compatibility. PUTST's
primary instruction page says the complete source register is copied into ST
and depicts the reserved positions as part of that 32-bit destination, but this
does not establish arbitrary reserved-bit readback on every silicon revision.
The new PUTST decode record therefore specifies the documented full-width copy
while silicon-revision readback remains an explicit qualification question.

## Implemented state owner

`rtl/core/tms34020_status.sv` owns a 32-bit state value and supports synchronous
masked writes:

```text
new ST = (old ST AND NOT mask) OR (write data AND mask)
```

Reset has priority and loads `00000010h`. This interface supports exact partial
updates such as:

- ABS writing N/Z/V while preserving C;
- NOT writing only Z;
- arithmetic instructions writing all N/C/Z/V;
- SETF writing only FS0/FE0 or FS1/FE1;
- EXGF atomically exchanging one FS/FE bank with a register's low six bits;
- SEXT writing N/Z and ZEXT writing only Z;
- SETC and CLRC changing only C;
- EINT and DINT changing only IE.

The synchronous `reset_i` is an FPGA architectural-state event, not a claim
about the electrical RESET pin timing. Original-pin assertion/release timing
remains `TMS20-0029`/`TMS20-0030`.

## Verification

`make rtl-leaf-tests` verifies:

- reset value, reset priority, and hold without write enable;
- all defined control/fault/flag bit positions;
- the complete reserved-bit mask;
- full N/C/Z/V replacement;
- N/Z/V replacement preserving C;
- Z-only replacement preserving N/C/V;
- isolated IE set and C clear;
- isolated SETF updates of both six-bit field banks, followed by SEXT/ZEXT
  consumers with preservation of unowned status fields; and
- PUTST full-width replacement from ordinary and shared-SP sources, including
  exact data and `FFFFFFFFh` ownership masks.

The module is also included in warning-free Cyclone V leaf Analysis &
Synthesis.

The independent software model additionally verifies the successful TRAPL
boundary: the complete old ST is stored at the final predecremented SP before
ST becomes `00000010h`. This does not add an RTL interrupt owner or establish
faulted-stack behavior. Source: User's Guide TRAPL, printed pp.13-256..13-258.

The model and bounded RTL also verify EXGF's atomic selected-bank exchange,
upper-register clearing, nonselected-ST preservation, both register files, and
shared SP. The RTL exposes simultaneous register and selected-bank masked write
intents; its FPGA commit edge is not evidence for EXGF's documented one- or
two-machine-state timing.

The independent model and bounded RTL verify PUTST as a complete 32-bit
source-to-ST copy from both files and shared SP. Mixed reserved-bit patterns
are tested at the architectural-model and RTL write-intent boundaries; this is
not silicon readback evidence. The model reports the documented three-state
count, while the serialized RTL commit edge is not architectural timing.

The independent model also verifies successful POPST and PUSHST transaction
boundaries. POPST replaces the complete ST value read at old SP before advancing
SP. PUSHST preserves ST while predecrementing SP and writing the complete value.
The model covers both alignment classes and the documented visible/hidden state
counts. It does not model stack faults, retries, waits, dynamic bus sizing, page
mode, or partial external writes.

RETS is also covered at the independent-model boundary. All 32 encodings
preserve the complete ST value while reading the return PC and advancing SP;
both TMS34020 5/6-state stack-alignment cases are tested. RETS remains blocked
in RTL pending stack-read and direct-PC ownership. Source: User's Guide RETS,
printed p.13-220.

Normal-context RETI restores the entire saved ST word before completion; this
includes IE and every reserved position represented in the model. A pending
enabled interrupt may be recognized after the last RETI state because restored
IE is then effective. Saved IX or BF instead requires restoration of 24 or 31
hidden internal-state words and clearing the corresponding continuation bit.
The model therefore executes only IX=BF=0 and rolls an IX/BF attempt back
atomically. The RTL return-control leaf classifies all three contexts and
computes the post-continuation IX/BF clear value, but owns neither ST nor stack
memory. Sources: User's Guide printed pp.3-29..3-30, Figure 6-3 p.6-10, RETI
pp.13-217..13-218; OQ-0023/RSC-0034.

RETM restores the same complete ST value, including IE and SS. It does not
clear those programmer-visible bits to create its delay; instead, hardware
masks recognition during the final return state so that one instruction
executes first. The model preserves the stacked bits and arms the documented
fetch bypass, but has no pending-interrupt/single-step scheduler. The RTL leaf
exports the delay intent without owning ST or arbitration. Sources: User's
Guide Figure 6-3 p.6-10, RETM p.13-219, and comparison p.6-32.

The independent model verifies complete ST preservation across CALL, CALLA,
and CALLR while SP and PC change and the return-PC write occurs. This includes
CALL's shared-SP read-before-write hazard and both stack alignment classes.
All three forms remain blocked in RTL pending stack-write/direct-PC ownership.
Sources: User's Guide CALL/CALLA/CALLR, printed pp.13-48..13-50.

The three extracted register-to-memory MOVB forms preserve the complete ST
value while writing the captured low source byte through indirect,
signed-offset, or absolute addressing. Model tests use mixed full-width ST
patterns rather than checking only NCZV. The byte-store RTL leaf has no status
or architectural commit port. Sources: User's Guide MOVB, printed
pp.13-154..13-157.

The three corresponding memory-to-register MOVB forms always sign-extend the
loaded byte, replace N and Z from that result, clear V, and preserve C plus all
lower ST fields. This rule is independent of both FS/FE banks. The model tests
all 256 byte values and mixed prior NCZV states; the byte-load RTL leaf exports
N/Z/V results but cannot preserve C or commit ST without the future memory
owner. Sources: User's Guide MOVB status, printed p.13-156.

The three memory-to-memory MOVB forms preserve the complete ST value. Their
fixed-byte source is captured before the destination write, including overlap,
but no compare or sign extension is performed. Model tests preserve mixed
full-width ST patterns across indirect, paired signed-offset, and absolute
forms; the byte-copy RTL leaf has no status or architectural commit port.
Source: User's Guide MOVB status applicability note, printed p.13-156.

Both CEXEC encodings preserve the complete ST value. The independent model
checks mixed full-width patterns across every command bit, coprocessor ID,
size, and both long-form alignments; the combinational RTL formatter has no ST
or architectural commit port. Sources: User's Guide CEXEC long and short,
printed pp.13-51 and 13-53.

CMOVCG replaces N/Z from the last inbound 32-bit word, preserves C, and clears
V. Its exact CMOVCS packet refinement instead replaces all four N/C/Z/V bits
from inbound bits 31:28, preserves ST bits 27:0, and writes no general
register. The model exhausts last-word and top-nibble discriminators; the
combinational read formatter emits an NCZV mask/value intent but has no ST
commit owner. Sources: User's Guide CMOVCG printed pp.13-59..13-60 and CMOVCS
printed p.13-66.

All five CMOVCM/CMOVMC memory-sequence forms preserve the complete ST value.
The model tests mixed status patterns while transferring 1..32 logical words;
the combinational memory-sequence formatter has no status or architectural
commit port. Sources: User's Guide CMOVCM printed pp.13-61..13-65 and CMOVMC
printed pp.13-71..13-79.

CPW preserves the complete status register except V, which reports whether
any of its four signed-XY window outcode bits are set. The independent model
tests both V outcomes while preserving arbitrary N/C/Z and lower status bits;
the standalone RTL comparison leaf emits the V condition but does not own ST
commit. Sources: User's Guide CPW, printed pp.13-85..13-86.

CVDXYL, CVMXYL, CVSXYL, and CVXYL preserve every ST bit for every pitch class.
The independent model checks full-width preservation rather than only NCZV;
the standalone conversion RTL has no status output. Sources: User's Guide
printed pp.13-87..13-93.

DIVS replaces N/Z/V and preserves C and every lower status field. DIVU
replaces only Z/V and preserves N/C and all lower fields. A successful zero
quotient sets Z; divisor zero or an unrepresentable quotient clears Z and sets
V while preserving the destination. DIVS additionally sets N for a negative
quotient or `80000000h` result except on the raw early-overflow path. The model
and standalone divider leaf cover these masks and results; architectural pair
commit remains absent. Sources: User's Guide DIVS/DIVU printed
pp.13-96..13-99.

MODS replaces N/Z/V from the stored signed remainder and preserves C; MODU
replaces Z/V and preserves N/C. With a zero divisor, MODS forces N=Z=0 and
MODU forces Z=0, while both set V and produce an Rd value equal to the old
dividend. The primary MODU word "quotient" is contradicted by its `8 mod 4`
zero-remainder/Z-set row, so RSC-0028 records the remainder-derived decision.
The model and shared divider leaf cover these status results; scalar commit is
absent. Sources: User's Guide MODS/MODU printed pp.13-152..13-153.

MPYS replaces N/Z from the full signed product and preserves C/V; MPYU
replaces only Z from the full unsigned product and preserves N/C/V. For odd
Rd this intentionally includes discarded high bits: a nonzero `00000001h:
00000000h` product clears Z although the stored word is zero, and signed N can
differ from stored bit 31. The model and standalone multiplier leaf cover
these discriminators. RSC-0032 keeps the older TMS34010 compatibility question
separate; the TMS34020 rule is explicit. Sources: User's Guide MPYS/MPYU
printed pp.13-172..13-176.

SWAPF uses FS0/FE0, replaces N/Z from the extended old memory field, preserves
C, and clears V. The field/replacement leaf produces N/Z/V; the model commits
the complete instruction-boundary mask after its abstract locked write. No RTL
memory/commit owner exists. Source: User's Guide SWAPF, printed p.13-247.

Ordinary `MOVE Rs,*Rd[,F]` reads FS0/FS1 and leaves all ST bits unchanged.
The postincrement `MOVE Rs,*Rd+[,F]` form has the same complete ST
preservation while updating Rd by the selected width.
`MOVE *Rs,Rd[,F]` reads the selected FS/FE bank, sets N/Z from the extended
field, preserves C, clears V, and preserves all lower fields. The model covers
both banks and the field-load leaf independently produces N/Z/V, but no RTL
memory/status commit owner exists. Sources: User's Guide printed pp.13-159,
13-160, and 13-163.

The postincrement `MOVE *Rs+,Rd[,F]` form has the same N/Z/V replacement and
C preservation; its source-pointer update does not affect ST. The model covers
both banks and extension modes. Source: User's Guide printed pp.13-161 and
13-163.

`MOVE *Rs,*Rd[,F]` reads the selected FS bank but preserves the complete ST;
FE is not applied to a memory-to-memory field copy. The exhaustive model
checks full-width preservation. Source: User's Guide printed pp.13-160 and
13-163.

The paired-postincrement `MOVE *Rs+,*Rd+[,F]` form likewise reads only the
selected FS bank and preserves complete ST while updating its pointer operand
or operands. The selected Rs=Rd final-pointer behavior remains CORROBORATED
under RSC-0037/OQ-0025 but does not alter this status contract. Source: User's
Guide printed pp.13-161 and 13-163.

The register-to-memory and paired-memory predecrement forms read only the
selected FS bank and preserve complete ST. `MOVE -*Rs,Rd[,F]` additionally
reads the selected FE bit, replaces N/Z/V from the extended field, and
preserves C; fetched data explicitly wins when Rs=Rd. Source: User's Guide
printed pp.13-160..13-163.

The signed-offset register-to-memory and memory-to-memory forms likewise read
only the selected FS bank and preserve ST. `MOVE *Rs(offset),Rd[,F]` reads the
selected FE bit, replaces N/Z/V from the extended result, and preserves C;
neither offset form modifies an address-base register. Source: User's Guide
printed pp.13-160..13-163.

The mixed `MOVE *Rs(offset),*Rd+[,F]` form reads only the selected FS bank,
preserves complete ST, leaves the source base unchanged when distinct, and
increments the destination pointer after the field write. Source: User's Guide
printed pp.13-162..13-163.

The absolute register-to-memory, absolute-to-absolute, and absolute-source/
postincrement-destination forms read only the selected FS bank and preserve
complete ST. `MOVE @SAddress,Rd[,F]` also reads the selected FE bit, replaces
N/Z/V from the extended result, and preserves C. Address extension words and
the destination postincrement do not modify ST. Source: User's Guide printed
pp.13-159..13-163.

MMTM replaces only N and preserves C/Z/V plus every lower ST bit. The guide's
two exceptions to the sign of `0-Rp` make the exact implemented rule
`N = ~old_Rp[31]`: Rp zero sets N while Rp `80000000h` clears it. MMFM leaves
the complete status register unchanged. The model and multiple-register
control leaf cover these boundaries, but no RTL status-commit/memory owner
exists. Source: User's Guide MMTM/MMFM, printed pp.13-148..13-151.

## Incomplete behavior

The following are not yet implemented:

- PUTST's three-state RTL retirement is not implemented; PUSHST and POPST
  remain atomic non-execution boundaries in RTL, and their successful model
  transactions do not implement fault/retry or external-bus scheduling; EXGF
  architectural retirement timing also remains;
- retirement/timing and interrupt-recognition ordering for the model and
  write-intent paths for GETST, SETC, CLRC, EINT, and DINT;
- interrupt/fault ownership of IX and BF, including RETI's 24/31-word
  continuation restore and final interrupt checkpoint;
- general interrupt/fault status save/restore ordering beyond the successful
  TRAPL model boundary;
- single-step recognition;
- pipeline hazards and same-state priority among multiple architectural
  writers;
- documented or measured reserved-bit behavior.

The generic masked-write port is not evidence that those operations are
complete.
