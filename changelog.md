# Changelog

## Unreleased

### Added

- Repository governance, stable milestone backlog, contribution policy, project
  layout, command surface, and machine-checkable foundation validation.
- Honest progress, verification, synthesis, confidence, and game-integration
  status reports.
- Reproducibly pinned TMS34010 reference, full initial module-level reuse
  classification, empty copied-file provenance ledger, and reuse/core
  architecture ADRs.
- Hash-pinned TI/MAME reference manifest with safe fetch, verify, and missing
  source reporting tools; copyrighted payloads remain untracked.
- Source-cited device scope, five-variant matrix, and target-game identification
  record with mechanical checks against missing categories and readiness
  overclaims.
- A 50-entry machine-readable TMS34010/TMS34020 delta ledger and human
  architectural crosswalk covering cache, bus, faults, interfaces, graphics,
  display, reset, clocks, compatibility, and A-revision clock stretch.
- The first primary-page-verified ISA database slice, deterministic query
  library, independent opcode fixtures, and a collision sweep across all 65,536
  first words.
- An independent bit-addressed architectural-model slice with A/B/SP aliasing,
  reset-vector handling, deterministic randomized state and replay, traces, and
  verified NOP/IDLE/MWAIT/ADDXYI/CMPK/EXGPS/GETPS/RMO/RPIX execution.
- A generated partial SystemVerilog decoder, dual-read A/B/SP register file,
  ADDXYI arithmetic leaf, RPIX replication/timing leaf, and a self-checking
  Verilator testbench with an explicit pass marker.
- A Cyclone V leaf-only Quartus project and warning-enforcing Analysis &
  Synthesis runner.
- Primary-page-verified CMPK, EXGPS, GETPS, and RMO ISA entries, model
  execution, generated decode, RTL semantic leaves, and directed tests.
- A hash-pinned official SPVU015C TMS340 Interface guide and separate missing
  records for the SPVU004 and SPVU020 code-generation-tool guide editions.
- Primary-page-verified ABS, NEG, NEGB, and NOT ISA/model/RTL semantics with
  explicit partial status-write masks and every TI example row as a test.
- Primary-page-verified ADD, ADDC, SUB, SUBB, and CMP decode/model/RTL
  semantics with explicit 33-bit carry, borrow, and overflow handling.
- A primary-cited 32-bit ST state owner with verified reset, documented field
  constants, reserved-bit mask, and partial masked updates.
- A decoder-controlled combinational register-execution router for twelve
  one-word instructions, with explicit operand selectors and register/ST write
  intents but no retirement or timing claim.
- Primary-page-verified CLRC, DINT, EINT, GETST, INC, DEC, and SETC database,
  model, generated-decode, and RTL write-intent paths.
- An externally gated register/ST commit composition for the nineteen verified
  one-word register operations, with explicit write-event observability and no
  pipeline or timing claim.
- Primary-page-verified AND, ANDN, OR, and XOR database, model, generated
  decode, Z-only RTL logical leaf, register-execution routing, and state commit.
- Primary-page-verified ANDNI/ANDI-alias, ORI, and XORI three-word decode and
  independent-model semantics, including extension alignment timing.
- A transaction-level independent instruction-cache model with documented
  address partitioning, all refill rotations, segment/subsegment misses,
  move-to-front LRU, `CD` preservation, `CF` flush, noncoherence, current-cycle
  retry, bus-fault pause/resume, abort, and deterministic pending replay.
- Architectural-model opcode and extension fetch through the cache model, with
  per-step lookup/native-read traces, I/O-controlled disable/flush, cache-aware
  snapshot replay, full rollback on failed steps, and explicit incomplete
  timing on a miss or bypass.
- A synthesizable bounded instruction-cache leaf with four-segment lookup,
  demand-long-word-last refill, move-to-front LRU, delayed present-bit commit,
  `CD` bypass, idle `CF` flush, decoupled successful native reads, and stable
  requests/responses under backpressure.
