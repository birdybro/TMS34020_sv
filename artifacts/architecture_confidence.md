# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 64 schema-checked entries; SETF/SEXT/ZEXT timing is quantified, while the remaining opcode/status/timing inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 70 primary-page-verified encoding records/22,992 first words; complete extraction pending |
| Architectural model slice | PROVISIONAL | 67 of 70 currently extracted encoding forms have bounded successful semantics, including all 25 primary BTST inputs with RSC-0018's corrected status digit plus A/B/same-register/shared-SP cases, every published ADDXY/SUBXY row and register hazards, primary-row and register-hazard LMO coverage, SLA/SLL/SRA/SRL count/status behavior, GETPC/EXGPC sequential-PC behavior, BLMOVE non-overlap/final state and TRAPL/VLCOL success paths, with fetch through deterministic cache transaction/retry state; SETF/SEXT/ZEXT roll back as unsupported, and the unextracted ISA, BLMOVE continuation/overlap/timing, non-cache fault/retry, and full interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 70-entry partial decoder, serialized cache/fetch frontend, A/B/SP and masked ST storage, common unary/binary/logical/rotate/shift/XY/bit-test arithmetic, TMS34020-specific semantic leaves including exhaustive SETC pitch conversion, and a bounded fetch-to-commit path for 44 one-word, four two-word, and eight three-word instructions pass directed Verilator and Cyclone V synthesis; BTST.K/R cover all 25 primary input rows plus complemented/low-five-bit counts, A/B, same-register, shared-SP and dependent Z-only commits, ADDXY/SUBXY cover all 25 primary rows plus register hazards, LMO has primary-row and register-hazard coverage, GETPC uses packet sequential PC and EXGPC atomically exchanges that address with the old destination before an aligned completion redirect, same-file and cross-file MOVE, RL, and all eight SLA/SLL/SRA/SRL forms are included, SETF/SEXT/ZEXT and SETC-pitch hidden writes block, and no architectural retirement timing or complete executable core exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC, IDLE and interrupt checkpoint rules are extracted with page citations |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
