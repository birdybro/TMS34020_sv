# Field access

This document records the verified field-access boundary currently present in
the project. It is not yet a complete implementation of the TMS34020 ordinary
MOVE-field sequencer.

## Programmer-visible field controls

ST bits 4:0 are FS0 and encoded zero means 32; values 1–31 select those bit
widths. FE0 in ST bit 5 selects zero extension when clear and sign extension
when set. FS1/FE1 occupy ST bits 10:6 for the second field bank. Source:
TI *TMS34020 User's Guide*, August 1990, Figure 4-1 and Table 4-1, printed
pp.4-2..4-3.

## Verified SWAPF boundary

SWAPF `7E00h`/`FE00h` exchanges the FS0-bit field at the bit address in Rs
with the low FS0 bits captured from Rd. The old field is right-justified in Rd
and extended according to FE0. It replaces N/Z from that extended result,
preserves C, and clears V. Rs and Rd use one A or B file, including the shared
SP alias. The field is required to fit in one addressed 32-bit word. Source:
User's Guide SWAPF, printed pp.13-247..13-248.

The independent model implements a successful word-local 32-bit target as an
atomic instruction-boundary update and records `bus_locked_data_read` followed
by `bus_locked_data_write`. It rejects crossing fields with complete snapshot
rollback because the primary page makes that use invalid but does not define a
portable result. It records the five-state base count but marks timing
incomplete because physical memory cycles are absent. The combinational
`tms34020_swap_field` leaf separates old-field extraction/extension and
replacement-word construction from bus control.

This is not physical atomicity evidence. The RTL has no locked memory owner,
and the model does not yet inject waits, refresh, grant loss, retry, bus fault,
16-bit targets, I/O register routing, cache interaction, or host activity into
SWAPF.

## Verified ordinary register-to-memory boundary

`MOVE Rs,*Rd[,F]` occupies `8000h`/`FC00h`. F selects FS0 or FS1; the low
selected-width bits of Rs are written at the bit address captured from Rd.
Both operands use the same A/B file and register number 15 aliases SP. Neither
register nor any ST bit changes. Source: User's Guide printed p.13-159; the
same programmer-visible form appears in the 1988 TMS34010 guide at printed
pp.12-127..12-128.

For little-endian addressing, the model performs the logical 1–32-bit write
and records the field alignment case. The five cases distinguish whether the
field crosses a 32-bit word and whether its start/end are byte aligned. The
visible count is one state; hidden pipelined-write counts for cases 1 through
5 are 1, 2, 2, 3, and 4. The clean-room combinational
`tms34020_field_store` leaf independently constructs the affected two-word
window and those classifications. Model and RTL tests exhaust all 32 encoded
sizes and 32 within-word offsets; model tests repeat both field banks and
verify A/B/SP capture. Sources: User's Guide timing Tables 15-2 and register-
to-memory rows, printed pp.15-10..15-11.

This is an instruction-boundary semantic slice only. BEN=1 is classified in
the ISA metadata but deliberately rejected by the model; the primary timing
table adds one visible state in that mode. No RTL request owner turns the
two-word result into byte CAS strobes, read/modify/write cycles, dynamic
16-bit beats, page-mode operations, waits, I/O accesses, retry, or bus-fault
continuation.

## Verified ordinary memory-to-register boundary

`MOVE *Rs,Rd[,F]` occupies `8400h`/`FC00h`. F selects the corresponding
FS/FE bank. The field at the bit address captured from Rs is right-justified,
zero-extended for FE=0 or sign-extended for FE=1, and written to Rd. N and Z
reflect the extended result, C is preserved, and V is cleared. If Rs and Rd
alias, the captured pointer is overwritten by the fetched data. Sources:
User's Guide printed pp.13-160 and 13-163; the compatible TMS34010 form is at
printed pp.12-135..12-136.

