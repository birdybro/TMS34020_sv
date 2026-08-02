# Device scope

## Purpose

This repository implements the Texas Instruments TMS34020 architecture. It does
not use “34020 family” as a synonym for one undifferentiated device. The
supported profiles will be selected explicitly only where primary evidence
shows externally observable differences.

Evidence labels in this document have their repository-wide meanings:

- `VERIFIED_PRIMARY`: stated by an applicable TI publication.
- `VERIFIED_HARDWARE`: directly measured on identified physical hardware.
- `CORROBORATED`: supported by independent sources, but not yet direct hardware
  measurement or an applicable primary source.
- `INFERRED`: a conclusion from stated evidence, with alternatives remaining.
- `PROVISIONAL`: an implementation choice awaiting stronger evidence.
- `UNKNOWN`: not established.

The architectural authority currently acquired is the August 1990
*TMS34020 User's Guide*, cataloged as
`TI-TMS34020-UG-1990`. The device/electrical authority for commercial original
and A devices is SPVS004D, cataloged as `TI-TMS34020-DS-SPVS004D`. The later
SGUS011D and SGUS057 documents apply only to the named high-reliability devices;
they are not substitutes for the original processor guide. Full hashes and
retrieval details are in [references/manifest.yaml](references/manifest.yaml).

## In-scope physical devices

| Profile name | Physical identity | Current scope decision | Confidence |
|---|---|---|---|
| `TMS34020` | Commercial original-revision TMS34020 | Architectural baseline defined by the 1990 user's guide and original-device portions of SPVS004D | `VERIFIED_PRIMARY` |
| `TMS34020A` | Commercial A-revision TMS34020A | Same SPVS004D-described device except for the specifically identified clock-stretch extension; no other delta is assumed | `VERIFIED_PRIMARY` |
| `SMJ34020` | Putative non-A military device | Named separately; no applicable primary data sheet has been acquired, so existence, orderability and deltas remain unresolved | `UNKNOWN` |
| `SMJ34020A` | Military/high-reliability A device | Documented by SGUS011D; package, environmental and electrical qualification differ from commercial parts | `VERIFIED_PRIMARY` |
| `SM34020A` | High-reliability A device | Documented by SGUS057; package, temperature and orderability differ from commercial and SMJ devices | `VERIFIED_PRIMARY` |

No unqualified profile will silently alias `SM34020A`, `SMJ34020A`, or an
unverified first-silicon behavior.

The `REV` instruction makes silicon identity architecturally visible. The
TMS34020 guide defines the result layout and gives `0000_0010h` and
`0000_0011h` as revision-1.0 and revision-2.0 examples, while the TMS34010
guide's same-encoding instruction returns a word with family bit 3 rather than
TMS34020 family bit 4. Until readable target-board markings or physical
execution establish the fitted stepping and spin-off fields, no Battletoads or
Revolution X profile may guess a REV result. RSC-0021 records that pinned MAME
incorrectly returns the TMS34010 example value for its TMS34020 class.
The independent model and bounded scalar RTL therefore default to an
unselected identity. They accept an explicit format-valid value, and their
positive tests label `0000_0010h` as a User's Guide example rather than a game
device selection.

## Established original-to-A delta

SPVS004D explicitly says its information applies to both TMS34020 and
TMS34020A except the clock-stretch material beginning on data-sheet page 21.
That statement is the present limit of the verified commercial revision delta;
it is not evidence that undocumented errata do not exist.

The TMS34020A adds:

- a normal four-quarter machine cycle and an eligible stretched cycle with a
  fifth quarter, Q4b;
- CONFIG register bit 4, conventionally `CONFIG.CSE`, at bit address
  `C00001A0h`;
- reset clearing CSE, so stretch mode is disabled by default;
- when CSE is set, stretching of all true address cycles and read data cycles
  of read-modify-write sequences, subject to the exceptions on page 22;
- a warning that clock stretch is not recommended in multiprocessor systems.

Sources: TI SPVS004D, description, data-sheet page 2; “clock stretch,” page 21;
“enabling clock stretch,” page 22; multiprocessor timing note, page 47.
Confidence: `VERIFIED_PRIMARY`.

No instruction, opcode, status, cache, host, display, interrupt, fault,
coprocessor, or reset delta beyond the CSE behavior is presently asserted. The
absence of another difference in the acquired data sheet is not a replacement
for missing silicon errata.

## Architectural baseline versus package timing

The portable architectural core will separate:

1. programmer-visible execution and device-profile state;
2. transaction-level memory, host, multiprocessor, coprocessor and video
   interfaces;
3. an original-pin timing wrapper; and
4. package/board electrical constraints.

Commercial package and speed options established by SPVS004D are:

- TMS34020-32: 125 ns instruction cycle;
- TMS34020A-32: 125 ns instruction cycle;
- TMS34020A-40: 100 ns instruction cycle;
- GB: 145-pin ceramic pin-grid package;
- PCM: 144-pin plastic quad-flat package.

The SMJ34020A is documented in 145-pin GB ceramic and 132-pin HT ceramic
quad-flat packages for -55 °C through 125 °C, at 125 ns and 100 ns instruction
cycles. Source: TI SGUS011D, title/features and package pin-assignment tables,
data-sheet pages 1, 3, and 5.

The acquired SM34020A data sheet lists the 145-pin GB ceramic
`SM34020AGBS40`, 100 ns, -40 °C through 110 °C device as orderable and labels
the 125 ns `SM34020AGBS32` as “potential release.” Source: TI SGUS057,
Table 1, data-sheet page 2. Confidence: `VERIFIED_PRIMARY` for that document
revision only.

Electrical limits belong in device/package constraints, not behavioral RTL.
Analog delays will not be modeled inside the core.

## Default profile policy

There is not yet enough direct board evidence to freeze one physical-device
default for both target games:

- Revolution X is documented by the pinned MAME driver as running a device
  labeled “TMS34020” at 40 MHz. SPVS004D lists the commercial 40 MHz speed only
  for TMS34020A-40, making A silicon the leading inference, not a verified top
  marking.
- Battletoads is modeled at 32 MHz, a speed offered for both original and A
  commercial parts. Clock alone cannot distinguish them.

Until readable production-board markings are obtained, the repository shall
not hide this uncertainty behind a generic alias. The planned executable
configuration will expose an explicit revision parameter, reset CSE to zero for
the A profile, and reject unknown values. A release default will be selected
only after the game-device evidence satisfies the acceptance criteria in
`TMS20-0003`. No device-selection RTL exists yet.

This is an intentional open decision, not a claim that an A data sheet can be
substituted for original TMS34020 behavior.

## Production revisions and errata

The following remain `UNKNOWN`:

- original first-silicon stepping identifiers and changes in later original
  production lots;
- complete original and A silicon errata;
- whether any undocumented architectural fixes accompanied A silicon;
- whether a non-A SMJ34020 was orderable and, if so, its package/timing/errata;
- per-lot behavior of game-board processors;
- electrical differences not represented in the acquired document revisions.

These questions are tracked as OQ-0001 through OQ-0005 in
[research/open_questions.md](research/open_questions.md). The implementation
must not promote an `UNKNOWN` entry to verified behavior without new evidence.

## Excluded from the generic core

Battletoads and Revolution X memory maps, shift-register callbacks, sprite/DMA
logic, palette devices, sound, controls, security, NVRAM, and PAL/GAL decoding
are board logic. They may be modeled only in separate wrappers and integration
harnesses. Their presence cannot change the architectural meaning of a core
device profile.