- Self-checking Verilator and Cyclone V Analysis & Synthesis commands for the
  bounded cache slice.
- A cache-native completion protocol in which absent response represents wait,
  retry reissues only the current beat, fault pauses it for external resume or
  abort, and abort signals cancellation without exposing partial refill data.
- Signal-level documentation for the bounded cache lookup, native read,
  completion, fault-control, reset, and cache-control interfaces.
- A deterministic randomized cache-native testbench and three-seed runner with
  address-derived data checking, randomized backpressure/latency/completions,
  explicit coverage counters, replayable plusargs, and ignored failure logs.
- A synthesizable serialized instruction-packet fetch block with aligned
  PC-load/redirect, one-to-five-word cache assembly, per-word cache metadata,
  invalid-word isolation, explicit completion gating, and abort-to-reload.
- Self-checking Verilator and warning-enforcing Cyclone V synthesis commands
  for the bounded instruction-fetch slice.
- A portable cache/fetch frontend with native memory and fault controls, plus
  integrated Verilator and Cyclone V synthesis qualification.
- A bounded scalar composition that admits 23 verified one-word packets plus
  complete ANDNI/ORI/XORI packets to A/B/SP and ST commit and exposes every
  other packet as blocked.
- Self-checking scalar-composition and warning-enforcing Cyclone V synthesis
  commands.

### Changed

- Expanded the initial one-line README into an evidence and build-oriented
  project introduction.
- Verilator lint and verified-leaf runners now fail on emitted warnings even
  when `--Wno-fatal` allows the tool process itself to return success.

### Fixed

- Model instruction errors roll back PC and all other state instead of leaving a
  partially committed checkpoint.
- The Quartus qualification digest now keeps ADDXYI flags and both register-file
  read ports observable through synthesis.
- The model now carries EXGPS's documented hidden PSIZE write state and
  overlaps it with subsequent execution states.
- Removed a stale one-bit padding field from the Quartus observability digest
  after the generated opcode enum grew to six bits; the warning-enforcing first
  synthesis run caught the resulting 33-to-32-bit truncation.
- Refactored the cache data-array access into an inference-friendly synchronous
  RAM path after synthesis review showed the initial form was implemented in
  logic; Quartus now maps the 128×32 array to 4,096 block-memory bits.

### Verified

- The working directory is the existing clean `birdybro/TMS34020_sv` clone on
  `main`; no nested repository was created.
- The requested TMS34010 baseline commit exists on its upstream `main` branch.
- The baseline commit/tree metadata and MIT license are preserved; every
  upstream RTL and simulation-model module is named in the reuse audit.
- Verified local SHA-256 values for seven TI documents and the pinned eleven-file
  MAME TMS34020 source set.
- Verified SPVS004D's bounded original-to-A delta: CONFIG.CSE clock stretching,
  reset disabled, with no unsupported ISA or subsystem differences asserted.
- Verified the documented commercial 32 MHz options and the A-only commercial
  40 MHz option; exact production-game top markings remain explicitly unknown.
- Verified the initial 11 decoder entries, ADDXYI leaf semantics, all legal
  RPIX replication sizes/state counts, and A/B/SP aliasing with Verilator.
- Expanded the collision-free ISA slice to 15 entries covering 1,676 first
  words and verified all current generated decoder entries in RTL.
- Expanded the collision-free ISA slice to 19 entries covering 1,804 first
  words and the independent model to 13 instructions.
- Expanded the collision-free ISA slice to 24 entries covering 4,364 first
  words and the independent model to 18 instructions.
- Quartus Prime Lite 17.0.2 Cyclone V Analysis & Synthesis passes for the
  implemented leaf slice with zero errors and zero warnings. This is not a
  fitter or timing-closure result.
- Verilator verifies instruction-controlled NOP, unary, binary-arithmetic,
  CMPK, and RMO write intents, including partial status masks and unsupported
  decode rejection; Quartus synthesizes the expanded leaf slice to 2,414 logic
  cells with zero errors and zero warnings.
