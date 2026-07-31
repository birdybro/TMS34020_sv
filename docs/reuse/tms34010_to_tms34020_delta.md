# TMS34010 to TMS34020 architectural delta

Status: required-topic coverage is complete in the 64-entry generated ledger;
instruction-by-instruction and cycle-by-cycle quantification is still in
progress under `TMS20-0005` and `TMS20-0006`.

Primary comparison source: *TMS34020 User's Guide*, document
2564006-9721, August 1990, §1.6, pages 1-16 through 1-18. Cache details below
use Chapter 5, pages 5-2 through 5-8. Electrical/revision details use
SPVS004D, March 1990 revised November 1993, pages 2 and 21-23.

The machine-readable authority for this comparison is
[`docs/generated/tms34010_tms34020_delta.yaml`](../generated/tms34010_tms34020_delta.yaml).
It uses the JSON subset of YAML 1.2 and gives every entry a TMS34010 behavior,
TMS34020 behavior, RTL impact, test impact, precise citation, confidence, and
unresolved-question list. Mechanical tests prevent a required topic from being
silently dropped.

## High-impact delta

| Feature | TMS34010 baseline | Documented TMS34020 behavior | RTL consequence |
|---|---|---|---|
| Pin compatibility | 16-bit local bus and HOLD interface | Explicitly not pin-compatible; 32-bit bus and multiprocessor/coprocessor interfaces | Dedicated pin wrapper and bus controller |
| External bus | 16 bits | 32 bits with dynamic 16-bit target sizing | New native transactions, beat splitting, four byte enables |
| Cycle time | 130/160/200 ns family values in comparison table | 100/125 ns products | Reconstruct TMS34020 phases and timing |
| Instruction cache | Upstream RTL deliberately omits its optional TMS34010 cache; comparison table says 256 bytes | Mandatory architectural 512-byte cache: four 64-instruction-word segments; eight four-long-word subsegments each; 22-bit SSA per segment; 32 P flags; four-entry LRU ordering | New cache, refill, replacement, flush/disable and pipeline integration |
| Cache refill | Not modeled in upstream RTL | Four long words per missed subsegment; requested opcode/immediate long word is fetched last; segment/subsegment miss handling differs | Exact ordered refill traces and fault/retry handling |
| Self-modifying/host code | No 34020 cache | Data writes do not update cached copies; software must flush with HSTCTLH.CF; CONTROL.CD preserves cache state while bypassed | Explicit noncoherence and controls |
| Parallelism | Upstream functional multicycle implementation disclaims silicon cycle parity | Cache lookup/fetch, execution unit and memory interface can operate in parallel | Dedicated pipeline/sequencer; no wrapper-only design |
| Endianness | Little endian | Reset-configurable little or big endian | CONFIG and all memory/host/cache data paths |
| Pixel pitch | Power-of-two conversion registers | Unlimited pitch using SPTCH/DPTCH relationships and added conversion support | Graphics/address-generation redesign |
| Pixel/color width | Upstream TMS34010 graphics commonly uses 16-bit color state | COLOR0/COLOR1 and PMASK are full 32-bit; PMASKL/H both valid | Full 32-bit pixel/mask datapath |
| VRAM | Serial registers | Serial registers, block writes, split serial registers, enhanced page mode, 1M VRAM special functions | New request classes and display/memory cycles |
| I/O map | 32 × 16-bit locations | 64 × 16-bit locations with moved/new registers | Reimplemented I/O map and reset/side effects |
| Host | TMS34010 host engine/pins | Direct access to full address space, 32-bit transfers/byte selects, implicit addressing, prefetch, host bus fault status | Reimplemented host subsystem and CDC |
| Arbitration | HOLD/HOLDA | GI plus R0/R1 encoded multiprocessor requests, release/reacquisition protocols | Reimplemented arbitration |
| Coprocessor | Memory-mapped external use | Direct interface and general-purpose coprocessor instructions/cycles | New instruction and bus subsystem |
| Bus faults | No equivalent upstream architecture | BUSFLT, retry encoding with LRDY/PGMD, bus-fault registers, interrupt and instruction continuation | Fault controller, checkpoints, idempotence proofs |
| Reset vector | Upstream consumes 32-bit vector as PC | Four vector LSBs initialize CONFIG; compatibility code must not rely on them as address bits | Reset fetch/config split and tests |
| A revision | Not applicable | SPVS004D says its content applies to original and A except clock stretch; A adds CONFIG.CSE and stretches selected address/RMW-read cycles by one Q4 quarter | Explicit device variant parameter only after target-board marking is known |

