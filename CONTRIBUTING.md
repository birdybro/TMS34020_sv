# Contributing

Read `AGENTS.md` first. Choose an unblocked task from `tasks.md`, verify its
sources, and make the smallest change that satisfies a testable acceptance
criterion.

Architectural changes require a cited primary source or an explicitly labeled
provisional hypothesis. Include or update tests in the same commit. A simulator
process exiting zero is insufficient: testbenches and tools must emit an
explicit pass marker and return nonzero on mismatch.

Before submitting a change:

```sh
make doctor
make lint
make test
git diff --check
```

For RTL, also run the affected subsystem tests, formal smoke checks, and
`make synth-yosys`. If a tool is unavailable, record that fact rather than
claiming its checks passed.

Do not add manuals, game ROMs, proprietary tool binaries, emulator-derived RTL,
or secrets. Put locally obtained references in `reference_cache/` and add only
metadata and hashes to the manifest.

Commit messages use a focused prefix (`research:`, `rtl:`, `test:`, and so on)
and state why the change is correct. Pull requests must list task IDs, evidence,
tests run, warnings, provisional assumptions, and remaining gaps.
