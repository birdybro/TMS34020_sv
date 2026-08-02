# Coprocessor interface

## Current scope

The TMS34020 has a processor-owned local-memory coprocessor protocol. An
external coprocessor implements the commands and associated computation; it is
not part of the generic CPU core. The current repository implements the two
CEXEC encodings and both CMOVGC register-to-coprocessor forms, their bounded
architectural transactions, and noncommitting synthesizable formatters. It
does not yet implement the pin cycle, completion handshake, fault checkpoint,
the other CMOV families, or a synthetic external coprocessor.

Source: TI *TMS34020 User's Guide*, 2564006-9721, August 1990, Chapter 10
overview and Table 10-1, printed pp.10-2..10-4. Confidence:
`VERIFIED_PRIMARY` for the documented protocol and `PROVISIONAL` for the
bounded implementation.

## Command value on LAD

During a coprocessor address/status subcycle, the 32-bit LAD value is:

| LAD bits | Meaning | CEXEC value |
|---:|---|---|
| 31:29 | coprocessor ID | instruction operand |
| 28:8 | 21-bit coprocessor command | instruction operand |
| 7 | parameter size | instruction operand |
| 6 | parameter index `I` | 0 because CEXEC transfers no data |
| 5 | reserved | 0 |
| 4 | 16-bit word select `S` | 0 |
| 3:0 | coprocessor status `BCST` | `0000b` |

Thus the implemented formatter constructs
`{id[2:0], command[20:0], size, 7'b0}`. `size=0` designates 32-bit values and
`size=1` designates 64-bit values for interpretation by the coprocessor; CEXEC
itself transfers no value. The reserved bit is documented as zero, `I=0` when
no data follows, `S=0` for all coprocessor cycles, and `BCST=0000b` for all
local-memory coprocessor cycles.

Sources: User's Guide Figure 10-1 and §§10.3.1..10.3.6, printed
pp.10-5..10-7; CEXEC long and short, printed pp.13-51..13-54. Confidence:
`VERIFIED_PRIMARY`.

## CEXEC encodings

| Internal database name | First word | Extensions | Legal command range | Length | Machine states |
|---|---:|---|---|---:|---|
| `CEXEC.L` | exact `0600h` | first extension carries command `[7:0]` in `[15:8]` and size in bit 7; bits `[6:0]` are zero. Second extension carries ID in `[15:13]` and command `[20:8]` in `[12:0]` | all 21 command bits | 3 words | `2 (1)` when the first extension is long-word aligned; `3 (1)` otherwise |
| `CEXEC.S` | `D800h`/`FF80h`; command `[5:0]` in first-word `[6:1]`, size in bit 0 | extension carries ID in `[15:13]` and command `[20:8]` in `[12:0]` | command `[7:6]` forced zero; remaining 19 bits selectable | 2 words | `2 (1)` |

Both forms preserve all registers and the complete ST value, including N, C,
Z, and V. The parenthesized state is retained separately as hidden command
latency; it is not a claim about a particular FPGA request/acknowledge edge.
The project-local long-form decoder accepts only the documented extension
layout and treats nonzero first-extension bits `[6:0]` as a reserved packet,
with atomic model rollback and no RTL commit path.

Sources: User's Guide CEXEC long, printed pp.13-51..13-52; CEXEC short,
printed pp.13-53..13-54; Chapter 15 timing table, printed p.15-3. Confidence:
`VERIFIED_PRIMARY` for legal encoding, command formation, status, and published
state counts.

## CMOVGC register transfers

CMOVGC moves captured TMS34020 register values to an external coprocessor. The
guide defines two distinct first-word families:

| Internal database name | First word | First extension | Data order | Machine states |
|---|---:|---|---|---|
| `CMOVGC.1` | `0620h`/`FFE0h`; Rs file/index in `[4:0]` | command `[7:0]` in `[15:8]`; low byte zero | one 32-bit Rs value | `2 (1)` aligned or `3 (1)` unaligned |
| `CMOVGC.2` | `0640h`/`FFE0h`; Rs1 file/index in `[4:0]` | command `[7:0]`, size in bit 7, zero bits `[6:5]`, and Rs2 file/index in `[4:0]` | Rs1 then Rs2, each 32 bits | `3 (1)` aligned or `4 (1)` unaligned |

