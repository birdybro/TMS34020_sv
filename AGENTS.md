# Engineering rules for TMS34020_sv

## Objective and device scope

Build a clean, reusable, synthesizable, extensively verified implementation of
the Texas Instruments TMS34020 Graphics System Processor. The exact scope
includes TMS34020, TMS34020A, SMJ34020, SMJ34020A, and SM34020A investigation;
silicon-specific behavior is selected only when supported by evidence. The
default must eventually match the production parts used by Battletoads and
Revolution X. Until that identification is verified, the default is explicitly
provisional.

The portable core is board-neutral. Battletoads and Revolution X memory maps,
DMA or sprite engines, palette, controls, sound, security, and PAL/GAL behavior
belong only in separate integration wrappers and harnesses.

## Required reading

Before modifying architectural RTL, every contributor or coding agent must read:

1. this file;
2. `tasks.md`;
3. `changelog.md`;
4. `docs/device_scope.md`;
5. `docs/reuse/tms34010_reuse_audit.md`;
6. applicable ADRs in `docs/decisions/`;
7. applicable primary documentation recorded in
   `docs/references/manifest.yaml`.

If a required document is absent, work on the prerequisite task rather than
inventing behavior.

## Evidence and clean-room policy

- Original TI TMS34020 documentation is the architectural authority.
- Device data sheets and errata govern pins, electrical timing, and revisions.
- Emulator code is a secondary differential oracle, never the specification.
- Do not copy MAME implementation code into the model or RTL.
- Do not infer TMS34020 timing or subsystem behavior solely from TMS34010.
- Label knowledge as `VERIFIED_PRIMARY`, `VERIFIED_HARDWARE`,
  `CORROBORATED`, `INFERRED`, `PROVISIONAL`, or `UNKNOWN`.
- Record contradictions in `docs/research/source_conflicts.md` and unresolved
  items in `docs/research/open_questions.md`.
- Cite publication number, revision, page, section/table/figure; source-code
  citations also need the pinned commit and line range.
- Never weaken a test or silently update expected output merely to pass.
- Do not claim completeness, accuracy, readiness, or timing closure without the
  evidence defined in `tasks.md` and the project specification.

## TMS34010 reuse

`third_party/TMS34010_sv_reference/` is pinned, read-only reference material.
Do not modify it and do not compile it into the TMS34020 design by default.
Every upstream module must be classified in the reuse audit as
`REUSE_UNCHANGED`, `REUSE_WITH_DEVICE_PARAMETER`, `COPY_AND_ADAPT`,
`REIMPLEMENT`, `NOT_APPLICABLE`, `REFERENCE_ONLY`, or
`UNKNOWN_PENDING_RESEARCH`.

Copied or adapted files require:

- an entry in `docs/reuse/copied_file_provenance.yaml`;
- preservation of the upstream MIT notice;
- an explanation of semantic and timing changes;
- independent TMS34020-specific tests.

Never copy a bus or instruction timing state machine based only on compatible
instruction semantics.

## Repository layout

- `rtl/core`, `rtl/execute`: architectural state, decode, sequencing, integer
  execution
- `rtl/cache`, `rtl/memory`, `rtl/bus`: cache and native/pin bus behavior
- `rtl/graphics`, `rtl/video`, `rtl/io`: graphics and display subsystems
- `rtl/host`, `rtl/coprocessor`, `rtl/cdc`: external interfaces
- `rtl/wrappers`: board-neutral and separate game harnesses
- `sim`, `tests`: testbenches, programs, traces, expected results
- `formal`: properties and bounded harnesses
- `tools`: ISA-derived tools and independent reference model
- `docs`: cited design and research record
- `fpga`: vendor integration kept outside portable RTL
- `reference_cache`, `build`: ignored local/generated data

## SystemVerilog coding conventions

- Use SystemVerilog-2017, `logic`, `always_ff`, `always_comb`, packages,
  explicit-width enumerations, and explicit finite-state machines.
- Begin source files with ``default_nettype none`` and restore it at EOF.
- Use lower_snake_case for signals, ports, variables, and instances;
  UpperCamelCase is forbidden for RTL identifiers. Constants and parameters use
  `UPPER_SNAKE_CASE`; modules use the `tms34020_` prefix.
- One synthesizable module per file, named to match the file.
- Declare every width and signedness. Cast deliberately at arithmetic and shift
  boundaries. Unsized numeric constants are forbidden in RTL.
- Combinational blocks assign every output on every path. Latches, multiple
  procedural drivers, internal tri-states, `casex`, and ambiguous wildcard
  decode are forbidden.
- Simulation-only code stays under `sim/` or is guarded by
  ``ifndef SYNTHESIS`` and must not affect architectural behavior.
- Reserved/illegal opcodes take an explicit path. No default may alias a legal
  instruction.
- Add compile-time parameter checks and local assertions where practical.

