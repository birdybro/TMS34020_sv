# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 70 schema-checked entries; MOVE.RM/RM.POST/MR/MM semantic compatibility versus TMS34020 bus/timing ownership, RETM/RETI, MMFM/MMTM and prior deltas are quantified, while the remaining inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 108 primary-page-extracted encoding records/35,286 first words; MOVE.RM/RM.POST/MR/MM cover 4,096 ordinary indirect field words with extension/status, pointer-update and one-/two-sided timing metadata. Complete extraction remains pending |
| Architectural model slice | PROVISIONAL | 107 of 108 extracted forms have bounded successful semantics. MOVE.RM/RM.POST/MR/MM cover exhaustive little-endian field geometry, FE/status, pointer/alias/overlap ordering and BEN rollback; REV alone is unsupported. Physical bus/page/wait/fault/retry/16-bit behavior, continuation, unextracted ISA, and interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 108-entry partial decoder, serialized frontend, state leaves, clean-room field insertion/extraction/copy and address-update leaves plus prior semantic leaves, and bounded 69-operation commit path pass directed Verilator. No field-memory owner or complete processor exists |
| Graphics/window slice | PROVISIONAL | CPW signed inclusive outcodes and the four XY conversion arithmetic/pitch-class paths are primary-verified in model and standalone RTL. No complete pixel matrix, graphics sequencer, clipping engine, memory trace, or architectural RTL timing exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
