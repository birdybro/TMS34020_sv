# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 62 schema-checked entries; multiply flags/timing, modulus, divide, CVXYL/new conversions and prior deltas are quantified, while the remaining inventory is pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 99 primary-page-extracted encoding records/30,612 first words; MPYS/MPYU add exact arithmetic/full-product flag contracts but retain RSC-0030 timing and RSC-0031 table-operand disclosures. Prior modulus/divide/conversion uncertainties and complete extraction remain pending |
| Architectural model slice | PROVISIONAL | 98 of 99 extracted forms have bounded successful semantics over documented operand domains. MPYS/MPYU cover all reliable primary rows, every even FS1, full-product flags, aliases and provisional timing; odd FS1 is explicitly rejected. REV alone is unsupported. Unextracted ISA, physical iterative/stack/fault behavior, BLMOVE continuation, and interfaces are absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 99-entry partial decoder, serialized frontend, state leaves, clean-room divide/modulus and multiply engines, graphics leaves, and bounded 69-operation commit path pass directed Verilator and warning-free Cyclone V probes. Multiply/divide/modulus and graphics forms remain noncommitting pending architectural owners. No complete processor exists |
| Graphics/window slice | PROVISIONAL | CPW signed inclusive outcodes and the four XY conversion arithmetic/pitch-class paths are primary-verified in model and standalone RTL. No complete pixel matrix, graphics sequencer, clipping engine, memory trace, or architectural RTL timing exists |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed model and bounded RTL cover native retry/fault semantics, while active-refill flush, CPU fault/interrupt state, bus-width/page/pin timing remain absent |
| PC/control-flow boundary | VERIFIED_PRIMARY | Bit-address alignment/advance, redirect classes, reset vector, GETPC/EXGPC/JUMP, JAcc and long-JR conditions/targets, DSJ/DSJS families, IDLE and interrupt checkpoint rules are extracted with page citations; JACC/JR.L have bounded model and functional direct-PC RTL ownership, but not documented retirement timing |
| Pipeline timing | PROVISIONAL | Primary guide establishes cache/execute/register/memory overlap, read blocking and hidden-write ordering; physical stage topology and complete timing cases remain unknown |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
