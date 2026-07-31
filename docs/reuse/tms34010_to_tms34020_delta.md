# Preliminary TMS34010 to TMS34020 delta

Status: research baseline, not the complete `TMS20-0005` delta.

Primary comparison source: *TMS34020 User's Guide*, document
2564006-9721, August 1990, §1.6, pages 1-16 through 1-18. Cache details below
use Chapter 5, pages 5-2 through 5-8. Electrical/revision details use
SPVS004D, March 1990 revised November 1993, pages 2 and 21-23.

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

The complete machine-readable delta will live in
`docs/generated/tms34010_tms34020_delta.yaml` and must cover every feature in
`TMS20-0005`.
