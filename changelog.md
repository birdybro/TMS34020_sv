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
- A bounded scalar composition that admits 23 verified one-word packets,
  complete two-word ADDI.W/CMPI.W/SUBI.W, and complete three-word
  ANDNI/ORI/XORI/ADDXYI/ADDI.L/CMPI.L/SUBI.L packets to A/B/SP and ST commit and
  exposes every other packet as blocked.
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
- Replaced the earlier narrow INC-only canonical decode with its full ADDK
  family after the primary INC page proved it is an alternate mnemonic for
  `ADDK 1,Rd`; no overlapping decode or expectation weakening was introduced.
- Replaced the earlier narrow DEC-only canonical decode with its full SUBK
  family after the primary DEC page proved it is an alternate mnemonic for
  `SUBK 1,Rd`; no overlapping decode or expectation weakening was introduced.

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
- ADDXYI now passes complete-packet gating, independent X/Y half addition,
  full NCZV replacement, A/B selection, shared-SP commit, and dependent fetched
  packet tests. Requalified Quartus wrappers report 5,681 leaf logic cells and
  3,598 scalar logic cells, with zero errors/warnings.
- Extracted collision-free ADDI.W and ADDI.L records from TI printed
  pp.13-35..13-36. The partial ISA now contains 40 records covering 6,672 first
  words, and the independent model covers 34 forms with signed-word extension,
  every TI example row, long-immediate alignment, A/B selection, and SP alias
  tests.
  Decoder-only requalification reports 5,685 leaf and 3,600 scalar logic cells
  with zero Quartus errors/warnings; ADDI execution was still blocked at that
  extraction checkpoint.
- ADDI.W and ADDI.L now pass complete-packet gating, word sign extension,
  32-bit addition, full NCZV replacement, A/B selection, shared-SP commit,
  incomplete-packet rejection, and dependent mixed-length fetched-packet
  tests. Requalified Quartus wrappers report 5,850 leaf logic cells and 3,696
  scalar logic cells with zero errors/warnings.
- Extracted collision-free SUBI.W and SUBI.L records from TI printed
  pp.13-243..13-244. The partial ISA now contains 42 records covering 6,736
  first words, and the independent model covers 36 forms with complemented
  object words, every arithmetic example row, short/long timing cases, borrow
  and overflow, and SP aliasing. At that extraction checkpoint, the scalar
  regression proved SUBI.W decoded but noncommitting. Warning-free Quartus
  requalification reported 5,859 leaf, 350 fetch, 723 frontend, and 3,679
  scalar logic cells.
- SUBI.W and SUBI.L now pass complete-packet gating, complemented object-word
  recovery, word sign extension, 32-bit subtraction, borrow and overflow,
  full NCZV replacement, A/B selection, shared-SP commit, incomplete-packet
  rejection, and dependent fetched-packet tests. Requalified Quartus wrappers
  report 6,015 leaf logic cells and 3,817 scalar logic cells with zero
  errors/warnings.
- Extracted collision-free CMPI.W and CMPI.L records from TI printed
  pp.13-81..13-82. The partial ISA now contains 44 records covering 6,800
  first words, and the independent model covers 38 forms with complemented
  object words, all twenty primary example rows, A/B and shared-SP reads,
  nondestructive state traces, full NCZV replacement, and short/long alignment
  cases. The scalar regression proves a complete decoded CMPI.W packet remains
  noncommitting. Warning-free decoder requalification reports 6,028 leaf, 348
  fetch, 735 frontend, and 3,792 scalar logic cells.
- CMPI.W and CMPI.L now pass complete-packet gating, complemented object-word
  recovery, word sign extension, nondestructive A/B/shared-SP reads, full NCZV
  replacement, incomplete-packet rejection, and dependent fetched-packet
  tests. Requalified Quartus wrappers report 6,040 leaf logic cells and 3,814
  scalar logic cells with zero errors/warnings.
