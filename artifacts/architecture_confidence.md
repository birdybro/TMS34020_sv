# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 66 schema-checked entries; TMS34020-only RETM and RETI continuation/timing, MMFM/MMTM page/timing ownership and prior deltas are quantified, while the remaining inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 104 primary-page-extracted encoding records/31,190 first words; RETM adds forced-fetch/recognition behavior and 10/38/52 timing while RETI/OQ-0023 retain hidden continuation questions. Complete extraction remains pending |
| Architectural model slice | PROVISIONAL | 103 of 104 extracted forms have bounded successful semantics. Normal RETM/RETI restore state; RETM snapshots a one-shot full-packet bypass; IX/BF roll back. REV alone is unsupported. Interrupt recognition, physical page/wait/fault/retry/16-bit behavior, continuation, unextracted ISA, and interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 104-entry partial decoder, serialized frontend, state leaves, clean-room RETI/RETM context control and prior semantic leaves, plus bounded 69-operation commit path pass directed Verilator. Return stack/cache/interrupt ownership and other memory/long/graphics forms remain noncommitting. No complete processor exists |
| Graphics/window slice | PROVISIONAL | CPW signed inclusive outcodes and the four XY conversion arithmetic/pitch-class paths are primary-verified in model and standalone RTL. No complete pixel matrix, graphics sequencer, clipping engine, memory trace, or architectural RTL timing exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
