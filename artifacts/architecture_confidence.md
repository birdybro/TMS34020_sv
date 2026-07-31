# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 65 schema-checked entries; CMPXY, SETF/SEXT/ZEXT, and EXGF timing deltas are quantified, while the remaining opcode/status/timing inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 82 primary-page-verified encoding records/25,810 first words; CMPXY now has exact `E400h`/`FE00h` classification, flags, timing, and compatibility metadata. CLR remains the exact 32 same-register aliases within XOR. Short JRcc exclusion representation, RSC-0020, and complete extraction remain pending |
| Architectural model slice | PROVISIONAL | 81 of 82 currently extracted encoding forms have bounded successful semantics; CMPXY has exact unsupported rollback pending its independent handler. CLR covers every A/B/shared-SP alias word through canonical XOR. Existing JACC/JR.L, DSJ-family, JUMP, stack, status/field, arithmetic, cache, and control-flow evidence remains unchanged. The unextracted ISA, BLMOVE continuation/overlap/timing, non-cache fault/retry, and full interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 82-entry partial decoder, serialized cache/fetch frontend, A/B/SP and masked ST storage, common semantic leaves, and a bounded fetch-to-commit path for 51 one-word, eight executable two-word, and nine executable three-word instructions pass directed Verilator; the decoder-bearing leaf slice passes Cyclone V synthesis. CMPXY is explicitly noncommitting pending its execution leaf. No architectural retirement timing or complete executable core exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
