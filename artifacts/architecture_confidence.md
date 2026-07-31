# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 63 schema-checked entries; opcode/status/timing quantification pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 65 primary-page-verified encoding records/21,200 first words; complete extraction pending |
| Architectural model slice | PROVISIONAL | All 65 currently extracted encoding forms have bounded successful semantics, including every published ADDXY/SUBXY row and B/same-register/shared-SP hazards, primary-row and register-hazard LMO coverage, SLA/SLL/SRA/SRL count/status behavior, GETPC/EXGPC sequential-PC behavior, BLMOVE non-overlap/final state and TRAPL/VLCOL success paths, with fetch through deterministic cache transaction/retry state; the unextracted ISA, BLMOVE continuation/overlap/timing, non-cache fault/retry, and full interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 65-entry partial decoder, serialized cache/fetch frontend, A/B/SP and masked ST storage, common unary/binary/logical/rotate/shift arithmetic, TMS34020-specific semantic leaves including exhaustive SETC pitch conversion, and a bounded fetch-to-commit path for 40 one-word, four two-word, and eight three-word instructions pass directed Verilator and Cyclone V synthesis; ADDXY/SUBXY decode but explicitly block, LMO has primary-row, Z-only, same-register and shared-SP coverage, GETPC uses packet sequential PC and EXGPC atomically exchanges that address with the old destination before an aligned completion redirect, same-file and cross-file MOVE, RL, and all eight SLA/SLL/SRA/SRL forms are included, SETC-pitch hidden writes and other unsupported packets block, and no architectural retirement timing or complete executable core exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC, IDLE and interrupt checkpoint rules are extracted with page citations |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
