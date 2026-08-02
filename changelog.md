# Changelog

## Unreleased

### Added

- Three primary-page-extracted register-to-memory MOVB forms at 8C00h,
  AC00h, and 05E0h, covering 1,056 first words, fixed-eight-bit semantics,
  indirect/signed-offset/absolute address ordering, ST preservation, primary
  visible/hidden timing, and compatible TMS34010 boundaries.
- Exhaustive little-endian architectural byte-store tests and a clean-room
  fixed-byte RTL leaf covering every byte value/offset, A/B/SP alias capture,
  signed wrap, absolute word order, alignment classes, and explicit noncommit
  without a memory owner.
- Four primary-page-extracted absolute-address field MOVE forms at
  0580h/05A0h/D400h/05C0h, covering 194 first words, low-then-high source and
  destination extension order, FE/status, destination postincrement,
  read-before-write overlap, first-extension alignment timing, and compatible
  TMS34010 semantic bounds.
- Little-endian architectural absolute field-store/load/copy traces with
  exhaustive bank/FE/width/source/destination geometry, all timing pairs,
  A/B/SP, exact 32-bit address word order, overlap, wrap, and atomic BEN
  rejection.
- A clean-room low-word/high-word absolute bit-address leaf whose RTL tests
  independently exhaust every possible low and high half.
- Primary-page-extracted `MOVE *Rs(offset),*Rd+[,F]` as internal
  MOVE.MM.SOFF_POST at D000h/FC00h, covering 1,024 first words, signed source
  displacement, original destination address, post-write destination update,
  unchanged ST, all A–H timing cases, and compatible TMS34010 semantics.
- Little-endian architectural mixed-address field-copy traces with exhaustive
  bank/width/source/destination geometry, every alignment pair, signed
  immediate boundaries, A/B/SP alias, overlap, destination wrap, and atomic
  BEN rejection.
- A clean-room source-offset/destination-postincrement address leaf whose RTL
  test covers all 65,536 signed displacements, all field-size encodings, alias,
  and wrap.
- Primary-page-extracted signed-offset MOVE.RM/MR/MM forms at B000h/B400h/
  B800h, covering 3,072 first words, source/destination extension-word order,
  modulo-2^32 bit-address addition, unchanged bases, status effects, five-case
  timing, and compatible TMS34010 semantic bounds.
- Little-endian architectural signed-offset field-store/load/copy traces with
  exhaustive bank/FE/width/source/destination geometry, all alignment pairs,
  signed immediate boundaries, A/B/SP alias, overlap, wrap, status and atomic
  BEN rejection.
- A clean-room signed-16 effective-address leaf whose RTL test exhausts all
  65,536 displacements and both wrap directions.
- Primary-page-extracted register-to-memory, memory-to-register, and paired
  memory-to-memory predecrement MOVE forms as internal MOVE.RM.PRE,
  MOVE.MR.PRE, and MOVE.MM.PRE, covering 3,072 words, before-operation pointer
  ordering, explicit load alias priority, twice-decremented paired aliasing,
  status effects, five-case timing, and compatible TMS34010 semantic bounds.
- Little-endian architectural predecrement field-store/load/copy traces with
  exhaustive bank/FE/width/source/destination geometry, every alignment pair,
  A/B/SP alias, overlap, pointer wrap, status and atomic BEN rejection.
- A clean-room paired-predecrement effective/final address leaf with exhaustive
  size, distinct/alias and wrap verification.
- RSC-0038 records why the pinned TMS34010 RTL's once-decremented paired alias
  writeback is not reusable for TMS34020, whose primary guide explicitly
  requires a twice-decremented final pointer.
- Primary-page-extracted `MOVE *Rs+,*Rd+[,F]` as internal MOVE.MM.POST,
  covering all 1,024 words, distinct pointer updates, TI-defined same-register
  incremented destination, selected twice-incremented final shared pointer,
  unchanged ST, all A–H timing cases, and compatible TMS34010 semantic bounds.
- A clean-room paired-postincrement effective/final address leaf with exhaustive
  size, distinct/alias and wrap verification.
- RSC-0037/OQ-0025 for the paired-postincrement final aliased-pointer conflict:
  TI's operation sequence and pinned MAME apply two logical increments, while
  the pinned TMS34010 RTL suppresses the second writeback.
- Little-endian architectural MOVE.MM.POST read/write traces with exhaustive
  bank/width/source/destination geometry, pointer updates, overlap/alias/wrap,
  and atomic BEN rejection.
- Primary-page-extracted `MOVE *Rs+,Rd[,F]` as internal MOVE.MR.POST,
  covering all 1,024 words, captured-address field load, source-pointer update,
  FE extension, status, five alignment classes, and compatible TMS34010
  semantic bounds.
- Little-endian architectural MOVE.MR.POST traces with exhaustive bank/FE/
  width/offset geometry, A/B/SP, pointer wrap, same-register data priority,
  and atomic BEN rejection.
- Primary-page-extracted `MOVE Rs,*Rd+[,F]` as internal MOVE.RM.POST,
  covering all 1,024 words, captured-address store ordering, field-size pointer
  update, unchanged ST, five alignment classes, hidden writes, and compatible
  TMS34010 semantic bounds.
- Little-endian architectural MOVE.RM.POST traces with exhaustive bank/width/
  offset geometry, A/B/SP and Rs=Rd capture, pointer wrap, and atomic BEN
  rejection.
- A clean-room ordinary/postincrement/predecrement field-address-update leaf
  with exhaustive size/mode/wrap verification and invalid dual-mode reporting.
- Primary-page-extracted `MOVE *Rs,*Rd[,F]` as internal MOVE.MM, covering all
  1,024 words, unchanged ST/register behavior, complete read-before-write,
  all 25 source/destination alignment pairs, timing, and compatibility bounds.
- Little-endian architectural MOVE.MM logical read/write traces with exhaustive
  bank/width/source/destination geometry, overlap ordering, and atomic BEN
  rejection.
- A clean-room two-source/two-destination-word MOVE.MM copy/timing leaf with
  exhaustive geometry and explicit noncommit without a memory sequencer.
- Primary-page-extracted `MOVE *Rs,Rd[,F]` as internal MOVE.MR, covering all
  1,024 words, FS/FE selection, extension/status behavior, five alignment
  cases, timing, alias ordering, and TMS34010 compatibility boundaries.
- Little-endian architectural MOVE.MR field reads with logical traces, exact
  N/C/Z/V behavior, exhaustive geometry/extension tests, and atomic BEN
  rejection.
- A clean-room two-long-word MOVE.MR extraction/extension/timing leaf with
  explicit noncommit while the physical memory owner is absent.
- Primary-page-extracted `MOVE Rs,*Rd[,F]` as the internal MOVE.RM family,
  covering all 1,024 words, both field banks, five alignment cases, BEN timing,
  pending writes, and compatibility boundaries.
- Little-endian architectural MOVE.RM field insertion with logical write
  traces, hidden-state accounting, adjacent-bit preservation, and atomic BEN
  rejection.
- A clean-room combinational two-long-word MOVE.RM store leaf with exhaustive
  size/offset insertion and alignment classification; register/memory commit
  remains outside the leaf.
- Primary-page-extracted TMS34020-only RETM `0860h` metadata with shared
  normal/IX/BF frames, 10/38/52-state cases, full next-instruction direct-
  memory fetch, and one-instruction interrupt/single-step recognition delay.
- RETM normal-context model execution with version-3-snapshotted one-shot
  packet bypass, rollback-safe consumption, a stale three-word cache
  discriminator, and atomic IX/BF rejection.
- RETI/RETM mode outputs in the clean-room return-control leaf, including
  RETM normal timing, full-packet bypass intent and interrupt-recognition delay
  intent while architectural ownership remains blocked.
- Primary-page-extracted exact RETI `0940h` metadata with ordinary and IX/BF
  saved-context contracts, ordered stack reads, complete ST/PC/SP effects,
  restored-IE checkpoint, and documented 7/38/52-state cases.
- Independent normal-context RETI model semantics covering ordered ST/PC
  reads, complete status/IE restoration, saved-PC alignment, SP wrap, a
  TRAP/RETI round trip, and atomic rollback for unsupported IX/BF frames.
- A clean-room synthesizable RETI context-control leaf that classifies
  normal/IX/BF with BF priority, exposes 0/24/31 extra words and 7/38/52
  states, computes normal return results and saved-PC misalignment, and remains
  noncommitting until a stack/continuation sequencer exists.
- Primary-page-extracted MMFM `09A0h`/`FFE0h` and MMTM
  `0980h`/`FFE0h` metadata for all 64 first words, including deliberately
  opposite extension-mask directions, A/B/shared-SP rules, logical transfer
  order, page-mode/dynamic-width/fault obligations, status effects, and
  documented successful timing classes.
- Independent MMFM/MMTM model semantics covering exhaustive mask order, every
  A/B/SP register, pointer wrap, predecrement/postincrement ordering, exact
  MMTM N behavior, timing classes, deterministic transactions, round trip, and
  atomic rejection of empty or pointer-containing lists.
- A clean-room synthesizable multiple-register control leaf that exhaustively
  normalizes all 65,536 masks in both directions, counts and validates lists,
  computes final pointer/MMTM N, selects visible/hidden states, and remains
  explicitly noncommitting until a page-mode/fault-aware memory owner exists.
- A hash-pinned metadata record for the prior `srg320/TMS34020` FPGA source at
  commit `2046b4378e2e29ee1fe9ef0b6365987e95fa5c0c`. Its absent license and
  self-declared missing features make it untracked, reference-only, and
  prohibited from reuse; the generic GitHub source-set fetcher now supports
  this independently pinned repository.
