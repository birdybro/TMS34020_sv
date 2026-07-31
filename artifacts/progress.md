# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest commit: `5b4b82a930e16dca166709d22e3892b30a5a3962`
- Passing tests: foundation, reference/hash, delta, ISA sweep, 47 directed model
  cases, warning-free Verilator lint, verified RTL leaf simulation, and
  warning-free Quartus Cyclone V leaf Analysis & Synthesis
- Failing tests: none observed
- Model status: independent state/replay plus 32 of 38 extracted instructions
  and a standalone transaction-level cache/retry model; cache is not connected
  to instruction stepping and full ISA/interfaces remain (`TMS20-0007`)
- RTL status: generated partial decode, A/B/SP and masked ST state,
  unary/binary/logical arithmetic plus ADDXYI/CMPK/EXGPS/GETPS/RMO/RPIX
  semantic leaves, and decoder-controlled register/ST write intents for 23
  one-word instructions, with externally gated one-edge state commit and
  ordered-state tests; no fetch, PC sequencing, architectural completion
  timing, or executable processor core
  (`TMS20-0009`–`TMS20-0011`)
- Cache status: primary organization/refill/reset/disable/flush and
  current-cycle fault/retry contracts are covered by 11 independent-model
  tests; instruction-fetch integration, randomized tests, RTL, interrupts,
  bus-width scheduling and pin timing remain (`TMS20-0012`)
- Graphics status: not implemented (`TMS20-0024`–`TMS20-0026`)
- Bus status: not implemented (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: not implemented; SymbiYosys unavailable locally
- Synthesis status: leaf-only Quartus 17.0.2 Analysis & Synthesis passes with
  0 errors/0 warnings; Yosys unavailable; no fit or TimeQuest result
- Documentation acquired: eight hash-verified TI documents plus an eleven-file
  pinned MAME source set; all payloads are gitignored
- Provisional behavior: the cache model represents architecturally
  uninitialized SSAs as abstract `None` tags and exposes native 32-bit refill
  transactions rather than pin-level dynamic-width cycles
- Unresolved conflicts: exact game parts, original/A errata and first-silicon
  history
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: connect the cache model to instruction-word fetch with explicit
  trace and rollback behavior, without assigning unverified cache-miss cycles
