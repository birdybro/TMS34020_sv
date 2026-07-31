# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 54 encoding records/13,520 first words | `make isa-tests`; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay, bounded semantics for all 54 currently extracted forms, cache-integrated fetch | 90 directed `make model-tests` cases, including GETPC/EXGPC sequential-PC/redirect behavior, complete ADDK/INC, SUBK/DEC, MOVK, MOVI, MOVE, MOVX/MOVY, RL constant/register, SETCDP/SETCMP/SETCSP, bounded BLMOVE, successful TRAPL/VLCOL, ADDI/SUBI/CMPI word/long forms, TI logical rows, 11 cache transaction cases and 5 fetch-integration cases; complete ISA extraction, BLMOVE continuation/timing, interfaces, and the full model remain `TMS20-0006`/`TMS20-0007` |
| RTL semantics | Partial leaves plus bounded scalar composition | Leaf tests exhaust every one-/two-power SETC pitch field pair and preserve its hidden-write boundary; fetch/frontend suites cover cache, packet and write-intent ordering; `make scalar-slice-tests` covers nine dependent one-word commits, complete ORI/XORI/ANDNI, dependent ADDXYI, mixed two-/three-word ADDI/SUBI packets, nondestructive CMPI.W/L, encoded-zero ADDK/SUBK/MOVK commits with MOVK ST preservation, complete MOVI.W/L, dependent MOVX/MOVY commits, dependent cross-file A-to-B/B-to-A MOVE commits, dependent RL.K/RL.R commits, blocked BLMOVE/unclassified noncommit, and eight cache-fed dependent commits after four refill reads; no timed retirement or complete executable core |
| Timing | Functional PC/packet ordering only; machine-state timing not implemented | `TMS20-0013`; packet handshakes are explicitly not TMS34020 cycles |
| Cache | Model plus bounded native-completion RTL leaf; full timing/pin/fault-controller path absent | 11 cache-unit plus 5 fetch-integration model tests; directed RTL matrix plus three seeds/396 fetches cover refill/lookup/LRU/controls/backpressure, retry/fault/abort, refill-state reset, data and present safety; full `TMS20-0012` remains |
| Memory/bus | Transaction-level cache completion subset only | `make fault-tests` includes the directed matrix and three seeds totaling 1,226 accepted native reads, 36 retries, 83 faults and 43 aborts; `TMS20-0014`–`TMS20-0019` remain |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | No proof run; eleven runtime SVAs simulation-enabled | Four cache, four fetch, and three scalar acceptance/noncommit properties run under Verilator; SymbiYosys remains unavailable and `TMS20-0032` is not complete |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