- Primary-page-extracted SWAPF `7E00h`/`FE00h` metadata and an independent
  successful 32-bit-target model boundary covering every valid word-local FS0
  width/offset, FE0 extension, A/B/SP aliases, exact status, five base states,
  ordered abstract locked read/write traces, and atomic invalid-crossing
  rollback.
- A clean-room combinational SWAPF field-transform leaf with old-field
  extraction/extension, replacement-word construction, crossing validity,
  direct tests, Cyclone V smoke integration, and scalar noncommit guards
  pending a physical locked memory and atomic Rd/ST owner.
- Initial field-access and local-bus documents separating the verified SWAPF
  semantic boundary from unimplemented ordinary fields, lock arbitration,
  waits, faults/retries, dynamic sizing, I/O routing, host exclusion, and pins.
- Primary-page-extracted MPYS `5C00h`/`FE00h` and MPYU
  `5E00h`/`FE00h` metadata plus independent model semantics for every even FS1,
  signed/unsigned full products, even-pair/odd-low result placement,
  full-product status, capture-before-write aliases, and atomic rejection of
  undocumented odd FS1.
- A clean-room combinational multiply leaf with signed/unsigned field
  extension, 64-bit product, full-product N/Z, even-FS1 validity, provisional
  detailed-page state classification, direct tests, and explicit scalar
  noncommit guards pending pair-capable architectural ownership.
- Primary-page-verified MODS `6C00h`/`FE00h` and MODU
  `6E00h`/`FE00h` metadata plus independent model semantics for signed and
  unsigned 32-bit remainders, every published row, zero divisors,
  same-register/shared-SP aliases, TMS34020-specific status masks, and
  reachable documented state cases.
- A modulus mode in the clean-room 32-step restoring datapath, including
  signed remainder conditioning, quotient-overflow-with-valid-remainder,
  zero-divisor outcomes, direct status/result tests, and explicit scalar
  noncommit guards pending an architectural completion owner.
- Primary-page-verified DIVS `5800h`/`FE00h` and DIVU
  `5A00h`/`FE00h` metadata plus independent model semantics for odd 32/32 and
  even 64/32 register-pair forms, signed/unsigned quotient and remainder,
  A/B/shared-SP pairing, zero-divisor and range-overflow preservation,
  instruction-specific status changes, and documented selected state cases.
- A clean-room, portable 32-step restoring-divider RTL leaf with signed
  magnitude normalization, pair/single classification, early overflow and
  divide-by-zero outcomes, and direct handshake/result/status tests. Its FPGA
  step count is explicitly separate from architectural machine-state timing,
  and the scalar commit path remains blocked pending atomic pair ownership.
- Primary-page-verified CVDXYL `0A80h`/`FFE0h`, CVMXYL
  `0A60h`/`FFE0h`, CVSXYL `EA00h`/`FE00h`, and CVXYL
  `E800h`/`FE00h` metadata plus model semantics for signed coordinates,
  one-/two-power and arbitrary pitches, offsets, PSIZE, aliases, unchanged ST,
  and documented pitch-class state cases; CVXYL arbitrary pitch provisionally
  selects its instruction page's 14 states pending RSC-0026.
- A portable signed XY-to-linear arithmetic/classification RTL leaf with
  direct equation, pitch-class, modulo-wrap, timing-selection, and noncommit
  guard tests pending a complete implied-register/I/O owner.
- Primary-page-verified CPW `E600h`/`FE00h` metadata, all 16 published model
  rows, signed and inclusive boundary tests, A/B/shared-SP and implied B5/B6
  hazard coverage, V-only status behavior, and one-state execution.
- A portable signed-XY window-comparison RTL leaf with direct outcode/V tests,
  plus scalar-router noncommit protection until three-register capture and
  atomic destination/status ownership exist.
- Primary-page-verified CALL `0920h`/`FFE0h`, CALLA `0D5Fh`, and CALLR
  `0D3Fh` metadata plus independent successful model semantics. Tests cover
  every A/B/shared-SP CALL target, source capture before SP predecrement,
  aligned/unaligned hidden writes, CALLR signed extremes and PC wrap, CALLA
  low/high target order, exact return-PC writes, and complete ST preservation.
- Direct RTL noncommit guards for CALL base/end, CALLR, and CALLA pending an
  atomic stack-write/direct-PC/fault-retry owner.
- Primary-page-verified RETS `0960h`/`FFE0h` metadata and independent model
  semantics for all 32 argument counts, aligned/unaligned old SP, exact
  return-PC reads, PC alignment, SP wrap, complete status preservation, and
  documented 5/6-state cases.
- Direct RTL noncommit guards for RETS 0 and 31 pending a real stack-read,
  redirect-completion, and fault/retry owner.
- Primary-page-verified TRAP `0900h`/`FFE0h` metadata plus an independent model
  covering all 32 vectors, trap-zero no-save behavior, aligned/unaligned stack
  frames, exact transaction traces, PC wrap/alignment, complete ST replacement,
  and the documented 7/10/12-state cases.
- Direct RTL noncommit guards for TRAP 0 and 31 pending a real stack/vector
  sequencer, memory ownership, and fault/retry implementation.
- Primary-page-verified REV `0020h`/`FFE0h` device-identity metadata, its
  TMS34010/TMS34020 result and timing delta, exact A/B/SP decode fixtures, and
  explicit model rollback plus RTL noncommit guards pending an evidence-backed
  physical-device revision profile.
- RSC-0021 records that pinned MAME returns the TMS34010 `0000_0008h` identity
  for its TMS34020 class, while OQ-0014 tracks the target-game silicon result.
- Independent CMPXY model execution with explicit wrapped halfword
  differences, equality N/Z, result-sign C/V, nondestructive register behavior,
  all nine primary rows, borrow-distinguishing boundaries, A/B, same-register,
  shared-SP, and one-state tests.
- Synthesizable CMPXY execution leaf and status-only router/commit path with
  independent halfword difference signs, full NCZV replacement, destination
  preservation, A/B/shared-SP selection, cache-fed execution, and a dedicated
  runtime ownership assertion.
- Primary-page-verified CMPXY `E400h`/`FE00h` metadata, status semantics,
  one-state TMS34020 timing, TMS34010 `1,4` timing delta, independent
  base/end fixtures, and explicit model/RTL nonexecution guards ahead of
  implementation.
- Primary-page-verified CLR alias metadata and independent tests establishing
  that exactly the 32 same-number source/destination words in the existing XOR
  range spell CLR. The model and RTL tests cover every A/B register encoding,
  shared SP, one-state behavior, zero result, Z set, and N/C/V preservation
  without creating a colliding decoder entry.
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
- A hash-pinned 1988 TMS34010 User's Guide for primary compatibility
  cross-checks without treating it as a TMS34020 timing authority.
- Primary-page-verified ADDXY/SUBXY encodings and metadata from both processor
  guides, generated 7-bit decode identifiers, boundary fixtures, explicit RTL
  noncommit checks, and atomic model rollback guards.
- Primary-page-verified BTST.K/R encodings and metadata from both processor
  guides, including the complemented constant field, same-file register count,
  Z-only status behavior, TMS34020 one-state timing, independent opcode
  fixtures, exact model rollback guards, and explicit RTL noncommit checks.
- Independent BTST.K/R architectural-model semantics with all 25 primary input
  rows, complemented constant recovery, upper-source-bit truncation, Z-only
  status changes, A/B, same-register, and shared-SP tests; RSC-0018 records and
  corrects the one example-table status digit that contradicts its operands.
- A synthesizable BTST selected-bit leaf, complemented-constant and
  low-five-bit register routing, Z-only atomic commit with no destination
  write, shared-SP and dependent scalar tests, and a dedicated runtime safety
  assertion.
- Primary-page-verified SETF, SEXT, and ZEXT encodings, field-bank/size/status
  metadata, TMS34020 state counts, independent boundary fixtures, exact model
  rollback guards, and explicit RTL noncommit checks. A quantified delta
  records that the compatible TMS34010 instructions have different timing.
- Independent SETF/SEXT/ZEXT model semantics with all 32 encoded sizes in both
  field banks, the published result rows, exact instruction-owned ST updates,
  A/B destinations, shared-SP aliasing, and TMS34020-specific state counts.
- A synthesizable 1–32-bit field-extension leaf, SETF selected-bank status
  intents, SEXT/ZEXT register and partial-status commit, both field banks,
  shared-SP coverage, a dependent scalar sequence, and two runtime safety
  assertions.
- Primary-page-verified EXGF encoding, atomic field-bank/register exchange
  contract, conditional `F=0`/`F=1` TMS34020 timing, independent decode
  boundaries, and RSC-0019 for pinned MAME's field-one timing undercount.
- Independent EXGF model semantics reproducing both published rows and
  covering both field banks/files, ordinary/shared-SP destinations,
  upper-register clearing, nonselected-ST preservation, and TI's one-/two-state
  split.
- Synthesizable EXGF execution with simultaneous destination and selected-bank
  write intents, A/B/shared-SP routing, upper-register clearing, dependent
  two-bank scalar commits, and a runtime atomicity assertion. Architectural
  one-/two-state retirement timing remains unimplemented.
- Primary-page-verified PUTST encoding, full-width status-write contract,
  A/B/shared-SP boundaries, three-state timing, adjacent POPST nonaliasing, and
  explicit preimplementation model/RTL rollback boundaries.
- Independent PUTST model semantics with complete A/B/shared-SP source-to-ST
  transfer, source preservation, all-zero/all-one/mixed patterns, and the
  primary-documented three-state count.
- Synthesizable PUTST register-source routing and full-width masked ST commit,
  with ordinary A/shared-SP ordered dependencies, cache-fed execution, and a
  runtime assertion requiring status-only, nonredirecting ownership. The
  three-state architectural retirement remains unimplemented.
