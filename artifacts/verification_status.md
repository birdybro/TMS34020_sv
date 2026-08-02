# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 93 encoding records/27,540 first words | 38 `make isa-tests` cases cover all 1,088 XY-conversion forms/metadata, CPW, CALL-family, RETS/TRAP/REV, aliases, neighboring rejection, and the complete 65,536-word unique-decode sweep; full decode and disclosed conflicts remain `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 92 of 93 extracted forms, cache-integrated fetch | 148 directed `make model-tests` cases cover all four XY conversions, signed coordinates/pitches, every pitch class, PSIZE/offset and alias cases, unchanged ST, and 2/3/4/14 states. CPW/CALL/RETS/TRAP retain coverage; REV remains exact rollback. Unextracted ISA, physical stack/fault behavior, BLMOVE continuation, interfaces, and full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | All four XY-conversion ranges and direct signed arithmetic/class/timing leaf tests pass; router guards prove no commit without implied register/I/O ownership. CPW and CALL-family/RETS/TRAP/REV retain guards. Existing scalar operations retain evidence; no timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-three runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
