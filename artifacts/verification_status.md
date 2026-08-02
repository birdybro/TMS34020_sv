# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 124 encoding records/45,752 first words | 65 `make isa-tests` cases add indirect, signed-offset and absolute register-to-memory MOVB families and exact 8C00h/AC00h/05E0h boundaries beside prior forms, plus the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 123 of 124 extracted forms over documented domains, cache-integrated fetch | 206 directed `make model-tests` cases add every byte value/offset for three register-to-memory MOVB forms, indirect/signed-offset/absolute address ordering, A/B/SP/alias capture, ST preservation, timing traces and BEN rollback beside exhaustive MOVE field coverage. MOVE.MR.POST same-register data priority is CORROBORATED under RSC-0036/OQ-0024; MM.POST's final alias pointer is CORROBORATED under RSC-0037/OQ-0025. REV is exact rollback. Physical page/wait/fault/retry/16-bit/BEN behavior, continuation, unextracted ISA, interfaces, and full model remain |
| RTL semantics | Partial leaves plus bounded scalar composition | Clean-room fixed-byte store, field insertion/extraction/copy, address, and timing leaves exhaust MOVB register-store and MOVE geometry while the execution router prevents memory-less commit. RETI/RETM and prior leaves remain. No field-memory, return, multiple-register or complete executable sequencer exists |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic byte/field/stack/multiple-transfer/SWAPF boundaries | Three MOVB register stores add logical fixed-byte writes and indirect/signed-offset/absolute addressing beside the MOVE field forms, but no BEN/request/byte-strobe/RMW owner. RETI, MMFM/MMTM and SWAPF remain similarly abstract. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