- Primary-page-verified POPST/PUSHST exact encodings, full-width stack/ST
  ordering, aligned/nonaligned visible and hidden state counts, explicit
  TMS34010 semantic compatibility/timing differences, and explicit RTL
  nonexecution boundaries pending stack-memory ownership.
- Independent POPST/PUSHST model semantics with full-width status transfers,
  old/new-SP ordering, aligned and unaligned timing, hidden PUSHST write
  accounting, bit-address wraparound, exact abstract data transactions, and
  round-trip coverage. Fault/retry and physical transfer decomposition remain
  unimplemented.
- Primary-page-verified JUMP encoding, A/B/shared-SP source selection, aligned
  indirect-PC redirect, two-state timing, adjacent GETPC/GETST boundaries, and
  TMS34010 semantic compatibility without timing-FSM reuse. Model and RTL
  began as explicit nonexecution boundaries at the extraction checkpoint.
- Independent JUMP model semantics reproducing all three TI target rows and
  covering both register files, shared SP, target alignment, complete source/ST
  preservation, next-PC traces, and the documented two-state count.
- Synthesizable JUMP direct-PC ownership with A/B/shared-SP target reads,
  low-nibble alignment, state-neutral commit, held frontend redirection, an
  EXGPC-to-GETPC-to-JUMP scalar dependency test, and a redirect-only runtime
  assertion. The documented two-state retirement remains unimplemented.
- Primary-page-verified DSJ, DSJEQ, and DSJNE encodings, signed 16-bit word
  displacements, condition-controlled decrement and relative redirect
  semantics, two-/three-state cases, TMS34010 semantic compatibility, generated
  decode, complete range-boundary fixtures, atomic model rollback guards, and
  explicit RTL packet noncommit checks.
- Primary-page-verified DSJS single-word encoding with independent direction,
  unsigned five-bit magnitude, A/B/shared-SP selection, instruction-relative
  range interpretation, two-/three-state timing, TMS34010 semantic
  compatibility, complete boundary fixtures, atomic model rollback guards, and
  explicit RTL packet noncommit checks.
- Primary-page-verified JAcc encoding with all 16 exact `C?80h` first words,
  low-word/high-word absolute target assembly, forced PC alignment,
  three-/four-state timing, TMS34010 semantic compatibility with different
  timing, exhaustive decode boundaries, and atomic model/direct/commit/
  cache-fed RTL nonexecution guards. RSC-0020 records the short-JR range text
  conflict at the `80h` escape.
- Independent JAcc model execution covering all 16 condition predicates, every
  possible false outcome, low-word/high-word absolute-target assembly, forced
  PC alignment, false-path PC wrap, exact instruction/next-PC traces, complete
  ST/register preservation, and documented three-/four-state cases.
- Synthesizable JAcc direct-PC ownership using both extension words, all 16
  NCZV predicates, forced target alignment, register/ST-neutral commit, held
  cache-fed taken/fallthrough completion, an exhaustive 256-cell condition
  matrix, and two runtime safety assertions. Architectural three-/four-state
  retirement remains unimplemented.
- Primary-page-verified long JRcc encoding with all 16 condition predicates,
  signed 16-bit word displacement, two-/three-state timing, TMS34010 semantic
  compatibility and distinct timing, exact `C?00h` decode, independent
  fixtures, atomic model rollback, and direct/commit/cache-fed RTL noncommit
  guards. Short JRcc remains deliberately unclassified pending an
  exclusion-capable decode representation.
- Independent DSJS model execution covering every published row, both
  directions, zero/max magnitudes, instruction-range endpoints, PC wrap,
  A/B/shared-SP selection, exact write traces, complete status preservation,
  and documented two-/three-state cases.
- Independent long-JR model execution covering all 16 condition predicates,
  every possible false outcome, signed displacement extremes, forward/backward
  PC wrap, exact instruction/next-PC trace fields, complete ST/register
  preservation, and documented two-/three-state cases.
- Synthesizable long-JR execution with a shared 16-condition NCZV predicate
  function, state-neutral true/false completion, exact signed word-relative
  targets, held cache-fed redirect/fallthrough paths, exhaustive 256-cell
  condition testing, displacement and PC-wrap boundaries, and two runtime
  safety assertions. Architectural two-/three-state retirement remains
  unimplemented.
- Synthesizable DSJS direct-PC execution with unconditional modulo-`2^32`
  destination decrement, status preservation, nonzero-result redirect,
  independent direction and unsigned-magnitude handling, held frontend target,
  A/B/shared-SP coverage, PC wrap, and two runtime safety assertions.
  Architectural two-/three-state retirement remains unimplemented.
- Independent DSJ/DSJEQ/DSJNE model execution covering all published rows,
  enabled and suppressed conditions, zero/wrapping decrements, signed
  displacement extremes, PC wrap, A/B/shared-SP selection, exact write traces,
  complete status preservation, and documented two-/three-state cases.
- Synthesizable DSJ-family execution ownership with a true 16-bit displacement
  port, condition-controlled atomic destination write, status neutrality,
  nonzero-result signed relative redirect, frontend target holding, integrated
  A-file execution, shared-SP commit coverage, and two runtime safety
  assertions. Architectural retirement timing remains unimplemented.
- Primary-page-verified LMO encoding metadata from both TMS34020 and TMS34010
  guides, generated decode, independent boundary fixtures, and a
  pre-implementation model rollback guard.
- Independent LMO architectural-model semantics with all five TI result rows,
  Z-only status updates, same-register prewrite behavior, B-file selection,
  and shared-SP source/destination coverage.
- Independent ADDXY/SUBXY architectural-model semantics with all 25 published
  rows, exact NCZV replacement, one-state accounting, B-file selection,
  same-register read-before-write, and shared-SP source/destination coverage.
- A shared synthesizable ADDXY/SUBXY independent-half arithmetic leaf, atomic
  register/NCZV routing, shared-SP commit coverage, and a dependent
  MOVK-to-ADDXY-to-SUBXY scalar sequence.
- A synthesizable LMO leading-priority leaf, Z-only atomic register/ST commit,
  cache-fed dependency sequence, and A/B/same-register/shared-SP RTL coverage.
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

- Expanded the generated partial decoder from 99 to 100 records and from
  30,612 to 31,124 uniquely classified first words.
- Expanded the generated partial decoder from 97 to 99 records and from
  29,588 to 30,612 uniquely classified first words.
- Expanded the generated partial decoder from 95 to 97 records and from
  28,564 to 29,588 uniquely classified first words.
- Expanded the generated partial decoder from 93 to 95 records and from
  27,540 to 28,564 uniquely classified first words.
- Expanded the generated partial decoder from 89 to 93 records and from
  26,452 to 27,540 uniquely classified first words.
- Expanded the generated partial decoder from 88 to 89 records and from
  25,940 to 26,452 uniquely classified first words.
- Expanded the generated partial decoder from 85 to 88 records and from
  25,906 to 25,940 uniquely classified first words without treating remaining
  unmatched words as reserved.
- Expanded the generated partial decoder from 84 to 85 records and from
  25,874 to 25,906 uniquely classified first words without treating remaining
  unmatched words as reserved.
- Factored the model's successful atomic TRAP/TRAPL boundary through one
  independently tested stack/vector helper while retaining their different
  immediates, trap-zero rule, instruction lengths, and traces.
- Expanded the generated partial decoder from 83 to 84 records and from
  25,842 to 25,874 uniquely classified first words.
- Expanded the generated partial decoder from 82 to 83 records and from
  25,810 to 25,842 uniquely classified first words without treating any
  remaining unmatched word as reserved.
- Expanded the initial one-line README into an evidence and build-oriented
  project introduction.
- ADDXYI now reuses the shared XY-add leaf, keeping its independently verified
  immediate packet behavior and status mapping unchanged.
- Verilator lint and verified-leaf runners now fail on emitted warnings even
  when `--Wno-fatal` allows the tool process itself to return success.

### Fixed

- Removed the unsupported claim that arbitrary-pitch CVXYL timing was exact:
  the instruction page specifies 14 states but the chapter-15 table specifies
  15. Both primary values are now machine-readable, the selected 14-state
  model/leaf behavior is explicitly provisional, and OQ-0017 tracks hardware
  or errata evidence.

- Corrected progress text that had overstated the machine-readable delta ledger
  as 65 entries; it contained 52 before this milestone and contains 53 after
  adding REV. The schema and all 37 mandatory feature names were already
  covered, so no test expectation or architectural entry was removed.
- Model instruction errors roll back PC and all other state instead of leaving a
  partially committed checkpoint.
- The Quartus qualification digest now keeps ADDXYI flags and both register-file
  read ports observable through synthesis.
- The model now carries EXGPS's documented hidden PSIZE write state and
  overlaps it with subsequent execution states.
- Removed a stale one-bit padding field from the Quartus observability digest
  after the generated opcode enum grew to six bits; the warning-enforcing first
  synthesis run caught the resulting 33-to-32-bit truncation.
- Rebalanced all decoder-bearing Quartus observability digests when the
  generated opcode identifier grew from six to seven bits, retaining every
  identifier bit without implicit truncation.
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

- The three extracted register-to-memory MOVB forms pass exhaustive model and
  RTL byte geometry, timing, address, decode-boundary, ST-preservation, BEN
  rollback, and direct-router noncommit checks.
- Warning-free Cyclone V Analysis & Synthesis reports 13,004 leaf logic
  cells/2,230 registers/9 DSP, 458 fetch logic cells, 831 frontend logic cells,
  and 5,459 scalar logic cells for the 124-entry decoder/fixed-byte-store
  revision. The frontend/scalar probes retain 4,096 block-memory bits. These
  are observability-wrapper analysis results, not fit, TimeQuest, or core-area
