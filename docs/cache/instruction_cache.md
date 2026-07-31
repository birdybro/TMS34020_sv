# TMS34020 instruction cache

## Scope and evidence state

This document records the architectural cache contract established directly
from the August 1990 *TMS34020 User's Guide* (`SPVU019 /
2564006-9721`). A transaction-level independent model implements the bounded
contract in `tools/model/cache.py` and now supplies instruction words to the
architectural model; this is not evidence that cache RTL, pipeline timing, or
local-bus timing is complete.

The organization, address partition, replacement policy, ordinary hit/miss
behavior, reset state, refill order, cache disable, and cache flush behavior
below are `VERIFIED_PRIMARY`. Fault/retry, interrupt, dynamic-bus-size, and
pin-cycle details remain research items where explicitly identified.

## Organization

| Item | Documented value | Primary citation |
|---|---:|---|
| Total data capacity | 512 bytes | User's Guide §5.1, pp.5-2–5-3, Figure 5-1 |
| Total capacity in instruction words | 256 16-bit words | User's Guide §5.1, p.5-3 |
| Total capacity in long words | 128 32-bit long words | User's Guide §5.1, p.5-3 |
| Cache segments | 4 | User's Guide §5.1, pp.5-2–5-3, Figure 5-1 |
| Instruction words per segment | 64 | User's Guide §5.1, p.5-3 |
| Long words per segment | 32 | Derived exactly from the cited 64 16-bit words |
| Bytes per segment | 128 | Derived exactly from the cited segment size |
| Subsegments per segment | 8 | User's Guide §5.1, p.5-3 |
| Long words per subsegment | 4 | User's Guide §5.1, p.5-3 |
| Instruction words per subsegment | 8 | User's Guide §5.1, p.5-3 |
| Bytes per subsegment | 16 | Derived exactly from the cited subsegment size |
| Segment-start address width | 22 bits | User's Guide §5.1, p.5-3, Figure 5-2 |
| Present flags | 8 per segment, 32 total | User's Guide §§5.2, 5.3.5, pp.5-4, 5-8 |

Each cache segment can hold one memory segment beginning at an even
64-instruction-word boundary. Each segment has one 22-bit segment-start
address (SSA), eight subsegment-present (`P`) flags, and 32 long words of
data. Replacement is performed at segment granularity, while allocation and
refill are performed at subsegment granularity.

Only words addressed through the PC are cache-accessible: opcodes, immediate
operands, displacements, and absolute addresses. Ordinary data reads and
writes always bypass the cache, even when their addresses overlap cached
instruction storage. User's Guide §5.1, p.5-3.

## Bit-address mapping

The TMS34020 PC and all addresses in this document are bit addresses.
Figure 5-2 establishes this partition for an aligned instruction-word
address:

| Bit-address field | Function |
|---|---|
| `[31:10]` | 22-bit SSA comparison |
| `[9:7]` | subsegment number within the memory segment |
| `[6:4]` | 16-bit instruction-word number within the subsegment |
| `[3:0]` | zero for an instruction-word address |

Consequently:

- a memory segment is 1024 bit addresses (`0x400`) and begins at an address
  with bits `[9:0]` clear;
- a subsegment is 128 bit addresses (`0x80`) and begins with bits `[6:0]`
  clear;
- a long word is 32 bits (`0x20` bit addresses);
- `[6:5]` select one of four long words in a subsegment; and
- bit `[4]` selects one of two instruction words in that long word.

The prose immediately below Figure 5-2 gives overlapping bit ranges. The
figure, the stated 22/3/3/4-bit partition, and all documented sizes resolve
the usable mapping above. The conflict and decision are recorded as
`RSC-0007` in `docs/research/source_conflicts.md`.

## Lookup and hits

For every requested instruction word, the cache compares address `[31:10]`
against all four SSA registers and examines the `P` flag selected by
address `[9:7]`.

- An SSA match with the selected `P=1` is a cache hit.
- No SSA match is a segment miss.
- An SSA match with the selected `P=0` is a subsegment miss.

On a hit, the cache performs a one-machine-state internal read and moves the
accessed segment to the most-recently-used end of the LRU stack. Instruction
fetch normally overlaps preceding instruction completion, so the guide
describes the effective hit-fetch overhead as zero. This does **not** by
itself define every instruction's completion timing or pipeline hazard
behavior. User's Guide §5.3.1, p.5-5.

## Replacement and LRU

The cache maintains an ordered stack containing each segment number exactly
once. The top is most recently used (MRU); the bottom is least recently used
(LRU). Every segment access moves that segment to the top and preserves the
relative order of the other three entries. User's Guide §5.2, p.5-4.

In executable pseudocode:

```text
touch(segment):
    lru = [segment] + [entry for entry in lru if entry != segment]
