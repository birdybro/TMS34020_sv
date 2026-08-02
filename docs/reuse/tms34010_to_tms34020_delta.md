# TMS34010 to TMS34020 architectural delta

Status: required-topic coverage is complete in the 96-entry generated ledger;
instruction-by-instruction and cycle-by-cycle quantification is still in
progress under `TMS20-0005` and `TMS20-0006`.

Primary comparison source: *TMS34020 User's Guide*, document
2564006-9721, August 1990, §1.6, pages 1-16 through 1-18. Cache details below
use Chapter 5, pages 5-2 through 5-8. Electrical/revision details use
SPVS004D, March 1990 revised November 1993, pages 2 and 21-23.

The machine-readable authority for this comparison is
[`docs/generated/tms34010_tms34020_delta.yaml`](../generated/tms34010_tms34020_delta.yaml).
It uses the JSON subset of YAML 1.2 and gives every entry a TMS34010 behavior,
TMS34020 behavior, RTL impact, test impact, precise citation, confidence, and
unresolved-question list. Mechanical tests prevent a required topic from being
silently dropped.

## High-impact delta

| Feature | TMS34010 baseline | Documented TMS34020 behavior | RTL consequence |
|---|---|---|---|
| Pin compatibility | 16-bit local bus and HOLD interface | Explicitly not pin-compatible; 32-bit bus and multiprocessor/coprocessor interfaces | Dedicated pin wrapper and bus controller |
| External bus | 16 bits | 32 bits with dynamic 16-bit target sizing | New native transactions, beat splitting, four byte enables |
| Cycle time | 130/160/200 ns family values in comparison table | 100/125 ns products | Reconstruct TMS34020 phases and timing |
| Instruction cache | Upstream RTL deliberately omits its optional TMS34010 cache; comparison table says 256 bytes | Mandatory architectural 512-byte cache: four 64-instruction-word segments; eight four-long-word subsegments each; 22-bit SSA per segment; 32 P flags; four-entry LRU ordering | New cache, refill, replacement, flush/disable and pipeline integration |
| Cache refill | Not modeled in upstream RTL | Four long words per missed subsegment; requested opcode/immediate long word is fetched last; segment/subsegment miss handling differs | Exact ordered refill traces and fault/retry handling |
| Self-modifying/host code | No 34020 cache | Data writes do not update cached copies; software must flush with HSTCTLH.CF; CONTROL.CD preserves cache state while bypassed | Explicit noncoherence and controls |
| Parallelism | Upstream functional multicycle implementation disclaims silicon cycle parity | Cache lookup/fetch, execution unit and memory interface can operate in parallel | Dedicated pipeline/sequencer; no wrapper-only design |
| Endianness | Little endian | Reset-configurable little or big endian | CONFIG and all memory/host/cache data paths |
| Pixel pitch | Power-of-two conversion registers | Unlimited pitch using SPTCH/DPTCH relationships and added conversion support | Graphics/address-generation redesign |
| Pixel/color width | Upstream TMS34010 graphics commonly uses 16-bit color state | COLOR0/COLOR1 and PMASK are full 32-bit; PMASKL/H both valid | Full 32-bit pixel/mask datapath |
| VRAM | Serial registers | Serial registers, block writes, split serial registers, enhanced page mode, 1M VRAM special functions | New request classes and display/memory cycles |
| I/O map | 32 × 16-bit locations | 64 × 16-bit locations with moved/new registers | Reimplemented I/O map and reset/side effects |
| Host | TMS34010 host engine/pins | Direct access to full address space, 32-bit transfers/byte selects, implicit addressing, prefetch, host bus fault status | Reimplemented host subsystem and CDC |
| Arbitration | HOLD/HOLDA | GI plus R0/R1 encoded multiprocessor requests, release/reacquisition protocols | Reimplemented arbitration |
| Coprocessor | Memory-mapped external use | Direct interface and general-purpose coprocessor instructions/cycles | New instruction and bus subsystem |
| Bus faults | No equivalent upstream architecture | BUSFLT, retry encoding with LRDY/PGMD, bus-fault registers, interrupt and instruction continuation | Fault controller, checkpoints, idempotence proofs |
| Reset vector | Upstream consumes 32-bit vector as PC | Four vector LSBs initialize CONFIG; compatibility code must not rely on them as address bits | Reset fetch/config split and tests |
| A revision | Not applicable | SPVS004D says its content applies to original and A except clock stretch; A adds CONFIG.CSE and stretches selected address/RMW-read cycles by one Q4 quarter | Explicit device variant parameter only after target-board marking is known |