qualification.
- The 65-case ISA suite, 86-entry delta ledger, complete 206-case model
  regression, and decoder/leaf/integration RTL suites pass for the fixed-byte
  register-store milestone.
- The 62-case ISA suite, 83-entry delta ledger, complete 204-case model
  regression, and decoder/leaf RTL suite pass. All four absolute forms cover
  low/high address ordering, both field banks, every geometry/timing case,
  FE/status, A/B/SP, overlap, postincrement wrap, extension alignment and BEN
  rollback.
- Warning-free Cyclone V Analysis & Synthesis reports 12,843 leaf logic
  cells/2,230 registers/9 DSP, 451 fetch logic cells, 829 frontend logic cells,
  and 5,399 scalar logic cells for the 117-entry decoder/mixed-address
  revision. The frontend/scalar probes retain 4,096 block-memory bits. These
  are observability-wrapper analysis results, not fit, TimeQuest, or core-area
  qualification.
- The 58-case ISA suite, 79-entry delta ledger, complete 199-case model
  regression, and decoder/leaf RTL suite pass. Exact D000h/D3FFh
  boundaries, all signed-16 source offsets, every field-size encoding, complete
  little-endian field geometry, all 25 timing pairs, alias/overlap/wrap and BEN
  rollback are covered.
- Warning-free Cyclone V Analysis & Synthesis reports 12,826 leaf logic
  cells/2,230 registers/9 DSP, 453 fetch logic cells, 806 frontend logic cells,
  and 5,365 scalar logic cells for the 116-entry decoder/signed-offset revision.
  The frontend/scalar probes retain 4,096 block-memory bits. These are
  observability-wrapper analysis results, not fit, TimeQuest, or core-area
  qualification.
- The 57-case ISA suite, 78-entry delta ledger, and complete 197-case model
  suite pass. Exact two-/three-word decoder boundaries, all signed-16 RTL
  effective addresses, model immediate extremes/wrap/aliases/BEN rollback,
  complete little-endian field geometry, FE/status behavior and all 25 paired
  timing cases are covered.
- Warning-free Cyclone V Analysis & Synthesis reports 12,774 leaf logic
  cells/2,230 registers/9 DSP, 439 fetch logic cells, 804 frontend logic cells,
  and 5,365 scalar logic cells for the 113-entry decoder/predecrement revision.
  The frontend/scalar probes retain 4,096 block-memory bits. These are
  observability-wrapper analysis results, not fit, TimeQuest, or core-area
  qualification.
- The 54-case ISA suite, 75-entry delta ledger, and 193-case model suite pass.
  All three predecrement families exhaust both banks, every width/offset,
  pointer ordering, exact logical traces and BEN rollback; the load exhausts
  FE/status behavior and the paired copy exhausts all 1,024 source/destination
  offsets and 25 timing pairs. Exact decoder boundaries, paired-address leaf
  arithmetic, and memory-owner noncommit pass.
- Warning-free Cyclone V Analysis & Synthesis reports 12,771 leaf logic
  cells/2,230 registers/9 DSP, 429 fetch logic cells, 806 frontend logic
  cells, and 5,367 scalar logic cells for the 110-entry decoder/paired-
  postincrement revision. The frontend/scalar probes retain 4,096 block-memory
  bits. These are observability-wrapper analysis results, not fit, TimeQuest,
  or core-area qualification.
- The 51-case ISA suite, 72-entry delta ledger, and 187-case model suite pass.
  MOVE.MM.POST exhausts both banks, every width and 1,024 source/destination
  offsets, all 25 timing pairs, A/B/SP, overlap, pointer wrap, once-incremented
  alias destination and selected twice-incremented final shared pointer, exact
  traces, unchanged ST and BEN rollback. The final alias pointer remains
  CORROBORATED under RSC-0037/OQ-0025.
  Its paired-address leaf exhausts all sizes in distinct and alias modes; exact
  decoder boundaries and memory-owner noncommit pass.
- Warning-free Cyclone V Analysis & Synthesis reports 12,582 leaf logic
  cells/2,230 registers/9 DSP, 438 fetch logic cells, 809 frontend logic
  cells, and 5,354 scalar logic cells for the 109-entry decoder/postincrement
  field-load revision. The frontend/scalar probes retain 4,096 block-memory
  bits. These are observability-wrapper analysis results, not fit, TimeQuest,
  or core-area qualification.
- The 50-case ISA suite, 71-entry delta ledger, and 184-case model suite pass.
  MOVE.MR.POST exhausts both banks and extension modes, every width/offset,
  all five alignment cases, A/B/SP, pointer wrap, exact N/C/Z/V and logical
  traces, plus BEN rollback. Exact decoder boundaries and direct-router
  noncommit pass; extraction and pointer arithmetic are independently
  exhaustive leaves. Same-register data priority remains CORROBORATED under
  RSC-0036/OQ-0024.
- Warning-free Cyclone V Analysis & Synthesis reports 12,660 leaf logic
  cells/2,230 registers/9 DSP, 437 fetch logic cells, 807 frontend logic
  cells, and 5,409 scalar logic cells for the 108-entry decoder/postincrement
  field-store revision. The frontend/scalar probes retain 4,096 block-memory
  bits. These are observability-wrapper analysis results, not fit, TimeQuest,
  or core-area qualification.
- The 49-case ISA suite, 70-entry delta ledger, and 181-case model suite pass.
  MOVE.RM.POST exhausts both banks, every width/offset, all five alignment
  cases, A/B/SP/same-register capture and pointer wrap, unchanged ST, exact
  logical traces, hidden writes, and BEN rollback. The RTL field-address leaf
  independently exhausts all sizes and update modes; direct execution remains
  noncommitting without a memory owner.
- Warning-free Cyclone V Analysis & Synthesis reports 12,544 leaf logic
  cells/2,230 registers/9 DSP, 433 fetch logic cells, 812 frontend logic
  cells, and 5,405 scalar logic cells for the 107-entry decoder/field-copy
  revision. The frontend/scalar probes retain 4,096 block-memory bits. These
  are observability-wrapper analysis results, not fit, TimeQuest, or core-area
  qualification.
- The 48-case ISA suite, 69-entry delta ledger, and 178-case model suite pass.
  MOVE.MM exhausts both FS banks, every width and 1,024 source/destination
  offset pairs, all 25 timing pairs, A/B/SP/alias/overlap ordering, unchanged
  ST/registers, logical transaction order, hidden writes, and BEN rollback.
  The RTL leaf independently exhausts 32,768 geometries and direct noncommit.
- The 47-case ISA suite, 68-entry delta ledger, and 175-case model suite pass.
  MOVE.MR coverage exhausts both FS/FE banks, every width/offset, all five
  cases, zero/sign extension, N/C/Z/V, A/B/SP/alias ordering, logical traces,
  visible state counts, and atomic BEN rollback. Its RTL leaf independently
  exhausts 2,048 size/offset/extension geometries and cannot commit through
  the register-only router.
- Warning-free Cyclone V Analysis & Synthesis reports 12,188 leaf logic
  cells/2,230 registers/9 DSP, 436 fetch logic cells, 808 frontend logic
  cells, and 5,353 scalar logic cells for the 106-entry decoder/field-load
  revision. The frontend/scalar probes retain 4,096 block-memory bits. These
  are observability-wrapper analysis results, not fit, TimeQuest, or core-area
  qualification.
- The 46-case ISA suite, 67-entry delta ledger, and 172-case model suite pass.
  MOVE.RM coverage exhausts both field banks, every 1–32-bit width and every
  within-long-word offset, all five hidden-write classes, crossing-word
  preservation, A/B/SP aliases, logical traces, and atomic BEN rollback. The
  RTL leaf independently exhausts all 1,024 size/offset geometries and cannot
  commit through the register-only router.
- Warning-free Cyclone V Analysis & Synthesis reports 11,903 leaf logic
  cells/2,230 registers/9 DSP, 433 fetch logic cells, 803 frontend logic
  cells, and 5,366 scalar logic cells for the 105-entry decoder/field-store
  revision. The frontend/scalar probes retain 4,096 block-memory bits. These
  are observability-wrapper analysis results, not fit, TimeQuest, or core-area
  qualification.
- The 45-case ISA suite, 66-entry delta ledger, and 169-case model suite pass.
  RETM coverage proves exact decode/nonalias, state restoration, ten normal
  states, all-word one-shot bypass despite a stale cached MOVI.L, snapshot/
  replay, and atomic IX/BF rollback. Direct RTL checks cover both return modes
  and all context/timing classes without permitting commit.
- Warning-free Cyclone V Analysis & Synthesis reports 11,626 leaf logic
  cells/2,230 registers/9 DSP, 434 fetch logic cells, 809 frontend logic
  cells, and 5,358 scalar logic cells for the 104-entry decoder revision. The
  frontend/scalar probes retain 4,096 block-memory bits. These are
  observability-wrapper analysis results, not fit, TimeQuest, or core-area
  qualification.
- The 44-case ISA suite, 65-entry delta ledger, and 166-case model suite pass.
  RETI coverage includes exact decode/nonalias, ordered normal-frame reads,
  full ST/IE restoration, PC alignment, SP wrap, TRAP round trip, and atomic
  IX/BF rejection. Direct RTL checks cover all three context classes and
  prevent RETI from bypassing absent stack ownership.
- Warning-free Cyclone V Analysis & Synthesis reports 11,522 leaf logic
  cells/2,230 registers/9 DSP, 434 fetch logic cells, 812 frontend logic
  cells, and 5,355 scalar logic cells. The frontend/scalar probes retain 4,096
  block-memory bits. These are observability-wrapper analysis results, not
  fit, TimeQuest, or core-area qualification.
