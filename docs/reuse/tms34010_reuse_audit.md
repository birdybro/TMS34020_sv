# TMS34010 reuse audit

Status: **initial classification complete; semantic and timing qualification
open** (`TMS20-0004`).

Baseline: `birdybro/TMS34010_sv` commit
`94a258e80a07ceb4303ce0b99818df832e96007f`. See
`tms34010_baseline.md`. Classifications express the intended treatment, not
proof that copied logic is already correct for TMS34020.

## Classification rules

- `REUSE_UNCHANGED`: identical implementation is justified by TMS34020 primary
  evidence and independent tests.
- `REUSE_WITH_DEVICE_PARAMETER`: a shared implementation is plausible, but an
  explicit device contract and tests are required.
- `COPY_AND_ADAPT`: preserve provenance and license; create a TMS34020-owned
  implementation with documented changes and tests.
- `REIMPLEMENT`: architecture, timing, interface, or maintainability requires a
  dedicated TMS34020 design.
- `NOT_APPLICABLE`: no corresponding TMS34020 deliverable.
- `REFERENCE_ONLY`: useful test/design evidence but not a code source.
- `UNKNOWN_PENDING_RESEARCH`: evidence is insufficient even to select a reuse
  strategy.

No file currently qualifies as `REUSE_UNCHANGED`.

## Synthesizable module/file audit

