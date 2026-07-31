# Target-game processor identification

## Result

Neither target game's exact production CPU top marking has yet been verified
from a readable, board-revision-correlated photograph or schematic. The
available evidence establishes the processor family and clocks, but supports
only an inference for Revolution X and no original-versus-A choice for
Battletoads.

This document records evidence, not game readiness.

## Pinned software reference

The current MAME source used here is pinned to commit
`a562e947b22f4f5acff0c182c26fd649d72dad0e` and stored only in the ignored
reference cache. The exact files and SHA-256 values are cataloged in
`docs/references/manifest.yaml`. MAME is a secondary implementation reference,
not authority for silicon identity or behavior.

## Battletoads

### Established evidence

| Claim | Evidence | Assessment |
|---|---|---|
| The current driver instantiates the TMS34020 family device | MAME `src/mame/rare/btoads.cpp`, pinned commit, lines 919–932 | `CORROBORATED` family identity |
| Driver CPU input is 64 MHz divided by two, or 32 MHz | Same file, lines 921–925 | `CORROBORATED` emulator configuration |
| Driver video clock is 20 MHz divided by two, or 10 MHz | Same file, lines 922 and 928–946 | `CORROBORATED` emulator configuration |
| Surviving boards contain a TMS34020-family GSP | PhilWIP, “PCB Repair – Battletoads,” 16 May 2024, board photographs and repair narrative; Bryan McPhail, “Battletoads arcade repair,” board-level bus investigation | `CORROBORATED`; the available images do not yield a reliably readable full top marking here |
| Exact original/A suffix, speed suffix, package marking, lot and date code | No adequate source acquired | `UNKNOWN` |

External evidence URLs, retrieved 2026-07-31:

- <https://philwip.com/2024/05/16/pcb-repair-battletoads/>
- <https://www.bryanmcphail.com/wp/?p=1349>

The 32 MHz operating point cannot select a revision: SPVS004D page 1 lists both
TMS34020-32 and TMS34020A-32 at a 125 ns instruction cycle. A 32 MHz input is
consistent with either commercial profile. Confidence: `VERIFIED_PRIMARY` for
the speed-option fact; `UNKNOWN` for the board part.

### Current selection

No Battletoads-specific default revision is authorized. A synthetic harness
must make the profile explicit. Local-ROM testing, when authorized ROMs become
available, should record whether boot software writes CONFIG.CSE, but software
behavior cannot by itself prove the package marking.

Smallest evidence needed: a high-resolution, glare-free photograph of the
complete GSP top marking, tied to the board revision and preferably the
specific ROM set.

## Revolution X

### Established evidence

| Claim | Evidence | Assessment |
|---|---|---|
| The documented board layout is 5770-13534-04 and labels the device TMS34020 | MAME `src/mame/williams/midxunit.cpp`, pinned commit, lines 23–59 | `CORROBORATED`; textual secondary record |
| The board/driver processor clock is 40 MHz | Same file, lines 32–35, 59, and 646–655 | `CORROBORATED` |
| Driver pixel clock is 8 MHz | Same file, lines 646–670 | `CORROBORATED` |
| Commercial SPVS004D lists a 40 MHz option only as TMS34020A-40 | TI SPVS004D, feature/order header, data-sheet page 1 | `VERIFIED_PRIMARY` for the cataloged speed option |
| Therefore the board probably uses A-revision silicon | Inference from the two preceding facts | `INFERRED`, not a verified top marking |
| Exact suffix, package marking, lot and date code | No adequate source acquired | `UNKNOWN` |

The “A” inference could be invalidated by an unlocated order option, a
high-reliability part, a driver clock error, or a board practice outside the
catalog rating. It must not be promoted to `VERIFIED_HARDWARE` without readable
physical evidence.

### Current selection

TMS34020A is the leading Revolution X research hypothesis because it is the
acquired commercial data sheet's documented 40 MHz part. It is not yet a
release default and no selection RTL exists. If later evidence identifies
TMS34020A-40, CONFIG.CSE must still reset to zero and only become active if
software writes it, per SPVS004D page 22.

Smallest evidence needed: a readable GSP top-mark photograph correlated with
each relevant 5770-13534 board revision. Service documentation or a bill of
materials naming the orderable CPU would be equivalent primary board evidence.

## Consequences for implementation and testing

- The portable core must not contain either game's memory map or peripherals.
- The eventual revision parameter must be visible in both synthetic harnesses
  and in trace metadata.
- Battletoads tests must exercise original and A/CSE-disabled profiles until
  physical identification resolves the choice.
- Revolution X tests may use A/CSE-disabled as a clearly labeled provisional
  hypothesis, and should separately exercise CSE-enabled bus timing.
- No game-ready or release-ready status may be claimed from the evidence in this
  document.
