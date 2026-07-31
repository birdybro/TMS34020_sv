# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 81 encoding records/25,298 first words | 30 `make isa-tests` cases include all 16 JAcc and long-JR conditions, exact `C?80h`/`C?00h` classification, target/timing metadata, neighboring short-JR rejection, and a complete 65,536-word unique-decode sweep; full decode and RSC-0020 remain `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for all 81 currently extracted forms, cache-integrated fetch | 133 directed `make model-tests` cases include every JACC predicate/outcome, low/high target assembly, forced alignment, false-path PC wrap, exact trace/state preservation, and three-/four-state cases plus the existing complete JR.L matrix and prior instruction/cache coverage. The unextracted ISA, stack fault/retry/physical transfers, BLMOVE continuation/timing, interfaces, and the full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | JACC exhausts all 256 condition-code/NCZV cells through direct execution, consumes the low/high target words, forces alignment, remains register/status neutral, and passes direct, commit, and cache-fed taken/false paths with exact redirects/fallthrough. JR.L retains corresponding signed-relative coverage. The previously verified DSJS, DSJ/DSJEQ/DSJNE, JUMP, and other bounded scalar operations remain executable; POPST/PUSHST remain rejected pending memory ownership. No timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-two runtime SVAs simulation-enabled | Four cache, four fetch, twenty-two scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
