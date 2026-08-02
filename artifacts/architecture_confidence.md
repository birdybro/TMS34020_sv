# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 110 schema-checked entries add the verified TMS34020-only PFILL pattern/alignment/conversion/window/bus delta beside FILL/DRAV/FLINE/FPIX/CLIP/LINIT and prior deltas; the full inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 149 primary-page-extracted records/48,739 first words add exact TMS34020-only PFILL.XY beside FILL and the prior graphics/coprocessor/memory/scalar slice; complete extraction is pending |
| Architectural model slice | PROVISIONAL | All 149 extracted forms have bounded handlers over disclosed domains. REV succeeds only with an explicit format-valid identity; the default rejects it and no game identity is guessed. PFILL remains bounded W0 without active windows/PPOP/transparency/CST, B14 parity or physical sequencing. Physical interfaces, unextracted ISA, and complete timing remain absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 149-entry partial decoder, serialized frontend, semantic leaves including normalized one-step PFILL/FILL/DRAV/FLINE/FPIX and CLIP/LINIT, and a bounded 70-operation commit path when a valid REV profile is selected pass directed Verilator. The default has no REV selection; graphics/CMOV leaves expose no architectural commit without missing owners; no complete processor exists |
| Graphics/window slice | PROVISIONAL | PFILL/FILL/DRAV/FLINE/FPIX PMASK-aware transforms, CLIP positive rectangles, LINIT, CPW, and four conversions are primary-verified in model/standalone RTL over disclosed domains. Full PPOP/transparency/window sequencing/continuation, zero-size CLIP, complete pixel matrix, physical traces, and complete timing remain absent |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor | UNKNOWN | Primary audit pending |
| Coprocessor | PROVISIONAL | Chapter 10 command/data format, both CEXEC encodings and every documented CMOVGC/CMOVCG/CMOVCS/CMOVCM/CMOVMC encoding are audited with bounded model/formatter tests. Physical handshake/data sequence, page arbitration, architectural commit, waits/fault/retry, and synthetic coprocessor remain; CMOVCM carries RSC-0042/RSC-0043 qualifications |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