Compatibility is conditional rather than equivalence. Section 1.6 specifically
warns TMS34010 software about full 32-bit colors/mask, B13 pattern state,
CONVxP/xPTCH consistency, timing loops, 32-bit alignment, cache-load order,
graphics-context saves, reset-vector low bits, moved video registers, and
interrupt stack assumptions. Each becomes a compatibility test, not a reason
to copy an implementation.

The nine extracted MOVB forms retain their TMS34010 encodings and fixed-byte
programmer-visible semantics. Stores and memory copies preserve ST; loads
always sign-extend and replace N/Z/V while preserving C independently of
FS/FE. This permits reuse of independently verified byte insertion/extraction/
copy, extension and signed/absolute address arithmetic, but not the TMS34010 memory
sequencer: the TMS34020 guide publishes its own visible/hidden state cases for
a 32-bit pipeline and the eventual owner must handle BEN, SIZE16, page mode,
byte CAS selection, read/modify/write, waits, faults and retries. The offset
memory-copy column-E hidden-state anomaly remains PROVISIONAL under
RSC-0039/OQ-0026. Sources:
TMS34020 User's Guide printed pp.13-154..13-156 and 15-10..15-12; TMS34010
User's Guide printed pp.12-114..12-124.

## Opcode and programmer-visible compatibility

The guide calls TMS34010 object code upward compatible, but immediately places
conditions on that statement. It is evidence for retaining compatible
encodings and architectural results, not for sharing a decoder, sequencer, or
cycle trace.

Established requirements are:

- enumerate all 65,536 possible first words before deciding which encodings are
  inherited, new, redefined, reserved, or illegal;
- treat `0000h`/TRAP 30 as the only portable illegal-opcode dependence stated by
  §1.6;
- implement TMS34020 status effects from §4.1 and chapters 13–14 instead of
  copying TMS34010 flag logic without an instruction-level audit;
- support full 32-bit COLOR0/COLOR1 and PMASKL/H state;
- preserve the different cache refill order and 32-bit alignment consequences;
- load CONFIG from the reset-vector low nibble before clearing the PC low bits;
- save the expanded graphics context and use TMS34020 interrupt-stack rules.

The generated ledger deliberately marks the complete removed/redefined opcode
list and exact common-instruction status delta `UNKNOWN`. Those fields can move
to `VERIFIED_PRIMARY` only when the ISA extraction and independent fixtures
exist.

The first instruction-specific timing delta is now quantified for the
field-parameter family. TMS34020 SETF, SEXT, and ZEXT take one, two, and one
machine states, respectively. The 1988 TMS34010 guide reports SETF cases of
`1,4` for field bank 0 and `2,5` for field bank 1, SEXT `3,6`, and ZEXT `1,4`.
Compatible encodings and results therefore do not authorize reuse of the older
sequencer. Sources: TMS34020 guide printed pp.13-230..13-232 and 13-268;
TMS34010 guide printed pp.12-237..12-238 and 12-257.

CMPXY is a second quantified timing delta. Both primary guides give the same
`E400h`/`FE00h` encoding, nondestructive signed-half comparisons, and unusual
NCZV meanings. The TMS34020 executes it in one machine state, while the 1988
TMS34010 guide reports `1,4`. The paired-half semantic datapath can therefore
be reused only after independent verification; the older instruction timing
state machine cannot. Sources: TMS34020 guide printed p.13-84; TMS34010 guide
printed p.12-56.

CPW retains `E600h`/`FE00h`, its signed inclusive XY window comparisons,
outcode layout, implied B5/B6 registers, and V-only status behavior. The
TMS34020 page specifies one machine state; the TMS34010 page reports one
machine state/four input clocks. This isolated semantic and timing-unit match
supports an independently verified comparison leaf, not reuse of surrounding
graphics sequencing. Both implementations must capture B5/B6 before a
destination alias writes either register. Sources: TMS34020 guide printed
pp.13-85..13-86 and p.15-4; TMS34010 guide printed pp.12-57..12-58 and
Appendix A p.A-13.

LINIT at exact `0C57h` is TMS34020-only; the TMS34010 guide has no matching
instruction. Its signed endpoint/window classification, major/minor setup,
five implied B-register writes, NCZV replacement, and fixed nine-state timing
therefore require a dedicated semantic leaf and eventual multi-register commit
owner rather than an adapted TMS34010 graphics timing machine. Sources:
TMS34020 guide §12.7.5.2 printed p.12-26, LINIT printed p.13-146, and timing
table p.15-6.

CLIP at exact `08F2h` is likewise TMS34020-only. It requires extended signed-
coordinate rectangle intersection, atomic B2/B7 adjustment, partial Z/V
replacement, and a complex internal execution owner. No TMS34010 graphics
state machine can be reused for this operation. The bounded implementation
rejects zero dimensions because TI does not state their CLIP Z/V result
(OQ-0029). Sources: TMS34020 guide DYDX printed pp.4-50..4-51,
§12.7.4.4 p.12-23, and CLIP pp.13-55..13-56.

