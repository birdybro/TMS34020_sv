# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 89 encoding records/26,452 first words | 37 `make isa-tests` cases cover all 512 CPW forms/metadata, CALL-family, RETS/TRAP/REV, CMPXY, aliases, condition forms, neighboring rejection, and the complete 65,536-word unique-decode sweep; full decode and disclosed conflicts remain `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 88 of 89 extracted forms, cache-integrated fetch | 145 directed `make model-tests` cases add every published CPW row, signed/inclusive boundaries, A/B/SP operands, implied B5/B6 hazards, V-only status, and one state to the prior CALL/RETS/TRAP coverage. REV remains exact rollback pending a profile. Unextracted ISA, physical stack transfers/faults/retries, BLMOVE continuation/timing, interfaces, and full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | CPW base/end decode and direct signed-window leaf tests pass; a router guard proves no commit without simultaneous Rs/B5/B6 ownership. CALL-family, RETS, TRAP, and REV retain noncommit guards. Existing scalar operations retain their evidence; no timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-three runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