- Expanded the collision-free ISA slice to 31 entries covering 4,464 first
  words and the independent model to 25 instructions. All TI example rows for
  CLRC, DINT, EINT, GETST, INC, DEC, and SETC are represented.
- Verilator verifies the seven new register/status write-intent paths; Quartus
  synthesizes the expanded leaf slice to 2,689 logic cells with zero errors and
  zero warnings.
- Verilator verifies thirteen ordered state-commit sequences, including
  preceding-state dependencies, shared-SP access, masked ST changes,
  nondestructive CMP, NOP acceptance, and unsupported-operation rejection.
  Quartus synthesizes the expanded diagnostic wrapper to 5,298 logic cells and
  2,021 registers with zero errors and zero warnings; duplicate raw and
  integrated state instances make this unsuitable as a core-area estimate.
- Expanded the collision-free ISA slice to 35 entries covering 6,512 first
  words and the independent model to 29 instructions. All 21 TI
  register-logical example rows pass in the model; Verilator checks the four
  leaf/router/commit paths. Quartus synthesizes the diagnostic wrapper to 5,481
  logic cells and 2,021 registers with zero errors and zero warnings.
- Expanded the collision-free ISA slice to 38 entries covering 6,608 first
  words and the independent model to 32 instructions. All 16 TI
  immediate-logical example rows and an ANDI complement-encoding fixture pass;
  RTL verifies three-word decode and rejection at the one-word router boundary.
  Quartus synthesizes the diagnostic wrapper to 5,504 logic cells with zero
  errors and zero warnings.
- Verilator verifies the bounded cache's successful refill/bypass path, refill
  ordering, lookup classifications, delayed present-bit commit, four-segment
  LRU behavior, controls, and backpressure. Quartus synthesizes it with zero
  errors/warnings to 361 logic cells, 198 registers, and 4,096 block-memory
  bits. No fault, retry, fit, or timing result is implied.
- Verilator verifies current-beat retry and fault-resume at all four refill
  indices, bypass retry/fault, abort after a partial refill, complete restart
  after abort, bypass abort, and no present-bit commit from retry/fault/abort.
  Reset is injected in the request and waiting-response states of every refill
  index. Four enabled runtime SVAs check stalled payloads, present safety, and
  fault quiescence without being represented as formal proof. Quartus retains
  the 4,096-bit inferred RAM and synthesizes the expanded controller to 375
  logic cells and 200 registers with zero errors/warnings.
- Three deterministic randomized seeds pass 396 fetches and 1,226 accepted
  native requests, including 36 retries, 83 faults, and 43 aborts, without
  weakening the warning or assertion gates.
- The bounded packet fetch passes directed NOP/ORI/unclassified/abort/wrap and
  backpressure tests plus four runtime assertions; Quartus synthesizes the
  diagnostic wrapper to 343 logic cells and 174 registers with zero
  errors/warnings.
- The integrated frontend passes cold-refill, cache-hit extension, bypass
  retry, fault-abort, PC-reload, and cache-preservation tests; Quartus retains
  4,096 block-memory bits and reports 709 logic cells/372 registers with zero
  errors/warnings.
- Initial scalar qualification established nine dependent bypass commits,
  stable noncommit for BLMOVE and then-unsupported three-word ORI, and eight
  cache-fed commits after four refill reads. Three runtime assertions enforced
  admission/noncommit safety; Quartus reported 3,444 logic cells, 1,357
  registers, and 4,096 block-memory bits with zero errors/warnings.
- Complete ANDNI/ORI/XORI packets now pass packet-length gating, A/B operand
  selection, Z-only status updates, atomic commit, and an integrated dependent
  ORI-to-XORI sequence. Incomplete ANDNI and unclassified packets cannot write.
  Requalified Quartus wrappers report 5,583 leaf logic cells and 3,512 scalar
  logic cells, with zero errors/warnings.

