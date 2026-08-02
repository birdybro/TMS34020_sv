# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 61 schema-checked entries; modulus status/timing, divide, CVXYL/new conversions, CPW, CALL-family, RETS/TRAP/REV and prior deltas are quantified, while the remaining inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 97 primary-page-verified encoding records/29,588 first words; MODS/MODU, DIVS/DIVU and four XY-conversion ranges have exact operand contracts. RSC-0028 resolves modulus Z and RSC-0029 preserves unreachable timing; prior DIVS/CVXYL/control uncertainties remain; complete extraction is pending |
| Architectural model slice | PROVISIONAL | 96 of 97 extracted forms have bounded successful semantics. MODS/MODU cover every primary row, status, aliases and reachable timing; DIVS/DIVU and prior forms retain coverage. REV alone is unsupported. Unextracted ISA, physical iterative/stack/fault behavior, BLMOVE continuation, and interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 97-entry partial decoder, serialized cache/fetch frontend, state leaves, clean-room divide/modulus engine, graphics leaves, and bounded 69-operation commit path pass directed Verilator and warning-free Cyclone V probes. Divide/modulus and graphics forms remain noncommitting pending architectural owners; prior guards remain. No complete processor exists |
| Graphics/window slice | PROVISIONAL | CPW signed inclusive outcodes and the four XY conversion arithmetic/pitch-class paths are primary-verified in model and standalone RTL. No complete pixel matrix, graphics sequencer, clipping engine, memory trace, or architectural RTL timing exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
