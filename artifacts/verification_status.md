# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 83 encoding records/25,842 first words | 33 `make isa-tests` cases include exact REV and CMPXY base/end metadata, all 32 CLR alias encodings, all 16 JAcc and long-JR conditions, neighboring short-JR rejection, and a complete 65,536-word unique-decode sweep; full decode and RSC-0020/RSC-0021 remain `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 82 of 83 currently extracted forms, cache-integrated fetch | 137 directed `make model-tests` cases include exact full-snapshot rollback for decoded REV pending a verified device profile, while retaining all prior CMPXY/instruction/cache coverage. The unextracted ISA, REV profile, stack fault/retry/physical transfers, BLMOVE continuation/timing, interfaces, and the full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | REV base/end words decode, while a direct noncommit guard proves `0020h` produces no execution support, register write, or status write without a device profile. CMPXY, every CLR alias, JACC/JR.L, the DSJ family, JUMP, and other bounded scalar operations retain their directed evidence; POPST/PUSHST remain rejected pending memory ownership. No timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-three runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
