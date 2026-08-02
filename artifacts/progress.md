# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest committed baseline: `e38834122f2fdc861494cb1a057b8ee7db522eb7`
- Passing tests: foundation, reference/hash, delta, 75-case ISA sweep, 217 directed model
  cases, warning-free Verilator lint, directed RTL leaf/cache simulation, three
  deterministic randomized cache seeds, bounded instruction-packet and
  integrated cache/fetch frontend and bounded scalar-composition tests, and
  warning-free Quartus Cyclone V leaf/cache/fetch/frontend/scalar Analysis &
  Synthesis
- Failing tests: none observed
- Model status: 134 of 135 currently extracted encoding forms have bounded
  successful semantics over documented operand domains. CMOVCG consumes a
  deterministic version-4-snapshotted inbound queue and exhausts both A/B/SP
  destinations, ID, size, alignment, ordered values, last-word N/Z/V with C
  preservation, exact CMOVCS top-nibble status replacement, logical traces,
  snapshot replay, and atomic reserved/underflow rollback. Physical input
  acceptance, page/I=1 reissue, wait, fault/retry and commit timing remain
  absent. CMOVGC.1/.2 exhaust
  both source selectors, IDs, sizes, alignments, ordered register values,
  initial command formation and reserved rollback; their traces disclose the
  absent physical page-mode/I=1 reissue, acceptance, wait, fault and retry
  sequence. CEXEC.L/S exhaust all
  21 command bits, IDs, sizes, long alignments and 128 short first words,
  preserve complete state, emit the formatted logical LAD command, and reject
  reserved long packets atomically. Short packing follows the primary
  high-13/zero-2/low-6 layout; RSC-0040 records pinned MAME's conflicting
  five-bit reconstruction. External acceptance, LRDY/BUSFLT,
  retry/fault and pin timing remain absent. All nine extracted
  MOVB store/load/copy forms exhaust all 256 byte values and source/destination
  bit offsets through indirect, signed-offset and absolute addressing with
  store/copy ST preservation, signed-load N/Z/V, preserved C, read-before-write
  overlap, A/B/SP/alias ordering, primary timing cases, exact traces and BEN
  rollback. Offset-copy case E preserves TI's anomalous 5(2) timing as
  PROVISIONAL under RSC-0039/OQ-0026. Ordinary,
  postincrement, predecrement, signed-offset, mixed-offset and absolute RM/MR/MM cover both
  field banks, all 32 widths and all 32 bit offsets in little-endian mode,
  including crossing-word preservation, FE extension and status, pointer wrap,
  signed-offset extremes and wrap, exact absolute low/high word ordering,
  A/B/SP/alias/overlap ordering, all source/
  destination alignment pairs and timing; MOVE.MR.POST same-register
  fetched-data priority is CORROBORATED
  under RSC-0036/OQ-0024 rather than primary-verified; MM.POST's
  once-incremented alias destination and selected twice-incremented final
  shared pointer are CORROBORATED under RSC-0037/OQ-0025; BEN=1 rolls back
  pending an endian-aware memory mapper.
  Normal RETI reads
  saved ST then PC and atomically restores complete ST/IE, aligned PC and
  SP+64 in seven documented states; IX/BF frames roll back rather than
  inventing the hidden 24/31-word continuation. Normal RETM shares that
  restore, reports ten states, and snapshots a one-shot complete-instruction
  direct-memory bypass. A stale three-word cached MOVI.L proves opcode and
  extensions bypass once before normal lookup resumes; interrupt/single-step
  recognition scheduling remains absent. MMFM/MMTM cover all
  65,536 mask words in both opposite mask directions, every A/B/SP register,
  pointer wrap, logical transaction order, exact MMTM status, and published
  successful timing classes. Empty and pointer-containing lists roll back;
  physical page mode, dynamic-width decomposition, waits, fault/retry, and
  partial-list continuation remain absent. SWAPF covers every
  valid word-local FS0 width/offset, FE0 extension, A/B/SP aliases, exact
  status, five base states, and ordered abstract locked read/write traces;
  crossing use rolls back. Physical lock ownership, waits, retry/fault,
  16-bit targets, I/O routing, and host exclusion remain absent. MPYS/MPYU reproduce
  every arithmetic-consistent primary row, every even FS1 2–32, even-pair and
  odd-low storage, full-product N/Z discriminators, source/destination/SP
  aliases, and C/V preservation. Odd FS1 is atomically rejected rather than
  invented. RSC-0030/OQ-0020 retain the detailed-page/timing-table swap;
  RSC-0031 records the impossible printed operand and RSC-0032/OQ-0021 keeps
  the TMS34010 odd-flag compatibility boundary open.
  MODS/MODU cover every primary row, signed remainder,
  zero-divisor results, same-register/shared-SP aliases, status masks, and
  35/40/3-state cases. RSC-0028 resolves remainder-derived Z; RSC-0029/OQ-0019
  retain the mathematically unreachable published MODS 41-state result.
  DIVS/DIVU cover odd 32/32 and even 64/32 forms,
  quotient/remainder sign rules, range and zero exceptions, A/B/shared-SP
  pairs, status masks, and selected documented state cases. RSC-0027/OQ-0018
  disclose that signed even-pair nonzero early overflow is ambiguous; the model
  provisionally compares normalized magnitudes. CVDXYL/CVMXYL/CVSXYL/CVXYL cover signed coordinates
  and arbitrary pitches, one-/two-power CONVxP paths, offsets/PSIZE, aliases,
  unchanged ST, and pitch-class state selection. RSC-0025 discloses three
  inconsistent PSIZE=4 example rows while the repeated equation is followed;
  RSC-0026 discloses the arbitrary-pitch 14/15-state conflict, for which the
  model provisionally selects the instruction page's 14.
  CPW covers all published outcodes, signed inclusive
  bounds, A/B/SP operands, implied B5/B6 hazards, V-only status, and one state.
  CALL covers every A/B/shared-SP target class and
  capture-before-predecrement ordering; CALLR covers signed extremes/wrap;
  CALLA state is exact while timing remains explicitly incomplete. RETS covers
  all 32 argument counts, both old-SP
  alignment classes, exact stack reads, PC alignment, SP wrap, unchanged ST,
  and 5/6-state cases. RETI normal context covers ordered stack reads,
  wrap/alignment, complete ST/IE restoration, TRAP round trip and seven states;
  OQ-0023 retains IX/BF continuation. TRAP covers every vector, trap-zero no-save behavior,
  aligned/unaligned stack frames, wrap/alignment, and 7/10/12-state cases. REV
  is decoded but atomically rolls back as unsupported
  until a physical-device profile supplies an evidence-backed complete result.
  CMPXY reproduces all primary rows, result-sign C/V
  rather than borrow/overflow, nondestructive A/B/same-register/shared-SP
  behavior, and one state. JACC covers all 16 conditions, every possible false
  outcome, low/high absolute-target assembly, forced alignment, false-path PC
  wrap, exact traces, complete state preservation, and three-/four-state
  cases. Long JRcc covers all 16 conditions, every possible
  false outcome, signed extremes, PC wrap, exact trace fields, complete state
  preservation, and two-/three-state cases. DSJS covers every published row, direction/magnitude
  endpoints, instruction-range endpoints, PC wrap, A/B/shared-SP, exact writes,
  ST preservation, and two-/three-state cases. DSJ, DSJEQ, and DSJNE reproduce
  all published rows,
  both condition outcomes, zero and wrapping decrements, signed displacement
  extremes, PC wrap, A/B/shared-SP selection, ST preservation, and two-/three-
  state instruction-boundary cases. JUMP covers all published targets, A/B/shared-SP
  sources, alignment, source/status preservation, and two states.
  POPST/PUSHST cover full-width stack/status ordering,
  both alignment classes, hidden writes, wraparound, exact abstract
  transactions, and round trip; stack faults/retries and physical transfer
  decomposition remain absent. PUTST covers complete A/B/shared-SP source-to-ST
  transfer and the primary three-state count. EXGF covers both primary rows,
  both field
  banks/files,
  upper-register clearing, nonselected-ST preservation, shared SP, and the
  bank-dependent state count. Other implemented coverage includes complete
  ADDK/INC, SUBK/DEC, MOVK, MOVI, MOVE, MOVX/MOVY, RL constant/register, and
  SLA/SLL/SRA/SRL constant/register forms, LMO, SETCDP/SETCMP/SETCSP, bounded
  BLMOVE, and successful TRAP/TRAPL/VLCOL forms;
  CLR is represented canonically as XOR with equal source/destination fields
  and covers every A/B register encoding, shared SP, Z-only status change, and
  the primary one-state case;
  fetch opcodes/extensions through
  transaction-level cache/retry state with traces, rollback and snapshot
  replay, including GETPC/EXGPC sequential-PC, redirect, alignment, A/B, and
  shared-SP behavior, plus every published ADDXY/SUBXY row and B-file,
  same-register, and shared-SP hazards. The extracted ISA is far from complete;
  BLMOVE overlap,
  continuation/timing, non-cache fault/retry, and full ISA/interfaces remain.
  BTST.K/R cover every primary input row with RSC-0018's one contradictory
  status digit corrected, plus A/B, same-register, and shared-SP cases.
  SETF/SEXT/ZEXT cover sizes 1–32 in both field banks, published rows,
  instruction-specific partial ST writes, A/B selection, and shared SP
  (`TMS20-0006`, `TMS20-0007`).
