# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 15 entries/1,676 first words | `make isa-tests`; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay and 9 instructions | 18 directed `make model-tests` cases; full model remains `TMS20-0007` |
| RTL semantics | Partial leaf slice | `make rtl-leaf-tests`: 15-entry partial decode, A/B/SP alias, ADDXYI/CMPK/EXGPS/GETPS/RMO/RPIX leaves; no executable core |
| Timing | Not implemented | `TMS20-0013` |
| Cache | Not implemented | `TMS20-0012` |
| Memory/bus | Not implemented | `TMS20-0014`–`TMS20-0019` |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | Not implemented | `TMS20-0032` |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
