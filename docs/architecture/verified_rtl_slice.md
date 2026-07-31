# Verified RTL slice

This document records the exact boundary of the first synthesizable RTL. It is
a collection of independently testable architectural leaves, not a processor
core, sequencer, pipeline, cache, memory controller, or pin interface.

## Implemented leaves

| Module | Implemented behavior | Primary source |
|---|---|---|
| `rtl/core/tms34020_decode.sv` | Classification and instruction length for the 15 entries currently present in the canonical ISA database; all other first words remain explicitly unclassified | TI *TMS34020 User's Guide*, August 1990, individual instruction pages listed in `docs/generated/tms34020_isa.yaml` |
| `rtl/core/tms34020_regfile.sv` | Two 32-bit combinational read ports, one synchronous write port, independent A0–A14 and B0–B14 storage, and shared A15/B15 stack-pointer storage | TI *TMS34020 User's Guide*, August 1990, §4.1, printed pp.4-2..4-3 |
| `rtl/execute/tms34020_addxyi.sv` | Independent 16-bit X/Y addition and the instruction-specific N/C/Z/V results | TI *TMS34020 User's Guide*, August 1990, ADDXYI, printed p.13-39 |
| `rtl/execute/tms34020_cmpk.sv` | Encoded-zero-means-32 subtraction and N/C/Z/V compare results without register modification | TI *TMS34020 User's Guide*, August 1990, CMPK, printed p.13-83 |
| `rtl/execute/tms34020_rmo.sv` | Least-significant set-bit index and Z result | TI *TMS34020 User's Guide*, August 1990, RMO, printed p.13-224 |
| `rtl/graphics/tms34020_pixel_size_ops.sv` | GETPS zero-extension and EXGPS register/16-bit PSIZE-write data paths; no I/O timing or write-queue implementation | TI *TMS34020 User's Guide*, August 1990, EXGPS, printed p.13-113; GETPS, printed p.13-131 |
| `rtl/graphics/tms34020_pixel_replicate.sv` | RPIX replication and documented machine-state counts for PSIZE 1, 2, 4, 8, 16, and 32 | TI *TMS34020 User's Guide*, August 1990, RPIX, printed p.13-225; §12.6, printed p.12-17 |

The generated include `rtl/generated/tms34020_isa_decode.svh` is derived from
`docs/generated/tms34020_isa.yaml` by
`tools/generators/generate_isa_rtl.py`. A freshness check prevents the checked-in
decoder from drifting away from the database. Because the database is
incomplete, an unmatched word means *unclassified*, not architecturally
reserved or illegal.

The register file is synchronously cleared in this FPGA implementation so
simulation and formal startup are deterministic. This is not a silicon-reset
claim. The TI reset description leaves the general registers uninitialized;
the future core must not make execution depend on their reset values. Source:
TI *TMS34020 User's Guide*, August 1990, §6.12.2, printed p.6-23.

## Verification evidence

`make rtl-leaf-tests` builds a self-checking SystemVerilog testbench with
Verilator. It checks:

- every currently extracted decoder entry, including masked register/mode
  encodings and instruction-word count;
- a near-neighbor that must remain unclassified;
- two ADDXYI arithmetic/flag cases;
- CMPK constant-32, borrow, and overflow cases;
- RMO zero, low-bit, and high-bit cases;
- GETPS and EXGPS data-path behavior;
- all six legal RPIX sizes and their documented state counts;
- rejection of an unsupported pixel size;
- independent A/B storage and the shared A15/B15 stack-pointer alias.

The testbench must emit `PASS: tms34020 verified leaf RTL`; simulator exit
status alone is not accepted.

`make quartus-leaf-smoke` runs warning-free Quartus Analysis & Synthesis for
the leaf qualification wrapper on Cyclone V device `5CSEBA6U23I7`. The wrapper
keeps both register-file read ports, arithmetic flags, decoder outputs, PSIZE
data paths, RMO, and RPIX timing outputs observable. This is an early
portability check only:
Analysis & Synthesis is not placement, routing, TimeQuest closure, or
full-core qualification.

## Explicitly absent

There is no instruction fetch or execution sequencer, architectural status
register, writeback path, interrupt logic, cache, memory access, page mode,
bus-fault/retry, host interface, multiprocessor interface, coprocessor
interface, display subsystem, original-pin bus, or game wrapper. The instruction
modules are combinational semantic leaves; their presence does not mean any
instruction can execute in RTL. In particular, the EXGPS leaf does not
implement the documented hidden internal-I/O write cycle.
