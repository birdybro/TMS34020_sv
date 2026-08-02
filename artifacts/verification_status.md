# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 88 encoding records/25,940 first words | 36 `make isa-tests` cases cover all CALL register forms, exact CALLA/CALLR fixed forms and lengths, retained timing ambiguity, all RETS/TRAP/REV encodings, CMPXY boundaries, CLR aliases, JAcc/long-JR conditions, neighboring rejection, and the complete 65,536-word unique-decode sweep; full decode and RSC-0020–RSC-0024 remain `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 87 of 88 currently extracted forms, cache-integrated fetch | 144 directed `make model-tests` cases cover all CALL A/B/shared-SP target classes, read-before-SP-write ordering, hidden-write alignments, CALLR signed extremes/wrap, and CALLA state with explicitly incomplete timing, plus all prior RETS/TRAP cases. REV remains exact full-snapshot rollback pending a profile. The unextracted ISA, physical stack transfers/faults/retries, BLMOVE continuation/timing, interfaces, and full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | CALL base/end, CALLR, CALLA, RETS 0/31, TRAP 0/31, and REV base/end words decode, while direct guards prove they produce no execution support, register write, or status write without their missing owners. CMPXY, every CLR alias, JACC/JR.L, DSJ, JUMP, and other bounded scalar operations retain their evidence; POPST/PUSHST remain rejected pending memory ownership. No timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-three runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
