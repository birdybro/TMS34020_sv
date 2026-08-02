# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 107 schema-checked entries add TMS34020-only FLINE state/pattern/timing semantics beside FPIX/CLIP/LINIT and prior deltas; the full inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 145 primary-page-extracted records/48,224 first words add exact TMS34020-only FLINE beside the prior graphics/coprocessor/memory/scalar slice; complete extraction is pending |
| Architectural model slice | PROVISIONAL | 144 of 145 extracted forms have bounded successful semantics; REV alone is unsupported. FLINE covers atomic replace/no-transparency patterned writes and its no-wait formula, but not physical sequencing or continuation. Physical interfaces, unextracted ISA, and complete timing remain absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 145-entry partial decoder, serialized frontend, semantic leaves including one-step FLINE/FPIX and CLIP/LINIT, and bounded 69-operation commit path pass directed Verilator. These graphics/CMOV leaves expose no architectural commit without missing owners; no complete processor exists |
| Graphics/window slice | PROVISIONAL | FLINE/FPIX one-step PMASK-aware transforms, CLIP positive rectangles, LINIT, CPW, and four conversions are primary-verified in model/standalone RTL. Full PPOP/transparency, sequencing/continuation, zero-size CLIP, complete pixel matrix, physical traces, and complete timing remain absent |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor | UNKNOWN | Primary audit pending |
| Coprocessor | PROVISIONAL | Chapter 10 command/data format, both CEXEC encodings and every documented CMOVGC/CMOVCG/CMOVCS/CMOVCM/CMOVMC encoding are audited with bounded model/formatter tests. Physical handshake/data sequence, page arbitration, architectural commit, waits/fault/retry, and synthetic coprocessor remain; CMOVCM carries RSC-0042/RSC-0043 qualifications |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