- Warning-free Cyclone V Analysis & Synthesis now reports 11,479 leaf logic
  cells/2,230 registers/9 DSP, 441 fetch logic cells, 811 frontend logic cells,
  and 5,366 scalar logic cells. The frontend/scalar probes retain 4,096
  block-memory bits. These are observability-wrapper analysis results, not
  fit, TimeQuest, or core-area qualification.
- The 43-case ISA suite, 64-entry delta ledger, and 163-case model suite pass.
  MMFM/MMTM coverage exhausts all 65,536 list masks in both directions and
  every A/B/SP register, including pointer/status/timing boundaries, logical
  transfer order, round trip, and atomic invalid-list rollback. All 64 decoded
  first words remain noncommitting without physical memory ownership.
- The 41-case ISA suite, 62-entry delta ledger, and 156-case model suite pass.
  MPYS/MPYU coverage includes all 1,024 encodings, every reliable primary
  example row and even FS1, full-versus-low flag discriminators, A/B/SP alias
  boundaries, status preservation, and provisional detailed-page timing.
- Decoder-bearing Cyclone V Analysis & Synthesis probes pass with zero
  errors/warnings at 10,662 leaf/9 DSP, 442 fetch, 812 frontend, and 5,396
  scalar logic cells. These remain portability probes, not fit or timing
  results.
- The 40-case ISA suite, 61-entry delta ledger, and 152-case model suite pass.
  MODS/MODU coverage includes all 1,024 encodings, every primary example,
  signed/unsigned result/status cases, aliases, and 35/40/3-state classes.
  Direct RTL tests cover remainder mode and its noncommit boundary.
- All four decoder-bearing Cyclone V Analysis & Synthesis probes pass with zero
  errors/warnings at 10,296 leaf, 434 fetch, 809 frontend, and 5,346 scalar
  logic cells. These are portability probes, not complete-core area, fit, or
  timing results.
- The 39-case ISA suite, 60-entry delta ledger, and 150-case model suite pass.
  DIVS/DIVU coverage includes all 1,024 encodings, primary example rows,
  odd/even destinations, shared-SP pair aliasing, zero/range exceptions,
  instruction-specific status masks, and selected state counts. Direct RTL
  tests cover the clean-room iterative leaf and prove the scalar router does
  not commit either opcode without an architectural sequencer.
- All four decoder-bearing Cyclone V Analysis & Synthesis probes pass with zero
  errors and zero warnings at 10,246 leaf, 443 fetch, 812 frontend, and 5,336
  scalar logic cells. The diagnostic divider adds state and datapath resources
  only to the leaf wrapper; these remain portability probes, not complete-core
  area, fit, or timing results.
- All four decoder-bearing Cyclone V Analysis & Synthesis probes pass with zero
  errors and zero warnings at 9,140 leaf, 423 fetch, 791 frontend, and 5,237
  scalar logic cells. The diagnostic XY-conversion leaf maps its arbitrary
  signed pitch products to three DSP blocks; these wrapper figures are not a
  complete-core area or timing result.

- The 38-case ISA suite, 59-entry delta ledger, and 148-case model suite pass.
  XY conversion coverage includes all 1,088 encodings, every pitch class,
  signed arbitrary multiplication, PSIZE/offset variants, aliases, full ST
  preservation, and the selected instruction-boundary states; direct RTL tests cover
  the shared leaf while all four commit paths remain guarded.
- The 37-case ISA suite, 58-entry delta ledger, and 145-case model suite pass.
  CPW covers every published outcode row, signed discriminators, alias hazards,
  and exact one-state/V-only behavior; direct RTL tests cover the semantic leaf
  while the commit path remains guarded. Decoder-bearing Cyclone V Analysis &
  Synthesis passes with zero errors/warnings at 8,846 leaf, 421 fetch, 804
  frontend, and 5,258 scalar logic cells. These are bounded semantic and
  synthesis-portability results, not a complete graphics path, fit, or
  TimeQuest evidence.
- The 36-case ISA suite, 57-entry delta ledger, and 144-case model suite pass.
  CALL and CALLR exercise exact state/timing cases; CALLA exercises exact state
  while proving timing remains incomplete. Direct RTL guards prove all three
  forms cannot mutate scalar state without their missing owner. Decoder-bearing
  Cyclone V Analysis & Synthesis passes with zero errors/warnings at 8,796
  leaf, 428 fetch, 792 frontend, and 5,225 scalar logic cells. These are bounded
  state and synthesis-portability results, not external stack timing, fit, or
  TimeQuest evidence.
- The 35-case ISA suite, 55-entry delta ledger, and 141-case model suite pass.
  RETS exercises every N value and both stack-alignment cases, while direct RTL
  guards prove decoded RETS packets cannot mutate register or status state.
  All decoder-bearing Cyclone V smoke targets pass with zero errors/warnings:
  leaf 8,792, fetch 416, frontend 788, and scalar 5,286 logic cells. These are
  bounded instruction-state and synthesis-portability results, not physical
  stack timing, fit, or TimeQuest evidence.
- The 34-case ISA suite, 54-entry delta ledger, and 139-case model suite pass.
  Every TRAP vector and both stack-alignment classes are covered, and prior
  TRAPL cases still pass after helper extraction. All decoder-bearing Cyclone V
  smoke targets pass with zero errors/warnings: leaf 8,773, fetch 406,
  frontend 784, and scalar 5,236 logic cells. These are bounded
  instruction-state and synthesis-portability results, not physical
  stack/vector timing, fit, or TimeQuest evidence.
- The 33-case ISA suite, 53-entry delta ledger, and 137-case model suite pass.
  REV is the only extracted form without successful model semantics: a
  directed snapshot test proves decoded execution rolls back exactly, and the
  RTL leaf test proves the same packet cannot produce register or status write
  intent. All decoder-bearing Cyclone V smoke targets pass Analysis &
  Synthesis with zero errors/warnings: leaf 8,777, fetch 419, frontend 785,
  and scalar 5,330 logic cells. These are source-classification and synthesis-
  portability results, not a REV value, one-state retirement, fit, or
  TimeQuest claim.
- CMPXY passes all nine published status rows plus a result-sign-versus-borrow
  discriminator in warning-free direct-leaf, router, ordered-commit, bypass
  fetch, and cache-refill tests. Cyclone V Analysis & Synthesis passes with
  zero errors/warnings at 8,784 leaf and 5,215 bounded-scalar logic cells,
  2,048/1,414 registers, and 0/4,096 block-memory bits respectively. These are
  functional and portability results, not the documented one-state retirement,
  fit, TimeQuest, or complete-core evidence.
- The 136-case independent model suite now has bounded successful semantics for
  all 82 extracted forms. CMPXY has no RTL execution in this checkpoint, and
  neither its one-state model result nor the untimed fetch boundary constitutes
  RTL retirement-timing evidence.
- The 82-entry partial decoder classifies 25,810 first words without collision.
  The 32-case ISA suite, 52-entry delta ledger, 135-case model suite, and
  warning-free Verilator leaf checks pass. CMPXY remains atomically unsupported
  in the model and noncommitting in RTL at this source checkpoint. Cyclone V
  leaf Analysis & Synthesis passes with 0 errors/warnings at 8,723 logic cells,
  2,048 registers, and no RAM; this is not CMPXY execution or timing evidence.
- JAcc RTL passes warning-free direct, commit, cache-fed scalar, and Cyclone V
  Analysis & Synthesis checks. Leaf/scalar diagnostic tops use 8,767/5,262
  logic cells with 2,048/1,414 registers; fetch and frontend remain at 411/785
  logic cells, and frontend/scalar retain 4,096 inferred RAM bits. These are
  wrapper-heavy synthesis regressions, not fit, TimeQuest, or cycle evidence.
- The 133-case independent model suite now has bounded successful semantics for
  all 81 currently extracted forms. JAcc tests independently cover every
  condition outcome, target-word ordering/alignment, false-path PC wrap, exact
  traces, state preservation, and primary three-/four-state counts. This is
  not coverage of short JRcc, the unextracted ISA, or RTL JAcc execution/timing.
- Expanded the collision-free ISA slice to 81 entries covering 25,298 first
  words. The 30-case ISA suite checks all JAcc/long-JR condition words and the
  adjacent short-JR exclusion across the complete 65,536-word sweep; the
  132-case model suite retains exact unsupported rollback for JACC. Verilator
  lint and direct/cache-fed nonexecution guards pass. All affected Cyclone V
  analyses pass with zero warnings at 8,659 leaf, 411 fetch, 785 frontend, and
  5,268 scalar logic cells. This is classification and nonexecution evidence,
  not JACC semantics or timing.
- The 131-case independent model suite now has bounded successful semantics for
  all 80 currently extracted forms. JR.L tests independently cover every
  condition outcome and signed target boundary. Functional RTL tests separately
  cover the complete condition truth table, direct targets, state-neutral
  commit, and cache-fed taken/fallthrough paths. This is not coverage of short
  JRcc, JAcc, the unextracted ISA, or RTL retirement timing.
- Expanded the collision-free ISA slice to 80 entries covering 25,282 first
  words. The 29-case ISA suite checks all long-JR conditions and neighboring
  exclusions across the complete 65,536-word sweep; the 131-case model suite
  proves unsupported execution rolls back exactly. Verilator leaf/scalar and
  all four decoder-bearing Cyclone V analyses pass with zero warnings at 8,679
  leaf, 410 fetch, 778 frontend, and 5,242 scalar logic cells. This is bounded
  functional and synthesis-portability evidence, not JR.L retirement timing.
- DSJS functional RTL passes direct-PC, ordered commit, and cache-fed scalar
  tests for zero/nonzero results, zero/max magnitudes, both directions,
  A/B/shared-SP destinations, exact status preservation, and PC wrap. The
  129-case model suite, 28-case ISA suite, complete 65,536-word decode sweep,
  warning-free Verilator lint, and all affected regressions pass. Quartus
  Cyclone V Analysis & Synthesis passes with zero errors/warnings at 8,641 leaf
  and 5,255 scalar diagnostic logic cells; register/RAM counts remain 2,048/0
  and 1,414/4,096 respectively. These are functional and synthesis-portability
  results, not retirement-timing, fit, TimeQuest, or release evidence.