The little-endian model and clean-room `tms34020_field_load` leaf exhaust all
32 sizes, 32 within-word offsets, both extension modes, and all five alignment
cases. FE=0 takes 3/3/4/4/4 visible states for cases 1..5; FE=1 adds one
state. Model tests additionally cover both banks/files, shared SP, alias
ordering, zero/negative/positive status, logical read traces, and atomic BEN
rollback. No request owner yet supplies dynamic-width beats, waits, page
mode, I/O routing, fault/retry suppression, interrupts, or pin timing.

## Verified postincrement register-to-memory boundary

`MOVE Rs,*Rd+[,F]` occupies `9000h`/`FC00h`. It captures the right-justified
source field and old Rd bit address, stores at that address, then writes
`Rd + field_size` back to Rd. The source and address capture precede the
pointer update, including when Rs=Rd or both names resolve to SP. ST is
unchanged. Sources: User's Guide printed pp.13-13 and 13-160; the compatible
TMS34010 form is printed pp.12-128..12-129.

The model exhausts both banks, all widths/offsets, A/B/SP aliases and 32-bit
pointer wrap while retaining MOVE.RM's one visible little-endian state and
1/2/2/3/4 hidden alignment-case writes. The clean-room
`tms34020_field_address_update` leaf independently exhausts ordinary,
postincrement and predecrement effective/final pointer calculations. There is
still no combined RTL operand-capture, store, pointer-commit or fault owner;
BEN mapping, CAS/RMW, SIZE16, page mode, waits, retry, faults, interrupts and
pin timing remain absent.

## Verified postincrement memory-to-register boundary

`MOVE *Rs+,Rd[,F]` occupies `9400h`/`FC00h`. It captures the old Rs bit
address, reads and FE-extends the selected field, advances Rs by the field
size, and writes the fetched result to Rd. N and Z reflect the extended data,
C is preserved, and V is cleared. Sources: User's Guide printed pp.13-13,
13-161, and 13-163; the compatible TMS34010 form is printed
pp.12-139..12-140.

The model exhausts both field banks and FE modes, all widths/offsets, A/B/SP,
pointer wrap, status and the five 3/3/4/4/4 plus-FE timing cases. If Rs=Rd,
the fetched data wins over the postincremented pointer in both pinned MAME and
the pinned TMS34010 RTL/test record, but TI's TMS34020 operation prose does
not state that priority explicitly. The project therefore records that corner
as `CORROBORATED` under RSC-0036/OQ-0024 rather than primary-verified. The
clean-room field-load and address-update leaves independently cover extraction,
extension, timing and pointer arithmetic; there is no combined RTL memory,
dual-register-write, fault/retry or interrupt owner. BEN mapping, SIZE16,
page mode, waits, I/O and pin timing remain absent.

## Verified ordinary memory-to-memory boundary

`MOVE *Rs,*Rd[,F]` occupies `8800h`/`FC00h`, captures both same-file bit
addresses, copies the selected FS0/FS1 field, and changes neither pointer nor
ST. The source field is fully captured before the destination write, including
when fields overlap. Source cases 1/2 take three visible states and 3–5 take
four; destination cases 1..5 contribute 1/2/2/3/4 hidden write states through
the A–H matrix. Sources: User's Guide printed pp.13-160 and 15-10..15-12; the
compatible TMS34010 form is printed pp.12-137..12-138.

The model exhausts both banks, all widths, and all 1,024 source/destination
offset pairs, while the independent `tms34020_field_move` leaf exhausts every
size/offset geometry and case pair. This evidence is little-endian and
logical: BEN, byte strobes/RMW, dynamic SIZE16, page turnaround, waits, I/O,
fault/retry idempotence, interrupts, and physical commit remain absent.

## Verified paired-postincrement memory-to-memory boundary

