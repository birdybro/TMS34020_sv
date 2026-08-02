# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 134 encoding records/48,026 first words | 74 `make isa-tests` cases add both CMOVGC source families and retain exact CEXEC, command/source/reserved/page-reissue contracts, neighbors, and the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 133 of 134 extracted forms over documented domains, cache-integrated fetch | 214 directed `make model-tests` cases add exhaustive CMOVGC first/second sources, ID/size/alignment/order, logical outbound data, timing metadata and reserved rollback beside CEXEC/MOVE/MOVB. REV is exact rollback. Physical coprocessor acceptance, page/wait/fault/retry/16-bit/BEN behavior, continuation, unextracted ISA, interfaces, and full model remain |
| RTL semantics | Partial leaves plus bounded scalar composition | Clean-room CEXEC and CMOVGC formatting exhausts both command forms and both register-source forms, including ordered data and initial/I=1 LAD packets, with explicit router noncommit; prior leaves remain. No coprocessor handshake, register capture, field-memory, return, multiple-register or complete executable sequencer exists |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic byte/field/stack/multiple-transfer/SWAPF boundaries | All nine MOVB register/memory/copy forms add logical fixed-byte writes, signed loads/status, read-before-write overlap and indirect/signed-offset/absolute addressing beside MOVE, but no BEN/request/byte-strobe/RMW owner. RETI, MMFM/MMTM and SWAPF remain similarly abstract. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Coprocessor | Partial CEXEC/CMOVGC instruction/formatter boundary | Long/short CEXEC and one/two-register CMOVGC model/RTL matrices verify command, source selectors, ordered data, ID, size, initial/I=1 LAD, state preservation and primary state classes. No physical handshake/page decision, LRDY/BUSFLT/retry/fault path, other CMOV transfer, or synthetic coprocessor exists; `TMS20-0021` remains |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
