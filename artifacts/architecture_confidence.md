# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 103 schema-checked entries now include all five CMOVCM/CMOVMC memory sequences beside CMOVCG/CMOVCS, both CMOVGC forms and CEXEC; MOVE field and all nine MOVB compatibility cases remain separated from TMS34020 bus/timing ownership, while the inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 140 primary-page-extracted records/48,218 first words add all five CMOVCM/CMOVMC families beside CMOVCG/CMOVCS, both CMOVGC forms and CEXEC. RSC-0042/OQ-0027 and RSC-0043/OQ-0028 qualify CMOVCM; complete extraction is pending |
| Architectural model slice | PROVISIONAL | 139 of 140 extracted forms have bounded successful semantics; REV alone is unsupported. CMOVCM/CMOVMC exhaust representative count/pointer/size/direction, alias/wrap, ordered logical data, status preservation, and atomic reserved/underflow rollback. Physical coprocessor acceptance, partial page/spacer/wait/fault/retry behavior, continuation, unextracted ISA, and complete interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 140-entry partial decoder, serialized frontend, state and memory-semantic leaves, combinational CEXEC/all-CMOV formatters, and bounded 69-operation commit path pass directed Verilator. CMOV memory forms expose no data or commit without a physical sequencer; no complete processor exists |
| Graphics/window slice | PROVISIONAL | CPW signed inclusive outcodes and the four XY conversion arithmetic/pitch-class paths are primary-verified in model and standalone RTL. No complete pixel matrix, graphics sequencer, clipping engine, memory trace, or architectural RTL timing exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor | UNKNOWN | Primary audit pending |
| Coprocessor | PROVISIONAL | Chapter 10 command/data format, both CEXEC encodings and every documented CMOVGC/CMOVCG/CMOVCS/CMOVCM/CMOVMC encoding are audited with bounded model/formatter tests. Physical handshake/data sequence, page arbitration, architectural commit, waits/fault/retry, and synthetic coprocessor remain; CMOVCM carries RSC-0042/RSC-0043 qualifications |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