- Canonicalized the complete ADDK range from TI printed p.13-37 while retaining
  INC as the documented K=1 alias from p.13-134. The 44-record database now
  covers 7,792 first words; 63 model tests cover all ADDK and INC example rows,
  A/B/SP selection, K=31, and encoded-zero K=32. RTL and fetched-packet tests
  cover the alias plus encoded-zero shared SP. Warning-free Quartus reports
  6,034 leaf, 344 fetch, 725 frontend, and 3,805 scalar logic cells.
- Canonicalized the complete SUBK range from TI printed p.13-245 while retaining
  DEC as the documented K=1 alias from p.13-94. The 44-record database now
  covers 8,784 first words; 66 model tests cover every SUBK and DEC example
  row, every K value, A/B/SP selection, K=31, and encoded-zero K=32. RTL and
  fetched-packet tests cover every K value, the alias, and encoded-zero shared
  SP. Warning-free Quartus reports 5,913 leaf, 344 fetch, 722 frontend, and
  3,744 scalar logic cells.
- Extracted the complete MOVK family from TI printed p.13-169 and timing-table
  p.15-6. The 45-record database covers 9,808 first words, and 68 model tests
  cover every K value, the four published examples, A/B/shared-SP selection,
  encoded-zero K=32, and complete ST preservation. The generated decoder
  recognizes all 1,024 MOVK words while leaf and scalar tests prove MOVK remains
  blocked and non-mutating at this extraction-only RTL checkpoint.
  Warning-free Quartus reports 5,867 leaf, 347 fetch, 721 frontend, and 3,722
  scalar logic cells.
- MOVK now passes RTL write-intent and atomic-commit checks for every K value,
  A/B selection, encoded-zero shared SP, and complete ST preservation. A fetched
  packet commits K=32 without changing live status. Warning-free Quartus
  requalification reports 5,915 leaf and 3,747 scalar logic cells; the unchanged
  fetch/frontend wrappers remain 347 and 721 logic cells.
- Extracted MOVI.W and MOVI.L from TI printed pp.13-167..13-168. The 47-record
  database covers 9,872 first words, and 70 model tests cover all published
  rows, short sign extension, A/B/shared-SP selection, C preservation, the
  resolved Z/V behavior, and aligned/unaligned long timing. Complete decoded
  MOVI packets remain blocked at this extraction-only RTL checkpoint.
  Warning-free Quartus reports 5,926 leaf, 363 fetch, 734 frontend, and 3,751
  scalar logic cells.
- Routed complete MOVI.W/L packets through atomic A/B/shared-SP commit.
  Directed RTL covers short sign extension, long-word assembly, primary
  example values, incomplete-packet rejection, and masked N/Z/V replacement
  with C preservation. The scalar composition fetches and commits both forms.
  Warning-free Quartus requalification reports 6,025 leaf and 3,810 scalar
  logic cells; fetch/frontend logic is unchanged.
- Extracted and modeled MOVX/MOVY from TI printed pp.13-170..13-171. The
  49-record database covers 10,896 first words; 72 model tests cover all TI
  rows, same-file A/B operation, shared SP, unchanged halves, same-register
  operation, and complete ST preservation. The decoded instructions remain
  blocked at this extraction-only RTL checkpoint. Warning-free Quartus reports
  5,939 leaf, 361 fetch, 740 frontend, and 3,792 scalar logic cells.
- Routed MOVX/MOVY through the register executor and atomic state commit.
  Directed RTL verifies low/high half replacement, retained destination halves,
  same-file A/B selectors, shared-SP source selection, dependent packet
  execution, and complete ST preservation. Warning-free Quartus
  requalification reports 6,071 leaf and 3,865 scalar logic cells; the
  generated decode, fetch, and frontend hardware are unchanged.
- Extracted and modeled full-register MOVE from TI printed p.13-158. The
  50-record database covers 11,920 first words; 74 model tests cover every
  primary example row, same-file and both cross-file directions, shared SP,
  same-register operation, N/Z/V replacement, and C preservation. The current
  same-file RTL operand interface explicitly blocks MOVE at this extraction
  checkpoint. Warning-free Quartus reports 6,048 leaf, 359 fetch, 732 frontend,
  and 3,836 scalar logic cells.