- The 129-case independent model suite covers bounded successful semantics for
  all 79 currently extracted forms. DSJS tests distinguish the embedded
  unsigned magnitude plus direction bit from DSJ signed extension and cover
  primary examples, range endpoints, aliasing, wrap, status, and state counts.
  This is not full-ISA or RTL retirement-timing coverage.
- Expanded the collision-free ISA slice to 79 entries covering 25,266 first
  words. DSJS forward/backward, zero/max-magnitude, A/B/shared-SP, and adjacent
  CMPK/ADD boundaries pass independent fixtures and the 65,536-word sweep. The
  127-case model suite proves complete attempts roll back atomically; leaf and
  scalar tests prove decoded packets cannot write registers/status or redirect
  before an execution owner exists. All four decoder-bearing Cyclone V
  analyses pass with zero errors/warnings at 8,612 leaf, 416 fetch, 790
  frontend, and 5,211 scalar diagnostic logic cells; these are not fitted
  core-area or timing-closure results.
- Expanded the collision-free ISA slice to 78 entries covering 23,218 first
  words. All DSJ/DSJEQ/DSJNE range boundaries and the adjacent SETC boundary
  pass the independent fixtures and 65,536-word sweep. The 126-case model suite
  executes every primary DSJ-family row and edge case. Leaf and scalar tests
  verify conditional decrement, status preservation, signed redirect targets,
  decrement-to-zero suppression, wrap, and PC wrap. All four decoder-bearing
  Cyclone V analyses pass with zero errors/warnings at 8,604 leaf, 407 fetch,
  772 frontend, and 5,170 scalar diagnostic logic cells; these are not fitted
  core-area or timing-closure results.
- The 122-case independent model suite covers bounded successful semantics for
  all 75 currently extracted forms. JUMP tests cover all primary target rows,
  A/B/shared-SP selection, alignment, preservation, and timing; this is not a
  full-ISA or RTL redirect-timing claim.
- Expanded the collision-free ISA slice to 75 entries covering 23,122 first
  words. JUMP A/B/shared-SP and adjacent GETPC/GETST boundaries pass; model
  preimplementation rollback guards were replaced by direct leaf, ordered
  commit, and scalar redirect tests that require alignment and forbid
  register/status writes.
  All four decoder-bearing Cyclone V analyses pass with zero errors/warnings at
  8,547 leaf, 401 fetch, 769 frontend, and 5,157 scalar diagnostic logic cells;
  these are not fitted core-area or timing-closure results.
- The 120-case independent model suite covers bounded successful semantics for
  all 74 currently extracted forms. POPST/PUSHST tests cover both alignment
  classes, full-width status values, SP ordering, abstract data traces,
  wraparound, and hidden-write overlap; this is not full-ISA, fault/retry, or
  pin-bus coverage.
- Expanded the collision-free ISA slice to 74 entries covering 23,090 first
  words. POPST/PUSHST exact and adjacent boundaries pass independently;
  execution, commit, and scalar RTL tests preserve state while handlers are
  absent.
  All four affected Cyclone V analyses pass with zero errors/warnings at 8,504
  leaf, 402 fetch, 775 frontend, and 5,133 scalar diagnostic logic cells; these
  are not fitted core-area or timing-closure results.
- PUTST passes direct leaf, ordered commit, and cache/fetch-to-commit tests with
  exact full-width data/mask and no register writeback. The scalar runtime SVA
  set grows to thirteen. Affected warning-free Cyclone V analyses use 8,491
  leaf and 5,131 scalar diagnostic logic cells; no formal proof, fitted area,
  or timing claim is made.
- The 116-case independent model suite covers bounded semantics for all 72
  currently extracted forms, including PUTST full-width transfer and timing.
  This is not coverage of the unextracted ISA or RTL retirement timing.
- Expanded the collision-free ISA slice to 72 entries covering 23,088 first
  words. All four PUTST file/index boundaries roll back atomically in the model
  and remain blocked without architectural writes in leaf/commit/scalar RTL.
  All four decoder-bearing Cyclone V analyses pass with zero errors/warnings at
  8,434 leaf, 394 fetch, 762 frontend, and 5,060 scalar diagnostic logic cells;
  these are not fitted core-area or timing-closure results.
- The 114-case independent model suite covers bounded semantics for all 71
  currently extracted forms, including EXGF's atomic two-owner exchange. This
  is not coverage of the unextracted ISA or RTL retirement timing.
- Expanded the collision-free ISA slice to 71 entries covering 23,056 first
  words. EXGF decodes and executes across both field banks, A/B, and shared SP
  in the independent model and bounded RTL, including atomic register/status
  exchange and nonselected-state preservation. All four decoder-bearing
  Cyclone V analyses pass with zero errors/warnings at 8,476 leaf, 397 fetch,
  771 frontend, and 5,062 scalar diagnostic logic cells; these are not fitted
  core-area or timing-closure results.
- SETF/SEXT/ZEXT pass the warning-free leaf and scalar Verilator regressions
  across all encoded sizes, both status banks, A/B/shared-SP routing, and
  ordered state dependencies. Affected Cyclone V Analysis & Synthesis passes
  with zero errors/warnings at 8,383 leaf and 5,033 bounded-scalar diagnostic
  logic cells; these are not fitted area or timing-closure results.
- The 112-case independent model suite covers bounded semantics for all 70
  currently extracted forms. SETF/SEXT/ZEXT are checked over every encoded
  size and both field banks without claiming coverage of the unextracted ISA.
- All 16 published ADDXY and nine published SUBXY result/flag rows now pass in
  both the independent model and directed RTL, with additional A/B,
  same-register, shared-SP, and dependent-commit checks. Warning-free Quartus
  Cyclone V Analysis & Synthesis reports 8,038 leaf and 4,726 bounded-scalar
  diagnostic logic cells; these are portability metrics, not fitted core area
  or timing closure.
- The 108-case independent model suite covers bounded semantics for all 67
  currently extracted forms. This remains coverage of a partial ISA
  extraction, not instruction completeness.
- All 25 published BTST.K/R input rows pass through the independent RTL leaf,
  with RSC-0018's contradictory printed status digit corrected from the
  operands and definition. Register routing, atomic commit, and scalar
  dependency tests cover constant complementation, upper-source-bit
  truncation, A/B, same-register, and shared-SP cases. Warning-free Quartus
  Cyclone V Analysis & Synthesis reports 8,068 leaf and 4,861 bounded-scalar
  diagnostic logic cells; these are portability metrics, not fitted core area
  or timing closure.
- Expanded the collision-free ISA slice to 70 entries covering 22,992 first
  words. SETF/SEXT/ZEXT decode across both field banks, A/B destinations, all
  encoded field sizes, and both extension modes while remaining atomically
  non-executable in the model and RTL at this extraction checkpoint. All four
  decoder-bearing Quartus Cyclone V Analysis & Synthesis smokes pass with zero
  errors/warnings: 8,067 leaf, 392 fetch, 766 frontend, and 4,804 scalar
  diagnostic logic cells. These are analysis-only portability metrics, not
  fitted core area or timing closure.
- Expanded the collision-free ISA slice to 67 entries covering 22,736 first
  words. BTST.K/R decode across their complete primary-defined ranges while
  remaining atomically non-executable in RTL at this extraction checkpoint.
  All four decoder-bearing Quartus Cyclone V Analysis & Synthesis smokes pass
  with zero errors/warnings: 7,986 leaf, 393 fetch, 765 frontend, and 4,806
  scalar diagnostic logic cells. These are
  analysis-only portability metrics, not fitted core area or timing closure.
- Verilator leaf/scalar regressions and warning-free Cyclone V Analysis &
  Synthesis cover LMO at the register-execution boundary. The leaf diagnostic
  top uses 7,713 logic cells and 2,021 registers; the bounded scalar diagnostic
  top uses 4,595 logic cells, 1,386 registers, and 4,096 block-memory bits.
  These are Analysis & Synthesis portability metrics, not fitted core area or
  timing closure.

- The working directory is the existing clean `birdybro/TMS34020_sv` clone on
  `main`; no nested repository was created.
- The requested TMS34010 baseline commit exists on its upstream `main` branch.
- The baseline commit/tree metadata and MIT license are preserved; every
  upstream RTL and simulation-model module is named in the reuse audit.
- Verified local SHA-256 values for nine TI documents and the pinned eleven-file
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
- Expanded the collision-free ISA slice to 63 entries covering 20,176 first
  words. LMO's complete `6A00h`–`6BFFh` range decodes as a one-word,
  TMS34010-compatible instruction and remains blocked at RTL execution
  boundaries. Decoder-only Cyclone V requalification reports 7,620 leaf, 381
  fetch, 760 frontend, and 4,563 scalar diagnostic logic cells with zero
  errors/warnings.
- All 63 currently extracted forms now have bounded successful model semantics;
  this remains partial-extraction coverage and is not instruction completeness.
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
- Implemented the independent TRAPL success path with the verified two-word
  encoding, ordered return-PC/ST predecrement stack frame, signed vector-table
  lookup, complete ST reset, PC alignment, and 10/12-state stack-alignment
  cases. The 84-test model covers 51/52 extracted forms. Stack/vector
  fault/retry behavior and RTL interrupt sequencing remain absent.
- Implemented a bounded independent BLMOVE success path for all four S/D
  modes, with TI's 32-bit alignment requirements, bit-exact non-overlapping
  copies, B0/B2 advancement, B7 completion, ST preservation, zero/self/wrap
  cases, abstract tracing, and rollback guards. The 88-test model now has
  bounded semantics for all 52 currently extracted forms; this is not a
  complete ISA or continuation/timing claim.
