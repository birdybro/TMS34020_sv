# Verified RTL slice

This document records the exact boundary of the synthesizable RTL. It is a
collection of independently testable architectural leaves, not a processor
core, sequencer, pipeline, complete memory controller, or pin interface.

## Implemented leaves

| Module | Implemented behavior | Primary source |
|---|---|---|
| `rtl/core/tms34020_decode.sv` | Classification and instruction length for the 38 entries currently present in the canonical ISA database; all other first words remain explicitly unclassified | TI *TMS34020 User's Guide*, August 1990, individual instruction pages listed in `docs/generated/tms34020_isa.yaml` |
| `rtl/core/tms34020_instruction_fetch.sv` | Serialized aligned PC load, cache-word request, one-to-five-word packet assembly, per-word cache metadata, stable packet backpressure, explicit sequential/redirect completion, and abort-to-PC-reload behavior | TI *TMS34020 User's Guide*, August 1990, §§4.2, 5.1, 5.3.1, and 6.5–6.6, printed pp.4-4, 5-3, 5-5, 6-9, and 6-13 |
| `rtl/core/tms34020_regfile.sv` | Two 32-bit combinational read ports, one synchronous write port, independent A0–A14 and B0–B14 storage, and shared A15/B15 stack-pointer storage | TI *TMS34020 User's Guide*, August 1990, §4.1, printed pp.4-2..4-3 |
| `rtl/core/tms34020_register_commit.sv` | Externally gated, single-edge register/ST state commit for the 23 one-word instructions supported by `tms34020_register_execute`; unsupported words cannot mutate state | TI *TMS34020 User's Guide*, August 1990, §4.1 and the individual instruction pages cited for `tms34020_register_execute` |
| `rtl/core/tms34020_status.sv` | Synchronous reset to `00000010h` and masked 32-bit state updates for exact partial instruction writes | TI *TMS34020 User's Guide*, August 1990, §4.1, Figure 4-1 and Table 4-1, printed pp.4-2..4-3 |
| `rtl/execute/tms34020_addxyi.sv` | Independent 16-bit X/Y addition and the instruction-specific N/C/Z/V results | TI *TMS34020 User's Guide*, August 1990, ADDXYI, printed p.13-39 |
| `rtl/execute/tms34020_binary_arithmetic.sv` | ADD, ADDC, SUB, SUBB, and nondestructive CMP result/flag paths with carry/borrow inputs | TI *TMS34020 User's Guide*, August 1990, printed pp.13-33..13-34, 13-80, and 13-241..13-242 |
| `rtl/execute/tms34020_cmpk.sv` | Encoded-zero-means-32 subtraction and N/C/Z/V compare results without register modification | TI *TMS34020 User's Guide*, August 1990, CMPK, printed p.13-83 |
| `rtl/execute/tms34020_logical.sv` | AND, ANDN, OR, and XOR register results plus Z; N/C/V remain outside the write mask | TI *TMS34020 User's Guide*, August 1990, printed pp.13-40, 13-42, 13-182, and 13-266 |
| `rtl/execute/tms34020_register_execute.sv` | Decoder-controlled operand selectors and register/ST write intents for NOP, ABS, NEG, NEGB, NOT, CLRC, DINT, EINT, GETST, INC, DEC, SETC, ADD, ADDC, SUB, SUBB, CMP, CMPK, RMO, AND, ANDN, OR, and XOR | TI *TMS34020 User's Guide*, August 1990, §4.1 and printed pp.13-32..13-34, 13-40, 13-42, 13-58, 13-80, 13-83, 13-94..13-95, 13-109, 13-132, 13-134, 13-178..13-182, 13-224, 13-226, 13-241..13-242, and 13-266 |
| `rtl/execute/tms34020_rmo.sv` | Least-significant set-bit index and Z result | TI *TMS34020 User's Guide*, August 1990, RMO, printed p.13-224 |
| `rtl/execute/tms34020_unary.sv` | ABS, NEG, NEGB, and NOT results plus instruction-specific N/C/Z/V values and write masks | TI *TMS34020 User's Guide*, August 1990, printed pp.13-32 and 13-178..13-181 |
| `rtl/graphics/tms34020_pixel_size_ops.sv` | GETPS zero-extension and EXGPS register/16-bit PSIZE-write data paths; no I/O timing or write-queue implementation | TI *TMS34020 User's Guide*, August 1990, EXGPS, printed p.13-113; GETPS, printed p.13-131 |
| `rtl/graphics/tms34020_pixel_replicate.sv` | RPIX replication and documented machine-state counts for PSIZE 1, 2, 4, 8, 16, and 32 | TI *TMS34020 User's Guide*, August 1990, RPIX, printed p.13-225; §12.6, printed p.12-17 |
| `rtl/cache/tms34020_icache.sv` | Bounded native-completion cache leaf: four segments, 32 subsegments, 128×32 data RAM, lookup classifications, demand-long-word-last refill, move-to-front LRU, reset abstraction, `CD` bypass, idle `CF`, backpressure, current-beat retry, and fault pause/resume/abort | TI *TMS34020 User's Guide*, August 1990, §§5.1–5.3.6, printed pp.5-2..5-8; fault/retry §§6.9 and 8.6, printed pp.6-19..6-20 and 8-12..8-14; reset §6.12.2, printed p.6-23 |

