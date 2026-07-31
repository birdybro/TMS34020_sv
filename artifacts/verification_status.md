# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 75 encoding records/23,122 first words | 26 `make isa-tests` cases include JUMP A/B/shared-SP boundaries, alignment/redirect metadata, adjacent GETPC/GETST nonaliasing, POPST/PUSHST timing and a complete 65,536-word unique-decode sweep; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for all 75 currently extracted forms, cache-integrated fetch | 122 directed `make model-tests` cases cover all three published JUMP targets, alignment, A/B/shared-SP sources, source/status preservation, and two-state timing. Existing evidence includes POPST/PUSHST ordering/timing, PUTST, EXGF, every SETF/SEXT/ZEXT size, every primary BTST row, XY/LMO/shift/register/immediate forms, bounded BLMOVE, successful TRAPL/VLCOL, cache and fetch integration. The unextracted ISA, stack fault/retry/physical transfers, BLMOVE continuation/timing, interfaces, and full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | JUMP and POPST/PUSHST decode but remain explicitly rejected without writes or redirects in execution, commit, and scalar boundaries. Leaf tests cover PUTST full-width status replacement from A/B/shared-SP sources with no register writeback, plus SETF/EXGF/SEXT/ZEXT in both field banks with exact partial ST masks, routing, atomic exchange, upper-register clearing, and ordered commits. Existing tests also cover all published ADDXY/SUBXY, BTST, LMO, and shift rows; all 32 SLA counts; SETC pitch conversion; and packet/write-intent boundaries. `make scalar-slice-tests` covers stable blocked JUMP/POPST/PUSHST/BLMOVE/unclassified packets and the existing dependent sequences; no timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; twenty-three runtime SVAs simulation-enabled | Four cache, four fetch, thirteen scalar, and two register-commit safety properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