FPIXEQ/FPIXNE at exact `0ABBh`/`0ADBh` are TMS34020-only plane-masked pixel
searches. Their signed count direction, B10/B11 checkpoint updates, aligned
COLOR0/PMASK comparison, Z result, complex timing, and special interrupt
restart require a new memory/graphics continuation owner. No TMS34010 leaf or
timing state machine is reusable. The current RTL implements only one logical
comparison/update step; the model's atomic scan is not physical sequencing.
Sources: TMS34020 guide FPIXEQ pp.13-126..13-127, FPIXNE pp.13-128..13-129,
interrupt exception p.6-14, and plane masking pp.12-39..12-40; RSC-0044.

FLINE at `DE1Ah`/`DE9Ah` is also TMS34020-only. Although it consumes
Bresenham state initialized by LINIT and shares graphics concepts with LINE,
it uses a linear DADDR, PATTERN-controlled COLOR0/COLOR1 output, converted XY
increments, no window checking, its own decision-zero selector, and the
published `12+3CD+(2+P)E+3` timing. A TMS34010 LINE sequencer cannot be
retimed or wrapped into this behavior. The current clean-room leaf owns one
normalized replace-mode step only; the atomic model owns no physical bus or
IX/BF continuation. Sources: TMS34020 guide §3.6 pp.3-15..3-16, FLINE
pp.13-121..13-125, and timing pp.15-2, 15-5.

DRAV retains `F600h`/`FE00h`, same-file Rs/Rd, aligned COLOR1 output,
independent XY half-addition, PPOP/window/transparency/PMASK controls, and
conditional V behavior. That functional compatibility does not authorize the
TMS34010 state machine: TMS34020 adds PSIZE=32, a 32-bit data path, signed
window coordinates, arbitrary/two-power pitch conversion, moved CONTROL plus
DPYCTL.CST, dynamic bus behavior, and its own `4+P+CD` window timing matrix.
The clean-room TMS34020 leaf reimplements only the normalized pixel transform
and XY addition. Sources: TMS34020 guide DRAV pp.13-100..13-102 and timing
p.15-5; TMS34010 guide DRAV pp.12-67..12-69; RSC-0045.

FILL.L and FILL.XY retain exact `0FC0h`/`0FE0h` encodings, unsigned DYDX
dimensions, COLOR1/PMASK pixel semantics, row pitch, and the final linear DADDR
checkpoint. Their compatible visible operation does not justify reuse of the
TMS34010 graphics state machine: TMS34020 adds PSIZE=32, a 32-bit/dynamic-16
path, arbitrary/two-power conversion, revised signed-window rules, moved
CONTROL plus DPYCTL.CST, page mode, hidden-write overlap, bus faults, and a
different continuation implementation. The clean-room leaf implements one
normalized W0 replace-mode traversal/pixel step only. Sources: TMS34020 guide
pp.4-30..4-34, 4-50..4-51, 12-8..12-9 and 13-114..13-120; TMS34010 guide
pp.12-80..12-87; RSC-0045/RSC-0046.

PFILL.XY is a TMS34020-only exact `0A37h` array instruction with no TMS34010
sequencer to reuse. It performs one XY conversion, derives a PATTERN start
index from the destination long-word position, selects aligned COLOR0/COLOR1,
and layers window/PPOP/transparency/PMASK behavior on a 32-bit/dynamic-16 bus.
The clean-room model/leaf cover only bounded/normalized W=0 replace mode; B14,
physical grouping, page/fault/retry and continuation owners remain absent.
Sources: TMS34020 guide pp.4-30..4-34, 4-73..4-74, 9-46, 12-15..12-16,
13-184..13-189 and 15-5; RSC-0046/RSC-0047.

CVXYL retains `E800h`/`FE00h`, same-file explicit operands, implied B3/B4,
CONVDP/PSIZE inputs, unaffected ST, and the signed XY-to-linear equation. The
TMS34020 expands pitch handling from the TMS34010's power-of-two display case
to power-of-two, sum-of-two-powers, and arbitrary signed DPTCH cases, with
3/4 states for the first two pitch classes and a disputed 14/15-state
arbitrary class instead of the TMS34010's published `3,6`. CVDXYL
`0A80h`/`FFE0h`, CVMXYL `0A60h`/`FFE0h`, and CVSXYL `EA00h`/`FE00h` are new
TMS34020 paths with 2/3/14-state pitch cases and distinct offset/pitch
operands. A TMS34010 power-of-two datapath or timing machine therefore cannot
be reused unchanged. The three contradictory PSIZE=4 example results are
isolated as RSC-0025; the repeated equation is the implemented contract.
RSC-0026 records the TMS34020 instruction-page/timing-table disagreement.