Compatibility is conditional rather than equivalence. Section 1.6 specifically
warns TMS34010 software about full 32-bit colors/mask, B13 pattern state,
CONVxP/xPTCH consistency, timing loops, 32-bit alignment, cache-load order,
graphics-context saves, reset-vector low bits, moved video registers, and
interrupt stack assumptions. Each becomes a compatibility test, not a reason
to copy an implementation.

## Opcode and programmer-visible compatibility

The guide calls TMS34010 object code upward compatible, but immediately places
conditions on that statement. It is evidence for retaining compatible
encodings and architectural results, not for sharing a decoder, sequencer, or
cycle trace.

Established requirements are:

- enumerate all 65,536 possible first words before deciding which encodings are
  inherited, new, redefined, reserved, or illegal;
- treat `0000h`/TRAP 30 as the only portable illegal-opcode dependence stated by
  §1.6;
- implement TMS34020 status effects from §4.1 and chapters 13–14 instead of
  copying TMS34010 flag logic without an instruction-level audit;
- support full 32-bit COLOR0/COLOR1 and PMASKL/H state;
- preserve the different cache refill order and 32-bit alignment consequences;
- load CONFIG from the reset-vector low nibble before clearing the PC low bits;
- save the expanded graphics context and use TMS34020 interrupt-stack rules.

The generated ledger deliberately marks the complete removed/redefined opcode
list and exact common-instruction status delta `UNKNOWN`. Those fields can move
to `VERIFIED_PRIMARY` only when the ISA extraction and independent fixtures
exist.

The first instruction-specific timing delta is now quantified for the
field-parameter family. TMS34020 SETF, SEXT, and ZEXT take one, two, and one
machine states, respectively. The 1988 TMS34010 guide reports SETF cases of
`1,4` for field bank 0 and `2,5` for field bank 1, SEXT `3,6`, and ZEXT `1,4`.
Compatible encodings and results therefore do not authorize reuse of the older
sequencer. Sources: TMS34020 guide printed pp.13-230..13-232 and 13-268;
TMS34010 guide printed pp.12-237..12-238 and 12-257.

## Cache and internal parallelism

The cache changes the observable memory trace and execution timing, so it cannot
be treated as an FPGA optimization:

1. The lookup uses one machine state and is overlapped with execution.
2. Four 64-instruction-word segments provide 512 bytes total capacity.
3. Each segment has eight subsegments of four long words.
4. A segment has a 22-bit start address and 32 presence bits.
5. A four-entry LRU order selects segment replacement.
6. A miss fetches four long words, with the opcode/immediate-containing long
   word deliberately fetched last.
7. Data writes bypass the cache and do not repair resident instructions.
8. HSTCTLH.CF flushes; CONTROL.CD bypasses while retaining the cached state.

Sources: UG §§5.1–5.4, printed pages 5-2 through 5-9. Internal overlap is
described in §5.5 and figure 5-4, printed pages 5-10 through 5-13.

Consequently, cache hit/miss/refill/fault state, the execution unit, and the
memory interface need separate ownership and checkpointing. A wrapper around an
already-sequenced TMS34010 core cannot insert this behavior faithfully.

## Memory and bus

The TMS34020 local interface is natively 32 bits and always reads aligned
32-bit long words. Four byte-oriented CAS controls permit 8-, 16-, 24-, and
32-bit writes. SIZE16 dynamically converts a target cycle into ordered 16-bit
transfers. Page mode can retain a row across eligible sequences, including
cache activity, and must interact correctly with bus locks, waits, faults,
refresh, display, host, and arbitration.

Sources: UG §§3.2–3.3, printed pages 3-3 onward; chapter 8, especially §§8.3–
8.9, printed pages 8-5 through 8-29.

The native FPGA transaction interface must therefore retain request class,
architectural transaction identity, bit address, byte enables, target width,
page eligibility, endian selection, special-function code, completion status,
and retry identity. The pin wrapper separately emits multiplexed LAD,
RAS/CAS/WE, page, width, wait, and fault timing.

## Fault, retry, and continuation

