# ADR-0002: Dedicated TMS34020 architectural fork

- Status: Accepted
- Date: 2026-07-31
- Tasks: `TMS20-0005`–`TMS20-0030`

## Context

Four strategies were evaluated before architectural RTL:

| Strategy | Strength | Blocking weakness |
|---|---|---|
| 1. Fork/adapt into a dedicated TMS34020 design | Clear ownership; leaf/test reuse remains possible; direct representation of cache, pipeline and bus | More up-front refactoring |
| 2. Shared TMS340x0 base with device frontends | Potential long-term deduplication | Prematurely forces a shared microarchitecture before equivalence boundaries are proven |
| 3. Wrap the existing TMS34010 core | Fast semantic demo | Cannot faithfully insert cache hits/misses, pipeline overlap, 32/16-bit/page cycles, continuation, coprocessor/multiprocessor behavior or revised display timing around an already sequenced core |
| 4. Reimplement major portions and reuse verified leaves/tests | Strongest clean architecture and evidence boundary | Risks discarding useful verified common logic and fixtures |

The TMS34020 guide states that the devices are not pin-compatible and documents
mandatory behavior absent from the upstream implementation: 512-byte segmented
LRU instruction cache and parallelism (Chapter 5), 32-bit/dynamic-16 local
memory and page mode (Chapters 6 and 8), direct coprocessor (Chapter 10),
multiprocessor protocols (Chapter 11), bus faults/continuation, and a 64-register
I/O map. SPVS004D adds A-revision clock stretch on selected memory subcycles
(pages 21-23).

## Decision

Use strategy 1 informed by strategy 4: a dedicated TMS34020 architectural fork
with new subsystem boundaries, while adapting only audited leaf components and
test infrastructure.

The design will separate:

- architectural fetch/cache/decode/pipeline state;
- execution leaves and graphics engines;
- a transaction-level bit-addressed memory interface that retains request
  class, bus-width/page eligibility, byte enables, wait/fault/retry identity;
- a dedicated original-pin local-bus engine;
- host, multiprocessor and coprocessor protocols;
- independent video-domain state;
- board-neutral wrappers and separate game harnesses.

A shared TMS340x0 base may be reconsidered only after compatibility tests prove
stable leaf-level equivalence. It will not be used to share timing sequencers by
default.

## Consequences

- The TMS34010 top/core/decode/bus/display modules remain reference-only.
- Decode and tools derive from one machine-readable TMS34020 ISA database.
- The independent software model must not mirror RTL structure.
- The cache cannot be bypassed in release configuration.
- Device revision differences use explicit parameters only when reliable
  evidence exists; original TMS34020 remains distinct from A clock stretch.
- Early commits will be incomplete but must disclose coverage precisely.