DIVS and DIVU retain `5800h`/`FE00h` and `5A00h`/`FE00h`, same-file
odd-destination 32-by-32 and even-destination 64-by-32 forms, quotient/
remainder placement, overflow-preserve behavior, and status masks. Their
TMS34020 timing is not inherited: the older guide publishes paired
alignment-dependent normal/special counts, while the TMS34020 pages collapse
these to DIVS 39/40 normal, 41 for result `80000000h`, and 7 for early cases,
and DIVU 37 normal, 7 for odd divide-by-zero, and 5 for even early cases.
RSC-0027 keeps the signed nonzero early-overflow comparison/timing provisional.
The upstream restoring divider is `COPY_AND_ADAPT` reference material only;
the new leaf is a clean-room TMS34020-owned implementation and no upstream
timing FSM is compiled. Sources: TMS34020 guide printed pp.13-96..13-99 and
15-4; TMS34010 guide printed pp.12-63..12-66 and Appendix A p.A-15.

MODS/MODU retain `6C00h`/`FE00h` and `6E00h`/`FE00h`, same-file 32-bit
operands, signed/unsigned remainder placement, and C preservation. Status and
timing do not transfer unchanged. TMS34020 MODS defines N/Z from the remainder,
forces N/Z low for zero divisor, and makes V a divisor-zero indicator; MODU
forces Z low for zero divisor. The older guide leaves more flags unchanged and
publishes alignment-paired 40/43, 41/44, 3/6 and 35/38, 3/6 timing, whereas
TMS34020 publishes 40, 41, 3 and 35, 3. RSC-0028 resolves the inherited MODU
"quotient" typo from the remainder example; RSC-0029 retains the unreachable
MODS `80000000h` timing condition. The clean-room TMS34020 divider leaf shares
only the arithmetic mechanism, not upstream status/timing control. Sources:
TMS34020 guide printed pp.13-152..13-153 and 15-5; TMS34010 guide printed
pp.12-112..12-114 and Appendix A p.A-17.

MPYS/MPYU retain `5C00h`/`FE00h` and `5E00h`/`FE00h`, low-FS1 field
arithmetic, and even-pair/odd-low-word placement, but the pinned upstream
multiply implementation is not reusable as timing or odd-flag control.
TMS34020 explicitly derives odd-Rd N/Z from the full product including
discarded MSBs. The older primary guide is ambiguous there: pinned MAME uses
the full product while the pinned TMS34010 RTL uses the retained word
(RSC-0032/OQ-0021). TMS34020 also removes the older destination-parity timing
pair, although its own detailed pages and chapter-15 table swap which mnemonic
has a sign-dependent extra state (RSC-0030/OQ-0020). The new multiplier leaf
is clean-room TMS34020-owned and its selected timing classification remains
provisional. Sources: TMS34020 guide printed pp.13-172..13-176 and 15-6;
TMS34010 guide printed pp.12-164..12-167.

SWAPF is a TMS34020-only `7E00h`/`FE00h` bus-locked field exchange and is not
an ordinary TMS34010 field-move variant. It captures `*Rs`, Rd, FS0, and FE0;
returns the old extended memory field in Rd; writes low Rd bits back; sets N/Z,
preserves C, clears V; and withholds completion until the locked write finishes.
The read/write pair is indivisible and restarts from the read after retry,
fault, refresh interruption, or lost grant. It does not sample SIZE16 and
emits only S=0, so the generic TMS34010 field sequencer and its retry point are
not reusable. The current model/leaf cover successful valid 32-bit word-local
semantics only. Sources: TMS34020 guide printed pp.13-247..13-248, 8-13,
8-26, and 15-9.

The ordinary `MOVE Rs,*Rd[,F]` encoding and visible low-field insertion are
compatible, but their timing and bus realization are not reusable. The
TMS34020 uses a 32-bit byte-strobed pipeline with five long-word/byte-
alignment cases and BEN-dependent visible timing; TMS34010's 16-bit memory
timing state machine is not evidence for those cycles. The model and field-
store leaf therefore reuse only independently verified field-size/insertion
semantics. Dynamic SIZE16, CAS strobes, RMW, page mode, waits, faults/retries,
and pins require a TMS34020-owned sequencer. Sources: TMS34020 guide printed
pp.13-159 and 15-10..15-11; TMS34010 guide printed pp.12-127..12-128.

