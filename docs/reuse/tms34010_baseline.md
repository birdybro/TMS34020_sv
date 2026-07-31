# Pinned TMS34010 baseline

## Identity

| Field | Value |
|---|---|
| Upstream | `https://github.com/birdybro/TMS34010_sv.git` |
| Local path | `third_party/TMS34010_sv_reference/` |
| Commit | `94a258e80a07ceb4303ce0b99818df832e96007f` |
| Commit tree | `0a52e2ad3cb0e9bb73ae058a05305111a43f9f3b` |
| Parent | `66cd2657d79f7ac22b790f6e9eefa36d574ffda9` |
| Author/committer | Kevin Coleman `<aberusugi@gmail.com>` |
| Timestamp | 2026-07-30 06:58:16 -0600 |
| Subject | `Record Task 0174 completion commit` |
| Upstream commit count at pin | 302 |
| Retrieval date | 2026-07-31 |
| License | MIT |

The commit was independently resolved both by `git ls-remote` on the upstream
`main` branch and by the GitHub commit API before the submodule was added. The
submodule is checked out detached at this SHA. Reproduce it with:

```sh
git submodule update --init third_party/TMS34010_sv_reference
test "$(git -C third_party/TMS34010_sv_reference rev-parse HEAD)" = \
  94a258e80a07ceb4303ce0b99818df832e96007f
```

The upstream repository itself pins `third_party/TMS34010_Info` at
`0f5094bf8d177d753ea7e18012827d26a5013371`. That nested source is deliberately
not initialized here: it contains reference-document material that must pass
this repository's redistribution and manifest review independently.

## License

The upstream `LICENSE` is the MIT License with:

> Copyright (c) 2026 Kevin Coleman

The complete notice remains present in the submodule. Any copied or adapted
file must preserve that notice and gain an entry in
`copied_file_provenance.yaml`.

## Baseline claims and limitations

The upstream README describes a completed, synthesizable production-revision
TMS34010 functional scope, large self-checking regression, MAME differential
corpus, TI workloads, and Cyclone V Quartus results. Its own documentation
explicitly excludes original-silicon instruction-cycle parity and the optional
instruction cache from its signed-off scope. Those exclusions are material:
this baseline cannot establish TMS34020 timing or cache behavior.

The pin contains:

- 33 synthesizable SystemVerilog files, including packages and wrappers;
- two simulation memory models;
- 168 `tb_*.sv` testbenches;
- Verilator/Questa lint and regression scripts;
- MAME graphics differential and TI-workload tooling;
- a Quartus Prime Lite 17 Cyclone V project and SDC constraints;
- detailed TMS34010 architecture/conformance records.

No upstream source is part of the TMS34020 compilation list.

## Verification performed here

- exact commit and tree identity: **PASS**
- detached, clean upstream worktree: **PASS**
- upstream MIT notice present: **PASS**
- nested reference-document submodule not initialized: **PASS**
- module-level reuse audit coverage: enforced by `test_reuse_audit.py`
- semantic/timing reuse qualification: **not yet performed**
- upstream RTL regression: **not run**; its preferred Questa/ModelSim or
  fallback Verilator flow has not yet been evaluated as a TMS34020 prerequisite

This file records acquisition, not approval to reuse any implementation.
