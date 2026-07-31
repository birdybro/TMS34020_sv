# ADR-0001: TMS34010 reuse strategy

- Status: Accepted
- Date: 2026-07-31
- Tasks: `TMS20-0004`, `TMS20-0005`

## Context

The pinned TMS34010 project contains valuable functional RTL, 168 directed
benches, differential/workload infrastructure, CDC patterns, and a complete
Cyclone V flow. Its signed-off scope explicitly does not claim original
instruction-cycle parity and omits its optional instruction cache. The
TMS34020 primary guide documents a different 32-bit/dynamic-size/page-mode
memory controller, 512-byte cache and overlap, expanded I/O/host/display
systems, bus fault/continuation, multiprocessor and coprocessor interfaces, and
non-pin-compatibility (*TMS34020 User's Guide*, 2564006-9721, August 1990,
§1.6 pages 1-16 through 1-18; Chapter 5).

## Decision

Treat the repository as a read-only, reproducibly pinned reference. Reuse is
selective:

- adapt independently verifiable arithmetic, register-file, CDC, model and test
  patterns with provenance;
- use upstream directed fixtures as compatibility candidates only after
  primary-source and license review;
- reimplement decode, status/control, cache/pipeline, memory/bus, I/O, host,
  graphics sequencing, display, interrupts and physical wrappers for TMS34020;
- never compile the upstream RTL directly into the default design.

Copied/adapted files preserve the MIT notice and are tracked in
`docs/reuse/copied_file_provenance.yaml`. Timing state machines require
TMS34020-specific primary evidence and waveform tests.

## Consequences

This sacrifices short-term apparent progress but prevents TMS34010 physical and
functional assumptions from becoming hidden TMS34020 behavior. The test corpus
and leaf logic remain useful, while architectural ownership stays clear.

No upstream file is currently approved as `REUSE_UNCHANGED`.
