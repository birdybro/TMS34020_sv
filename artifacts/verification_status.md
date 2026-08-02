# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 132 encoding records/47,962 first words | 73 `make isa-tests` cases add exact long CEXEC and all 128 short first words, command-field contracts, reserved neighbors, and the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 131 of 132 extracted forms over documented domains, cache-integrated fetch | 212 directed `make model-tests` cases add exhaustive CEXEC command/ID/size/alignment/short-word reconstruction, state preservation, logical command traces, timing metadata, and reserved rollback beside MOVE/MOVB coverage. REV is exact rollback. Physical coprocessor acceptance, page/wait/fault/retry/16-bit/BEN behavior, continuation, unextracted ISA, interfaces, and full model remain |
| RTL semantics | Partial leaves plus bounded scalar composition | Clean-room CEXEC command formatting now exhausts both encodings and exposes exact LAD/SF/BCST/I/S with explicit router noncommit; prior memory/state/result leaves remain. No coprocessor handshake, field-memory, return, multiple-register or complete executable sequencer exists |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic byte/field/stack/multiple-transfer/SWAPF boundaries | All nine MOVB register/memory/copy forms add logical fixed-byte writes, signed loads/status, read-before-write overlap and indirect/signed-offset/absolute addressing beside MOVE, but no BEN/request/byte-strobe/RMW owner. RETI, MMFM/MMTM and SWAPF remain similarly abstract. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Coprocessor | Partial CEXEC instruction/formatter boundary | Long and short CEXEC model/RTL matrices verify command, ID, size, LAD, status preservation and primary state classes. No physical command handshake, LRDY/BUSFLT/retry/fault path, CMOV transfer, or synthetic coprocessor exists; `TMS20-0021` remains |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
