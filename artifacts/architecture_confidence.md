# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 89 schema-checked entries; MOVE field and six MOVB register/memory semantic compatibility cases are separated from TMS34020 bus/timing ownership, while the remaining inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 127 primary-page-extracted encoding records/46,808 first words; seventeen MOVE RM/MR/MM families cover 13,506 field words and six MOVB register/memory families cover 2,112 fixed-byte words with primary addressing/status/timing metadata. MOVE.MR.POST and MOVE.MM.POST alias corners remain CORROBORATED; complete extraction remains pending |
| Architectural model slice | PROVISIONAL | 126 of 127 extracted forms have bounded successful semantics. MOVE field plus six MOVB store/load forms cover exhaustive little-endian geometry, signed-byte status, pointer/alias/overlap/offset/absolute-word ordering and BEN rollback; REV alone is unsupported. Physical bus/page/wait/fault/retry/16-bit behavior, continuation, unextracted ISA, and interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 127-entry partial decoder, serialized frontend, state leaves, clean-room fixed-byte store/load and field insertion/extraction/copy/address leaves plus prior semantic leaves, and bounded 69-operation commit path pass directed Verilator. No field-memory owner or complete processor exists |
| Graphics/window slice | PROVISIONAL | CPW signed inclusive outcodes and the four XY conversion arithmetic/pitch-class paths are primary-verified in model and standalone RTL. No complete pixel matrix, graphics sequencer, clipping engine, memory trace, or architectural RTL timing exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
