# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 38 entries/6,608 first words | `make isa-tests`; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, 32 instructions, cache-integrated fetch | 52 directed `make model-tests` cases, including TI logical rows, 11 cache transaction cases and 5 fetch-integration cases; full model remains `TMS20-0007` |
| RTL semantics | Partial leaves plus serialized packet fetch | `make rtl-leaf-tests`: 38-entry partial decode, A/B/SP, masked ST, arithmetic/logical and TMS34020 leaves, write intents, and 17 ordered commit checks; `make fetch-tests`: aligned one-/three-word packets, metadata, backpressure, explicit completion, redirect, invalid, abort/reload and wrap; no cache/fetch/execution composition, timed retirement, or executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; four cache and four fetch SVAs simulation-enabled | Cache request/response/present/fault safety and fetch request/packet/alignment/abort safety run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