| Upstream file | Classification | Rationale and required gate |
|---|---|---|
| `rtl/tms34010_pkg.sv` | REIMPLEMENT | TMS34020 needs its own 32-bit bus cycle taxonomy, cache/pipeline/fault/coprocessor/multiprocessor state, 64-register map, and revision selection. |
| `rtl/tms34010_system.sv` | REIMPLEMENT | Wrapper composition and request classes differ fundamentally. |
| `rtl/tms34010_pin_system.sv` | REIMPLEMENT | Devices are explicitly not pin-compatible; TMS34020 has 32 LAD bits, four CAS strobes, SIZE16, PGMD, BUSFLT, GI/R0/R1, and coprocessor cycles. |
| `rtl/core/tms34010_core.sv` | REIMPLEMENT | Large monolithic sequencing omits TMS34020 cache/pipeline/continuation/coprocessor architecture and upstream does not claim exact instruction timing. It may serve only as semantic/test evidence. |
| `rtl/core/tms34010_decode.sv` | REIMPLEMENT | Decode must be generated from the complete TMS34020 ISA database and swept across 65,536 words. |
| `rtl/core/tms34010_alu.sv` | COPY_AND_ADAPT | Basic 32-bit arithmetic is a candidate leaf, but flag masks/undefined behavior and all operations require TMS34020 instruction-page verification. |
| `rtl/core/tms34010_divider.sv` | COPY_AND_ADAPT | Candidate arithmetic leaf; signed/unsigned edge behavior, latency, interruptibility, and fault checkpoint timing remain unverified. |
| `rtl/core/tms34010_shifter.sv` | COPY_AND_ADAPT | Candidate barrel-shifter leaf; TMS34020 encodings, flag behavior, and single-state timing require primary verification. |
| `rtl/core/tms34010_pc.sv` | COPY_AND_ADAPT | Bit-addressed PC concepts carry over, but cache/pipeline fetch ownership, branch alignment, faults, and reset vector configuration change the contract. |
| `rtl/core/tms34010_regfile.sv` | COPY_AND_ADAPT | A/B files and SP alias are compatible candidates; hazards, coprocessor paths, continuation context, and exact read/write ordering require new tests. |
| `rtl/core/tms34010_status_reg.sv` | REIMPLEMENT | TMS34020 status includes additional architectural behavior (including fault/continuation context) and cannot inherit reserved-bit policy. |
| `rtl/core/tms34010_int_ctrl.sv` | REIMPLEMENT | Interrupt sources, bus-fault entry, continuation, host status, and pipeline recognition differ. |
| `rtl/cdc/tms34010_sync_bit.sv` | COPY_AND_ADAPT | The two-flop pattern is reusable, but Altera attributes must be isolated from portable RTL and reset assumptions re-audited. |
| `rtl/cdc/tms34010_cdc_mailbox.sv` | REUSE_WITH_DEVICE_PARAMETER | Generic source-held MCP protocol is a strong candidate after independent reset/liveness/formal checks and device-neutral renaming. |
| `rtl/cdc/tms34010_local_bus_bridge.sv` | COPY_AND_ADAPT | Handshake pattern is useful; TMS34020 payload, reset, response/fault/retry, burst and ownership semantics are different. |
| `rtl/cdc/tms34010_screen_cdc.sv` | COPY_AND_ADAPT | Screen transaction concept is useful; TMS34020 display payload/register sequencing must define a new contract. |
| `rtl/cdc/tms34010_emu_bridge.sv` | REIMPLEMENT | TMS34020 emulator pins and local phases require their own evidence. |
| `rtl/host/tms34010_host_if.sv` | REIMPLEMENT | TMS34020 has direct host addressing, 32-bit data/byte selection, different pins, prefetch, host faults, and coherence requirements. |
| `rtl/host/tms34010_host_bus.sv` | REIMPLEMENT | Physical asynchronous host timing and pin surface differ. |
| `rtl/io/tms34010_io_regs.sv` | REIMPLEMENT | TMS34020 has 64 registers with moved/new display, CONFIG/CONTROL2/CONVMP, PMASKL/H, cache and bus-fault state. |
| `rtl/memory/tms34010_field_sequencer.sv` | REIMPLEMENT | Its 16-bit aligned physical-word state machine is not the TMS34020 32-bit/dynamic-16/page/fault pipeline. The field extraction tests remain useful. |
| `rtl/memory/tms34010_bus_arbiter.sv` | REIMPLEMENT | HOLD/HOLDA is not proof of GI/R0/R1 multiprocessor behavior; priorities and clients differ. |
| `rtl/memory/tms34010_local_bus.sv` | REIMPLEMENT | Upstream uses a device-specific 8× TMS34010 phase engine. TMS34020 LCLK and page/size/fault/stretch timing must be reconstructed independently. |
| `rtl/memory/tms34010_memory_fabric.sv` | REIMPLEMENT | Request classes, bus width, cache, fault/retry, host, display, coprocessor and multiprocessor integration differ. |
| `rtl/video/tms34010_display_addr.sv` | REIMPLEMENT | Display address registers and revised TMS34020 sequencing need a new model. |
| `rtl/video/tms34010_refresh.sv` | REIMPLEMENT | DRAM/VRAM width, page-mode, refresh registers/arbitration and A-revision stretch require device-specific timing. |
| `rtl/video/tms34010_video.sv` | REIMPLEMENT | Register addresses, display controls, SCLK/VRAM support, and timing differ. |
| `rtl/video/tms34010_video_subsystem.sv` | COPY_AND_ADAPT | CDC composition patterns are useful, but all architectural payload/ownership and display sequencing must be replaced. |
| `rtl/fpga/tms34010_reset_sync.sv` | REUSE_WITH_DEVICE_PARAMETER | Generic synchronous deassertion is a candidate after reset polarity/domain/PLL-lock policy is restated. |
| `rtl/fpga/tms34010_fpga_io.sv` | REIMPLEMENT | Pin names, widths, polarities, ownership and electrical constraints differ. |
| `rtl/fpga/tms34010_cyclone_v_pll.sv` | NOT_APPLICABLE | TMS34010 frequency and 8× phase generation do not define the TMS34020 clock plan. |
| `rtl/fpga/tms34010_cyclone_v_video_pll.sv` | REFERENCE_ONLY | PLL generation style may inform Quartus integration, not architectural RTL. |
| `rtl/fpga/tms34010_cyclone_v_top.sv` | REIMPLEMENT | Target board may be shared, but processor pins/clocks/interfaces and generic MiSTer boundary differ. |

## Simulation-model audit

| Upstream file | Classification | Rationale and required gate |
|---|---|---|
| `sim/models/sim_memory_model.sv` | COPY_AND_ADAPT | Useful deterministic memory and field-test pattern; must gain native 32-bit, dynamic 16-bit, page, wait, fault, retry and transaction-class behavior. |
| `sim/models/sim_ti_workload_memory.sv` | REFERENCE_ONLY | Loader/workload technique is useful after license/provenance review; content and 34020 object format remain separate tasks. |

