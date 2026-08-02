# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 58 schema-checked entries; CPW semantic/timing compatibility, CALL-family, RETS/TRAP/REV, CMPXY, SETF/SEXT/ZEXT, and EXGF deltas are quantified, while the remaining opcode/status/timing inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 89 primary-page-verified encoding records/26,452 first words; CPW adds its complete 512-word same-file range and one-state/V-only contract. CALL-family evidence, RETS/TRAP, REV, and short-JR uncertainties remain disclosed; complete extraction is pending |
| Architectural model slice | PROVISIONAL | 88 of 89 extracted forms have bounded successful semantics. CPW covers all primary rows, signed bounds, aliases, V-only status, and one state. CALL/RETS/TRAP retain their coverage; REV alone is atomically unsupported pending a physical-device result. The unextracted ISA, physical stack fault/retry, BLMOVE continuation/timing, non-cache fault/retry, and full interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 89-entry partial decoder, serialized cache/fetch frontend, A/B/SP and masked ST storage, common semantic leaves, a standalone CPW signed-window leaf, and the existing bounded 69-operation commit path pass directed Verilator and Cyclone V synthesis. CPW is noncommitting pending an implied-register owner; CALL-family, RETS, TRAP, and REV retain their guards. No architectural retirement timing or complete executable core exists |
| Graphics/window slice | PROVISIONAL | CPW's signed inclusive outcode and V condition are primary-verified in model and standalone RTL. No complete pixel-processing matrix, graphics sequencer, clipping engine, memory trace, or timing implementation exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