The generated include `rtl/generated/tms34020_isa_decode.svh` is derived from
`docs/generated/tms34020_isa.yaml` by
`tools/generators/generate_isa_rtl.py`. A freshness check prevents the checked-in
decoder from drifting away from the database. Because the database is
incomplete, an unmatched word means *unclassified*, not architecturally
reserved or illegal.

The register file is synchronously cleared in this FPGA implementation so
simulation and formal startup are deterministic. This is not a silicon-reset
claim. The TI reset description leaves the general registers uninitialized;
the future core must not make execution depend on their reset values. Source:
TI *TMS34020 User's Guide*, August 1990, §6.12.2, printed p.6-23.

## Verification evidence

`make rtl-leaf-tests` builds a self-checking SystemVerilog testbench with
Verilator. It checks:

- every currently extracted decoder entry, including masked register/mode
  encodings and instruction-word count;
- explicit three-word decode and one-word-router rejection for the ANDNI/ORI/
  XORI immediate-logical family;
- a near-neighbor that must remain unclassified;
- two ADDXYI arithmetic/flag cases;
- CMPK constant-32, borrow, and overflow cases;
- RMO zero, low-bit, and high-bit cases;
- every TI example row for ABS, NEG, NEGB, and NOT, including borrow and
  partial status-write masks;
- ADD/ADDC carry and overflow, SUB/SUBB borrow and overflow, and CMP write
  inhibition;
- GETPS and EXGPS data-path behavior;
- all six legal RPIX sizes and their documented state counts;
- rejection of an unsupported pixel size;
- independent A/B storage and the shared A15/B15 stack-pointer alias.
- ST reset/priority, documented bit layout and reserved mask, full flag
  replacement, partial flag preservation, isolated IE set, and isolated C
  clear.
- decoder-controlled NOP, unary, binary-arithmetic, logical, CMPK, RMO,
  CLRC/SETC, DINT/EINT, GETST, and INC/DEC write intents, including A/B
  register-file selection, source/destination indices, CMP write inhibition,
  partial status masks, carry/borrow edges, Z-only logical updates, and
  rejection of decoded-but-unsupported and unclassified words.
- seventeen ordered commit checks covering EINT, SETC, GETST, INC, DINT, DEC,
  ABS, shared-SP write/read, ADD, nondestructive CMP, RMO, unsupported BLMOVE
  rejection, state-neutral NOP, AND, OR, XOR, and ANDN. These checks prove that
  a later operation observes the preceding committed register/ST state; they do
  not assign an architectural cycle count to the commit edge.

The testbench must emit `PASS: tms34020 verified leaf RTL`; simulator exit
status alone is not accepted.

