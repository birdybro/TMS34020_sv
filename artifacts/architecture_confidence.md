# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 64 schema-checked entries; SETF/SEXT/ZEXT and EXGF timing deltas are quantified, while the remaining opcode/status/timing inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 80 primary-page-verified encoding records/25,282 first words; long JRcc now includes the exact 16 first words, all condition predicates, signed target, timing, and TMS34010 semantic compatibility. Short JRcc/JAcc exclusion representation and complete extraction remain pending |
| Architectural model slice | PROVISIONAL | 79 of 80 currently extracted encoding forms have bounded successful semantics; a complete decoded long-JR packet rolls back exactly until its independent condition handler is implemented. Existing DSJS, DSJ-family, JUMP, stack, status/field, arithmetic, cache, and control-flow evidence remains unchanged. The unimplemented/unextracted ISA, BLMOVE continuation/overlap/timing, non-cache fault/retry, and full interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 80-entry partial decoder, serialized cache/fetch frontend, A/B/SP and masked ST storage, common semantic leaves, and a bounded fetch-to-commit path for 51 one-word, seven executable two-word, and eight three-word instructions pass directed Verilator and Cyclone V synthesis. JR.L is fetched as a complete two-word packet but is explicitly blocked without writes or redirects; the previous DSJS/DSJ/JUMP and other bounded execution evidence remains unchanged. No architectural retirement timing or complete executable core exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, long JRcc conditions/target, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JR.L execution is not yet implemented |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
