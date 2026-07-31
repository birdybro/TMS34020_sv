# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest commit: `b2ff91a7cfe3bfca66c4c4063a0ff88a8ce60fe8`
- Passing tests: foundation, reference/hash, delta, ISA sweep, 52 directed model
  cases, warning-free Verilator lint, directed RTL leaf/cache simulation, three
  deterministic randomized cache seeds, bounded instruction-packet fetch, and
  warning-free Quartus Cyclone V leaf/cache/fetch Analysis & Synthesis
- Failing tests: none observed
- Model status: 32 of 38 extracted instructions fetch opcodes/extensions
  through transaction-level cache/retry state with traces, rollback and
  snapshot replay; full ISA/interfaces remain (`TMS20-0007`)
- RTL status: generated partial decode, A/B/SP and masked ST state,
  unary/binary/logical arithmetic plus ADDXYI/CMPK/EXGPS/GETPS/RMO/RPIX
  semantic leaves, and decoder-controlled register/ST write intents for 23
  one-word instructions, with externally gated one-edge state commit and
  ordered-state tests; standalone native-completion cache lookup/refill RTL;
  plus a serialized aligned instruction-packet fetch/PC cursor with explicit
  completion and abort/reload. Cache, fetch, execution, and commit remain
  separate, with no architectural completion timing or executable processor
  core
  (`TMS20-0009`–`TMS20-0011`)
- Cache status: primary organization/refill/reset/disable/flush and
  current-cycle fault/retry contracts are covered by the model and bounded RTL;
  RTL covers lookup/refill/LRU, CD/idle-CF, delayed P commit, backpressure,
  retry, fault resume/abort, refill-state reset, and three randomized seeds.
  CPU fault/interrupt state, bus-width/page scheduling and pin timing remain
  (`TMS20-0012`, `TMS20-0017`)
- Graphics status: not implemented (`TMS20-0024`–`TMS20-0026`)
- Bus status: cache-native completion subset only; no width/page/pin controller
  (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: four cache and four fetch SVAs run in simulation only;
  SymbiYosys unavailable, so no bounded or unbounded proof result exists
- Synthesis status: leaf, bounded-cache, and bounded-fetch Quartus 17.0.2
  Analysis & Synthesis pass with 0 errors/0 warnings; cache uses 375 logic
  cells, 200 registers and 4,096 block-memory bits; fetch uses 343 logic cells
  and 174 registers; Yosys unavailable; no fit or TimeQuest result
- Documentation acquired: eight hash-verified TI documents plus an eleven-file
  pinned MAME source set; all payloads are gitignored
- Provisional behavior: the cache model represents architecturally
  uninitialized SSAs as abstract `None` tags and exposes native 32-bit refill
  transactions rather than pin-level dynamic-width cycles
- Unresolved conflicts: exact game parts, original/A errata and first-silicon
  history
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: integrate the bounded cache and packet assembler and verify
  cold-miss/hit/abort instruction sequences before connecting execution
