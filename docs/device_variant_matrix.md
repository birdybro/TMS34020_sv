# TMS34020 device variant matrix

This matrix distinguishes verified differences from fields for which no
applicable source has been acquired. “Same documented base” means the acquired
device data sheet describes the same TMS34020 architecture and does not state a
difference in that category. It does **not** mean that missing errata have been
proved empty.

Source keys:

- UG: TI *TMS34020 User's Guide*, August 1990,
  `TI-TMS34020-UG-1990`.
- COM: TI SPVS004D, *TMS34020, TMS34020A Graphics Processors*, March 1990,
  revised November 1993, `TI-TMS34020-DS-SPVS004D`.
- MIL-A: TI SGUS011D, *SMJ34020A Graphics System Processor*, April 1991,
  revised September 2004, `TI-SMJ34020A-DS-SGUS011D`.
- HIREL-A: TI SGUS057, *SM34020A Graphics System Processor*, February 2005,
  `TI-SM34020A-DS-SGUS057`.

| Category | TMS34020 | TMS34020A | SMJ34020 | SMJ34020A | SM34020A |
|---|---|---|---|---|---|
| Instruction set | UG baseline | Same documented base (COM p.2) | `UNKNOWN` | Same documented base (MIL-A pp.1–2) | Same documented base (HIREL-A pp.1–2) |
| Opcode encodings | UG chapters 13–14; extraction pending | No delta stated in COM | `UNKNOWN` | No delta stated in MIL-A | No delta stated in HIREL-A |
| Status register | UG chapters 3, 13–14; extraction pending | No delta stated in COM | `UNKNOWN` | No delta stated in MIL-A | No delta stated in HIREL-A |
| I/O registers | 64-register architecture (COM p.2); exact map pending | CONFIG.CSE bit 4 added/defined for clock stretch (COM pp.21–22); other delta not stated | `UNKNOWN` | CSE documented (MIL-A pp.21–22) | CSE documented (HIREL-A pp.20–22) |
| Instruction cache | 512 bytes (UG §5.1; COM p.2) | Same documented base | `UNKNOWN` | 512 bytes (MIL-A p.2) | 512 bytes (HIREL-A p.1) |
| Memory controller | 32-bit DRAM/VRAM controller, pipelined variable-field writes (COM p.2) | Adds eligible CSE clock stretch (COM pp.21–22) | `UNKNOWN` | A clock stretch documented | A clock stretch documented |
| Host interface | General host port and direct/implicit modes; detailed audit pending | Same documented base | `UNKNOWN` | Same documented base | Same documented base |
| Display controller | Integrated CRT/VRAM interface; detailed register/timing audit pending | Video logic remains VCLK-clocked during CSE stretch (COM p.22); other delta not stated | `UNKNOWN` | Same A statement | Same A statement |
| Interrupt system | UG baseline; detailed audit pending | No delta stated in COM | `UNKNOWN` | No delta stated in MIL-A | No delta stated in HIREL-A |
| Bus-fault behavior | Bus-fault detection and instruction continuation (COM p.2) | Same documented base; CSE changes eligible phase duration | `UNKNOWN` | Same documented base | Same documented base |
| Multiprocessor behavior | Request/grant environment (COM p.2) | Clock stretch not recommended in multiprocessor systems (COM p.47) | `UNKNOWN` | Same warning (MIL-A p.47) | Same warning (HIREL-A p.46) |
| Coprocessor behavior | Documented interface and special instructions (COM p.2; UG chapter 10) | Same documented base | `UNKNOWN` | Same documented base | Same documented base |
| Reset behavior | UG/SPVS004D baseline; detailed reset table extraction pending | CSE clears to 0 at reset (COM p.22) | `UNKNOWN` | CSE clears to 0 at reset (MIL-A p.22) | CSE clears to 0 at reset (HIREL-A p.21) |
| Clock/machine-cycle behavior | Four-quarter normal cycle; commercial -32 is 125 ns (COM pp.1, 21) | Normal four-quarter cycle; eligible CSE cycle adds Q4b and is 25% longer; -32 125 ns, -40 100 ns (COM pp.1, 21–22) | `UNKNOWN` | A stretch; -32 125 ns, -40 100 ns (MIL-A pp.1, 21–22) | A stretch; -40 100 ns; -32 listed potential release (HIREL-A pp.2, 20–22) |
| Electrical qualification | Commercial limits/tables in COM; package-dependent | Commercial limits/tables in COM; package-dependent | `UNKNOWN` | Military/high-reliability, -55 °C to 125 °C (MIL-A p.1 and electrical tables) | High-reliability, -40 °C to 110 °C (HIREL-A Table 1 p.2) |
| Package and pins | 145-pin GB ceramic or 144-pin PCM plastic (COM pp.1, 3–8) | Same commercial packages (COM pp.1, 3–8) | `UNKNOWN` | 145-pin GB ceramic or 132-pin HT ceramic QFP (MIL-A pp.1, 3–8) | 145-pin GB ceramic documented orderable part (HIREL-A pp.1–5) |
| Documented errata | Separate silicon errata not acquired | Separate silicon errata not acquired | No applicable data sheet or errata acquired | Separate errata not acquired | Separate errata not acquired |
| Current RTL profile | Not implemented | Not implemented | Not implementable without evidence | Not implemented | Not implemented |
| Overall confidence | `VERIFIED_PRIMARY` architecture; errata `UNKNOWN` | `VERIFIED_PRIMARY` stated CSE delta; errata `UNKNOWN` | `UNKNOWN` | `VERIFIED_PRIMARY` for acquired data sheet | `VERIFIED_PRIMARY` for acquired data sheet |