### Documentation

- Defined evidence precedence, TMS34010 reuse constraints, coding/CDC/synthesis
  rules, completion claims, and current architectural risks.
- Distinguished TMS34020, TMS34020A, SMJ34020, SMJ34020A, and SM34020A without
  substituting later high-reliability data sheets for the original user guide.
- Extracted the primary-source instruction-cache organization, bit-address
  mapping, LRU replacement, demand-longword-last refill order, reset state,
  `CD` preservation, `CF` flush, coherence limits, bounded timing facts, RTL
  boundary, verification matrix, and unresolved fault/pipeline interactions.
- Recorded and resolved the guide's overlapping cache address-bit ranges and
  erroneous four-present-flag cache-flush wording from same-guide figures and
  organization text.
- Extracted local-cycle completion codes, current-cycle-only retry,
  bus-fault save/restore, page-mode fault restrictions, and dynamic 16-bit
  restart boundaries into a primary-cited memory contract.
- Documented unresolved opcode/status/timing, CONTROL2, errata, and
  first-silicon questions as unknown rather than assigning inferred behavior.
- Recorded a pinned MAME disassembler discrepancy: TI's TRAPL consumes a signed
  extension word, but the secondary path does not advance over it.
- Recorded a second pinned MAME disassembler discrepancy: its broad masks label
  nonzero low-bit neighbors of fixed NOP/CLRC/DINT/EINT/SETC encodings, while
  TI fixes bits 4–0 to zero.
- Documented the first synthesizable RTL boundary and its explicit exclusions;
  deterministic FPGA register clearing is not represented as silicon behavior.
- Documented the bounded commit contract: a future sequencer owns the real
  architectural completion boundary, stalls, faults, interrupts, and timing.
- Documented the successful-read cache RTL boundary, deterministic private tag
  validity, native-interface convention, active-refill flush uncertainty, and
  exact exclusions from cache/timing claims.
- Refined the cache boundary from successful-only reads to explicit internal
  success/retry/fault completion outcomes while keeping pin encodings, CPU fault
  state, interrupt handling, dynamic width, page mode, and cycles unclaimed.
- Recorded the SPVU004/SPVU020 tool-guide catalog evidence and lawful search
  result without treating secondary GSPA notes as a syntax specification.
- Recorded and resolved the ORI instruction-page alignment wording error
  against the same guide's chapter 15 timing table.
- Extracted the primary PC alignment/advance, branch redirect, reset-vector,
  GETPC/EXGPC, IDLE, interrupt-checkpoint, cache/execute overlap, read
  serialization, hidden-write, and chapter 15 timing-assumption contracts.
- Defined a bounded instruction-packet/fetch-cursor vocabulary separately from
  undocumented physical pipeline stages and from TMS34020 machine-state timing.
- Documented the implemented packet-fetch signals, state progression,
  assertions, test evidence, synthesis boundary, and explicit lack of
  fetch/execute overlap or cycle qualification.
- Documented the composed cache/fetch path, native completion coverage, and
  remaining execution/timing boundary.
- Documented the exact 26-operation scalar admission set, blocked-packet
  contract, directed state dependencies, synthesis evidence, and timing
  non-claims.

### Integration

- No board integration is implemented.

### Known Issues

- The architectural model and RTL cover only a small verified slice; modeled
  instruction fetch uses an untimed native cache transaction boundary, the
  bounded scalar composition accepts only 23 one-word and three
  immediate-logical operations, and every other packet blocks. There is no
  complete executable core, timed retirement, pin-level completion decoder,
  CPU fault controller, overlapped pipeline, or subsystem integration.
- Target-game chip markings, first-silicon history, and silicon errata remain
  unavailable; Revolution X A-silicon identification is an inference only.
- Yosys, SymbiYosys, and Icarus Verilog are not installed in the current local
  environment; Quartus Prime Lite 17.0 and Verilator are available.