## Clock, reset, memory, and CDC policy

- The portable design has one primary FPGA system clock. Model processor and
  local-bus phases with clock enables and state, never generated or gated
  clocks.
- Additional host/video domains are permitted only where required and must have
  explicit CDC structures.
- Synchronize asynchronous levels with at least two destination-domain flops.
  Use source-held request/acknowledge for bundled data and asynchronous FIFOs
  for continuous streams. Synchronize reset deassertion separately per domain.
- Reset assertion/release, first fetch, cache invalidation, I/O reset values,
  bus outputs, host, and video reset behavior require device-specific evidence.
- The board-neutral transaction interface must preserve request class, bit
  address, size, byte enables, 16/32-bit target behavior, page eligibility,
  waits, faults, retries, and completion identity.
- Requests and write data remain stable while stalled. A response completes
  exactly one request. Faulted/retried writes must be idempotent.
- Vendor primitives and physical I/O electrical adaptations stay in `fpga/` or
  thin wrappers, never in the portable architectural core.

## Verification and formal requirements

- Every implemented opcode has directed semantic, status, addressing, timing,
  wait, cache, bus-width, interrupt, and applicable fault tests.
- Every bus-cycle family has request/response and pin-level trace tests.
- Graphics tests compare exact request-by-request memory traces.
- Generate decode tables and exhaustive sweeps from the ISA database, but retain
  independent handwritten opcode fixtures to avoid circular validation.
- The software architectural model must be structurally independent of RTL.
- Differential failures are retained with deterministic seeds and minimized.
- Assertions must cover reset-known state, legal FSM transitions, stable stalled
  requests, unique completion, cache consistency, aliasing, atomic partial
  writes, retry safety, interrupt priority, ownership, and liveness under stated
  fairness assumptions.
- State proof bounds and assumptions. Never describe a bounded check as a
  complete proof.

## Synthesis requirements

- Run portable lint and Yosys synthesis early for RTL changes.
- No inferred latches, accidental clocks, internal tri-states, unresolved
  multiple drivers, or ignored width warnings.
- Quartus targets the MiSTer DE10-Nano Cyclone V only after portable synthesis
  passes. Timing closure requires fitter and TimeQuest reports, not estimates.
- Track logic, registers, memories, DSPs, PLLs, clock frequency, critical paths,
  slack, unconstrained paths, CDC findings, and all material warnings in
  `artifacts/synthesis_status.md`.

## Documentation, provenance, and copyright

- Update architecture documents with implementation changes in the same commit.
- Update reference hashes and retrieval metadata without committing copyrighted
  manuals whose redistribution is unclear.
- Never commit game ROMs, proprietary TI tools, credentials, or downloaded
  legacy executables.
- Do not execute legacy binaries on the host. Use an isolated emulator/VM with
  no credentials or sensitive mounts.
- Preserve all third-party licenses and source history. Record every copied or
  adapted file in provenance YAML.

## Task, changelog, and commit rules

- Use stable task IDs from `tasks.md`. A task is complete only when every listed
  acceptance criterion and named test passes.
- Update task status, confidence, questions, and tests as work evolves.
- A completed task records the resulting commit hash in a follow-up metadata
  commit if the hash could not be known in the completing commit.
- Update the structured `changelog.md` for meaningful behavior, verification,
  synthesis, research, documentation, and integration changes.
- Keep commits small and coherent with prefixes such as `docs`, `research`,
  `reuse`, `model`, `tools`, `rtl`, `test`, `formal`, `synth`, `battletoads`,
  `revx`, and `fix`.
- Preserve unrelated user changes. Never rewrite history or force-push without
  explicit authorization.
- The repository must remain buildable at every commit.

Before each commit:

1. inspect `git diff --check`, the full diff, and `git status`;
2. run focused tests and the affected broader regression;
3. run `make lint`;
4. for RTL, run `make synth-yosys` and relevant formal smoke checks;
5. inspect warnings and document unavailable tools;
6. scan staged paths for manuals, ROMs, binaries, and proprietary material;
7. update tasks, changelog, citations, provenance, and progress artifacts.

## Completion definitions and current risks

Instruction-complete, cycle-accurate, generic release-ready, Battletoads-ready,
and Revolution X-ready mean all corresponding acceptance criteria in the
project specification and `TMS20-0042` pass. RTL existence alone never
completes a task.

Current high risks:

- original versus A-revision behavioral and errata differences;
- exact game-board device markings;
- reconstructing cache/pipeline overlap and continuation checkpoints;
- dynamic 16-bit sizing, page mode, bus fault/retry, and pin timing;
- complete 64-register I/O/display behavior;
- coprocessor and multiprocessor behavior with limited hardware evidence;
- copyrighted ROMs and unavailable physical hardware for final qualification;
- Quartus 17.0 compatibility with modern generated RTL.