## Cache organization common to the documented architecture

The UG gives the original TMS34020 cache organization, which is not changed by
the acquired A data sheets:

- 512 bytes: 128 32-bit long words or 256 instruction words;
- four segments of 64 instruction words;
- eight subsegments per segment, four long words per subsegment;
- one 22-bit segment-start address and 32 presence bits per segment;
- four-entry LRU replacement;
- one-state hit lookup overlapped by the pipeline;
- a miss refill of four long words, requesting the opcode/immediate-containing
  long word last;
- data operations bypass the instruction cache;
- self-modifying writes do not update a resident cached copy;
- HSTCTLH.CF flushes and CONTROL.CD bypasses the cache while preserving its
  contents.

Source: UG chapter 5, §§5.1–5.4, printed pages 5-2 through 5-8.
Confidence: `VERIFIED_PRIMARY`. This describes requirements, not implemented
RTL.

## Revision-selector implications

A complete future device parameter must at minimum determine whether CONFIG.CSE exists
and whether eligible machine cycles may enter Q4b. It must also provide an
explicit, cited 32-bit REV result: TMS34020 family bit 4 is established, but
the silicon-revision and spin-off fields must not be inferred merely from the
profile name. The current model and bounded scalar RTL expose an evidence-
neutral unselected default and accept only an explicit format-valid revision
word; verification uses the guide's revision-1.0 example under a clearly named
test profile, not as a game default. A future complete device parameter must
not alter opcode, cache, status, host, graphics, display,
interrupt, fault, multiprocessor, or coprocessor behavior without a cited
delta.

The non-A SMJ34020 shall remain an invalid/unimplemented selection until an
applicable primary publication is acquired. Package selection will remain
outside architectural state except where a package truly changes signal
availability, which has not yet been established.

## Unresolved evidence

The matrix is intentionally incomplete in areas where only a marketing-level
data-sheet description has been audited. Detailed programmer-visible behavior
will be extracted from the UG into the architecture and generated delta
documents. Missing silicon errata and first-silicon records are tracked in
`docs/research/open_questions.md`; those gaps prevent a final device-release
claim.