- RTL status: generated 135-entry partial decode, combinational CEXEC.L/S and
  CMOVGC.1/.2/CMOVCG/CMOVCS formatters with exhaustive command/ID/size/LAD/SF/BCST/I/S/timing,
  ordered-data, and initial/I=1 reissue tests plus explicit noncommit without a
  register-capture or physical command-cycle owner, exhaustive clean-room
  MOVE.RM insertion, MOVE.MR/MR.POST extraction/extension, MOVE.MM two-sided copy/
  alignment, ordinary/postincrement/predecrement single-pointer, paired-
  increment/decrement, signed-offset, mixed source-offset/destination-
  postincrement, absolute low/high address, and fixed-byte register-store/load/
  memory-copy leaves with
  explicit noncommit at the absent memory owner, a clean-room RETI/RETM
  mode plus normal/IX/BF context/result/timing/bypass-delay classification
  leaf, an exhaustive
  clean-room MMFM/MMTM list-normalization/pointer/status/timing control leaf,
  clean-room iterative
  DIVS/DIVU/MODS/MODU and combinational MPYS/MPYU leaves, A/B/SP and masked ST state,
  unary/binary/logical arithmetic plus ADDXYI/CMPK/EXGPS/GETPS/LMO/RMO/RPIX and
  SETC-pitch conversion semantic leaves, and decoder-controlled register/ST
  write intents for 52 one-word instructions, with externally gated one-edge
  state commit and
  ordered-state tests, including same-file and cross-file MOVE with N/Z/V
  replacement and C preservation, MOVX/MOVY half-register merges with
  complete ST preservation, and RL.K/RL.R C/Z replacement with N/V
  preservation, plus all eight SLA/SLL/SRA/SRL forms with direct or
  two's-complement count recovery and instruction-specific status masks;
  standalone native-completion cache lookup/refill RTL;
  a dedicated GETPC/EXGPC/JUMP/JACC/JR.L direct-PC leaf, an integrated serialized
  cache/instruction-packet frontend with explicit completion and abort/reload;
  and a bounded fetch-to-commit path for those 52
  one-word operations plus complete two-word ADDI.W/CMPI.W/MOVI.W/SUBI.W and
  three-word JACC/ANDNI/ORI/XORI/ADDXYI/ADDI.L/CMPI.L/MOVI.L/SUBI.L packets.
  GETPC consumes the packet sequential PC, while EXGPC atomically writes that
  address and redirects to the aligned old destination. JUMP reads an
  A/B/shared-SP target, clears bits `[3:0]`, and redirects through the held
  completion path without a register or status write. MOVI.W
  sign-extends its extension word; both MOVI forms
  replace N/Z/V while preserving C.
  LMO uses a dedicated leading-priority leaf, Z-only masked update, same-file
  selection, shared-SP aliasing, and cache-fed dependent commit coverage.
  ADDXY/SUBXY use a shared independent-half arithmetic leaf, replace NCZV,
  and pass all 25 primary example rows plus A/B, same-register, shared-SP, and
  dependent scalar-commit tests.
  CMPXY uses a dedicated nondestructive leaf: N/Z report X/Y equality while
  C/V report the signs of wrapped Y/X differences. All nine primary rows,
  a result-sign-versus-borrow discriminator, A/B/same-register/shared-SP
  routing, ordered commit, cache-fed execution, and a status-only runtime
  assertion pass; the documented one-state retirement is not implemented.
  TRAP 0 and 31 decode but remain explicitly noncommitting in the RTL router;
  the model's successful entry semantics do not bypass absent stack/vector
  ownership, fault/retry state, or physical timing.
  RETS 0 and 31 likewise decode but remain explicitly noncommitting until a
  stack-read transaction owner can couple memory completion, SP update, and
  direct-PC redirect without violating retry idempotence.
  CALL base/end, CALLR, and CALLA decode with exact packet lengths but remain
  explicitly noncommitting pending stack-write/direct-PC ownership; this also
  prevents an unsupported CALLA timing hypothesis from entering RTL.
  CPW base/end decode and a standalone signed-window comparison leaf pass,
  while the scalar router rejects CPW until Rs, B5, and B6 can be captured and
  destination/V committed atomically.
  DIVS/DIVU/MODS/MODU decode and a standalone 32-step restoring-divider leaf pass
  directed signed/unsigned single/pair, zero, early-overflow, range-overflow,
  SP-alias, result, flag, and handshake checks. The scalar router rejects both
  divide forms until a sequencer can capture and commit a pair atomically;
  modulus mode additionally verifies remainder-derived status, zero divisor,
  and quotient-overflow-with-valid-remainder while remaining noncommitting.
  The FPGA
  step count is not architectural timing.
  MPYS/MPYU decode and a standalone multiplier leaf pass signed/unsigned,
  every representative FS1 class, full-product status discriminators, raw-Rs
  timing selection, and illegal-odd-FS1 checks. The scalar router rejects both
  forms until one owner can capture operands and commit either an even pair or
  odd single result plus status atomically; the leaf state output remains
  provisional under RSC-0030.
  MMFM/MMTM base/end decode and all 65,536 direct/reversed masks pass, with
  explicit noncommit guards until a page-mode/fault-aware memory owner exists.
  SWAPF decode and its standalone field-transform leaf pass full and
  positioned fields, FE0 extension, status, valid-boundary and crossing
  classification. The router rejects it pending a locked memory/commit owner.
  CVDXYL/CVMXYL/CVSXYL/CVXYL decode and a standalone signed conversion leaf
  pass all pitch classes, PSIZE/mask-X, offsets, wrap, and published state-case
  checks; the scalar router rejects them until explicit/implied registers,
  CONVxP, PSIZE, and destination ownership can be captured atomically.
  CLR requires no duplicate execution opcode: the existing XOR path decodes
  all 32 same-register alias words, routes equal source/destination selectors,
  clears the selected A/B/shared-SP register, sets Z, and preserves N/C/V.
  BTST.K/R use an independent selected-bit leaf, recover complemented constant
  or low-five-bit register counts, preserve the destination, and update only Z;
  all 25 primary input rows plus A/B, same-register, shared-SP, and dependent
  scalar-commit cases pass.
  SETF selects and atomically writes either six-bit field-parameter bank;
  SEXT/ZEXT consume the selected size through a dedicated all-width extension
  leaf, update only N/Z or Z, and pass A/B/shared-SP plus dependent scalar
  commit tests.
  EXGF atomically exchanges either field bank with an A/B/shared-SP destination,
  clears the destination upper bits, preserves nonselected ST bits, and passes
  dependent two-bank scalar commits; its documented one-/two-state retirement
  split is not implemented.
  PUTST replaces all 32 ST bits from an A/B/shared-SP source without register
  writeback and passes a cache-fed dependency; its three-state architectural
  retirement is not implemented.
  Complete JACC packets consume both extension words, evaluate all 16 NCZV
  predicates, preserve registers and ST, and hold either an aligned absolute
  redirect or sequential fallthrough through completion. Direct tests exhaust
  all 256 condition/status cells and cache-fed taken/false paths. The documented
  three-/four-state retirement is not implemented. Long JRcc evaluates all 16
  NCZV predicates through a shared combinational
  condition function, preserves registers and ST, and holds a signed
  extension-word redirect when true or completes sequentially when false.
  Direct tests exhaust all 256 condition/status combinations and signed/PC-wrap
  targets; cache-fed taken and false paths pass. Its documented two-/three-state
  retirement is not implemented. JUMP functional redirect semantics pass, but
  its documented two-state retirement is not implemented. DSJS always
  decrements its A/B/shared-SP
  destination, preserves ST, and holds its encoded forward/backward short
  redirect for a nonzero result; its documented two-/three-state retirement is
  not implemented. DSJ/DSJEQ/DSJNE
  conditionally decrement
  A/B/shared-SP destinations, preserve ST, and issue signed relative redirects
  only for nonzero results; their documented two-/three-state retirement is not
  implemented. POPST and PUSHST remain blocked and noncommitting pending
  memory-transaction ownership.
  There is no architectural completion timing or
  complete executable processor core (`TMS20-0009`–`TMS20-0011`)
