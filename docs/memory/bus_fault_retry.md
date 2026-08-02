# Bus fault and retry

## Scope

This is the verified transaction-level contract extracted from the August
1990 *TMS34020 User's Guide* (`SPVU019 / 2564006-9721`). It is not yet a
pin-timing implementation, interrupt implementation, or proof of restart
correctness.

## Local-cycle completion codes

During a standard local-memory data subcycle, the processor samples `LRDY`
and `BUSFLT` on the rising edge of `LCLK2`. User's Guide §8.6, p.8-12
defines:

| `BUSFLT` | `LRDY` | Meaning |
|---:|---:|---|
| 0 | 0 | Insert one wait state |
| 0 | 1 | Successful transfer |
| 1 | 0 | Retry |
| 1 | 1 | Bus fault |

Waits retain active control signals for another full local-clock cycle and
resample both signals. A successful read promises valid LAD data at the next
falling `LCLK2` edge; a successful write promises the destination can latch
the data at that edge. User's Guide §§8.6.1–8.6.2, pp.8-12–8-13.

## Retry

A retry terminates the current local-memory cycle without completing the
transfer. The memory controller later restarts that cycle from its
address/status subcycle with the original address and status code. Higher
priority pending memory requests may run before the retry. User's Guide
§8.6.3, p.8-13.

For a multi-cycle operation, retry normally restarts only the cycle that
returned retry:

- a retry on a read/modify/write write cycle does not repeat its read;
- a retry on the second `S=1` half of a 16-bit target access does not repeat
  the first `S=0` half; and
- the documented exception is a bus-locked `SWAPF` write, which restarts from
  the read to preserve adjacent locked read/write behavior.

This establishes the required idempotence boundary for field, dynamic-width,
cache-fill, and graphics controllers: state for prior successful native cycles
must be preserved, while no architectural completion may be recorded for the
retried cycle.

## CPU bus fault

A CPU-initiated local-memory cycle returns bus fault when both `BUSFLT` and
`LRDY` are sampled high. The fault is not restricted to an instruction
boundary. The memory controller:

1. saves LAD data in the 32-bit `BSFLTD` register;
2. saves the access type and resume point in `BSFLTST`;
3. requests the bus-fault interrupt; and
4. after the handler and `RETI`, restores the memory-controller state and
   restarts the faulted access in the same manner as a retry.

The CPU responds within one machine state, saves its execution state, and
vectors through bit address `0xFFFF_FBC0`. User's Guide §§6.9–6.9.1,
pp.6-19–6-20; `BSFLTD` and `BSFLTST` descriptions, pp.4-15–4-17; §8.6.4,
p.8-14.

If software writes `0xFFFF` to `BSFLTST`, the memory controller returns to its
inert state instead of restarting the saved cycle. No other software-written
`BSFLTST` value is documented as safe.

The bus-fault state is a single hardware save area, not a stack. A second bus
fault during interrupt-state stack traffic can destroy the first saved memory
cycle. If nested faults are possible in the handler, software must preserve
and restore `BSFLTD` and `BSFLTST` before another faultable access. User's
Guide §6.9.2, p.6-20.

Host-initiated faults do not take the CPU bus-fault interrupt. They terminate
the host local-memory cycle and set `HBFI`; host retry sets `HRYI` while the
cycle restarts. DRAM-refresh and video-initiated screen-refresh faults
terminate without the CPU recovery sequence. User's Guide §§8.6.3–8.6.4,
pp.8-13–8-14.

## Page-mode restriction

Only the first standard data subcycle of a page-mode sequence samples
`LRDY`, `BUSFLT`, and `PGMD`. Once `PGMD=0` starts page mode, subsequent
one-state page transfers do not sample them. Therefore every location in the
64-long-word page must be zero-wait and mapped; no later page beat can request
a retry or bus fault. User's Guide §§8.7–8.7.1, pp.8-15–8-16.