Both use a second extension with ID in `[15:13]` and command `[20:8]` in
`[12:0]`. The one-register form sends `size=0`. In the two-register form,
`size=0` means two separate 32-bit parameters and `size=1` means two halves of
one 64-bit parameter; the physical bus still carries two ordered 32-bit data
words. Registers and every ST bit are unaffected. Register number 15 resolves
through the shared SP alias in either file.

The initial command has `I=0`. Ordinarily the second word follows through page
mode. If the coprocessor rejects page mode or a high-priority local-memory
request intervenes, the processor must issue a new address/status subcycle
with the same ID, command, size, S, and BCST, but `I=1`, before transferring
Rs2. The clean-room RTL leaf exposes both initial and I=1 LAD command values;
it does not decide whether page mode continues. The model records one logical
command followed by one or two ordered outbound data transactions, and notes
that the physical page decision is pending.

Sources: User's Guide CMOVGC one-register form, printed pp.13-67..13-68;
CMOVGC two-register form, printed pp.13-69..13-70; §§10.3.3..10.3.5 and
§10.4.6, printed pp.10-6..10-7 and 10-11..10-12; Chapter 15 timing table,
printed p.15-3. Confidence: `VERIFIED_PRIMARY` for encoding, logical order,
command/data values and published state counts; `PROVISIONAL` for the bounded
implementation without a physical sequencer.

## Command-cycle signaling

CEXEC causes a coprocessor command cycle. The command replaces the ordinary
memory address during the address/status subcycle. A coprocessor distinguishes
it through `SF=1` and `BCST=0000b` and latches it on the high-to-low transition
of ALTCH. The command cycle transfers no other data. Figure 10-2 additionally
identifies DDIN low and RAS, TR/QE, and SF high while ALTCH is low. Page mode is
not required for the command cycle, although PGMD must be driven to a valid
level when sampled.

Coprocessor cycles are restricted to 32-bit operation: the processor drives
`S=0`, ignores SIZE16, and does not support a coprocessor access to a dynamic
16-bit target. This restriction describes the physical cycle width; it does
not change the CEXEC `size` bit, which tells the external coprocessor how to
interpret its own operands.

Sources: User's Guide §§10.4.1 and 10.4.5 and Figure 10-2, printed
pp.10-8 and 10-10; §§10.3.5..10.3.6, printed p.10-7; §10.4.2 note, printed
p.10-8. Confidence: `VERIFIED_PRIMARY`.

## Completion, retry, and fault boundary

LRDY and BUSFLT terminate local-memory coprocessor cycles under the same
completion rules used for other local-memory cycles. The guide permits wait
states, retry, and bus fault. Data present during a retried or faulted transfer
is invalid; after the bus-fault handler, the cycle is performed again as for a
retry. These rules require the future physical bus owner to hold a command
request stable until one completion outcome, suppress stale completion, and
reissue without duplicating processor-visible retirement.

The current model records logical `coprocessor_command` and, for CMOVGC,
`coprocessor_data_out` transactions only after legal packet decode. It does not
claim that an external device accepted them and cannot inject LRDY, BUSFLT,
retry, or an asynchronous interrupt. The current RTL modules
`rtl/coprocessor/tms34020_coprocessor_command.sv` and
`rtl/coprocessor/tms34020_coprocessor_register_write.sv` are purely
combinational and own no pins or request state. Consequently the point at which
an external coprocessor may acquire an irreversible side effect relative to
BUSFLT remains an implementation checkpoint to verify with command/data-cycle
waveforms and a synthetic coprocessor.

Sources: User's Guide §10.4.4, printed pp.10-9..10-10, with the general cycle
completion rules in §8.6, printed pp.8-12..8-14. Confidence:
`VERIFIED_PRIMARY` for the required behavior and `UNKNOWN` for unmeasured
silicon edge ordering beyond the published diagrams.

## Remaining implementation work

`TMS20-0021` remains incomplete. Its next required increments are:

- a native command/data request and success/retry/fault response contract;
- exact command-cycle phase generation in the original-pin bus wrapper;
- CEXEC wait, retry, bus-fault, interrupt, and restart tests;
- all CMOVCG, CMOVCM, CMOVCS, and CMOVMC encodings and transfers;
- direct and indirect one-word, two-word, and sequence interruption behavior;
- a deterministic synthetic external coprocessor and randomized asynchronous
  completion tests; and
- safety assertions for stable stalled payloads, unique completion, retry
  idempotence, and no drive without local-bus ownership.

No complete coprocessor-interface, instruction-completeness, bus-timing, or
cycle-accuracy claim follows from the current CEXEC slice.
