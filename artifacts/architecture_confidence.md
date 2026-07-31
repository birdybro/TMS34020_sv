# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 50 schema-checked entries; opcode/status/timing quantification pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 31 primary-page-verified entries/4,464 first words; complete extraction pending |
| Architectural model slice | PROVISIONAL | 25 page-verified instructions and deterministic state/replay; cache/full ISA absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 31-entry partial decoder, A/B/SP and masked ST storage, common unary/binary arithmetic, six TMS34020-specific semantic leaves, and externally gated commit for 19 one-word instructions pass directed Verilator and Cyclone V synthesis; no fetch, PC sequencing, architectural retirement timing, or executable core |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide Chapter 5 |
| Pipeline timing | UNKNOWN | Detailed timing-case extraction pending |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