- Cache status: primary organization/refill/reset/disable/flush and
  current-cycle fault/retry contracts are covered by the model and bounded RTL;
  RTL covers lookup/refill/LRU, CD/idle-CF, delayed P commit, backpressure,
  retry, fault resume/abort, refill-state reset, and three randomized seeds.
  CPU fault/interrupt state, bus-width/page scheduling and pin timing remain
  (`TMS20-0012`, `TMS20-0017`)
- Graphics status: CPW signed inclusive window/outcode and all four
  XY-to-linear conversion semantics exist in the model and standalone RTL
  leaves; the full pixel/graphics matrix, I/O/register owner, memory sequencer,
  clipping, and continuation remain (`TMS20-0024`–`TMS20-0026`)
- Bus status: cache-native completion plus logical ordinary/postincrement/
  predecrement/signed-offset/mixed-offset/absolute RM/MR/MM
  field-store/load/copy, pointer-update, and indirect/signed-offset/absolute
  MOVB byte-store/load/copy
  geometry only; no BEN/byte-strobe/RMW/width/page/pin controller
  (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: four cache, four fetch, twenty-three scalar, two commit-owner,
  and three divider
  SVAs run in simulation only;
  SymbiYosys unavailable, so no bounded or unbounded proof result exists
- Synthesis status: leaf, bounded-cache/fetch, composed frontend, and scalar
  composition Quartus 17.0.2 Analysis & Synthesis pass with 0 errors/0
  warnings; the current decoder-bearing leaf wrapper uses 13,295 logic cells,
  2,230 registers, and 9 DSP blocks, while
  the fetch, frontend, and scalar wrappers use 491, 873, and 5,486 logic cells;
  the scalar wrapper has 1,416 registers and 4,096 block-memory bits; Yosys
  unavailable; no fit or TimeQuest result
- Documentation acquired: nine hash-verified TI documents, an eleven-file
  pinned MAME source set, and an eleven-file pinned prior FPGA source set; all
  payloads are gitignored. The prior FPGA source has no license and is
  reference-only, explicitly incomplete, and not copied or adapted
- Provisional behavior: the cache model represents architecturally
  uninitialized SSAs as abstract `None` tags and exposes native 32-bit refill
  transactions rather than pin-level dynamic-width cycles;
  ordinary/postincrement/predecrement/signed-offset/mixed-offset/absolute RM/MR/MM and all nine MOVB store/load/copy forms reject
  BEN=1 and expose logical field transactions rather than physical bus beats
- Unresolved conflicts: exact game parts and REV values, original/A errata,
  first-silicon history, the MPYS/MPYU detailed-page/timing-table swap and
  TMS34010 odd-product flag boundary, the unreachable published MODS 41-state result,
  signed even-pair DIVS nonzero early-overflow behavior,
  CVXYL's three contradictory PSIZE=4 table rows, its arbitrary-pitch
  14/15-state primary timing disagreement, MMFM's unexplained statement
  that original-Rp alignment affects timing despite no corresponding timing
  table class, MOVE.MR.POST same-register write priority (RSC-0036/OQ-0024),
  MOVE.MM.POST same-register final pointer (RSC-0037/OQ-0025),
  RETI/RETM's undisclosed IX/BF internal-frame layout/padding/
  restore order, and the absent RETM one-instruction interrupt-recognition
  scheduler
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: continue primary ISA extraction and preserve explicit noncommit
  until each newly classified form has independent model and RTL semantics
