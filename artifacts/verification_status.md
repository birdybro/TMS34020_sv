# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 149 encoding records/48,739 first words | 83 `make isa-tests` cases add exact PFILL.XY pattern/alignment metadata and retain the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 148 of 149 extracted forms over documented domains, cache-integrated fetch | 248 directed `make model-tests` cases add bounded PFILL pattern rows, primary alignment, every PSIZE/lane/COLOR/PATTERN/PMASK, final DADDR and rollback. REV is exact rollback. Active windows/PPOP/transparency/CST, B14 parity and physical sequencing remain |
| RTL semantics | Partial leaves plus bounded scalar composition | Clean-room normalized PFILL leaf covers one aligned COLOR0/COLOR1/PATTERN/PMASK pixel plus pattern/row/column traversal and guards with explicit router noncommit. Existing FILL/DRAV/FLINE/FPIX/CLIP/LINIT/CEXEC/CMOV/scalar leaves remain; no complete executable sequencer exists |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic byte/field/stack/multiple-transfer/SWAPF boundaries | All nine MOVB register/memory/copy forms add logical fixed-byte writes, signed loads/status, read-before-write overlap and indirect/signed-offset/absolute addressing beside MOVE, but no BEN/request/byte-strobe/RMW owner. RETI, MMFM/MMTM and SWAPF remain similarly abstract. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Coprocessor | Partial CEXEC/CMOV instruction/formatter boundary | Long/short CEXEC and every CMOVGC/CMOVCG/CMOVCS/CMOVCM/CMOVMC family have bounded model/RTL evidence for command, selectors, count, ordered logical data, address update, status, ID, size and state classes. No physical handshake/page data sequence, architectural commit, LRDY/BUSFLT/retry/fault path, or synthetic coprocessor exists; `TMS20-0021` remains |
| Graphics/video | Partial PFILL, FILL, DRAV, FLINE, FPIX, CLIP, LINIT, CPW and conversion semantic leaves only | Bounded W0 PFILL patterns/FILL rows, DRAV, patterned FLINE and plane-masked FPIX model/normalized RTL, array clipping, line setup/window/status and conversion tests pass; other PPOP/transparency/window sequencing, B14 parity, grouping/continuation, OQ-0029, commit, pixel matrix, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