- Extracted the primary GETPC and EXGPC register-file forms from TI printed
  pp.13-130 and 13-112. The 54-record partial database covers 13,520 first
  words; independent boundary fixtures and the full first-word collision sweep
  verify both A/B-file ranges, instruction lengths, and no new decode overlap.
  The regenerated 54-entry RTL decode passes the complete implemented
  regression and warning-free Cyclone V leaf/fetch/frontend/scalar synthesis;
  model execution and RTL redirect ownership remain separate follow-on work.
- Implemented independent GETPC and EXGPC model behavior using the
  instruction-boundary sequential PC rather than cache-fetch state. The
  90-test model suite covers TI's published rows, both register files, shared
  SP, low-nibble target alignment, status preservation, one-/two-state counts,
  and trace next-PC values. All 54 currently extracted forms now have bounded
  successful model semantics; this remains a partial-ISA claim only.
- Added a synthesizable direct-PC execution leaf and atomic commit integration
  for GETPC and EXGPC. The bounded scalar composition carries the packet's
  sequential PC through writeback and holds EXGPC's aligned old-register target
  until frontend completion, without assigning architectural cycle timing.
- Verilator verifies direct GETPC/EXGPC leaf semantics, A/B and shared-SP
  commits, old-value capture, status preservation, length rejection, and an
  EXGPC redirect that reaches a GETPC at a nonsequential address. Warning-free
  Cyclone V Analysis & Synthesis reports 6,933 leaf logic cells and
  4,145 scalar-composition logic cells; these are diagnostic wrapper metrics,
  not fit, TimeQuest, or core-area results.
- Extracted primary SLA/SLL/SRA/SRL constant and same-file register forms from
  TI printed pp.13-233..13-240, including direct left-count encodings,
  two's-complement right-count encodings, status masks, and the three-state SLA
  versus one-state logical/right-shift distinction. The 62-record database now
  covers 19,664 first words without collisions; independent Python boundaries
  and SystemVerilog decode fixtures pass. A model guard verifies that all eight
  decoded-but-unsupported forms roll back without state change; execution
  support is explicitly deferred.
- Regenerated the partial RTL decoder and requalified every decoder-bearing
  smoke boundary warning-free. Quartus reports 6,932 leaf, 375 fetch, 748
  frontend, and 4,167 scalar logic cells; these remain Analysis & Synthesis
  diagnostics, not timing or area qualification.
- Implemented independent architectural-model semantics for all eight
  SLA/SLL/SRA/SRL forms. The 100-test model suite checks every published TI
  example row, direct and five-bit two's-complement counts, arithmetic versus
  zero fill, count-zero carry, partial status preservation, B-file/shared-SP
  selection, and same-register pre-write hazards. All 32 SLA counts across
  representative bit patterns also match a separate iterative overflow oracle.
  All 62 currently extracted forms now have bounded successful model semantics;
  this is not a complete-ISA or cycle-accuracy claim.
- Added a portable SLA/SLL/SRA/SRL RTL leaf and routed all eight constant and
  register forms through atomic register/ST commit. Directed Verilator checks
  cover every published result row, all 32 SLA counts against an iterative
  oracle, count encoding, fill, status masks, selectors, packet rejection, and
  an eight-operation dependency chain. A sixteenth runtime assertion requires
  atomic shift register/status writes without redirect.
- Warning-free Cyclone V Analysis & Synthesis now reports 7,548 leaf and 4,491
  scalar-wrapper logic cells, with the scalar cache still using 4,096
  block-memory bits. These are diagnostic synthesis results, not fit,
  TimeQuest, or core-area qualification.

### Documentation

- Recorded MOVB register-store semantics, TMS34010 compatibility bounds,
  TMS34020-only timing ownership, RTL boundary, and unresolved physical
  memory/fault/retry work across the ISA, model, field-access, timing, delta,
  status, task, and status ledgers.
- Recorded `2c15791fbe6b04b5712dcb86ffce88308ad4e12d` as the verified
  absolute-address field-MOVE implementation baseline.
- Documented all four absolute field MOVE encodings, low/high address-word
  order, status behavior, aligned/unaligned extension timing, reuse boundary,
  model/RTL ownership, remaining physical-bus gaps, and four new
  primary-verified architectural-delta entries.
- Recorded the verified mixed-offset field-move implementation baseline as
  commit `f6522b1f076712b6cc64bef8920cdc8da0a66029` in the progress ledger.
- Documented the source-offset/destination-postincrement compatibility boundary
  separately from TMS34020-owned 32-bit A–H timing, BEN, dynamic-width, hidden-
  write, page, interrupt and fault/retry realization.
- Recorded the verified signed-offset field-move implementation baseline as
  commit `a8199e2c7648ee776af17c8ad4212a748478bc17` in the progress ledger.
- Documented the three signed-offset MOVE compatibility boundaries separately
  from TMS34020-owned 32-bit alignment, BEN, hidden-write, dynamic-width, page
  and fault/retry realization.
- Recorded the verified predecrement field-move implementation baseline as
  commit `985b09468c8e543c38f870ec28789f5c8c68a03a` in the progress ledger.
- Documented all three predecrement MOVE compatibility boundaries separately
  from TMS34020-owned 32-bit alignment, BEN, hidden-write, dynamic-width, page
  and fault/retry realization.
- Recorded the verified paired-postincrement field-copy implementation baseline
  as commit `a4976c969da3746f8e7f4e6d794b98d5fe093b3d` in the progress ledger.
- Documented paired-postincrement field-copy compatibility separately from
  TMS34020-owned A–H timing, BEN, dynamic-width, hidden-write, page and
  fault/retry realization.
- Recorded the verified postincrement field-load implementation baseline as
  commit `13821007e7929b9d312c82fa91f5eeabdd5f7bf6` in the progress ledger.
- Documented postincrement field-load semantic compatibility separately from
  TMS34020-owned 32-bit alignment, BEN, physical dual-write retirement and
  fault sequencing; recorded RSC-0036/OQ-0024 for the primary-source omission
  of an explicit same-register write-priority rule.
- Recorded the verified postincrement field-store implementation baseline as
  commit `58d2fe1743557cde1e8a836fba2a96047d8103a0` in the progress ledger.
- Documented postincrement field-store semantic compatibility separately from
  TMS34020-owned 32-bit alignment, BEN, hidden-write and fault sequencing.
- Recorded the verified ordinary memory-to-memory field-copy implementation
  baseline as commit `3b235c2b0fb2ad1b45d94f95394806c3b775fd60`
  in the progress ledger.
- Documented the compatible indirect-to-indirect field copy separately from
  TMS34020-owned A–H timing, BEN, dynamic-width, page and fault sequencing.
- Recorded the verified ordinary field-load implementation baseline as commit
  `4dc5694298903b68d5c0542f536a00500baee7eb` in the progress ledger.
- Documented ordinary memory-to-register compatibility separately from the
  TMS34020-owned 32-bit/BEN/timing/request realization.
- Recorded the verified ordinary field-store implementation baseline as commit
  `8c46ccb496ba9f3b87e0e7a0f89f3d2a8b66c207` in the progress ledger.
- Documented MOVE.RM's compatible programmer-visible field store separately
  from the TMS34020-owned 32-bit/BEN/timing realization, plus the explicit
  byte-strobe/RMW/dynamic-width/page/fault boundary.
- Recorded the verified bounded RETM implementation baseline as commit
  `5157e331e3e95cdcae61b02b24b99b7e1cc3a097` in the progress ledger.
- Documented RETM's single-step role, TMS34010 absence, one-shot cache bypass,
  ten-state normal case, shared continuation boundary, and explicit lack of an
  interrupt scheduler. RSC-0035 records the instruction page's boxed RETI/
  RETM cache-note transposition and the repeated-primary resolution.
- Recorded the verified bounded RETI implementation baseline as commit
  `e7eed66741359d9a6bc1905dc3c0ba10011e004f` in the progress ledger.
- Documented RETI's normal frame, restored-IE checkpoint, TMS34010 timing/
  continuation delta, and strict model/RTL boundary. RSC-0034 resolves the
  instruction page's stray `SF` label to defined ST.BF bit 26; OQ-0023 tracks
  the undisclosed IX/BF hidden-word layout, padding, restore order, and nested
  checkpoints.
- Recorded the verified bounded MMFM/MMTM implementation baseline as commit
  `95b84aeb0342bb379eadfe5d165bf0457b8b36ba` in the progress ledger.
- Documented MMFM/MMTM register-list encoding, pointer/status behavior,
  TMS34020 timing and page-mode boundary, TMS34010 semantic compatibility, and
  explicit exclusions from physical bus/continuation claims. RSC-0033 records
  three primary-page editing errors and MMFM's unexplained alignment/timing
  statement; OQ-0022 keeps that timing distinction open.
- Recorded the verified bounded SWAPF implementation baseline as commit
  `fea7a996312e8558663b377ae89b3c078dd835f5` in the progress ledger.
- Documented the TMS34020-only SWAPF delta, locked restart-from-read boundary,
  implicit completion wait, host exclusion, and SIZE16/S=0 restriction without
  treating its field transform as a complete memory controller.
- Recorded the verified MPYS/MPYU implementation baseline as commit
  `281989160aa466c8ab98b9d06634802e432e367b` in the progress ledger.
- Recorded RSC-0030/OQ-0020 for the TMS34020 detailed-page/chapter-15 swap of
  MPYS/MPYU sign-dependent timing; selected detailed-page timing remains
  provisional. RSC-0031 records the impossible MPYS Example 1 operand and its
  arithmetic-consistent companion value. RSC-0032/OQ-0021 isolates the older
  TMS34010 odd-product flag disagreement from the explicit TMS34020 rule.
