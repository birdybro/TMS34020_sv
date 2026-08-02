# Reference acquisition

`manifest.yaml` is the authoritative catalog. It is written in the JSON subset
of YAML 1.2 so the standard-library tooling does not depend on PyYAML.

Copyrighted TI manuals, proprietary tools, MAME working files, and all ROMs are
stored only under the gitignored `reference_cache/`. The repository commits
metadata, immutable source identities, hashes, citations, and lawful retrieval
instructions—not the payloads.

## Commands

```sh
# Validate metadata without downloading anything
python3 scripts/verify_reference_hashes.py --validate-only

# Show required and optional missing sources
python3 scripts/report_missing_references.py

# Fetch all sources explicitly marked automatic/git_files
python3 scripts/fetch_references.py --all

# Fetch or verify one source
python3 scripts/fetch_references.py --id TI-TMS34020-UG-1990
python3 scripts/verify_reference_hashes.py --id TI-TMS34020-UG-1990

# Require every hashed manifest entry to be present and correct
python3 scripts/verify_reference_hashes.py --require-all
```

Fetches are streamed to a temporary sibling and are moved into place only after
SHA-256 verification. The fetcher refuses legacy executable/tool records.
Never execute downloaded binaries on the host.

`committed: false` must remain set for every source whose redistribution rights
are unclear. Adding a source requires every schema field, a stable ID, exact
revision/URL/retrieval metadata, SHA-256 when acquired, applicable device and
silicon scope, authority level, redistribution/license status, and relevant
page/section notes.

## Authority

1. TMS34020-specific TI user guides
2. TI data sheets and errata
3. TI development-system and tool documentation
4. original game board documentation and measurements
5. contemporary TI software/diagnostics
6. pinned MAME and independent emulators
7. community sources

MAME is used as a differential oracle only. Its source is BSD-3-Clause and must
not be copied or translated into RTL.

The prior `srg320/TMS34020` FPGA implementation is pinned at commit
`2046b4378e2e29ee1fe9ef0b6365987e95fa5c0c` as a secondary discrepancy and
coverage reference. That commit has no license file or source license notice,
so its payload remains untracked and no code, decode table, or timing state
machine may be copied or adapted. Its own top-level header lists substantial
missing bus, host, graphics, interrupt, and instruction behavior; it is not an
architectural authority or completion baseline.
