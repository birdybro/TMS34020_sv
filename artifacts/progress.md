# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest verified baseline commit: `f0693430ff62dd6a583b4b1f8d2f5dd7a13ea9d0`
- Passing tests: foundation, reference/hash, delta, 32-case ISA sweep, 135 directed model
  cases, warning-free Verilator lint, directed RTL leaf/cache simulation, three
  deterministic randomized cache seeds, bounded instruction-packet and
  integrated cache/fetch frontend and bounded scalar-composition tests, and
  warning-free Quartus Cyclone V leaf/cache/fetch/frontend/scalar Analysis &
  Synthesis
- Failing tests: none observed
- Model status: 81 of 82 currently extracted encoding forms have bounded
  successful semantics; CMPXY decodes but has an exact unsupported
  state/cache rollback guard pending its independent handler. JACC covers all
  16 conditions, every possible false
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
  BLMOVE, and successful TRAPL/VLCOL forms;
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
- RTL status: generated 82-entry partial decode, A/B/SP and masked ST state,
  unary/binary/logical arithmetic plus ADDXYI/CMPK/EXGPS/GETPS/LMO/RMO/RPIX and
  SETC-pitch conversion semantic leaves, and decoder-controlled register/ST
  write intents for 51 one-word instructions, with externally gated one-edge
  state commit and
  ordered-state tests, including same-file and cross-file MOVE with N/Z/V
  replacement and C preservation, MOVX/MOVY half-register merges with
  complete ST preservation, and RL.K/RL.R C/Z replacement with N/V
  preservation, plus all eight SLA/SLL/SRA/SRL forms with direct or
  two's-complement count recovery and instruction-specific status masks;
  standalone native-completion cache lookup/refill RTL;
  a dedicated GETPC/EXGPC/JUMP/JACC/JR.L direct-PC leaf, an integrated serialized
  cache/instruction-packet frontend with explicit completion and abort/reload;
  and a bounded fetch-to-commit path for those 51
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
- Graphics status: not implemented (`TMS20-0024`–`TMS20-0026`)
- Bus status: cache-native completion subset only; no width/page/pin controller
  (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: four cache, four fetch, twenty-two scalar, and two commit-owner
  SVAs run in simulation only;
  SymbiYosys unavailable, so no bounded or unbounded proof result exists
- Synthesis status: leaf, bounded-cache/fetch, composed frontend, and scalar
  composition Quartus 17.0.2 Analysis & Synthesis pass with 0 errors/0
  warnings; the current decoder-bearing leaf wrapper uses 8,723 logic cells
  and 2,048 registers, while
  the fetch, frontend, and scalar wrappers use 411, 785, and 5,262 logic cells;
  the scalar wrapper has 1,414 registers and 4,096 block-memory bits; Yosys
  unavailable; no fit or TimeQuest result
- Documentation acquired: nine hash-verified TI documents plus an eleven-file
  pinned MAME source set; all payloads are gitignored
- Provisional behavior: the cache model represents architecturally
  uninitialized SSAs as abstract `None` tags and exposes native 32-bit refill
  transactions rather than pin-level dynamic-width cycles
- Unresolved conflicts: exact game parts, original/A errata and first-silicon
  history
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: continue primary ISA extraction and preserve explicit noncommit
  until each newly classified form has independent model and RTL semantics
