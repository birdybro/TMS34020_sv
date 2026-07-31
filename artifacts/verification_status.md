# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 11 entries/76 first words | `make isa-tests`; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay and 5 instructions | 14 directed `make model-tests` cases; full model remains `TMS20-0007` |
| RTL semantics | Partial leaf slice | `make rtl-leaf-tests`: 11-entry partial decode, A/B/SP alias, ADDXYI and all RPIX sizes; no executable core |
| Timing | Not implemented | `TMS20-0013` |
| Cache | Not implemented | `TMS20-0012` |
| Memory/bus | Not implemented | `TMS20-0014`–`TMS20-0019` |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | Not implemented | `TMS20-0032` |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