The ordinary `MOVE *Rs,Rd[,F]` encoding, FE extension, N/Z/V update and C
preservation are likewise compatible, but the TMS34020's five 32-bit
alignment cases and 3/3/4/4/4-state read timing are device-owned; FE adds one
state. The current model/leaf reuse only independently verified extraction,
extension, and visible status semantics. Pointer capture, BEN, dynamic
SIZE16, page mode, waits, faults/retries and physical requests require the
TMS34020 sequencer. Sources: TMS34020 guide printed pp.13-160, 13-163, and
15-10..15-11; TMS34010 guide printed pp.12-135..12-136.

`MOVE *Rs,*Rd[,F]` also retains its encoding and visible read-before-write
field copy, but its TMS34020 timing is the 32-bit A–H matrix: source alignment
selects three/four visible states and destination alignment selects
1/2/2/3/4 hidden writes. The logical model/leaf reuse no 16-bit TMS34010
sequencer. BEN, CAS/RMW, dynamic SIZE16, page turnaround, waits, faults/retries
and interrupts require device-owned control. Sources: TMS34020 guide printed
pp.13-160 and 15-10..15-12; TMS34010 guide pp.12-137..12-138.

`MOVE Rs,*Rd+[,F]` retains `9000h`/`FC00h`, captured-source/address ordering,
field-size pointer addition and unchanged ST. Its TMS34020 32-bit alignment,
BEN and hidden-write timing are nevertheless device-owned. The current model
and address/insertion leaves reuse only semantic capture, add and insertion;
they do not reuse a TMS34010 bus/timing FSM. Dynamic SIZE16, CAS/RMW, page
mode, waits, interrupt recognition and idempotent fault/retry still require
the TMS34020 sequencer. Sources: TMS34020 guide printed pp.13-13, 13-160 and
15-10..15-11; TMS34010 guide printed pp.12-128..12-129.

`MOVE *Rs+,Rd[,F]` retains `9400h`/`FC00h`, field read/FE extension, source
postincrement, N/Z/V replacement and C preservation. TMS34020 owns the five
32-bit alignment cases, BEN behavior, dynamic sizing and physical retirement;
no TMS34010 timing FSM is reused. TI's TMS34020 page does not explicitly
resolve Rs=Rd write priority. Pinned MAME and the pinned TMS34010 RTL/test
record both make fetched data win, so only that corner is `CORROBORATED` under
RSC-0036/OQ-0024. Sources: TMS34020 guide printed pp.13-13, 13-161, 13-163,
and 15-10..15-11; TMS34010 guide printed pp.12-139..12-140.

`MOVE *Rs+,*Rd+[,F]` retains `9800h`/`FC00h`, read-before-write copy,
complete ST preservation and pointer increments. Both guides explicitly make
the same-register destination the once-incremented source address, but neither
states the final shared value unambiguously. The selected CORROBORATED behavior
applies both named increments and leaves original plus twice the field size,
matching the primary operation sequence and pinned MAME while conflicting with
the pinned TMS34010 RTL's suppressed second update. RSC-0037/OQ-0025 retain
this boundary. The TMS34020 A–H 32-bit alignment matrix, BEN mapping, hidden
writes, dynamic width, page and fault retirement remain device-owned; no
TMS34010 timing FSM is reused. Sources: TMS34020 guide printed pp.13-161,
13-165..13-166, and 15-10..15-12; TMS34010 guide printed pp.12-140..12-141;
pinned MAME `34010ops.hxx` lines 1311–1324.

The three predecrement forms retain `A000h`, `A400h`, and `A800h` with mask
`FC00h`. Their compatible semantic ordering is reusable only at the leaf level:
register-to-memory decrements Rd before observing an aliased Rs; memory-to-
register decrements Rs before reading and explicitly makes loaded data win an
Rs=Rd collision; paired memory-to-memory decrements/captures the source before
decrementing/writing the destination and explicitly leaves an aliased pointer
two field sizes below its original value. The pinned TMS34010 RTL deliberately
suppresses that second shared-register writeback, so RSC-0038 prohibits reuse
of its alias handling. TMS34020 replaces the 16-bit timing
environment with five-case 32-bit alignment: two visible states for the store,
4/4/5/5/5 plus FE for the load, and 4/4/5/5/5 visible source states plus
1/2/2/3/4 hidden destination writes for the copy. BEN, byte strobes/RMW,
dynamic width, pages, waits and fault/retry retirement remain TMS34020-owned;
no upstream timing FSM is reused. Sources: TMS34020 guide printed pp.13-8,
13-160..13-163 and 15-10..15-12; TMS34010 guide printed pp.12-130..12-131,
12-138..12-139 and 12-143..12-144.

