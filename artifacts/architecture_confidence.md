# Architecture confidence

| Area | Confidence | Reason |
|---|---|---|
| Required device family list | VERIFIED_PRIMARY | Project scope |
| TMS34010 pin commit identity | VERIFIED_PRIMARY | Git commit/tree and upstream remote |
| Commercial original/A revision delta | VERIFIED_PRIMARY | SPVS004D bounds the stated delta to A clock stretch |
| TMS34010/TMS34020 required-topic delta coverage | PROVISIONAL | 50 schema-checked entries; opcode/status/timing quantification pending |
| Exact Battletoads silicon | UNKNOWN | 32 MHz fits both commercial original and A parts; marking unreadable |
| Exact Revolution X silicon | INFERRED | 40 MHz board/driver evidence and commercial A-40 catalog option; marking unreadable |
| ISA | PROVISIONAL | 38 primary-page-verified entries/6,608 first words; complete extraction pending |
| Architectural model slice | PROVISIONAL | 32 page-verified instructions fetch through deterministic cache transaction/retry state; full ISA/interfaces absent |
| Synthesizable RTL slice | PROVISIONAL | Generated 38-entry partial decoder, A/B/SP and masked ST storage, common unary/binary/logical arithmetic, six TMS34020-specific semantic leaves, externally gated commit for 23 one-word instructions, and a standalone successful-read cache leaf pass directed Verilator and Cyclone V synthesis; no PC/execution integration, architectural retirement timing, or executable core |
| Cache organization | VERIFIED_PRIMARY | August 1990 guide chapters 5–6 and 8; directed transaction model and bounded successful-read RTL pass, while completion codes, active-refill flush behavior, interrupts, bus-width/page/pin timing remain absent |
| Pipeline timing | UNKNOWN | Detailed timing-case extraction pending |
| Memory/bus timing | PROVISIONAL | A clock-stretch cases identified; complete phase extraction pending |
| Host/multiprocessor/coprocessor | UNKNOWN | Primary audit pending |
| Graphics/display | UNKNOWN | Primary audit pending |

Confidence applies to current documentation knowledge, not implemented RTL.