```

On reset the documented order from top to bottom is `[0, 1, 2, 3]`.
Segment 3 is therefore the initial replacement candidate. User's Guide
§6.12.2, p.6-23.

## Miss handling

### Subsegment miss

When an SSA matches but the requested `P` flag is clear, the processor:

1. reads the requested eight-instruction-word subsegment into that cache
   segment;
2. moves the segment to MRU;
3. sets the requested subsegment's `P` flag; and
4. returns the requested word from cache.

User's Guide §5.3.2, pp.5-5–5-6.

### Segment miss

When no SSA matches, the processor:

1. selects the bottom LRU segment and clears all eight of its `P` flags;
2. writes requested address `[31:10]` into that segment's SSA;
3. refills the requested subsegment and sets its `P` flag;
4. moves the replaced segment from LRU to MRU; and
5. returns the requested word from cache.

User's Guide §§5.2 and 5.3.2, pp.5-4–5-6.

The externally useful `P` flag must not indicate a successfully present
subsegment before its four-long-word refill is complete. The guide states
that the flag is set after loading. Sections 6.9 and 8.6 further establish
that prior successful native cycles remain complete while retry or bus-fault
return restarts the current native cycle. The independent model may retain
partial data internally, but it keeps `P=0` until the complete refill succeeds.

## Refill address order

Every miss loads all four long words of the selected subsegment. The long
word containing the first requested opcode or immediate operand is fetched
**last**, not first. The other three are fetched in ascending cyclic order
before it. User's Guide §5.3.3, Examples 5-1–5-3, pp.5-6–5-7.

For a request address `A`:

```text
subsegment_base = A & 0xFFFF_FF80
requested_index = (A >> 5) & 3
refill_indices  = [
    (requested_index + 1) & 3,
    (requested_index + 2) & 3,
    (requested_index + 3) & 3,
    requested_index
]
refill_address(index) = subsegment_base + index * 0x20
```

All constants are in bit-address units.

Documented examples:

| First request | Refill addresses, in order |
|---:|---|
| `0x000` | `0x020`, `0x040`, `0x060`, `0x000` |
| `0x0A0` | `0x0C0`, `0x0E0`, `0x080`, `0x0A0` |

The same order applies when an extension or other immediate word, rather
than an opcode, causes the miss.

## Reset state

Immediately following reset:

- all SSA registers are uninitialized;
- the LRU order, MRU to LRU, is `[0, 1, 2, 3]`; and
- all 32 `P` flags are clear, so the cache is empty.

User's Guide §6.12.2, p.6-23.

Portable synthesizable RTL must not rely on FPGA power-up unknowns. The
architecturally unobservable SSA representation and the exact selection rule
if an uninitialized SSA happens to compare equal while every `P` bit in that
segment is clear require an explicit implementation decision after further
evidence. No validity or replacement behavior beyond the cited guide is
invented here.

## Disable, flush, and coherence

| State | Fetch behavior | Cache metadata/data behavior | Resume behavior |
|---|---|---|---|
| `CD=0`, `CF=0` | Normal cache operation | Normal lookup, fill, and replacement | — |
| `CD=1`, `CF=0` | Each requested instruction word bypasses cache | Data, `P`, SSA, LRU, and other cache state are preserved | Clearing `CD` restores the preserved state |
| `CF=1` | Each requested instruction word bypasses cache | Cache remains flushed; all `P` flags are forced clear | Clearing `CF` with `CD=0` starts in reset-equivalent empty-cache state |

`CD` is bit 15 of `CONTROL`; see User's Guide `CONTROL` register
description, pp.4-26–4-27, and §5.3.6, p.5-8. `CF` is bit 14 of
`HSTCTLH`; see its register description, pp.4-60–4-61, and §5.3.5,
p.5-8.

The `HSTCTLH` register description says "all 4" `P` flags, while the cache
architecture and cache-flush section establish eight flags in each of four
segments and explicitly say all 32 are cleared. This contradiction is
resolved as a typographical error and recorded as `RSC-0008`.

Self-modifying writes update external memory only. They neither update nor
automatically invalidate cached copies, and the processor does not detect
them. Software or a host downloading code must arrange quiescence and flush
the cache before executing the modified code. User's Guide §§5.3.4–5.3.5,
p.5-8.

This is the documented coherence mechanism. No automatic coherence is
assumed for host writes, DMA, multiprocessor writes, or other external
agents.

## Bus classifications and bounded timing facts

The local-memory status code distinguishes a four-long-word **cache fill**
from a one-word **instruction fetch** made while the cache is disabled.
User's Guide §8.5, p.8-11. The encoded status values and pin-level phasing
belong to the local-bus contract and must be verified there rather than
guessed in the cache.

The guide gives these bounded performance statements:

- a hit uses a one-machine-state internal cache access, normally overlapped
  with preceding instruction completion (§5.3.1, p.5-5);
- with cache disabled and no external waits, each instruction-word fetch
  adds three machine states (§5.4, p.5-9); and
- the example enabled-cache page-mode refill takes five machine states for
  four long words plus one state to begin instruction processing, or
  0.75 state per instruction word if all eight are consumed (§5.4, p.5-9).

These statements do not yet establish the exact transaction beat schedule for
32-bit versus dynamic 16-bit targets, arbitrary waits, interrupted page mode,
fault/retry, or every pipeline overlap case. They must not be promoted to a
general cycle-accuracy claim.

## Transaction model and RTL boundary

`tools/model/cache.py` implements the cycle-independent request/response
boundary below. It supports resumable current-beat retry and bus fault,
`BSFLTST=FFFFh`-style abort, and deterministic pending-refill snapshots. It
drives opcode and extension-word reads in `Tms34020Model.step()` and records
lookup/refill/direct-fetch traces. It does not decompose native long words into
pin-level 16-bit cycles or assign cache-miss machine-state timing.

The portable cache must separate instruction lookup from the native
transaction interface. Its eventual contract must make these events explicit:

- aligned 16-bit PC-word lookup request and response;
- hit, subsegment miss, and segment miss classification;
- four ordered 32-bit refill requests identified as cache-fill traffic;
- accepted refill beats and completion;
- stall stability;
- abort/fault and retry disposition;
- `CD` bypass fetches identified as direct instruction-fetch traffic;
- `CF` flush and reset;
- LRU, SSA, and `P` updates at documented commit points; and
- trace observability for address, selected segment/subsegment, hit/miss,
  refill beat, and replacement.

The cache may use FPGA block RAM, inferred memory, or flops without changing
this architectural boundary. Vendor primitives must remain outside the
portable implementation.

## Required verification

At minimum, directed and randomized tests must cover:

- cold segment miss and all four refill-request positions;
- hit of each instruction word within a subsegment;
- subsegment miss within a resident segment;
- four distinct segment fills and every LRU replacement position;
- move-to-front ordering from every stack position;
- segment and subsegment boundaries;
- branches and extension-word misses;
- `CD` preservation across bypass fetches;
- `CF` held high, `CF` release, and `CD`/`CF` combinations;
- self-modification and host modification with and without an explicit flush;
- reset from idle and reset during each refill beat;
- 32-bit targets, dynamic 16-bit targets, page mode, arbitrary waits,
  interrupted page sequences, and bus-width changes where legal;
- fault and retry at every meaningful refill and bypass-fetch phase;
- no early `P` commit, no stale refill commit after abort, no duplicate
  refill completion, and no invalid hit; and
- interrupt recognition before, during, and after a miss according to the
  pipeline checkpoint contract.

Formal properties must include permutation validity of the LRU stack,
present-bit safety, stable requests while stalled, refill-address ordering,
replacement-tag consistency, and rejection of stale responses after an
aborted refill.

## Unresolved questions

The following prevent honest cache RTL completion:

1. What is the exact local-clock/pin phase for each standard and page-mode
   refill transfer, including the first cycle's `BUSFLT` sampling edge?
2. What CPU continuation words and interrupt-stack contents correspond to a
   faulted fetch or refill, beyond the memory controller's saved current-cycle
   state?
3. At which checkpoint may a non-fault interrupt preempt a miss or bypass
   fetch?
4. How are the native refill words scheduled onto `S=0`/`S=1` transfers on
   each legal `SIZE16` wiring, including page-mode column sequencing?
5. What externally observable behavior is required when an uninitialized SSA
   compares equal after reset while all of that segment's `P` flags are clear?
6. What exact cache-fill and disabled-fetch local-bus status encodings and
   phase waveforms apply?

These questions are tracked under `OQ-0009` and dependent cache, pipeline,
memory, page-mode, and fault tasks. Until they are resolved and tested, the
cache remains a researched contract rather than implemented RTL.