The three signed-offset forms retain `B000h`, `B400h`, and `B800h` with mask
`FC00h`, signed 16-bit bit displacements, source-before-destination extension
word order for the paired copy, modulo-2^32 effective-address addition, and no
base writeback. Compatible field insertion/extraction/extension/status and
read-before-write semantics may be reused only after independent tests. The
TMS34020 owns its five-case 32-bit timing: three visible states for the store,
4/4/5/5/5 with a two-state FE surcharge for the load, and 5/5/6/6/6 source
states plus 1/2/2/3/4 destination hidden writes for the paired copy. BEN,
byte strobes/RMW, dynamic width, page behavior, waits and fault/retry retirement
remain TMS34020-specific; no TMS34010 timing FSM is reused. Sources: TMS34020
guide printed pp.13-14, 13-160..13-163 and 15-10..15-12; TMS34010 guide
printed pp.12-132..12-133, 12-147..12-148 and 12-151..12-152.

The mixed `MOVE *Rs(offset),*Rd+[,F]` form retains `D000h`/`FC00h`, one
signed 16-bit source displacement, the original destination write address,
post-write destination increment, unchanged ST and read-before-write field
semantics. Compatible arithmetic and ordering may be reused only after
independent tests. The TMS34020 owns its 5/5/6/6/6 visible source-case timing,
1/2/2/3/4 hidden destination writes, BEN mapping, byte strobes/RMW, dynamic
width, page behavior, waits, interrupts and fault/retry retirement; no upstream
timing FSM is reused. Sources: TMS34020 guide printed pp.13-14, 13-162, 13-166
and 15-12; TMS34010 guide printed pp.12-149..12-150.

The four absolute-address forms retain low-word/high-word extension ordering
and compatible field/status semantics: `0580h`/`FDE0h` register-to-absolute,
`05A0h`/`FDE0h` absolute-to-register, `D400h`/`FDE0h` absolute-source to
postincrement destination, and `05C0h`/`FDFFh` absolute-to-absolute. The
five-word form consumes complete source then destination addresses and retains
read-before-write ordering. These semantic components may be reused only after
independent verification. TMS34020 owns extension-fetch alignment timing,
five-case 32-bit field timing, hidden writes, BEN, dynamic width, pages, waits,
fault/retry and retirement: no TMS34010 timing FSM is reusable. Sources:
TMS34020 guide printed pp.13-14..13-15, 13-159..13-166 and 15-11..15-12;
TMS34010 guide printed pp.12-133..12-134 and 12-152..12-158.

MMTM/MMFM retain their TMS34010 `0980h`/`FFE0h` and `09A0h`/`FFE0h`
encodings, opposite second-word mask directions, register order, and visible
pointer/status semantics. Their timing and memory-controller ownership do not
carry forward. The TMS34010 pages publish cache-enabled/disabled and aligned/
nonaligned 16-bit-bus cases. TMS34020 MMFM instead publishes `n+5` under
RSC-0033, while MMTM distinguishes long-word, byte and bit alignment, hidden
pipelined writes, and instruction alignment. Both are eligible for the new
32-bit page-mode memory system and dynamic 16-bit sizing. Reuse is limited to
register numbering and semantic compatibility fixtures; the multiaccess,
page, fault/retry and timing state machines require a TMS34020 owner. Sources:
TMS34020 guide printed pp.8-16..8-17, 13-148..13-151, and 15-6; TMS34010
guide printed pp.12-109..12-112.

RETI retains exact word `0940h` and the ordinary ST/PC stack-return semantics,
but its continuation architecture and timing are not reusable. TMS34010
publishes normal and PBX-interrupted cases with 11/14-or-15 states. TMS34020
uses IX and BF saved-context selectors, 24- and 31-word internal frames, and
7/38/52 states. The TMS34020 normal model path is independently implemented;
IX/BF are classified but rejected until their own sequencer and exact hidden
frame are established. No TMS34010 return state machine is copied. Sources:
TMS34020 guide printed pp.3-29..3-30, 6-9..6-10, 13-217..13-218, and 15-8;
TMS34010 guide printed pp.12-230..12-231 and Appendix A p.A-18;
OQ-0023/RSC-0034.

RETM exact word `0860h` is TMS34020-only. It uses the same saved-context
classes, but its normal path takes ten states, forces the complete next
instruction to direct memory, and delays interrupt/single-step recognition
until one instruction executes. This requires a one-shot fetch override and
recognition gate in the TMS34020 frontend/sequencer; it cannot be wrapped
around a TMS34010 RETI implementation. Sources: TMS34020 guide Figure 6-3
p.6-10, RETM p.13-219, comparison p.6-32, timing p.15-8; RSC-0035.

