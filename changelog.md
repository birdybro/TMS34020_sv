# Changelog

## Unreleased

### Added

- Repository governance, stable milestone backlog, contribution policy, project
  layout, command surface, and machine-checkable foundation validation.
- Honest progress, verification, synthesis, confidence, and game-integration
  status reports.
- Reproducibly pinned TMS34010 reference, full initial module-level reuse
  classification, empty copied-file provenance ledger, and reuse/core
  architecture ADRs.
- Hash-pinned TI/MAME reference manifest with safe fetch, verify, and missing
  source reporting tools; copyrighted payloads remain untracked.
- Source-cited device scope, five-variant matrix, and target-game identification
  record with mechanical checks against missing categories and readiness
  overclaims.
- A 50-entry machine-readable TMS34010/TMS34020 delta ledger and human
  architectural crosswalk covering cache, bus, faults, interfaces, graphics,
  display, reset, clocks, compatibility, and A-revision clock stretch.
- The first primary-page-verified ISA database slice, deterministic query
  library, independent opcode fixtures, and a collision sweep across all 65,536
  first words.
- An independent bit-addressed architectural-model slice with A/B/SP aliasing,
  reset-vector handling, deterministic randomized state and replay, traces, and
  verified NOP/IDLE/MWAIT/ADDXYI/RPIX execution.
- A generated partial SystemVerilog decoder, dual-read A/B/SP register file,
  ADDXYI arithmetic leaf, RPIX replication/timing leaf, and a self-checking
  Verilator testbench with an explicit pass marker.
- A Cyclone V leaf-only Quartus project and warning-enforcing Analysis &
  Synthesis runner.

### Changed

- Expanded the initial one-line README into an evidence and build-oriented
  project introduction.

### Fixed

- Model instruction errors roll back PC and all other state instead of leaving a
  partially committed checkpoint.
- The Quartus qualification digest now keeps ADDXYI flags and both register-file
  read ports observable through synthesis.

### Verified

- The working directory is the existing clean `birdybro/TMS34020_sv` clone on
  `main`; no nested repository was created.
- The requested TMS34010 baseline commit exists on its upstream `main` branch.
- The baseline commit/tree metadata and MIT license are preserved; every
  upstream RTL and simulation-model module is named in the reuse audit.
- Verified local SHA-256 values for seven TI documents and the pinned eleven-file
  MAME TMS34020 source set.
- Verified SPVS004D's bounded original-to-A delta: CONFIG.CSE clock stretching,
  reset disabled, with no unsupported ISA or subsystem differences asserted.
- Verified the documented commercial 32 MHz options and the A-only commercial
  40 MHz option; exact production-game top markings remain explicitly unknown.
- Verified all 11 currently extracted decoder entries, ADDXYI leaf semantics,
  all legal RPIX replication sizes/state counts, and A/B/SP aliasing with
  Verilator.
- Quartus Prime Lite 17.0.2 Cyclone V Analysis & Synthesis passes for the
  implemented leaf slice with zero errors and zero warnings. This is not a
  fitter or timing-closure result.

### Documentation

- Defined evidence precedence, TMS34010 reuse constraints, coding/CDC/synthesis
  rules, completion claims, and current architectural risks.
- Distinguished TMS34020, TMS34020A, SMJ34020, SMJ34020A, and SM34020A without
  substituting later high-reliability data sheets for the original user guide.
- Documented unresolved opcode/status/timing, CONTROL2, errata, and
  first-silicon questions as unknown rather than assigning inferred behavior.
- Recorded a pinned MAME disassembler discrepancy: TI's TRAPL consumes a signed
  extension word, but the secondary path does not advance over it.
- Documented the first synthesizable RTL boundary and its explicit exclusions;
  deterministic FPGA register clearing is not represented as silicon behavior.

### Integration

- No board integration is implemented.

### Known Issues

- The architectural model and RTL cover only a small verified slice; there is
  no executable RTL core, cache, pipeline, memory bus, or subsystem integration.
- Target-game chip markings, first-silicon history, and silicon errata remain
  unavailable; Revolution X A-silicon identification is an inference only.
- Yosys, SymbiYosys, and Icarus Verilog are not installed in the current local
  environment; Quartus Prime Lite 17.0 and Verilator are available.