`MOVE *Rs+,*Rd+[,F]` occupies `9800h`/`FC00h`. With distinct registers it
copies from old Rs to old Rd, then advances each pointer once by the selected
field size. TI explicitly defines Rs=Rd differently from an ordinary same-
address copy: data is read at the original pointer and written at the once-
incremented pointer. TI does not explicitly state the final shared pointer;
the selected CORROBORATED behavior applies both named increments and leaves
original plus twice the field size, matching TI's operation sequence and
pinned MAME while conflicting with the pinned TMS34010 RTL. RSC-0037/OQ-0025
retain the conflict. ST is unchanged. Sources: User's Guide printed pp.13-161
and 13-165..13-166; the compatible TMS34010 form is printed pp.12-140..12-141;
pinned MAME commit `a562e947b22f4f5acff0c182c26fd649d72dad0e`,
`34010ops.hxx` lines 1311–1324.

The model exhausts both banks, all widths and all 1,024 source/destination
offset pairs, exact A–H timing, pointer updates, alias/wrap/overlap ordering and
BEN rollback. The clean-room `tms34020_field_pair_postincrement` leaf
independently exhausts distinct and alias effective/final address arithmetic;
the existing field-copy leaf independently exhausts copy geometry. There is no
combined memory/pointer owner, so byte strobes/RMW, SIZE16, page mode, waits,
fault/retry idempotence, interrupt checkpoints, I/O and pin timing remain.

## Verified predecrement field boundaries

`MOVE Rs,-*Rd[,F]` (`A000h`/`FC00h`) decrements Rd by the selected field size
before observing the register source and writing. When Rs=Rd, the stored field
therefore comes from the decremented pointer. ST is unchanged. Little-endian
execution exposes two visible states plus 1/2/2/3/4 destination-case hidden
writes. `MOVE -*Rs,Rd[,F]` (`A400h`/`FC00h`) decrements Rs before reading and
uses 4/4/5/5/5 visible states plus one for sign extension; loaded data
explicitly wins an Rs=Rd collision and updates N/Z/V while preserving C.

`MOVE -*Rs,-*Rd[,F]` (`A800h`/`FC00h`) performs source predecrement and capture
before destination predecrement and write. Distinct pointers each subtract one
field size. If Rs=Rd, the source read uses original minus one field size, the
destination write uses original minus two, and the shared final pointer is the
twice-decremented value explicitly specified by TI. Its source cases expose
4/4/5/5/5 visible states and its destination cases contribute 1/2/2/3/4 hidden
writes.

Model tests exhaust both field banks, all widths/offsets, every paired alignment
case, A/B/SP alias and overlap ordering, pointer wrap, status, traces and BEN
rollback. The single-pointer address leaf and new paired-predecrement leaf
independently exhaust address arithmetic. No combined memory owner exists, so
BEN mapping, byte strobes/RMW, SIZE16, page mode, waits, fault/retry,
interrupts, I/O and pin timing remain. Sources: User's Guide printed pp.13-8,
13-160..13-163 and 15-10..15-12.

## Verified signed-offset field boundaries

`MOVE Rs,*Rd(offset)[,F]` (`B000h`/`FC00h`) adds a signed 16-bit bit
displacement to Rd modulo 2^32, writes the selected low source field at that
effective address, and changes neither register nor ST. It consumes two words,
exposes three visible states, and contributes 1/2/2/3/4 hidden write states by
destination case. `MOVE *Rs(offset),Rd[,F]` (`B400h`/`FC00h`) similarly leaves
Rs unchanged, reads at the signed-offset effective address, applies FE, writes
Rd, replaces N/Z/V and preserves C. Its zero-extended cases expose
4/4/5/5/5 states; sign extension adds two states.

`MOVE *Rs(SOffset),*Rd(DOffset)[,F]` (`B800h`/`FC00h`) consumes the source
offset before the destination offset. It captures the selected field at
`Rs + sign_extend(SOffset)` before writing at
`Rd + sign_extend(DOffset)`, with modulo-2^32 arithmetic, and changes neither
base nor ST. This remains true when Rs=Rd: the two offsets select independent
effective addresses from the same unchanged base. Source cases expose
5/5/6/6/6 visible states and destination cases add 1/2/2/3/4 hidden writes.