`make cache-tests` separately builds the cache leaf with Verilator and requires
`PASS: tms34020 cache native completion RTL`. It checks reset metadata,
segment/subsegment miss refill, all four demand-word refill rotations,
low/high half hits, no early present-bit commit, four-segment LRU
allocation/touch/replacement, `CD` preservation, an idle `CF` flush/bypass,
and stable request/response payloads under backpressure. It also checks retry
and fault resume at all four refill sequence indices, bypass retry/fault,
fault abort after a prior successful beat, full refill restart, bypass abort,
reset in the request and response-wait states of every refill index, and no
early present commit. Four enabled SystemVerilog assertions check stalled
payloads, retry/fault present safety, and fault-state quiescence in simulation;
they are not formal proofs. Other abort/control combinations, the CPU fault
controller/interrupt, `SIZE16`, page mode, reset in other cache states, flush
during refill, and cycle timing remain unverified.

The cache command also runs three deterministic randomized seeds. The initial
run covered 396 fetches and 1,226 accepted native reads with randomized
backpressure/latency, 36 retries, 83 faults, and 43 aborts. It checks every
returned word against an independent address-derived memory function and
records a failing seed under ignored `build/` for replay. This is protocol
stress, not differential silicon evidence or architectural cycle validation.

`make fetch-tests` separately verifies the serialized instruction-packet
assembler. It checks aligned PC load and redirect, one-word and three-word
packets, extension order, per-word cache classifications, request and packet
backpressure, explicit completion gating, unclassified-word isolation,
cache-abort discard/reload, and 32-bit PC wrap. Four runtime assertions cover
request stability, packet stability, alignment, and post-abort packet safety.
This handshake regression does not establish machine-state timing or pipeline
overlap.

`make quartus-leaf-smoke` runs warning-free Quartus Analysis & Synthesis for
the leaf qualification wrapper on Cyclone V device `5CSEBA6U23I7`. The wrapper
keeps both register-file read ports, arithmetic flags, decoder outputs, PSIZE
data paths, unary, binary, and logical arithmetic, RMO, and RPIX timing outputs
observable. It also keeps every output of the register-execution router
observable and instantiates the commit composition. The wrapper deliberately
retains both the original raw state leaves and the integrated commit instance,
so its resource count is not a core-area estimate. This is an early portability
check only:
Analysis & Synthesis is not placement, routing, TimeQuest closure, or
full-core qualification.

`make quartus-cache-smoke` independently runs warning-free Analysis &
Synthesis for the cache leaf. Quartus infers the 128×32 data array as 4,096
block-memory bits; the diagnostic top uses 375 logic cells and 200 registers.
This is not fit, routing, TimeQuest, a complete cache, or a core-area/timing
result.

`make quartus-fetch-smoke` runs warning-free Analysis & Synthesis for the
packet assembler and generated decoder. Its observability wrapper uses 343
logic cells and 174 registers. This is not fit, routing, TimeQuest, a complete
frontend, or a core-area/timing result.

## Explicitly absent

There is a serialized RTL instruction-start/fetch cursor, but no integrated
cache/frontend top, opcode-to-execution composition, timing sequencer,
retirement boundary derived from processor state, interrupt logic, complete
memory access, page mode, complete bus-fault/retry subsystem, host interface,
multiprocessor interface, coprocessor interface, display subsystem,
original-pin bus, or game wrapper. The standalone cache leaf has transaction
completion outcomes, but no pin-level decoder, fault registers, interrupt
entry/return, or dynamic-width/page-mode memory controller.
The register-execution module emits combinational write *intents*. The bounded
commit composition can apply those intents to its private register/ST state,
but only when an external controller asserts `commit_i`; it does not fetch,
advance PC, schedule, overlap, stall, retry, interrupt, or supply architectural
timing. Its presence therefore does not constitute an executable processor
core. In particular, the EXGPS leaf does not implement the documented hidden
internal-I/O write cycle and is not routed through this composition.
