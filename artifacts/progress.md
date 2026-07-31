# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest commit: `e144c189d0aeacb547b5de080793770f8c99874f`
- Passing tests: foundation, reference/hash, delta, ISA sweep, 18 directed model
  cases, warning-free Verilator lint, verified RTL leaf simulation, and
  warning-free Quartus Cyclone V leaf Analysis & Synthesis
- Failing tests: none observed
- Model status: independent state/replay plus 9 of 15 extracted instructions;
  full ISA/cache/interfaces not implemented (`TMS20-0007`)
- RTL status: generated partial decode, A/B/SP register file, and
  ADDXYI/CMPK/EXGPS/GETPS/RMO/RPIX semantic leaves; no executable processor
  core (`TMS20-0009`–`TMS20-0011`)
- Cache status: not implemented (`TMS20-0012`)
- Graphics status: not implemented (`TMS20-0024`–`TMS20-0026`)
- Bus status: not implemented (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: not implemented; SymbiYosys unavailable locally
- Synthesis status: leaf-only Quartus 17.0.2 Analysis & Synthesis passes with
  0 errors/0 warnings; Yosys unavailable; no fit or TimeQuest result
- Documentation acquired: eight hash-verified TI documents plus an eleven-file
  pinned MAME source set; all payloads are gitignored
- Provisional behavior: none implemented
- Unresolved conflicts: exact game parts, original/A errata and first-silicon
  history
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: expand primary ISA extraction, then add status/writeback and the
  smallest page-verified execution path without asserting pipeline accuracy
