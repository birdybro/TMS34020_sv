# TMS34020 SystemVerilog

This repository is an evidence-driven reimplementation of the Texas
Instruments TMS34020 Graphics System Processor in portable, synthesizable
SystemVerilog. The intended consumers include future MiSTer integrations for
Battletoads, Revolution X, and other TMS34020 systems.

## Current status

The project is in the research and architectural-foundation phase. It is **not**
instruction-complete, cycle-accurate, pin-timing-accurate, game-ready, or
release-ready. See [artifacts/progress.md](artifacts/progress.md) and
[tasks.md](tasks.md) for evidence and open work.

The generic processor core is kept separate from board-specific memory maps,
DMA engines, palettes, controls, audio, security devices, and video glue.

## Source authority

Architectural decisions use this precedence:

1. original TI TMS34020 documentation;
2. device data sheets and errata;
3. TI development-system and tool documentation;
4. original board documents and physical measurements;
5. contemporary TI software;
6. independently pinned emulator sources, including MAME;
7. community material.

The pinned TMS34010 implementation is a reusable reference, not a specification.
Object-code compatibility does not establish equal timing or subsystem
behavior.

## Repository map

- `rtl/`: portable CPU/GPU RTL and board-neutral wrappers
- `sim/`, `tests/`, `formal/`: simulation, fixtures, and properties
- `tools/`: ISA-derived assembler, disassembler, trace, and differential tools
- `docs/`: cited architecture, research, integration, and decision records
- `third_party/`: reproducibly pinned read-only source references
- `reference_cache/`: gitignored copyrighted/manual cache
- `fpga/`: Yosys/Quartus/MiSTer integration
- `artifacts/`: text status reports; generated binaries remain ignored

## First use

```sh
git submodule update --init --recursive
make doctor
make test
```

Python 3.10+ and GNU Make are required for foundation checks. Verilator is used
for RTL lint and simulation when RTL exists. Yosys, SymbiYosys, and Quartus are
separate qualification tools; their availability is reported by `make doctor`.

The public command surface requested by the project specification is listed by
`make help`. A suite with no implementation yet reports an explicit `SKIP`
instead of implying coverage.

## References and copyrighted material

Run `python3 scripts/fetch_references.py --help` after the reference tooling is
installed. Manuals with unclear redistribution rights and all proprietary tools
or game ROMs belong in `reference_cache/` and are never committed. Downloaded
legacy executables must not be run directly on the development host.

## Contributing

Read [AGENTS.md](AGENTS.md), [CONTRIBUTING.md](CONTRIBUTING.md),
[tasks.md](tasks.md), and the applicable architecture decision records before
changing architectural RTL. Each claim needs traceable evidence and each
implemented behavior needs an automated test.

## License

Original work in this repository is MIT licensed. Adapted material retains its
original notices and is recorded in
`docs/reuse/copied_file_provenance.yaml`.
