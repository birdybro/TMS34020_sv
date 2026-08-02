# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 102 encoding records/31,188 first words | 43 `make isa-tests` cases cover all 64 MMFM/MMTM first words and their opposite list-mask contracts, all 512 SWAPF, 1,024 MPYS/MPYU, 1,024 MODS/MODU, 1,024 DIVS/DIVU, and 1,088 XY-conversion forms/metadata, plus prior fixtures and the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 101 of 102 extracted forms over documented domains, cache-integrated fetch | 163 directed `make model-tests` cases add exhaustive MMFM/MMTM mask order, every A/B/SP register, pointer wrap, logical transaction order, MMTM status/timing classes, MMFM timing disclosure, and atomic invalid-list rollback. SWAPF/multiply/divide/modulus and prior coverage remain; REV is exact rollback. Physical page mode, wait/fault/retry/16-bit behavior, continuation, unextracted ISA, interfaces, and full model remain `TMS20-0006`/`TMS20-0007`/`TMS20-0014` |
| RTL semantics | Partial leaves plus bounded scalar composition | The clean-room MMFM/MMTM control leaf exhaustively normalizes both 16-bit list directions, counts, validates, computes pointer/N, and selects documented timing classes while router guards prevent memory-less commit. SWAPF, multiply/divide/modulus and prior leaves remain. No multiple-register memory sequencer, long-arithmetic retirement timing, or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic multiple-transfer/SWAPF boundaries | MMFM/MMTM model logical transfers and list-control leaf do not own physical page-mode, width, wait, fault, or continuation cycles; SWAPF likewise has no lock owner. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
