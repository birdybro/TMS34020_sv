# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 53 schema-checked entries; REV identity/timing, CMPXY, SETF/SEXT/ZEXT, and EXGF timing deltas are quantified, while the remaining opcode/status/timing inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 83 primary-page-verified encoding records/25,842 first words; REV has exact `0020h`/`FFE0h` decode, result layout, and timing metadata, but its physical-profile value is unknown and pinned MAME conflicts with TI. CMPXY and CLR retain their verified classifications. Short JRcc exclusion representation, RSC-0020/RSC-0021, and complete extraction remain pending |
| Architectural model slice | PROVISIONAL | 82 of 83 currently extracted encoding forms have bounded successful semantics. REV alone is decoded but atomically unsupported pending an evidence-backed physical-device result. Existing CMPXY, CLR, control-flow, stack, status/field, arithmetic, cache, and control-flow evidence remains unchanged. The unextracted ISA, REV profile, BLMOVE continuation/overlap/timing, non-cache fault/retry, and full interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 83-entry partial decoder, serialized cache/fetch frontend, A/B/SP and masked ST storage, common semantic leaves, and a bounded fetch-to-commit path for 52 one-word, eight executable two-word, and nine executable three-word instructions pass directed Verilator and Cyclone V synthesis. REV is classified but verified noncommitting until a device profile exists; the implemented operation count remains 69. No architectural retirement timing or complete executable core exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