BUSFLT is not merely an external error flag. It participates with LRDY and PGMD
in completion coding, aborts a bus access, records fault state, and interacts
with interrupt/continuation handling. A retry must reissue exactly the
architectural work not committed before the checkpoint.

Sources: UG §§6.9–6.9.2, printed pages 6-17 through 6-21; §8.6.4, printed page
8-14; chapter 2 completion-code signal descriptions.

Required invariants are:

- no write is committed twice;
- no read beat is skipped;
- a crossed field is neither partially advanced nor silently corrupted;
- cache refill state is not made present after a failed transfer;
- register, status, array position, and continuation state advance once;
- a pending interrupt is neither lost nor taken at an undocumented boundary.

These invariants require directed phase injection and bounded formal properties;
the current repository has specifications but no implementation or proof yet.

## Host, multiprocessor, and coprocessor interfaces

The TMS34020 host interface adds a 32-bit organization, HBS0–HBS3, full local
address-space access, implicit addressing, prefetch behavior, and host-visible
fault/wait interaction. HSTADR compatibility does not make the TMS34010 host
FSM reusable.

The TMS34010 HOLD/HOLDA model is replaced by GI and encoded R0/R1
multiprocessor requests. Table 11-1 and chapter 11 define request, grant,
termination, release, and reacquisition behavior. This arbitration shares the
bus with refresh, display, host, cache miss, retry, and processor traffic.

Chapter 10 adds a direct coprocessor interface with command and
direct/indirect-data operations. The protocol belongs in the processor; the
external coprocessor function remains outside it.

## I/O, graphics, and display

The I/O space expands from 32 to 64 16-bit registers. The verified delta
includes CONFIG, CONVMP, PMASKL/H, moved display registers, and full-width
graphics state. The complete address/reset/side-effect table remains a separate
deliverable under `TMS20-0022`.

`CONTROL2` is intentionally present in the ledger as `UNKNOWN`: it is a
project-required research candidate, but an applicable definition has not yet
been found in the acquired 1990 guide. No address or bits will be invented.

TMS34020 arbitrary pitch, additional conversion state, new graphics/array/VRAM
operations, 1M VRAM controls, clipping and expanded raster operations require a
semantic conformance matrix. Similar TMS34010 instruction names do not prove
equal memory traces, continuation points, or timing.

Display register movement is explicit in §1.6, and chapters 4 and 9 are the
authority for the new map and sequencer. The upstream TMS34010 display RTL is
therefore reference-only.

## Reset, clocks, and A silicon

The TMS34010 reference's FPGA clocking method is not a TMS34020 timing model.
CLKIN, LCLK1/LCLK2 phases, wait states, reset sampling, HCS halt selection,
CONFIG vector loading, cache invalidation, and first fetch must be reconstructed
from TMS34020 sources.

SPVS004D bounds the currently verified commercial original/A delta to the A
clock-stretch extension:

- CSE is CONFIG bit 4;
- reset clears CSE;
- an ordinary cycle has Q1, Q2, Q3, Q4;
- an eligible stretched cycle adds Q4b and is 25 percent longer;
- true address cycles and read data cycles of read-modify-write sequences are
  eligible, subject to the page-22 exceptions;
- TI does not recommend clock stretch in a multiprocessor system.

Sources: SPVS004D description page 2, clock-stretch pages 21–22, and
multiprocessor note page 47. Missing silicon errata prevent a claim that this is
the only physical-silicon change ever produced.

## Implementation boundary

The delta supports ADR-0002's dedicated TMS34020 architecture:

- leaf ALU/shifter/register concepts and licensed test ideas may be adapted
  after semantic audit;
- decoder, cache, pipeline, memory controller, local bus, host, I/O, display,
  interrupt, multiprocessor, coprocessor, fault and pin timing are reimplemented;
- game-specific maps and peripherals remain outside the generic core;
- MAME remains a differential reference, not an architectural source.

## Remaining qualification work

Structural coverage of the required delta topics is now machine checked. The
following prevent `TMS20-0005` from being complete:

- the ISA database has not classified every legal/reserved encoding;
- common-instruction status and timing cases are not yet enumerated;
- CONTROL2 identity/applicability is unresolved;
- display-sequencing and interrupt deltas are not yet field/cycle complete;
- complete silicon errata and first-silicon records are unavailable;
- the independent model and RTL cover only bounded instruction/leaf slices;
  no cache, bus, subsystem waveform suite, or physical measurement yet
  verifies the remaining requirements.
