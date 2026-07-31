# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest commit: `70beb4b3654b9e7d263d9c6f35e63132a3c6b16c`
- Passing tests: foundation, reference/hash, delta, ISA sweep, 58 directed model
  cases, warning-free Verilator lint, directed RTL leaf/cache simulation, three
  deterministic randomized cache seeds, bounded instruction-packet and
  integrated cache/fetch frontend and bounded scalar-composition tests, and
  warning-free Quartus Cyclone V leaf/cache/fetch/frontend/scalar Analysis &
  Synthesis
- Failing tests: none observed
- Model status: 36 of 42 extracted encoding forms fetch opcodes/extensions
  through transaction-level cache/retry state with traces, rollback and
  snapshot replay; full ISA/interfaces remain (`TMS20-0007`)
- RTL status: generated partial decode, A/B/SP and masked ST state,
  unary/binary/logical arithmetic plus ADDXYI/CMPK/EXGPS/GETPS/RMO/RPIX
  semantic leaves, and decoder-controlled register/ST write intents for 23
  one-word instructions, with externally gated one-edge state commit and
  ordered-state tests; standalone native-completion cache lookup/refill RTL;
  an integrated serialized cache/instruction-packet frontend with explicit
  completion and abort/reload; and a bounded fetch-to-commit path for those 23
  one-word operations plus complete two-word ADDI.W and three-word
  ANDNI/ORI/XORI/ADDXYI/ADDI.L packets. All other unsupported packets block.
  There is no architectural completion timing or complete executable
  processor core (`TMS20-0009`–`TMS20-0011`)
- Cache status: primary organization/refill/reset/disable/flush and
  current-cycle fault/retry contracts are covered by the model and bounded RTL;
  RTL covers lookup/refill/LRU, CD/idle-CF, delayed P commit, backpressure,
  retry, fault resume/abort, refill-state reset, and three randomized seeds.
  CPU fault/interrupt state, bus-width/page scheduling and pin timing remain
  (`TMS20-0012`, `TMS20-0017`)
- Graphics status: not implemented (`TMS20-0024`–`TMS20-0026`)
- Bus status: cache-native completion subset only; no width/page/pin controller
  (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: four cache, four fetch, and three scalar acceptance/noncommit
  SVAs run in simulation only;
  SymbiYosys unavailable, so no bounded or unbounded proof result exists
- Synthesis status: leaf, bounded-cache/fetch, composed frontend, and scalar
  composition Quartus 17.0.2 Analysis & Synthesis pass with 0 errors/0
  warnings; the scalar wrapper uses 3,679 logic cells, 1,357 registers, and
  4,096 block-memory bits; Yosys unavailable; no fit or TimeQuest result
- Documentation acquired: eight hash-verified TI documents plus an eleven-file
  pinned MAME source set; all payloads are gitignored
- Provisional behavior: the cache model represents architecturally
  uninitialized SSAs as abstract `None` tags and exposes native 32-bit refill
  transactions rather than pin-level dynamic-width cycles
- Unresolved conflicts: exact game parts, original/A errata and first-silicon
  history
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: qualify the extracted SUBI.W and SUBI.L forms through
  complete-packet RTL execution while preserving complemented object-word
  handling and the timing non-claim
