# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 80 encoding records/25,282 first words | 29 `make isa-tests` cases include all 16 long-JR conditions, exact `C?00h` classification, signed relative metadata, two-/three-state timing, neighboring short-JR/JAcc rejection, and a complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 79 of 80 currently extracted forms, cache-integrated fetch | 130 directed `make model-tests` cases retain all prior successful instruction coverage and prove exact full-state rollback for newly decoded JR.L until its independent handler exists. The unimplemented/unextracted ISA, stack fault/retry/physical transfers, BLMOVE continuation/timing, interfaces, and the full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | JR.L is decoded and assembled into a complete two-word packet, but direct execution, register execution, commit, and cache-fed scalar guards require it to remain nonmutating and nonredirecting. The previously verified DSJS, DSJ/DSJEQ/DSJNE, JUMP, and other bounded scalar operations remain executable; POPST/PUSHST remain rejected pending memory ownership. No timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; twenty-eight runtime SVAs simulation-enabled | Four cache, four fetch, eighteen scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
