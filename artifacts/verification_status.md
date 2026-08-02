# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 100 encoding records/31,124 first words | 42 `make isa-tests` cases cover all 512 SWAPF, 1,024 MPYS/MPYU, 1,024 MODS/MODU, 1,024 DIVS/DIVU, and 1,088 XY-conversion forms/metadata, plus prior fixtures and the complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for 99 of 100 extracted forms over documented domains, cache-integrated fetch | 158 directed `make model-tests` cases add every valid word-local SWAPF width/offset, sign/zero extension, status, aliases, ordered abstract locked transactions and invalid-crossing rollback. Multiply/divide/modulus and prior coverage remain; REV is exact rollback. Physical lock/wait/fault/16-bit/I/O behavior, unextracted ISA, interfaces, and full model remain `TMS20-0006`/`TMS20-0007`/`TMS20-0014` |
| RTL semantics | Partial leaves plus bounded scalar composition | The clean-room SWAPF leaf passes full/positioned exchange, extension, status and valid/crossing classification while router guards prevent bypassing a locked owner. Multiply/divide/modulus and prior leaves remain. No SWAPF memory commit, long-arithmetic retirement timing, or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Cache completion subset plus semantic SWAPF boundary | SWAPF model traces one abstract locked read/write and its leaf transforms a containing word, but no physical memory request or lock owner exists. Cache fault tests retain 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Partial CPW and XY-conversion semantic leaves only | Signed window/outcode and conversion equation/pitch-class tests pass; pixel matrix, sequencer, memory traces, display/video, and full `TMS20-0024`–`TMS20-0028` remain |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; thirty-six runtime SVAs simulation-enabled | Four cache, four fetch, twenty-three scalar, two register-commit, and three divider safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