- Routed full-register MOVE through independent source/destination file
  selectors and atomic state commit. Directed RTL covers same-file operation,
  both cross-file directions, shared SP, all primary result classes, dependent
  A-to-B/B-to-A commits, N/Z/V replacement, and C preservation. Warning-free
  Quartus requalification reports 6,037 leaf and 3,830 scalar logic cells; the
  generated decode, fetch, and frontend hardware are unchanged.
- Extracted and modeled the constant and register-count RL forms from TI
  printed pp.13-222..13-223. The 52-record database covers 13,456 first words;
  77 model tests cover every published row, all five count bits, count zero,
  same-file A/B operation, shared SP, same-register operation, one-state
  timing, C/Z replacement, and N/V preservation. RSC-0013 records and resolves
  the count-30 example's contradictory C digit from the same page's bit
  definition and result, corroborated by pinned MAME. RL remains blocked at
  this extraction-only RTL checkpoint. Warning-free Quartus reports 6,037
  leaf, 363 fetch, 742 frontend, and 3,838 scalar logic cells.
- Routed RL.K and RL.R through a dedicated rotate leaf, the register executor,
  and atomic state commit. Directed RTL covers all count boundaries, count
  zero, source-low-five register counts, same-file selectors, dependent
  execution, C/Z replacement, N/V preservation, and the RSC-0013 count-30
  interpretation. Warning-free Quartus requalification reports 6,520 leaf and
  4,129 scalar logic cells; registers and cache RAM are unchanged.
- Implemented independent SETCDP/SETCMP/SETCSP model behavior from the TI
  CONVxP field definition, Figure 12-20, and all instruction-page example
  rows. The 80-test model suite now covers 49/52 extracted forms, all three
  implied B-register/I/O-register mappings, one-/two-power and arbitrary
  pitch timing, status preservation, and the hidden write state. RSC-0014
  records that pinned MAME misencodes SETCDP and leaves SETCMP/SETCSP as stubs.
- Added a synthesizable shared SETC-pitch conversion leaf with exhaustive
  one-/two-power field-pair tests, all primary rows, arbitrary/sentinel cases,
  and explicit 4/6/3 visible-state outputs. The scalar opcodes remain blocked
  pending a verified hidden-I/O write owner. Warning-free Quartus
  requalification reports 6,804 leaf logic cells and 2,021 registers.
- Implemented the independent VLCOL success path as a full-width B9/COLOR1
  load to an explicit external VRAM color-latch state with nominal address
  zero, special status `0111b`, `2 (1)` timing, field-size independence, and
  unchanged ST. The 82-test model covers 50/52 extracted forms. Special-cycle
  fault/retry and RTL request ownership remain absent; RSC-0015 records that
  pinned MAME's VLCOL handler is a logging stub.

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
- Documented the exact 34-operation scalar admission set, blocked-packet
  contract, directed state dependencies, synthesis evidence, and timing
  non-claims.
- Recorded RSC-0009 for the SUBI.L example row that prints `NCZV=0001` despite
  a zero, non-overflowing result; the model follows the page's flag definitions
  and its other zero-result rows (`0010`).
- Recorded RSC-0012 for the MOVI.W page's swapped Z/V prose. The implementation
  follows that page's examples, the adjacent MOVI.L definition, and §4.1:
  result-derived N/Z, preserved C, and cleared V.

### Integration

- No board integration is implemented.

### Known Issues

- The architectural model and RTL cover only a small verified slice; modeled
  instruction fetch uses an untimed native cache transaction boundary, the
  bounded scalar composition accepts only 29 one-word, four two-word, and eight
  three-word operations, and every other packet blocks. There is no
  complete executable core, timed retirement, pin-level completion decoder,
  CPU fault controller, overlapped pipeline, or subsystem integration.
- Target-game chip markings, first-silicon history, and silicon errata remain
  unavailable; Revolution X A-silicon identification is an inference only.
- Yosys, SymbiYosys, and Icarus Verilog are not installed in the current local
  environment; Quartus Prime Lite 17.0 and Verilator are available.