Cache fills are explicitly eligible for page mode (§8.7.2, p.8-16). Thus:

- a fault/retry before page mode starts restarts the initial standard cycle;
- after a successful page-mode start, the remaining refill page beats cannot
  independently fault or retry at the pins; and
- virtual-memory or protection logic must map the complete page before
  allowing page mode.

## Dynamic 16-bit transfers

For a 16-bit target, the first `S=0` cycle transfers one half of a long word
and a second `S=1` cycle transfers the other half. `SIZE16` is sampled with
the completion inputs. A retry on `S=1` repeats only `S=1`. User's Guide
§§8.6.3 and 8.9, pp.8-13 and 8-25.

When a page-mode sequence starts with `SIZE16=0`, later page transfers still
sample `SIZE16` to select the connected LAD half, but do not resample
`LRDY`, `BUSFLT`, or `PGMD`. User's Guide §8.9.2, pp.8-28–8-29.

## Cache-refill consequence

The cache refill is a four-long-word multi-cycle memory-controller operation.
Combining §§5.3.2–5.3.3 with §8.6.3 establishes this bounded restart model:

- successful earlier refill cycles remain successful;
- retry reissues only the current native cycle;
- bus-fault return restores and reissues the faulted native cycle;
- a subsegment `P` flag is not set until the four-long-word refill finishes;
  and
- abandoning the faulted cycle must not expose the partial subsegment as a
  hit.

The independent model in `tools/model/cache.py` implements this
transaction-level contract and intentionally omits machine-state and pin
timing. Exact visibility of partial cache RAM contents, `BSFLTST` encoding,
interrupt-stack contents, and reset during a saved fault remain unresolved.

The bounded `rtl/cache/tms34020_icache.sv` leaf now implements the
transaction-level cache consequence of this contract. Absence of a native
response represents wait/outstanding state; explicit success, retry, and fault
outcomes either advance, reissue the same beat, or pause it. External
resume reissues that beat. External abort discards the pending lookup without
setting its present flag. Directed tests cover retry and fault-resume at all
four refill sequence indices, bypass retry/fault, and partial-refill
fault-abort/restart.

This is not the local-bus pin completion decoder or a CPU fault controller.
`BSFLTD`, `BSFLTST`, vectoring, `RETI`, interrupt context, nested faults,
dynamic 16-bit subcycles, page mode, and exact sampling phases remain
acceptance work for `TMS20-0017`. See
`docs/memory/cache_native_interface.md`.

FPIXEQ/FPIXNE now have bounded uninterrupted logical scans and a one-pixel
comparison/update leaf, but neither is fault evidence. A faultable pixel-read
owner must preserve the B10/B11 checkpoint and Z until completion, distinguish
the instruction's special no-temporary interrupt restart from BF continuation,
and resume without skipping or duplicating a comparison. The guide's general
graphics-fault rule sets BF and uses the bus-fault continuation sequence
(printed p.6-14), but it does not disclose enough internal checkpoint fields
to implement that owner. No `pixel_read` transaction in the model represents
physical acceptance or BUSFLT sampling.

## Required verification

Future RTL tests and properties must inject all four completion codes during
every standard data subcycle and prove:

- address, status, write data, byte enables, and `S` remain correct across
  waits and retry;
- retry does not duplicate completed reads or writes;
- the second half of a 16-bit transfer resumes without replaying the first;
- `SWAPF` alone restarts its locked pair from the read when its write retries;
- fault return resumes the saved native cycle exactly once;
- `BSFLTST=FFFFh` abandons the cycle without a stale completion;
- no cache present flag or architectural write commits from a partial access;
- fault entry/return preserves PC, ST, registers, continuation state, pending
  interrupts, and memory-controller priority state as documented; and
- no unsupported `BUSFLT` sampling is inferred during page-mode beats.

Exact pin sampling and context-stack waveforms remain part of
`TMS20-0017`, not a completed claim of this research slice.
