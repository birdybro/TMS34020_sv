# Cache native transaction interface

## Scope

This document defines the portable, transaction-level boundary implemented by
`rtl/cache/tms34020_icache.sv`. It preserves the documented TMS34020 cache-fill
and current-native-cycle restart semantics without claiming original-pin
phasing, CPU interrupt entry, `BSFLTST` encoding, dynamic 16-bit decomposition,
page-mode timing, or architectural machine-state timing.

The source contract is TI *TMS34020 User's Guide*, August 1990
(`SPVU019 / 2564006-9721`):

- cache organization and refill: §§5.1–5.3.3, printed pp.5-2–5-7;
- cache disable and flush: §§5.3.5–5.3.6, printed p.5-8;
- bus-fault save/resume: §§6.9–6.9.2, printed pp.6-19–6-20;
- local-cycle completion and retry: §§8.6–8.6.4, printed pp.8-12–8-14; and
- dynamic 16-bit and page-mode restrictions not yet implemented here:
  §§8.7–8.9, printed pp.8-15–8-29.

## Lookup side

`request_valid_i` and `request_ready_o` transfer one aligned, bit-addressed
16-bit instruction-word request. `request_bit_address_i[3:0]` must be zero.
`cache_disable_i` and an idle `cache_flush_i` are sampled with the request.

The cache returns exactly one of:

| `response_result_o` | Meaning |
|---|---|
| `TMS34020_CACHE_HIT` | Resident segment and present subsegment |
| `TMS34020_CACHE_SEGMENT_MISS` | New SSA allocated to the LRU segment and refill completed |
| `TMS34020_CACHE_SUBSEGMENT_MISS` | Matching SSA existed and the missing subsegment was refilled |
| `TMS34020_CACHE_BYPASS` | `CD` or `CF` caused a direct 16-bit instruction fetch |

`response_valid_o`, `response_word_o`, and `response_result_o` remain stable
until `response_ready_i` accepts them. A fault-aborted lookup produces no word
response; it produces the cancellation pulse described below.

## Native read request

`memory_request_valid_o` and `memory_request_ready_i` transfer one native read.
The output payload remains stable while valid is asserted and ready is low.

| Signal | Meaning |
|---|---|
| `memory_request_bit_address_o` | Bit address of this native read |
| `memory_request_width_32_o` | One for a 32-bit refill long word; zero for a 16-bit bypass word |
| `memory_request_cache_fill_o` | One for refill traffic; zero for direct disabled/flush fetch |
| `memory_request_sequence_index_o` | Refill beat 0–3; zero for bypass |

The four refill addresses follow the demand-long-word-last order. The
interface does not split a 32-bit request for `SIZE16`, drive local-bus status
pins, or assert page-mode eligibility. Those are memory-controller
responsibilities that remain unimplemented.

## Native completion

Once a native request is accepted, the cache waits for
`memory_response_valid_i`. Absence of a response represents an outstanding
transaction or wait at this transaction boundary. It is not a claim that the
ready/valid signals reproduce `LRDY` pin timing.

When a response is valid, `memory_response_completion_i` has this internal
meaning:

| Completion | Cache action |
|---|---|
| `TMS34020_MEMORY_SUCCESS` | Consume `memory_response_data_i`; advance the refill or return the bypass word |
| `TMS34020_MEMORY_RETRY` | Consume no data and reissue the same address, width, traffic class, and sequence index |
| `TMS34020_MEMORY_FAULT` | Consume no data, preserve the current beat, and enter the faulted state |
| `TMS34020_MEMORY_RESERVED` | Forbidden interface value; simulation asserts and the RTL does not accept it |

These enum values are an internal protocol, not the electrical
`BUSFLT`/`LRDY` encoding. A future pin adapter derives success, retry, and fault
from the documented pin samples. Prior successful refill beats are retained;
retry and fault do not decrement the sequence index or repeat them.

## Fault pause, resume, and abort

`faulted_o` identifies a saved native cache operation. While it is asserted:

- no native request or instruction response is offered;
- the lookup port remains unavailable;
- `fault_resume_i` reissues the same native beat; and
- `fault_abort_i` discards the pending lookup and pulses
  `request_aborted_o`.

Resume and abort must not be asserted together. `fault_abort_i` is the cache
boundary needed for an external fault controller's documented
`BSFLTST=FFFFh` abandon operation; this leaf does not itself implement that
register, the bus-fault vector, interrupt state, `RETI`, or the CPU
continuation stack.

Partial refill data may exist internally after successful earlier beats, but
the requested present bit remains clear until a successful fourth completion.
After abort, a later lookup therefore begins a complete four-beat refill and
cannot hit the partial data.

## Reset and controls

Synchronous `reset_i` cancels the local transaction state, clears all present
and private tag-valid bits, and restores LRU order `[0,1,2,3]`. The native peer
must share the reset/cancellation contract; there are no transaction IDs for
discarding an old response after reset.

`cache_disable_i` preserves metadata while requests bypass. `cache_flush_i`
clears present/tag-valid state and restores reset LRU order while high. The
defined RTL test covers flush accepted with an idle lookup. Assertion or
release of flush during an already active native transaction remains
unverified pending the architectural decision tracked by `OQ-0009`.

## Verified and missing cases

`make cache-tests` currently verifies:

- all four refill rotations, segment and subsegment miss, hit, and LRU paths;
- stable lookup/native payloads under backpressure and absent response waits;
- successful 32-bit refill and 16-bit bypass reads;
- retry at every refill sequence index and on a bypass read;
- fault/resume at every refill sequence index and on a bypass read;
- fault/abort after an earlier successful beat and full refill restart; and
- fault/abort of a bypass read; and
- reset in the request and waiting-response states of every refill sequence
  index; and
- no present-bit commit on retry, fault, or abort.

The Verilator run explicitly enables four in-module SystemVerilog assertions:
native-request stability under stall, instruction-response stability under
stall, no present-bit commit after retry/fault, and quiescent ports while
faulted. Passing simulation is not a formal proof of these properties.

The same command runs deterministic randomized stress with seeds `34020001`,
`b7a17ead`, and `5eedc0de`. Each seed performs 132 fetches against an
independent address-derived memory function while varying lookup delay, native
request backpressure, response latency, response backpressure, retry, fault
hold/resume/abort, `CD`, and idle `CF`. The initial qualification run covered
396 fetches, 1,226 accepted native requests, 36 retries, 83 faults, and 43
aborts. A seed can be replayed as a Verilator plusarg; the runner appends any
simulation failure and its seed to ignored
`build/cache_random_failures.txt`. The supported replay command is
`python3 scripts/run_cache_random_tests.py --seed b7a17ead`.

The suite does not yet cover every reset/active-flush/control combination,
larger seed campaigns, interrupt entry/return, page mode, `SIZE16`, pin
waveforms, or exact cycles. It is not complete `TMS20-0012` or
`TMS20-0017` verification.
