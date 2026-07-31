# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest commit: `efb69c6b146fa6e21a4feba1efbc46805bcd069a`
- Passing tests: foundation, reference/hash, delta, ISA sweep, 22 directed model
  cases, warning-free Verilator lint, verified RTL leaf simulation, and
  warning-free Quartus Cyclone V leaf Analysis & Synthesis
- Failing tests: none observed
- Model status: independent state/replay plus 13 of 19 extracted instructions;
  full ISA/cache/interfaces not implemented (`TMS20-0007`)
- RTL status: generated partial decode, A/B/SP register file, and
  ABS/NEG/NEGB/NOT/ADDXYI/CMPK/EXGPS/GETPS/RMO/RPIX semantic leaves; no
  executable processor core (`TMS20-0009`–`TMS20-0011`)
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
