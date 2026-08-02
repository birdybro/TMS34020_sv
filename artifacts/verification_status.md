# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 99 encoding records/30,612 first words | 41 `make isa-tests` cases cover all 1,024 MPYS/MPYU, 1,024 MODS/MODU, 1,024 DIVS/DIVU, and 1,088 XY-conversion forms/metadata, plus prior fixtures and the complete 65,536-word unique-decode sweep; full decode and disclosed conflicts remain `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 98 of 99 extracted forms over documented domains, cache-integrated fetch | 156 directed `make model-tests` cases add every reliable MPYS/MPYU primary row, every even FS1, full-versus-low flag discriminators, alias capture, provisional timing, and atomic odd-FS1 rejection. Divide/modulus and prior coverage remain; REV is exact rollback. Unextracted ISA, physical multiply retirement, stack/fault behavior, interfaces, and full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | The clean-room multiplier leaf passes signed/unsigned FS1 products, full-product N/Z, legality, and provisional state classification; router guards prevent pair/single commits without an owner. The divide/modulus and prior evidence remains. No multiply/divide/modulus retirement timing or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
