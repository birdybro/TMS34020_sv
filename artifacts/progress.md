# Progress

- Current milestone: device/delta research and architecture extraction
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest commit: `2400f4019fae4b61272bafbb16cb5914bd52eecb`
- Passing tests: foundation, reference-manifest/hash, reuse-audit, and
  device-scope/delta schema and required-feature coverage checks
- Failing tests: none observed
- Model status: independent state/replay plus 5 of 11 extracted instructions;
  full ISA/cache/interfaces not implemented (`TMS20-0007`)
- RTL status: not implemented (`TMS20-0009`, `TMS20-0010`)
- Cache status: not implemented (`TMS20-0012`)
- Graphics status: not implemented (`TMS20-0024`–`TMS20-0026`)
- Bus status: not implemented (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: not implemented; SymbiYosys unavailable locally
- Synthesis status: RTL absent; Yosys unavailable; Quartus 17.0 available
- Documentation acquired: seven hash-verified TI documents plus an eleven-file
  pinned MAME source set; all payloads are gitignored
- Provisional behavior: none implemented
- Unresolved conflicts: exact game parts, original/A errata and first-silicon
  history
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: expand primary ISA extraction and implement the independent
  architectural-model state/first verified instruction slice