- Recorded the verified MODS/MODU implementation baseline as commit
  `f8a3ebef2693c4d2eb3240bccabf0b0a1da3bc28` in the progress ledger.
- Recorded RSC-0028 for the inherited MODU "quotient" noun that conflicts with
  the operation and `8 mod 4` zero-remainder/Z-set row; remainder-derived Z is
  primary-verified. RSC-0029/OQ-0019 retain the published MODS
  result-`80000000h` timing class without inventing operands for a
  mathematically unreachable remainder.
- Recorded the verified DIVS/DIVU implementation baseline as commit
  `3b45d4c027ef971cdc90127fb63fe8d06e622b29` in the progress ledger.
- Recorded RSC-0027/OQ-0018 for the signed even-pair nonzero early-overflow
  ambiguity: the DIVS instruction page omits that shortcut, while chapter 15
  prints a raw `Rs <= Rd` rule that is inconsistent with mixed-sign arithmetic.
  The current model and RTL leaf provisionally compare normalized magnitudes;
  this is not promoted to verified behavior.
- Documented the four XY conversion contracts and TMS34010 delta, and recorded
  the three CVXYL PSIZE=4 example rows that contradict the repeated equation
  as RSC-0025/OQ-0016 instead of inventing an undocumented exception.
- Added the required pixel-processing document with an explicitly partial CPW
  window boundary, exact outcode table, citations, and nonclaims; documented
  CPW's TMS34010 compatibility and isolated timing equivalence without
  generalizing it to the graphics pipeline.
- Documented CALL-family state and compatibility, the TMS34010/TMS34020 timing
  delta, pinned MAME's shared-handler under-modeling, and CALLA's internally
  ambiguous primary timing clauses as RSC-0024/OQ-0015 rather than guessing a
  four-case schedule.
- Documented RETS state and timing compatibility, the TMS34010 7/9 versus
  TMS34020 5/6 delta, pinned MAME's fixed-7 discrepancy (RSC-0023), and the
  boundary between model success and absent RTL stack-read ownership.
- Documented the TRAP vector map, reset exception, stack frame, timing delta,
  pinned MAME 16-cycle discrepancy (RSC-0022), and the explicit boundary
  between model success semantics and absent physical memory/fault ownership.
- Documented REV's identity bit layout, TMS34010/TMS34020 behavior and timing
  boundary, the pinned MAME conflict, and the rule that target-game profiles
  may not guess an unverified stepping result.
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
- Recorded and resolved an internal TI TRAPL contradiction: the instruction
  prose's shift/sign-extension formula disagrees with two vector maps and every
  worked example. The database and model use the repeated descending-vector
  mapping, while RSC-0016 retains the evidence and need for errata/hardware
  corroboration.
- Recorded that pinned MAME's BLMOVE uses 16-bit rather than TI's 32-bit
  alignment check and leaves S/D-dependent continuation updates TODO.
  RSC-0017 keeps its request width, overlap, continuation, and timing behavior
  out of the primary-driven model contract.
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
- Documented the bounded scalar admission set, blocked-packet
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

- MOVE.RM.OFFSET/MR.OFFSET/MM.OFFSET are logical little-endian
  instruction-boundary models plus separate field and signed-address leaves.
  No RTL owner fetches their extensions or makes memory/data/status retirement
  fault/retry/interrupt-safe; BEN, byte strobes/RMW, SIZE16, page mode, waits,
  I/O and pin cycles remain.
- MOVE.RM.PRE/MR.PRE/MM.PRE are logical little-endian instruction-boundary
  models plus insertion/extraction/copy and address leaves. No RTL owner makes
  pointer, memory, destination and status retirement fault/retry/interrupt-safe;
  BEN, byte strobes/RMW, SIZE16, page mode, waits, I/O and pin cycles remain.
- MOVE.MM.POST is a logical little-endian read-before-write model plus separate
  field-copy and paired-address leaves. Its final same-register pointer is
  CORROBORATED rather than primary-verified under RSC-0037/OQ-0025. No RTL
  owner makes the read, write and one/two pointer commits fault/retry/interrupt-
  safe; BEN, byte strobes/RMW, SIZE16, page mode, waits, I/O and pin cycles
  remain.
- MOVE.MR.POST is a logical little-endian field load plus instruction-boundary
  source-pointer update and separate extraction/address leaves. No RTL owner
  makes the memory read and two possible register writes fault/retry/interrupt-
  safe. BEN, SIZE16, page mode, waits, I/O and pin cycles remain, and the
  same-register data-wins rule is CORROBORATED rather than primary-verified.
- MOVE.RM.POST is a logical little-endian store plus instruction-boundary
  pointer update and a separate combinational address leaf. No RTL owner yet
  makes memory and Rd commit fault/retry/interrupt-safe; BEN, CAS/RMW, SIZE16,
  page mode, waits, I/O and pin cycles remain.
- MOVE.MM is a little-endian logical read-before-write model and combinational
  window leaf only. BEN, byte strobes/RMW, dynamic SIZE16, page turnaround,
  waits, I/O, faults/retries, interrupts and a committing sequencer remain.
- MOVE.MR is a little-endian logical-read model and combinational two-word
  leaf only. BEN=1, dynamic SIZE16, physical requests, page mode, waits,
  I/O routing, faults/retries, interrupts, and a committing sequencer remain.
- MOVE.RM is an instruction-boundary little-endian semantic implementation and
  combinational two-word leaf only. BEN=1, byte CAS strobes, physical RMW,
  dynamic SIZE16, page mode, waits, faults/retries, I/O routing, interrupts,
  and a committing memory sequencer remain unimplemented.
- RETM's normal return and transaction-level next-packet bypass are modeled,
  and its RTL intents are classified, but no stack/cache composition or
  one-instruction interrupt/single-step recognition scheduler exists. IX/BF,
  physical fetch timing, width/page/wait/fault/retry, and pins remain open.
- RETI normal-context behavior is implemented only at the atomic model
  boundary; RTL provides classification/result metadata but no stack reader or
  state owner. IX/BF 24/31-word continuation frames, padding, restore order,
  nested faults, retry, restored-IE interrupt recognition, and pin timing are
  unimplemented under OQ-0023.
- MMFM/MMTM have successful instruction-boundary model semantics and a
  combinational control leaf, but no physical read/write owner, page-mode
  controller, dynamic 16-bit decomposition, wait/fault/retry handling,
  interrupt checkpoint, partial-list continuation, or architectural commit.
  MMFM alignment timing remains provisional under RSC-0033/OQ-0022.
- SWAPF has a successful instruction-boundary model and combinational field
  leaf, but no locked bus owner, memory response path, atomic architectural
  commit, wait insertion, refresh/grant interruption, fault/retry injection,
  16-bit target qualification, I/O-register route, or host-exclusion test.
- MPYS/MPYU have instruction-boundary model semantics and a standalone RTL
  product leaf, but no pair-capable scalar retirement owner. Odd FS1 behavior
  is undocumented and rejected; multiply timing remains provisional under
  RSC-0030/OQ-0020, and TMS34010 odd-result compatibility remains open under
  RSC-0032/OQ-0021.
- MODS/MODU have complete instruction-boundary model semantics and a shared
  iterative RTL leaf, but no scalar operand/commit/timing owner. The published
  MODS 41-state result class is unreachable under documented remainder
  arithmetic and remains unresolved under RSC-0029/OQ-0019.
- DIVS/DIVU have instruction-boundary model semantics and a clean-room
  iterative RTL leaf, but no scalar sequencer owns paired operand capture,
  pair-atomic commit, exception write suppression, or documented retirement
  timing. Signed even-pair nonzero early-overflow behavior remains provisional
  under RSC-0027/OQ-0018.
- CVDXYL/CVMXYL/CVSXYL/CVXYL have complete instruction-boundary model
  semantics and a shared combinational RTL leaf, but no scalar implied-register,
  CONVxP/PSIZE, destination, pipeline, or internal-I/O ordering owner.
- CPW has complete instruction-boundary model semantics and a combinational RTL
  leaf, but no scalar three-read/atomic destination-plus-V owner. The rest of
  window checking, clipping, and pixel processing remains unimplemented.
- CALL/CALLR/CALLA have instruction-boundary model semantics only. RTL
  execution, external stack writes, width/page/wait/fault/retry behavior, and
  physical overlap remain unimplemented; CALLA machine-state classification is
  also unresolved from the available primary text.
- RETS has instruction-boundary model semantics only. RTL execution, external
  stack-read decomposition, waits, dynamic width, page mode, faults, retries,
  and exact redirect/machine-state timing remain unimplemented.
- TRAP has instruction-boundary model semantics only. RTL execution, external
  stack/vector transaction decomposition, waits, dynamic width, page mode,
  bus faults, retries, and exact pin/machine-state timing remain unimplemented.
- REV execution is intentionally unsupported until an evidence-backed
  physical-device profile provides the complete 32-bit identity. Exact
  Battletoads and Revolution X silicon results remain unknown, and pinned MAME
  is not a valid TMS34020 oracle for this instruction.
- The architectural model and RTL cover only a small verified slice; modeled
  instruction fetch uses an untimed native cache transaction boundary, the
  bounded scalar composition accepts only 52 one-word, eight two-word, and nine
  three-word operations, and every other packet blocks. There is no
  complete executable core, timed retirement, pin-level completion decoder,
  CPU fault controller, overlapped pipeline, or subsystem integration.
- Target-game chip markings, first-silicon history, and silicon errata remain
  unavailable; Revolution X A-silicon identification is an inference only.
- Yosys, SymbiYosys, and Icarus Verilog are not installed in the current local
  environment; Quartus Prime Lite 17.0 and Verilator are available.