## Required functional-area audit

| Area | Classification | Reuse decision |
|---|---|---|
| PC and bit-addressed program flow | COPY_AND_ADAPT | Preserve only verified bit-address/align primitives; redesign fetch/cache/pipeline ordering. |
| A/B register files and SP aliasing | COPY_AND_ADAPT | Leaf candidate with exhaustive alias/hazard tests. |
| ALU | COPY_AND_ADAPT | Leaf candidate after per-instruction status audit. |
| Multiplier | REIMPLEMENT | Upstream multiply is embedded in the core rather than an independently reusable module; TMS34020 timing/width cases need separation. |
| Divider | COPY_AND_ADAPT | Leaf candidate only. |
| Shifter | COPY_AND_ADAPT | Leaf candidate only. |
| Status register | REIMPLEMENT | New/reserved/continuation behavior. |
| Decoder | REIMPLEMENT | ISA-database generated. |
| Instruction fetch | REIMPLEMENT | 512-byte cache and overlap are mandatory. |
| Ordinary field memory operations | REIMPLEMENT | Reuse semantic vectors, not the 16-bit timing FSM. |
| Graphics operations | REIMPLEMENT | Upstream graphics engines are embedded in `tms34010_core`; use tests as candidates after delta audit. |
| Pixel processing | COPY_AND_ADAPT | Boolean/arithmetic leaf functions and matrices may be adapted only after the 34020 conformance matrix exists. |
| Window checking | COPY_AND_ADAPT | Semantic candidate; additional 34020 modes/operations require independent tables. |
| Plane masking | COPY_AND_ADAPT | Expand and verify full 32-bit PMASKL/H ordering. |
| Field sequencer | REIMPLEMENT | Native 32-bit plus SIZE16/page/fault/retry. |
| Local-memory bus | REIMPLEMENT | Different pins and timing. |
| Host interface | REIMPLEMENT | Different access model and pins. |
| Interrupts | REIMPLEMENT | Fault, continuation, and expanded sources. |
| Display subsystem | REIMPLEMENT | Revised register map/sequencing. |
| Video subsystem | REIMPLEMENT | Revised timing and VRAM features. |
| Refresh system | REIMPLEMENT | Memory controller integration differs. |
| CDC modules | REUSE_WITH_DEVICE_PARAMETER | Protocol patterns only; device-neutral modules and formal CDC contracts required. |
| FPGA wrapper | REIMPLEMENT | Keep vendor primitives outside portable core. |
| Simulation infrastructure | COPY_AND_ADAPT | Reuse test structure and pass-marker discipline, not expected architectural results. |
| MAME differential tooling | COPY_AND_ADAPT | Preserve adapter approach; pin current 34020 paths/commit independently and respect BSD-3-Clause separation. |
| TI workload tooling | COPY_AND_ADAPT | Preserve isolation/hash approach; acquire 34020 workloads and tools independently. |
| Quartus project | REIMPLEMENT | Reuse reporting discipline; new sources, clocks, pins and constraints. |
| SDC constraints | REIMPLEMENT | No timing constraints transfer automatically between devices. |

## Tests and corpus

The upstream contains 168 `tb_*.sv` benches. They are `REFERENCE_ONLY` until
each fixture's license, expected result, compatible opcode semantics, and
memory-interface assumptions are reviewed. Tests copied later must be listed in
`copied_file_provenance.yaml`; timing expectations must be replaced with
TMS34020-specific primary evidence.

The upstream MAME workflow pins commit
`70725158b4e9d2e1230c0515faec754f9cee86a2`. This project independently pins a
current MAME commit for TMS34020 work; neither MAME implementation may be
translated into RTL.

## Open gates

1. Map every compatible instruction fixture to a TMS34020 User's Guide page.
2. Compare leaf arithmetic semantics and undefined flags against the TMS34020
   instruction pages.
3. Separate reusable device-neutral CDC utilities from Altera attributes.
4. License-review any copied test vectors and TI workload metadata.
5. Run the upstream regression with available tools as a baseline integrity
   check.
6. Update every provisional classification after the architecture delta and
   device-revision audit.
