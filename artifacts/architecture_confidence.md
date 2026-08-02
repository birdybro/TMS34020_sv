# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 98 schema-checked entries now include CMOVCG/CMOVCS, both CMOVGC register-write forms and long/short CEXEC; MOVE field and all nine MOVB compatibility cases remain separated from TMS34020 bus/timing ownership, while the inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 135 primary-page-extracted records/48,058 first words add the 32-word CMOVCG family with exact CMOVCS extension refinement beside both CMOVGC forms and CEXEC. Seventeen MOVE families cover 13,506 words and nine MOVB families cover 3,137. RSC-0039/OQ-0026 and MOVE alias qualifications remain; complete extraction is pending |
| Architectural model slice | PROVISIONAL | 134 of 135 extracted forms have bounded successful semantics; REV alone is unsupported. CMOVCG/CMOVCS exhaust destinations, ID, size, alignment, ordered input, status, snapshot/replay and atomic underflow/reserved rollback; CMOVGC/CEXEC remain. Physical coprocessor acceptance, bus/page/wait/fault/retry/16-bit behavior, continuation, unextracted ISA, and complete interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 135-entry partial decoder, serialized frontend, state and memory-semantic leaves, combinational CEXEC and CMOVGC/CMOVCG/CMOVCS formatters, and bounded 69-operation commit path pass directed Verilator. Coprocessor forms are explicitly noncommitting without register/ST-capture/cycle ownership; no complete processor exists |
| Graphics/window slice | PROVISIONAL | CPW signed inclusive outcodes and the four XY conversion arithmetic/pitch-class paths are primary-verified in model and standalone RTL. No complete pixel matrix, graphics sequencer, clipping engine, memory trace, or architectural RTL timing exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor | UNKNOWN | Primary audit pending |
| Coprocessor | PROVISIONAL | Chapter 10 command/data format, both CEXEC encodings, CMOVGC, CMOVCG and exact CMOVCS are primary-audited with model/formatter tests including I=1 reissue metadata; physical handshake, page arbitration, CMOVCM/CMOVMC, architectural commit, waits/fault/retry, and synthetic coprocessor remain |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
