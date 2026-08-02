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

## Locked-cycle requirements

The write immediately follows the read and instruction completion waits for
the write. A retry on the write restarts from the read, unlike an ordinary
unlocked read/modify/write. The instruction page also requires restart from
the read after a bus fault or an intervening refresh/grant loss. A locked
operation does not sample SIZE16 and emits only S=0, so a semaphore placed in
the inaccessible half of a 16-bit target cannot be exchanged. Sources: User's
Guide printed pp.8-13, 8-26, and 13-247.

## Remaining field work

Remaining ordinary MOVE predecrement, paired-update, offset and absolute forms,
BEN mapping,
dynamic 16-bit sizing, byte strobes, partial-word atomicity, page-mode composition,
fault/retry checkpoints, I/O routing, host access, and pin traces remain
unimplemented. No complete memory-subsystem claim follows from SWAPF.
