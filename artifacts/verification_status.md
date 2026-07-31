# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 79 encoding records/25,266 first words | 28 `make isa-tests` cases include all DSJS direction/magnitude/file boundaries, embedded-offset metadata, two-/three-state timing, CMPK/ADD adjacency, the DSJ-family matrix, and a complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for all 79 currently extracted forms, cache-integrated fetch | 129 directed `make model-tests` cases cover every DSJS published row, forward/backward zero/max magnitudes, instruction-range endpoints, PC wrap, A/B/shared-SP, exact writes, ST preservation, and two-/three-state cases. Existing evidence also covers all 15 DSJ-family rows, JUMP, POPST/PUSHST, PUTST, EXGF, every SETF/SEXT/ZEXT size, every primary BTST row, XY/LMO/shift/register/immediate forms, bounded BLMOVE, TRAPL/VLCOL, cache and fetch integration. The unextracted ISA, stack fault/retry/physical transfers, BLMOVE continuation/timing, interfaces, and the full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | DSJS executes as a complete one-word packet: leaf tests cover zero/nonzero results, zero/max magnitudes, both directions, A/B/shared-SP destinations, PC wrap, and status neutrality; a cache-fed scalar test reaches the backward maximum wrapped target. DSJ/DSJEQ/DSJNE execute as complete two-word packets with enabled/suppressed conditions, decrement-to-zero, wrapping decrement, signed forward/backward targets, PC wrap, shared SP, and status-neutral held redirects. JUMP reads A/B/shared-SP targets, aligns bits `[3:0]`, redirects through scalar frontend completion, and performs no register/status write. POPST/PUSHST remain rejected pending memory ownership. No timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; twenty-eight runtime SVAs simulation-enabled | Four cache, four fetch, eighteen scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
