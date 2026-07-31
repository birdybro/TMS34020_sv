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

### Changed

- Expanded the initial one-line README into an evidence and build-oriented
  project introduction.

### Fixed

- None.

### Verified

- The working directory is the existing clean `birdybro/TMS34020_sv` clone on
  `main`; no nested repository was created.
- The requested TMS34010 baseline commit exists on its upstream `main` branch.
- The baseline commit/tree metadata and MIT license are preserved; every
  upstream RTL and simulation-model module is named in the reuse audit.
- Verified local SHA-256 values for seven TI documents and the pinned eleven-file
  MAME TMS34020 source set.

### Documentation

- Defined evidence precedence, TMS34010 reuse constraints, coding/CDC/synthesis
  rules, completion claims, and current architectural risks.

### Integration

- No board integration is implemented.

### Known Issues

- The architectural model and RTL are not implemented.
- Device variants and target-game chip markings remain under research.
- Yosys, SymbiYosys, and Icarus Verilog are not installed in the current local
  environment; Quartus Prime Lite 17.0 and Verilator are available.
