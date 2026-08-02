# Pixel processing

This document is an incomplete primary-source extraction. It does not yet
define the complete pixel-processing matrix, raster operations, transparency,
plane masks, or graphics memory sequencing required by `TMS20-0025`.

## Window comparison boundary

CPW is the first independently modeled window operation. It treats the source
register, B5/WSTART, and B6/WEND as signed XY pairs, with X in bits `[15:0]`
and Y in `[31:16]`. WSTART and WEND are inclusive lower and upper corners.
The zero-extended destination outcode is:

| Bit | Set condition |
|---:|---|
| 5 | `WSTART.X > point.X` |
| 6 | `point.X > WEND.X` |
| 7 | `WSTART.Y > point.Y` |
| 8 | `point.Y > WEND.Y` |

V is the OR of bits `[8:5]`; every other ST bit is preserved. All three inputs
must be captured before destination writeback because an explicit B-file
destination may alias B5 or B6. The model reproduces all 16 published example
rows and signed-boundary discriminators. `tms34020_window_compare.sv` is a
portable combinational semantic leaf; the scalar composition does not execute
CPW until it gains an owner for the two implied register reads and atomic V/
destination commit. No complete window-checking, clipping, pixel-processing,
or graphics-timing claim follows from this leaf.

Sources: TI *TMS34020 User's Guide*, August 1990, Window Checking §12.7,
printed p.12-19; CPW printed pp.13-85..13-86; instruction timing printed
p.15-4. Compatibility cross-check: TI *TMS34010 User's Guide*, 1988, CPW
printed pp.12-57..12-58 and Appendix A p.A-13.

## Array clipping boundary

CLIP at exact `08F2h` intersects the positive-size unsigned B7 height:width
array rooted at signed-XY B2 with inclusive signed B5/B6 window bounds. The
bounded model and `tms34020_array_clip.sv` compute the endpoint in an extended
coordinate domain before intersection; this preserves TI's explicit support
for arrays whose ending coordinate overflows signed 16-bit XY space. A
nonempty common rectangle replaces B2 and B7. A wholly outside rectangle
leaves both unchanged. Z reports no common rectangle, V reports any portion
outside, and N/C/lower ST are preserved.

Directed rows cover wholly inside, left/top and right/bottom clipping, wholly
outside, a positive-coordinate overflow, maximum dimensions, zero dimensions,
and inverted windows. The last two are unsupported guards rather than silicon
claims: OQ-0029 records that TI says a zero dimension suppresses a graphics
transfer but never defines CLIP's Z/V result for the empty rectangle. The
scalar router cannot execute CLIP until it can capture four implied registers
and atomically commit B2/B7/Z/V. TI lists timing only as complex; no state
count, memory cycle, pixel sequencer, or continuation behavior is invented.

Sources: TMS34020 User's Guide DYDX printed pp.4-50..4-51, §12.7.4.4 printed
p.12-23, CLIP printed pp.13-55..13-56, and timing table p.15-2.

## Line initialization boundary

LINIT is the exact `0C57h` TMS34020-only setup operation used before line
drawing. It captures B2/DADDR as `(y0:x0)`, B7/DYDX as `(y1:x1)`, and the
signed inclusive B5/WSTART and B6/WEND corners. With
`a=max(abs(x1-x0),abs(y1-y0))` and `b=min(...)`, it produces:

| Result | Meaning |
|---|---|
| B0 | decision variable `2b-a` |
| B7 | `b:a`, minor extent in the high half and major in the low half |
| B10 | count `a+1` |
| B11 | signed XY increment for a diagonal/minor-axis step |
| B12 | signed XY increment along only the dominant axis |

N reports `x0==x1`, C reports a shared nonzero endpoint outcode, Z reports
`y0==y1`, and V reports either endpoint outside. The model and
`tms34020_line_initialize.sv` cover horizontal, vertical, equal, reversed,
degenerate, signed-window and maximum coordinate-delta cases. The scalar
router deliberately does not execute LINIT: it lacks the simultaneous four
implied reads and atomic five-register/status commit owner. The leaf exposes
the documented nine-state count but does not implement graphics-pipeline
timing, FLINE execution, clipping, continuation, or memory cycles.

Sources: TMS34020 User's Guide §12.7.5.2 printed p.12-26; FLINE setup printed
pp.13-121..13-123; LINIT printed p.13-146; timing table p.15-6.

## XY-to-linear conversion boundary

The model implements CVDXYL, CVMXYL, CVSXYL, and CVXYL using the signed
coordinate equation and all three CONVxP pitch classes. Conversion value 1 in
bits `[4:0]` equal to zero selects a signed 16-by-32 arbitrary-pitch multiply;
otherwise its one's-complement shift count forms the first Y product. A
nonzero conversion value 2 in bits `[12:8]` adds a second shifted Y product.
PSIZE scales X for destination, source, and general conversion. Mask
conversion uses the published unscaled X term and no offset.

`tms34020_xy_to_linear.sv` implements the combinational arithmetic, pitch
class, and visible pitch-class state selection independently of the register
owner. The scalar composition rejects all four decoded forms because it cannot
yet atomically capture their explicit operand(s), B-file pitch/offset
registers, conversion register, and PSIZE. This leaf is not a claim that I/O
write latency, pipeline overlap, or a complete graphics operation is present.

RSC-0025 isolates three CVXYL PSIZE=4 examples whose results omit `X × 4`
despite the equations on printed pp.12-47 and 13-92. The model/RTL follow the
equation, and OQ-0016 retains the need for errata or hardware confirmation.
RSC-0026 separately records that arbitrary-pitch CVXYL is 14 states on the
instruction page but 15 in the chapter-15 timing table. The leaf provisionally
reports 14 and is not evidence of resolved physical timing.
Sources: the same guide, CONVxP printed pp.4-28..4-29, §12.12 printed
pp.12-47..12-49, instruction pages 13-87..13-93, and timing p.15-4.
