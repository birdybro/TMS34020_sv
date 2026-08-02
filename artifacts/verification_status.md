# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 107 encoding records/34,262 first words | 48 `make isa-tests` cases add full MOVE.MM two-sided timing metadata and range boundaries beside MOVE.RM/MR and prior families, plus the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 106 of 107 extracted forms over documented domains, cache-integrated fetch | 178 directed `make model-tests` cases cover exhaustive MOVE.RM/MR/MM little-endian banks/FE/width/source/destination geometry, crossing preservation, A/B/SP/alias/overlap ordering, status, timing traces, and atomic BEN rollback. REV is exact rollback. Physical page/wait/fault/retry/16-bit/BEN behavior, continuation, unextracted ISA, interfaces, and full model remain |
| RTL semantics | Partial leaves plus bounded scalar composition | Clean-room MOVE.RM insertion, MOVE.MR extraction/extension and MOVE.MM copy leaves exhaust two-word little-endian geometry, all 25 case pairs and timing classification while the execution router prevents memory-less commit. RETI/RETM and prior leaves remain. No field-memory, return, multiple-register or complete executable sequencer exists |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic field/stack/multiple-transfer/SWAPF boundaries | MOVE.RM/MR/MM add logical crossing stores/loads/copies and two-word leaves but no BEN/request/byte-strobe/RMW owner. RETI, MMFM/MMTM and SWAPF remain similarly abstract. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