Model tests exhaust both field banks, widths and alignment geometry, FE/status,
source-before-destination overlap, A/B/SP aliases, signed extremes, address
wrap and BEN rollback. The clean-room offset-address leaf independently
exhausts all 65,536 signed extension values and wraparound. No combined memory
owner exists, so BEN mapping, byte strobes/RMW, SIZE16, page mode, waits,
fault/retry, interrupts, I/O and pin timing remain absent. Sources: User's
Guide printed pp.13-14, 13-160..13-163 and 15-10..15-12; compatible forms:
TMS34010 User's Guide printed pp.12-132..12-133, 12-147..12-148 and
12-151..12-152.

`MOVE *Rs(offset),*Rd+[,F]` (`D000h`/`FC00h`) consumes one signed source
offset, reads at original `Rs + sign_extend(offset)`, writes at original Rd,
and increments Rd after the move. Source cases expose 5/5/6/6/6 visible states
and destination cases add 1/2/2/3/4 hidden writes. When Rs=Rd, both addresses
derive from the original shared value and the final shared pointer is original
plus the selected field size. Model tests exhaust both banks, every width and
source/destination alignment pair, signed extremes, alias, overlap, wrap,
unchanged ST and BEN rollback. The clean-room mixed-address leaf independently
covers every signed displacement and field-size encoding. Physical retirement
and bus behavior remain outside these leaves. Sources: User's Guide printed
pp.13-14, 13-162, 13-166 and 15-12; compatible form: TMS34010 User's Guide
printed pp.12-149..12-150.

## Verified absolute-address field boundaries

`MOVE Rs,@DAddress[,F]` (`0580h`/`FDE0h`) and
`MOVE @SAddress,Rd[,F]` (`05A0h`/`FDE0h`) consume the absolute address low
word before its high word. The store preserves ST; the load applies FE,
replaces N/Z/V, and preserves C. An aligned first extension gives the store
two visible states and the load 4/4/5/5/5 by source case; an unaligned first
extension adds one visible state. FE adds one more load state. Store hidden
writes remain 1/2/2/3/4 by destination case.

`MOVE @SAddress,*Rd+[,F]` (`D400h`/`FDE0h`) reads at the assembled source,
writes at the original Rd address, and increments Rd only after the move. Its
aligned first-extension source timing is 4/4/5/5/5; unaligned adds one, and
destination hidden writes remain 1/2/2/3/4. The five-word
`MOVE @SAddress,@DAddress[,F]` (`05C0h`/`FDFFh`) consumes source low/high then
destination low/high, captures the source before writing, and preserves ST.
Its aligned visible timing is 5/5/6/6/6, while unaligned is 7/7/8/8/8; hidden
writes again follow the destination case.

Model tests exhaust both banks, FE, widths, all 25 source/destination timing
pairs, A/B/SP, word order, absolute boundaries, postincrement wrap, overlap,
status and BEN rollback. The clean-room absolute-address leaf exhausts every
16-bit low and high half. It does not fetch extensions or issue requests.
Physical BEN mapping, byte strobes/RMW, SIZE16, page mode, waits, fault/retry,
interrupt and I/O behavior remain absent. Sources: User's Guide printed
pp.13-14..13-15, 13-159..13-166 and 15-11..15-12; compatible forms:
TMS34010 User's Guide printed pp.12-133..12-134 and 12-152..12-158.

## Locked-cycle requirements

The write immediately follows the read and instruction completion waits for
the write. A retry on the write restarts from the read, unlike an ordinary
unlocked read/modify/write. The instruction page also requires restart from
the read after a bus fault or an intervening refresh/grant loss. A locked
operation does not sample SIZE16 and emits only S=0, so a semaphore placed in
the inaccessible half of a 16-bit target cannot be exchanged. Sources: User's
Guide printed pp.8-13, 8-26, and 13-247.

## Remaining field work

BEN mapping,
dynamic 16-bit sizing, byte strobes, partial-word atomicity, page-mode composition,
fault/retry checkpoints, I/O routing, host access, and pin traces remain
unimplemented. No complete memory-subsystem claim follows from SWAPF.