REV is an architecturally visible identity delta despite using the same
`0020h`/`FFE0h` register encoding. The TMS34010 example returns `0000_0008h`
with family bit 3 and has `1,4` timing. The TMS34020 format instead sets family
bit 4, carries silicon revision in bits `[2:0]`, and optionally identifies a
spin-off in bits `[23:16]`; its revision-1.0/revision-2.0 examples are
`0000_0010h` and `0000_0011h`, and it executes in one machine state. A shared
constant or TMS34010 execution leaf is therefore incorrect. Sources:
TMS34020 guide printed p.13-221; TMS34010 guide printed p.12-233. Exact
target-game revision words remain OQ-0014.

TRAP retains its `0900h`/`FFE0h` encoding, vector map, stack frame, complete-ST
replacement, and trap-zero no-save exception, but not its TMS34010 timing. The
TMS34020 uses 7 states for trap zero and 10/12 for nonzero aligned/unaligned
saved-ST addresses; the TMS34010 guide publishes `16,19` and `30,33` cases.
Entry-state logic may be shared only after independent verification; the
TMS34010 sequencer cannot. Sources: TMS34020 guide printed pp.13-253..13-255;
TMS34010 guide printed pp.12-253..12-254.

RETS retains its `0960h`/`FFE0h` object form and visible old-SP read,
`32 + 16N` bit-address increment, PC redirect, and status preservation. Its
timing does not carry over: the TMS34020 specifies 5/6 states for aligned and
unaligned old SP, while the TMS34010 publishes minimum 7/9. Decode and semantic
fixtures are compatibility candidates; the upstream stack/bus state machine
is reference-only. Source: TMS34020 User's Guide printed p.13-220; TMS34010
User's Guide printed p.12-232 and Appendix A p.A-16.

CALL, CALLA, and CALLR retain their object forms and visible target/return-PC/
stack ordering, but their TMS34010 timing state machines are not reusable.
TMS34020 CALL and CALLR specify three visible states plus one/four hidden write
states for aligned/unaligned SP; TMS34010 publishes materially longer values.
TMS34020 CALLA's four immediate/SP alignment clauses are themselves
grammatically ambiguous, while TMS34010 gives only an aligned/unaligned stack
split. Decode and semantic fixtures are compatibility candidates. Stack-write,
redirect, overlap, fault/retry, and physical timing require a TMS34020 owner;
CALLA's exact schedule additionally remains OQ-0015. Sources: TMS34020 User's
Guide printed pp.13-48..13-50 and p.15-3; TMS34010 User's Guide printed
pp.12-48..12-50; RSC-0024.

## Cache and internal parallelism

The cache changes the observable memory trace and execution timing, so it cannot
be treated as an FPGA optimization:

1. The lookup uses one machine state and is overlapped with execution.
2. Four 64-instruction-word segments provide 512 bytes total capacity.
3. Each segment has eight subsegments of four long words.
4. A segment has a 22-bit start address and 32 presence bits.
5. A four-entry LRU order selects segment replacement.
6. A miss fetches four long words, with the opcode/immediate-containing long
   word deliberately fetched last.
7. Data writes bypass the cache and do not repair resident instructions.
8. HSTCTLH.CF flushes; CONTROL.CD bypasses while retaining the cached state.

Sources: UG §§5.1–5.4, printed pages 5-2 through 5-9. Internal overlap is
described in §5.5 and figure 5-4, printed pages 5-10 through 5-13.

Consequently, cache hit/miss/refill/fault state, the execution unit, and the
memory interface need separate ownership and checkpointing. A wrapper around an
already-sequenced TMS34010 core cannot insert this behavior faithfully.

## Memory and bus

The TMS34020 local interface is natively 32 bits and always reads aligned
32-bit long words. Four byte-oriented CAS controls permit 8-, 16-, 24-, and
32-bit writes. SIZE16 dynamically converts a target cycle into ordered 16-bit
transfers. Page mode can retain a row across eligible sequences, including
cache activity, and must interact correctly with bus locks, waits, faults,
refresh, display, host, and arbitration.

Sources: UG §§3.2–3.3, printed pages 3-3 onward; chapter 8, especially §§8.3–
8.9, printed pages 8-5 through 8-29.

The native FPGA transaction interface must therefore retain request class,
architectural transaction identity, bit address, byte enables, target width,
page eligibility, endian selection, special-function code, completion status,
and retry identity. The pin wrapper separately emits multiplexed LAD,
RAS/CAS/WE, page, width, wait, and fault timing.

## Fault, retry, and continuation

BUSFLT is not merely an external error flag. It participates with LRDY and PGMD
in completion coding, aborts a bus access, records fault state, and interacts
with interrupt/continuation handling. A retry must reissue exactly the
architectural work not committed before the checkpoint.

Sources: UG §§6.9–6.9.2, printed pages 6-17 through 6-21; §8.6.4, printed page
8-14; chapter 2 completion-code signal descriptions.

