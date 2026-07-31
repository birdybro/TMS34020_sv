# Verification status

| Area | Status | Evidence |
|---|---|---|
| Repository policy | Verified current scope | `foundation-check` |
| ISA database | Partial: 38 entries/6,608 first words | `make isa-tests`; full decode remains `TMS20-0006` |
| Architectural model | Partial: state/replay and 32 instructions | 36 directed `make model-tests` cases, including all 21 register-logical and 16 immediate-logical TI example rows; full model remains `TMS20-0007` |
| RTL semantics | Partial leaf slice | `make rtl-leaf-tests`: 38-entry partial decode, A/B/SP, masked ST, unary/binary arithmetic, register logical operations, TMS34020-specific leaves, decoder-controlled write intents, and 17 ordered state-commit checks for 23 one-word instructions; three-word immediate logical operations are decoded but intentionally rejected before a sequencer exists; no fetch, PC sequencer, timed retirement, or executable core |
| Timing | Not implemented | `TMS20-0013` |
| Cache | Primary contract documented; RTL/tests not implemented | `TMS20-0012` |
| Memory/bus | Not implemented | `TMS20-0014`–`TMS20-0019` |
| Graphics/video | Not implemented | `TMS20-0024`–`TMS20-0028` |
| Differential | Not implemented | `TMS20-0031` |
| Formal | Not implemented | `TMS20-0032` |

No full-ISA, executable-core, cycle-accuracy, or release coverage claim is made.
