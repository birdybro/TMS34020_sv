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

## Locked-cycle requirements

The write immediately follows the read and instruction completion waits for
the write. A retry on the write restarts from the read, unlike an ordinary
unlocked read/modify/write. The instruction page also requires restart from
the read after a bus fault or an intervening refresh/grant loss. A locked
operation does not sample SIZE16 and emits only S=0, so a semaphore placed in
the inaccessible half of a 16-bit target cannot be exchanged. Sources: User's
Guide printed pp.8-13, 8-26, and 13-247.

## Remaining field work

Remaining ordinary MOVE addressing forms and memory reads, BEN mapping,
dynamic 16-bit sizing, byte strobes, partial-word atomicity, page-mode composition,
fault/retry checkpoints, I/O routing, host access, and pin traces remain
unimplemented. No complete memory-subsystem claim follows from SWAPF.
