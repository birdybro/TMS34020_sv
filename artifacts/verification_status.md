# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 103 encoding records/31,189 first words | 44 `make isa-tests` cases add exact RETI/nonalias, normal/IX/BF metadata and 7/38/52 timing, plus all prior families and the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 102 of 103 extracted forms over documented domains, cache-integrated fetch | 166 directed `make model-tests` cases add normal RETI ordered ST/PC reads, complete ST/IE and PC/SP restoration, wrap/alignment, TRAP round trip, and atomic IX/BF rollback. MMFM/MMTM, SWAPF, long arithmetic and prior coverage remain; REV is exact rollback. Physical page mode, wait/fault/retry/16-bit behavior, IX/BF continuation, unextracted ISA, interfaces, and full model remain `TMS20-0006`/`TMS20-0007`/`TMS20-0014` |
| RTL semantics | Partial leaves plus bounded scalar composition | The clean-room RETI control leaf classifies normal/IX/BF, 0/24/31 extra words and 7/38/52 states, and computes normal result metadata while router guards prevent stack-less commit. MMFM/MMTM, SWAPF, multiply/divide/modulus and prior leaves remain. No RETI stack/continuation sequencer, multiple-register memory sequencer, long-arithmetic retirement timing, or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic stack/multiple-transfer/SWAPF boundaries | Normal RETI's two model reads and context leaf do not own physical width/page/wait/fault/continuation cycles. MMFM/MMTM and SWAPF boundaries remain similarly abstract. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