Required invariants are:

- no write is committed twice;
- no read beat is skipped;
- a crossed field is neither partially advanced nor silently corrupted;
- cache refill state is not made present after a failed transfer;
- register, status, array position, and continuation state advance once;
- a pending interrupt is neither lost nor taken at an undocumented boundary.

These invariants require directed phase injection and bounded formal properties;
the current repository has specifications but no implementation or proof yet.

## Host, multiprocessor, and coprocessor interfaces

The TMS34020 host interface adds a 32-bit organization, HBS0–HBS3, full local
address-space access, implicit addressing, prefetch behavior, and host-visible
fault/wait interaction. HSTADR compatibility does not make the TMS34010 host
FSM reusable.

The TMS34010 HOLD/HOLDA model is replaced by GI and encoded R0/R1
multiprocessor requests. Table 11-1 and chapter 11 define request, grant,
termination, release, and reacquisition behavior. This arbitration shares the
bus with refresh, display, host, cache miss, retry, and processor traffic.

Chapter 10 adds a direct coprocessor interface with command and
direct/indirect-data operations. The protocol belongs in the processor; the
external coprocessor function remains outside it.

The generated ledger now separates the long exact-`0600h` and short
`D800h`/`FF80h` CEXEC encodings because neither has a TMS34010 instruction
equivalent. The TMS34020-owned model and formatter reconstruct the documented
ID/command/size LAD value and retain visible/hidden state metadata, while the
formatter deliberately owns no physical command cycle or completion. No
TMS34010 sequencer or wrapper is reused. Sources: TMS34020 User's Guide
Chapter 10, printed pp.10-2..10-10, and CEXEC printed pp.13-51..13-54; see
`docs/coprocessor/interface.md`.

## I/O, graphics, and display

The I/O space expands from 32 to 64 16-bit registers. The verified delta
includes CONFIG, CONVMP, PMASKL/H, moved display registers, and full-width
graphics state. The complete address/reset/side-effect table remains a separate
deliverable under `TMS20-0022`.

`CONTROL2` is intentionally present in the ledger as `UNKNOWN`: it is a
project-required research candidate, but an applicable definition has not yet
been found in the acquired 1990 guide. No address or bits will be invented.

TMS34020 arbitrary pitch, additional conversion state, new graphics/array/VRAM
operations, 1M VRAM controls, clipping and expanded raster operations require a
semantic conformance matrix. Similar TMS34010 instruction names do not prove
equal memory traces, continuation points, or timing.

Display register movement is explicit in §1.6, and chapters 4 and 9 are the
authority for the new map and sequencer. The upstream TMS34010 display RTL is
therefore reference-only.

## Reset, clocks, and A silicon

The TMS34010 reference's FPGA clocking method is not a TMS34020 timing model.
CLKIN, LCLK1/LCLK2 phases, wait states, reset sampling, HCS halt selection,
CONFIG vector loading, cache invalidation, and first fetch must be reconstructed
from TMS34020 sources.

SPVS004D bounds the currently verified commercial original/A delta to the A
clock-stretch extension:

- CSE is CONFIG bit 4;
- reset clears CSE;
- an ordinary cycle has Q1, Q2, Q3, Q4;
- an eligible stretched cycle adds Q4b and is 25 percent longer;
- true address cycles and read data cycles of read-modify-write sequences are
  eligible, subject to the page-22 exceptions;
- TI does not recommend clock stretch in a multiprocessor system.

Sources: SPVS004D description page 2, clock-stretch pages 21–22, and
multiprocessor note page 47. Missing silicon errata prevent a claim that this is
the only physical-silicon change ever produced.

## Implementation boundary

The delta supports ADR-0002's dedicated TMS34020 architecture:

- leaf ALU/shifter/register concepts and licensed test ideas may be adapted
  after semantic audit;
- decoder, cache, pipeline, memory controller, local bus, host, I/O, display,
  interrupt, multiprocessor, coprocessor, fault and pin timing are reimplemented;
- game-specific maps and peripherals remain outside the generic core;
- MAME remains a differential reference, not an architectural source.

## Remaining qualification work

Structural coverage of the required delta topics is now machine checked. The
following prevent `TMS20-0005` from being complete:

- the ISA database has not classified every legal/reserved encoding;
- common-instruction status and timing cases are not yet enumerated;
- CONTROL2 identity/applicability is unresolved;
- display-sequencing and interrupt deltas are not yet field/cycle complete;
- complete silicon errata and first-silicon records are unavailable;
- the independent model and RTL cover only bounded instruction/leaf slices;
  no cache, bus, subsystem waveform suite, or physical measurement yet
  verifies the remaining requirements.
