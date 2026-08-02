# Verified RTL slice

This document records the exact boundary of the synthesizable RTL. It is a
collection of independently testable architectural leaves, not a processor
core, sequencer, pipeline, complete memory controller, or pin interface.

## Implemented leaves

| Module | Implemented behavior | Primary source |
|---|---|---|
| `rtl/core/tms34020_decode.sv` | Classification and instruction length for the 116 entries currently present in the canonical ISA database, including 12,288 ordinary/postincrement/predecrement/signed-offset RM/MR/MM field words, exact RETI/RETM, all 64 MMFM/MMTM first words, 32 REV destinations, 32 TRAP vectors, 32 RETS argument counts, 32 CALL register forms, fixed CALLA/CALLR forms, all 512 CPW and 512 SWAPF forms, all 1,088 XY-conversion forms, and all 3,072 DIVS/DIVU/MODS/MODU/MPYS/MPYU forms; all other first words remain explicitly unclassified | TI *TMS34020 User's Guide*, August 1990, individual instruction pages listed in `docs/generated/tms34020_isa.yaml` |
| `rtl/core/tms34020_frontend.sv` | Direct cache/fetch composition from explicit aligned PC through lookup/refill/bypass/retry/fault-abort to a complete serialized instruction packet | TI *TMS34020 User's Guide*, August 1990, §§4.2, 5.1–5.3.6, 6.5–6.6, 6.9, and 8.6 |
| `rtl/core/tms34020_instruction_fetch.sv` | Serialized aligned PC load, cache-word request, one-to-five-word packet assembly, per-word cache metadata, stable packet backpressure, explicit sequential/redirect completion, and abort-to-PC-reload behavior | TI *TMS34020 User's Guide*, August 1990, §§4.2, 5.1, 5.3.1, and 6.5–6.6, printed pp.4-4, 5-3, 5-5, 6-9, and 6-13 |
| `rtl/core/tms34020_pc_execute.sv` | Length-checked GETPC sequential-PC write intent, EXGPC sequential-PC write plus aligned old-register redirect intent, status/register-neutral JUMP aligned redirect intent, JACC all-condition fallthrough or aligned low-word/high-word absolute redirect intent, JR.L all-condition fallthrough or signed 16-bit word redirect intent, DSJ/DSJEQ/DSJNE Z-conditioned decrement plus signed 16-bit word redirect intent, and DSJS unconditional decrement plus encoded unsigned-magnitude/direction redirect intent; no PC storage or machine-state timing | TI *TMS34020 User's Guide*, August 1990, JAcc printed pp.13-135..13-136, long JR printed pp.13-138..13-140, DSJ family printed pp.13-103..13-108, EXGPC printed p.13-112, GETPC printed p.13-130, and JUMP printed p.13-141 |
| `rtl/core/tms34020_regfile.sv` | Two 32-bit combinational read ports, one synchronous write port, independent A0–A14 and B0–B14 storage, and shared A15/B15 stack-pointer storage | TI *TMS34020 User's Guide*, August 1990, §4.1, printed pp.4-2..4-3 |
| `rtl/core/tms34020_register_commit.sv` | Externally gated, single-edge register/ST state commit and direct-PC redirect event for 52 one-word operations including CMPXY and DSJS, eight two-word operations including JR.L/DSJ/DSJEQ/DSJNE, and nine complete three-word operations including JACC and ANDNI/ORI/XORI/ADDXYI/ADDI.L/CMPI.L/MOVI.L/SUBI.L; CMPXY is nondestructive and replaces NCZV; JACC and JR.L are register/status neutral and redirect only when their selected condition is true; DSJ-family decrement is condition-controlled while DSJS always decrements; both are status-neutral and redirect only for a nonzero result; PUTST replaces all 32 ST bits without register writeback; EXGF atomically writes its destination and selected status bank; GETPC/EXGPC consume the packet's sequential PC; EXGPC captures the old destination before writeback; JUMP redirects through the aligned old source without state writeback; unsupported or length-mismatched packets cannot mutate state | TI *TMS34020 User's Guide*, August 1990, §4.1, CMPXY printed p.13-84, JAcc printed pp.13-135..13-136, long JR printed pp.13-138..13-140, DSJ family printed pp.13-103..13-108, PUTST printed p.13-216, EXGF printed p.13-111, EXGPC printed p.13-112, GETPC printed p.13-130, JUMP printed p.13-141, and the individual instruction pages cited for `tms34020_register_execute` |
| `rtl/core/tms34020_scalar_slice.sv` | Conservative cache/fetch-to-register composition for 69 verified scalar/control-flow operations, including CMPXY, JACC, JR.L, DSJ/DSJEQ/DSJNE/DSJS, PUTST, SETF/EXGF/SEXT/ZEXT, ADDXY/SUBXY, BTST.K/R, LMO, all eight scalar shift forms, and held control-flow completion redirects; other unsupported or unclassified packets remain stable and noncommitting | TI *TMS34020 User's Guide*, August 1990, §4.1 and the individual instruction pages cited for the execution leaves |
| `rtl/core/tms34020_status.sv` | Synchronous reset to `00000010h` and masked 32-bit state updates for exact partial instruction writes | TI *TMS34020 User's Guide*, August 1990, §4.1, Figure 4-1 and Table 4-1, printed pp.4-2..4-3 |
| `rtl/execute/tms34020_addxyi.sv` | Independent 16-bit X/Y addition and the instruction-specific N/C/Z/V results | TI *TMS34020 User's Guide*, August 1990, ADDXYI, printed p.13-39 |
| `rtl/execute/tms34020_binary_arithmetic.sv` | ADD, ADDC, SUB, SUBB, and nondestructive CMP result/flag paths with carry/borrow inputs | TI *TMS34020 User's Guide*, August 1990, printed pp.13-33..13-34, 13-80, and 13-241..13-242 |
| `rtl/execute/tms34020_bit_test.sv` | Selected-bit test producing Z when the selected destination bit is zero; register and status ownership remain in the execution router | TI *TMS34020 User's Guide*, August 1990, BTST constant/register printed pp.13-46..13-47 |
| `rtl/execute/tms34020_field_extend.sv` | Right-justified 1–32-bit zero/sign extension with encoded-zero size 32 and result-derived N/Z | TI *TMS34020 User's Guide*, August 1990, SEXT printed p.13-232 and ZEXT printed p.13-268 |
| `rtl/execute/tms34020_cmpk.sv` | Encoded-zero-means-32 subtraction and N/C/Z/V compare results without register modification | TI *TMS34020 User's Guide*, August 1990, CMPK, printed p.13-83 |
| `rtl/execute/tms34020_cmpxy.sv` | Nondestructive same-file XY comparison: N/Z report X/Y equality and C/V report the signs of independently wrapped Y/X differences; no overflow or borrow interpretation | TI *TMS34020 User's Guide*, August 1990, CMPXY, printed p.13-84 |
| `rtl/execute/tms34020_divider.sv` | Clean-room 32-step restoring unsigned-magnitude engine with signed input/output conditioning, DIVS/DIVU odd 32-bit and even 64-bit dividends, MODS/MODU remainder mode, divide-by-zero/raw-high-half/signed-range outcomes, N/Z/V results, and visible-state classification. Modulus mode derives flags from the remainder and does not invalidate a valid MODS remainder on quotient overflow. Its FPGA busy/done protocol is not the TMS34020 timing sequencer, and architectural commit remains outside the leaf | TI *TMS34020 User's Guide*, August 1990, DIVS/DIVU printed pp.13-96..13-99, MODS/MODU printed pp.13-152..13-153, and timing pp.15-4..15-5; RSC-0027/RSC-0029 apply |
| `rtl/execute/tms34020_multiplier.sv` | Clean-room signed/unsigned low-FS1 by 32-bit product, full 64-bit result, full-product N/Z, explicit even-FS1 validity, and provisional detailed-page state classification. Pair selection and atomic architectural writes remain outside the combinational leaf | TI *TMS34020 User's Guide*, August 1990, MPYS/MPYU printed pp.13-172..13-176 and timing p.15-6; RSC-0030/RSC-0031 apply |
| `rtl/memory/tms34020_swap_field.sv` | Clean-room word-local field extraction/FE0 extension and replacement-word construction for FS0 widths 1–32, with explicit crossing-field validity and old-field N/Z/V. It performs no memory request, lock, retry, or commit | TI *TMS34020 User's Guide*, August 1990, SWAPF printed pp.13-247..13-248 |
| `rtl/memory/tms34020_field_store.sv` | Clean-room two-long-word little-endian insertion and five-case alignment/hidden-write classification for `MOVE Rs,*Rd[,F]`; it performs no register capture, BEN mapping, memory request, byte-strobe/RMW, retry, fault, or commit | TI *TMS34020 User's Guide*, August 1990, printed pp.13-159 and 15-10..15-11 |
| `rtl/memory/tms34020_field_address_update.sv` | Clean-room encoded field-size decoding plus effective/final pointer calculation for ordinary, postincrement and predecrement field addressing, including 32-bit wrap and invalid simultaneous-mode reporting; it performs no operand capture, memory request, or commit | TI *TMS34020 User's Guide*, August 1990, MOVE forms printed pp.13-159..13-161 |
| `rtl/memory/tms34020_field_pair_postincrement.sv` | Clean-room paired-postincrement effective/final source/destination address calculation, including 32-bit wrap, TI's Rs=Rd once-incremented destination, and the selected CORROBORATED twice-incremented final shared pointer; it performs no operand capture, field transfer, memory request, or commit | TI *TMS34020 User's Guide*, August 1990, paired-postincrement MOVE printed p.13-161; RSC-0037/OQ-0025 |
| `rtl/memory/tms34020_field_pair_predecrement.sv` | Clean-room paired-predecrement source/destination effective and final pointer calculation, including 32-bit wrap and TI's Rs=Rd once-decremented source/twice-decremented destination and final pointer; it performs no operand capture, field transfer, memory request, or commit | TI *TMS34020 User's Guide*, August 1990, predecrement addressing and paired-predecrement MOVE printed pp.13-8 and 13-161..13-162 |
| `rtl/memory/tms34020_field_offset_address.sv` | Clean-room signed-16-bit displacement extension and modulo-2^32 effective-address addition; exhaustive simulation covers all 65,536 displacements and positive/negative wrap, but the leaf does not fetch extension words, select bases, issue memory requests, or commit | TI *TMS34020 User's Guide*, August 1990, signed-offset MOVE forms printed pp.13-160..13-162 |
| `rtl/memory/tms34020_field_load.sv` | Clean-room two-long-word little-endian extraction, FE-selected extension, N/Z/V result, and five-case visible-state classification for `MOVE *Rs,Rd[,F]`; it performs no pointer capture, C preservation, BEN mapping, memory request, retry, fault, or commit | TI *TMS34020 User's Guide*, August 1990, printed pp.13-160, 13-163, and 15-10..15-11 |
| `rtl/memory/tms34020_field_move.sv` | Clean-room two-source/two-destination-word little-endian field copy with independent five-case alignment, visible-source and hidden-destination timing classification for `MOVE *Rs,*Rd[,F]`; it performs no pointer capture, BEN mapping, physical read/write, retry, fault, or commit | TI *TMS34020 User's Guide*, August 1990, printed pp.13-160 and 15-10..15-12 |
| `rtl/memory/tms34020_multiple_register_control.sv` | Clean-room MMFM/MMTM operation-specific mask normalization, register count, pointer-in-list/empty validity, final pointer, MMTM N, and published visible/hidden timing classification. It performs no register capture, memory request, page sequence, partial-list continuation, or commit | TI *TMS34020 User's Guide*, August 1990, MMFM/MMTM printed pp.13-148..13-151 and timing p.15-6; RSC-0033 applies |
| `rtl/interrupts/tms34020_interrupt_return_control.sv` | Clean-room RETI/RETM saved-context classification: BF-priority normal/IX/BF selection, 0/24/31 extra-word metadata, RETI 7/38/52 and RETM 10/38/52 state selection, normal SP+64 result, aligned saved PC with misalignment diagnostic, post-continuation IX/BF clearing, and RETM next-packet-bypass/interrupt-delay intents. It performs no stack access, cache request, hidden-state restore, interrupt checkpoint, or architectural commit | TI *TMS34020 User's Guide*, August 1990, Figure 6-3 p.6-10, RETI pp.13-217..13-218, RETM p.13-219, comparison p.6-32, and timing p.15-8; OQ-0023/RSC-0034/RSC-0035 apply |
| `rtl/execute/tms34020_lmo.sv` | Leading-zero count in the range 0–31 and zero-source Z result | TI *TMS34020 User's Guide*, August 1990, LMO, printed p.13-147 |
| `rtl/execute/tms34020_logical.sv` | AND, ANDN, OR, and XOR register results plus Z; CLR uses XOR with equal register-number fields; N/C/V remain outside the write mask | TI *TMS34020 User's Guide*, August 1990, printed pp.13-40, 13-42, 13-57, 13-182, and 13-266 |
| `rtl/execute/tms34020_register_execute.sv` | Packet-length-checked independent source/destination file selectors and register/ST write intents for NOP, ABS, NEG, NEGB, NOT, CLRC, DINT, EINT, GETST, PUTST, SETF, EXGF, SEXT, ZEXT, ADDK/INC, SUBK/DEC, MOVK, MOVI.W/L, MOVE, MOVX, MOVY, RL.K/R, BTST.K/R, SLA.K/R, SLL.K/R, SRA.K/R, SRL.K/R, SETC, ADD, ADDC, ADDXY, SUB, SUBB, SUBXY, CMP, CMPXY, CMPI.W/L, CMPK, LMO, RMO, AND, ANDN, OR, XOR/CLR, ANDNI, ORI, XORI, ADDXYI, ADDI.W/L, and SUBI.W/L | TI *TMS34020 User's Guide*, August 1990, §4.1 and printed pp.13-32..13-47, 13-57..13-58, 13-80..13-84, 13-94..13-95, 13-109, 13-111, 13-132, 13-134, 13-147, 13-158, 13-167..13-183, 13-216, 13-222..13-246, and 13-266..13-268 |
| `rtl/execute/tms34020_rotate_left.sv` | 32-bit rotate-left result for counts 0–31, count-zero C clearing, last-bit-out C, and result-derived Z | TI *TMS34020 User's Guide*, August 1990, RL, printed pp.13-222..13-223 |
| `rtl/execute/tms34020_shift.sv` | SLA/SLL/SRA/SRL results for counts 0–31, arithmetic or zero fill, count-zero C clearing, last-bit-out C, instruction-specific N/C/Z/V write masks, and SLA sign-change overflow | TI *TMS34020 User's Guide*, August 1990, printed pp.13-233..13-240 |
| `rtl/execute/tms34020_rmo.sv` | Least-significant set-bit index and Z result | TI *TMS34020 User's Guide*, August 1990, RMO, printed p.13-224 |
| `rtl/execute/tms34020_unary.sv` | ABS, NEG, NEGB, and NOT results plus instruction-specific N/C/Z/V values and write masks | TI *TMS34020 User's Guide*, August 1990, printed pp.13-32 and 13-178..13-181 |
| `rtl/execute/tms34020_xy_arithmetic.sv` | Independent 16-bit X/Y ADDXY and SUBXY results; ADDXY derives flags from result halves, while SUBXY derives them from source/destination equality and unsigned comparisons | TI *TMS34020 User's Guide*, August 1990, ADDXY printed p.13-38 and SUBXY printed p.13-246 |
| `rtl/graphics/tms34020_pixel_size_ops.sv` | GETPS zero-extension and EXGPS register/16-bit PSIZE-write data paths; no I/O timing or write-queue implementation | TI *TMS34020 User's Guide*, August 1990, EXGPS, printed p.13-113; GETPS, printed p.13-131 |
| `rtl/graphics/tms34020_pitch_conversion.sv` | Shared SETCDP/SETCMP/SETCSP conversion-field and 4/6/3 visible-state classification for one-power, two-power, and arbitrary pitches; no hidden-I/O write owner | TI *TMS34020 User's Guide*, August 1990, printed pp.4-28..4-29, Figure 12-20 p.12-49, instruction pp.13-227..13-229, and timing-table p.15-8 |
| `rtl/graphics/tms34020_pixel_replicate.sv` | RPIX replication and documented machine-state counts for PSIZE 1, 2, 4, 8, 16, and 32 | TI *TMS34020 User's Guide*, August 1990, RPIX, printed p.13-225; §12.6, printed p.12-17 |
| `rtl/graphics/tms34020_window_compare.sv` | Signed XY comparison against inclusive WSTART/WEND bounds, zero-extended CPW outcode bits 8:5, and outside/V condition; register capture and commit ownership remain outside the leaf | TI *TMS34020 User's Guide*, August 1990, CPW, printed pp.13-85..13-86 |
| `rtl/graphics/tms34020_xy_to_linear.sv` | Signed XY and arbitrary-pitch arithmetic, one-/two-power CONVxP shifts, optional PSIZE scaling or unscaled mask X, modulo-32-bit offset addition, pitch classification, and visible state selection; CVXYL arbitrary pitch provisionally selects 14 under RSC-0026, while implied-register/I/O capture and commit ownership remain outside the leaf | TI *TMS34020 User's Guide*, August 1990, CONVxP printed pp.4-28..4-29, §12.12 printed pp.12-47..12-49, CVDXYL/CVMXYL/CVSXYL/CVXYL printed pp.13-87..13-93, and timing p.15-4 |
| `rtl/cache/tms34020_icache.sv` | Bounded native-completion cache leaf: four segments, 32 subsegments, 128×32 data RAM, lookup classifications, demand-long-word-last refill, move-to-front LRU, reset abstraction, `CD` bypass, idle `CF`, backpressure, current-beat retry, and fault pause/resume/abort | TI *TMS34020 User's Guide*, August 1990, §§5.1–5.3.6, printed pp.5-2..5-8; fault/retry §§6.9 and 8.6, printed pp.6-19..6-20 and 8-12..8-14; reset §6.12.2, printed p.6-23 |

REV, TRAP, RETS, CALL, CALLA, and CALLR are classified but intentionally absent
from the execution lists above. Leaf tests drive `0020h`, `0900h`, `091Fh`,
`0920h`, `093Fh`, `0960h`, `097Fh`, `0D3Fh`, and `0D5Fh` through
`tms34020_register_execute` and require zero support, register-write, and
status-write intents. This prevents a shared TMS34010 REV constant from
becoming architectural RTL and prevents TRAP from bypassing the unimplemented
stack/vector sequencer, fault/retry state, and physical timing. It likewise
prevents RETS from bypassing absent stack-read and direct-PC completion
ownership. CALL-family guards likewise prevent decoded packets from bypassing
the absent stack-write/direct-PC owner or silently assigning CALLA timing.
CPW base-word guards prevent its verified combinational comparison leaf from
bypassing the absent simultaneous Rs/B5/B6 read and atomic destination/V owner.
CVDXYL, CVMXYL, CVSXYL, and CVXYL guards likewise prevent their verified
conversion leaf from bypassing the absent simultaneous explicit/implied
register reads, CONVxP/PSIZE state, destination owner, and timing sequencer.
DIVS/DIVU base/end guards likewise prevent the arithmetic leaf from bypassing
the absent three-register capture, atomic quotient/remainder pair commit,
overflow write suppression, interrupt checkpoint, and machine-state owner.
MODS/MODU base/end guards prevent remainder mode from bypassing same-file
operand capture, single-register/status commit, divisor-zero handling,
interrupt checkpoint, and machine-state ownership.
MPYS/MPYU base/end guards likewise prevent the product leaf from bypassing
FS1 validation, same-file operand capture, even-Rd atomic pair or odd-Rd
single commit, full-product status, interrupt checkpoint, and timing ownership.
SWAPF base/end guards prevent its word-transform leaf from bypassing the absent
locked read/write owner, implicit completion wait, host exclusion, complete
restart point, 16-bit restriction, field-address capture, and atomic Rd/ST
commit.
MOVE.RM/RM.POST/RM.PRE/MR/MR.POST/MR.PRE/MM/MM.POST/MM.PRE base/end guards prevent the semantic leaves from bypassing
the absent operand capture, BEN mapper, byte-strobe/RMW or read requester,
dynamic-width/page/fault controller, and atomic memory/register/status owner.
MMTM/MMFM base/end guards likewise prevent decoded two-word lists from
bypassing the absent multiport capture, ordered memory sequencer, page-mode/
dynamic-width controller, partial-list fault continuation, hidden-write
retirement, pointer/status commit, and RSC-0033 timing boundary.
The exact RETI/RETM guards likewise prevent the normal/context classification leaf
from bypassing the absent ordered stack reader, 24/31-word hidden-state
restore, fault/retry checkpoint, interrupt recognition, and atomic ST/PC/SP
owner.

The generated include `rtl/generated/tms34020_isa_decode.svh` is derived from
`docs/generated/tms34020_isa.yaml` by
`tools/generators/generate_isa_rtl.py`. A freshness check prevents the checked-in
decoder from drifting away from the database. Because the database is
incomplete, an unmatched word means *unclassified*, not architecturally
reserved or illegal.

The register file is synchronously cleared in this FPGA implementation so
simulation and formal startup are deterministic. This is not a silicon-reset
claim. The TI reset description leaves the general registers uninitialized;
the future core must not make execution depend on their reset values. Source:
TI *TMS34020 User's Guide*, August 1990, §6.12.2, printed p.6-23.

## Verification evidence

`make rtl-leaf-tests` builds a self-checking SystemVerilog testbench with
Verilator. It checks:

- every currently extracted decoder entry, including masked register/mode
  encodings and instruction-word count;
- exhaustive MOVE.RM and MOVE.MR two-long-word geometry for all 32 encoded
  sizes and 32 starting offsets; MOVE.MR additionally covers zero/sign
  extension, N/Z/V, 3/3/4/4/4 plus FE timing, and direct-router noncommit;
- exhaustive field-address calculation for all 32 sizes in ordinary,
  postincrement and predecrement modes, including effective-address ordering,
  pointer wrap and invalid dual-mode classification; MOVE.RM.POST also has
  exact decode boundaries and direct-router noncommit; MOVE.MR.POST adds exact
  decode boundaries and noncommit while reusing the independently exhaustive
  field-load and address-update leaf evidence; MOVE.MM.POST adds exact decode/
  noncommit plus exhaustive distinct/alias paired-address arithmetic;
  MOVE.RM.PRE/MR.PRE/MM.PRE add exact decode/noncommit, reuse the exhaustive
  single-pointer address leaf for the one-sided forms, and exhaust distinct/
  alias/wrap paired-predecrement arithmetic for the two-sided form;
  MOVE.RM.OFFSET/MR.OFFSET/MM.OFFSET add exact two-/three-word decode and
  noncommit boundaries plus exhaustive signed-16 effective-address arithmetic;
- exhaustive MOVE.MM source/destination geometry for all 32 sizes and 1,024
  offset pairs, including all 25 alignment-case pairs, value preservation,
  visible/hidden timing, crossing-word writes, and direct-router noncommit;
- exact MMFM/MMTM base/end decode boundaries, exhaustive 65,536-mask direct
  and reverse normalization in RTL, representative one/general list counts,
  pointer validity/final value, MMTM N, all alignment/hidden-state classes,
  instruction-alignment penalty, and direct-router noncommit;
- exact RETI/RETM decode/nonalias, normal/IX/BF classification with BF
  priority, 0/24/31 extra words, RETI 7/38/52 and RETM 10/38/52 state values,
  SP wrap, saved-PC alignment/misalignment, IX/BF post-context clearing,
  RETM bypass/delay intents, and direct-router noncommit while stack/cache/
  continuation ownership is absent;
- exact CMPXY `E400h`/`FE00h` base/end decode boundaries, all nine published
  flag rows, a result-sign-versus-borrow discriminator, A/B and same-register
  routing, shared-SP source/destination selection, full NCZV replacement, and
  register-write suppression through direct, commit, and scalar paths;
- exact CPW `E600h`/`FE00h` base/end decode boundaries, primary inclusive
  corners, signed negative/positive discriminators, outcode/V agreement, and
  direct router noncommit while implied B5/B6 reads remain unowned;
- exact CVDXYL/CVMXYL/CVSXYL/CVXYL range boundaries, equation-based
  power-of-two, two-power, and arbitrary signed-pitch arithmetic, PSIZE and
  mask-X selection, offsets, signed wrap, pitch-class state selection, and
  direct-router noncommit while implied register/I/O ownership remains absent;
- all 32 CLR same-register alias encodings, equal A/B source/destination
  selectors, shared-SP selection, zero result, Z set, and N/C/V preservation
  through the canonical XOR datapath;
- exact JACC `C?80h` condition boundaries, three-word packet assembly,
  adjacent short-JR nonaliasing, every one of the 256 condition-code/NCZV
  execute cells, aligned low-word/high-word targets, direct and commit
  taken/false paths, and cache-fed redirect/fallthrough;
- PUTST A/B/shared-SP decode, source-routing, full-status data/mask, and
  no-register-writeback boundaries;
- complete SETF/EXGF/SEXT/ZEXT field-bank, register-file, field-size, exchange,
  and extension decode boundaries; all 32 encoded field sizes in the extension
  leaf; the
  published result rows; exact selected-bank, N/Z, and Z-only ST masks; A/B
  routing; shared-SP commit; and dependent scalar execution;
- ADDXY and SUBXY base/end decode boundaries, all 16 published ADDXY result and
  flag rows, all nine published SUBXY result and comparison-flag rows,
  same-register read-before-write, A/B file selectors, shared-SP source and
  destination selection, and atomic register/ST commit;
- BTST.K/R base/end decode boundaries, all 25 published input rows with
  RSC-0018's contradictory printed status digit corrected from the page's own
  operands and definition, complemented constant recovery, low-five-bit
  register counts with upper-bit truncation, A/B and same-register selection,
  shared-SP count and destination access, no register write, and Z-only atomic
  status commit;
- both LMO decode boundaries, all five primary result rows, Z-only status
  writes, A/B and shared-SP selectors, and same-register read-before-write;
- every published SLA/SLL/SRA/SRL result row, all 32 SLA counts against an
  iterative overflow oracle, direct and two's-complement count recovery,
  arithmetic versus zero fill, partial status masks, same-register count
  hazards, B-file selectors, and incomplete-packet rejection;
- direct GETPC and EXGPC execution, including packet-length rejection,
  sequential-PC write data, old-destination capture, target alignment, A/B
  selection, shared SP, and status preservation; JUMP A/B/shared-SP source
  selection, target alignment, and absence of register/status writes; all
  256 long-JR condition-code/NCZV combinations, true/false outcomes, exact
  signed displacement targets, PC wrap, and absence of register/status writes;
- the complete MOVK family, including all 32 constants, A/B selection,
  encoded-zero shared SP, and complete status preservation;
- both MOVI forms, including incomplete-packet rejection, short sign
  extension, long-word assembly, TI example values, A/B/shared-SP selection,
  result-derived N/Z, preserved C, and cleared V;
- MOVX/MOVY decode boundaries, same-file operand selection, shared-SP source,
  low/high half replacement, and complete ST preservation;
- full-register MOVE decode boundaries, same-file and both cross-file
  directions, independent source/destination selectors, shared SP, full-width
  copying, result-derived N/Z/V, and C preservation;
- RL.K/RL.R decode boundaries, counts 0–31, source-low-five register counts,
  same-file selection, shared SP, result-derived C/Z, and preserved N/V;
- SETCDP/SETCMP/SETCSP conversion values for every one-bit and two-bit pitch,
  all four primary example rows, arbitrary/zero classification, and 4/6/3
  visible-state outputs; the opcodes remain rejected by register execution;
- explicit three-word decode, incomplete-packet rejection, and complete-packet
  execution for the ANDNI/ORI/XORI immediate-logical family;
- complete ADDXYI packet execution through the register router, including
  independent X/Y halves, full NCZV replacement, A/B selection, and incomplete
  packet rejection;
- complete ADDI.W and ADDI.L packet execution through the register router,
  including word sign extension, full NCZV replacement, A/B selection, and
  incomplete-packet rejection;
- complete SUBI.W and SUBI.L packet execution through the register router,
  including one's-complement object-word recovery, word sign extension, full
  NCZV replacement, A/B selection, and incomplete-packet rejection;
- complete nondestructive CMPI.W and CMPI.L packet execution through the
  register router, including one's-complement object-word recovery, word sign
  extension, full NCZV replacement, A/B selection, and incomplete-packet
  rejection;
- a near-neighbor that must remain unclassified;
- two ADDXYI arithmetic/flag cases;
- CMPK constant-32, borrow, and overflow cases;
- LMO zero, bit-0, bit-4, bit-27, and bit-31 cases;
- RMO zero, low-bit, and high-bit cases;
- every TI example row for ABS, NEG, NEGB, and NOT, including borrow and
  partial status-write masks;
- ADD/ADDC carry and overflow, SUB/SUBB borrow and overflow, and CMP write
  inhibition;
- GETPS and EXGPS data-path behavior;
- all six legal RPIX sizes and their documented state counts;
- rejection of an unsupported pixel size;
- independent A/B storage and the shared A15/B15 stack-pointer alias.
- ST reset/priority, documented bit layout and reserved mask, full flag
  replacement, partial flag preservation, isolated IE set, and isolated C
  clear.
- decoder-controlled NOP, unary, binary-arithmetic, logical, CMPK, CMPXY, LMO,
  RMO,
  CLRC/SETC, DINT/EINT, GETST, ADDK/INC, SUBK/DEC, and MOVK write intents,
  including A/B
  register-file selection, source/destination indices, CMP write inhibition,
  all 32 SUBK and MOVK constants, encoded-zero ADDK/SUBK/MOVK, carry/borrow
  edges, partial
  status masks, Z-only logical updates, and rejection of
  decoded-but-unsupported and unclassified words.
- ordered commit checks covering EINT, SETC, GETST, nondestructive CMPXY,
  ADDK/INC, DINT,
  SUBK/DEC,
  ABS, shared-SP write/read, ADD, nondestructive CMP, RMO, LMO shared-SP
  source commit, unsupported BLMOVE rejection, state-neutral NOP,
  AND, OR, XOR,
  ANDN, incomplete-ANDNI rejection,
  complete ORI/XORI/ANDNI packets, two dependent ADDXYI packets, ADDXYI
  through the shared SP alias, dependent ADDI.W/ADDI.L packets, and ADDI.L
  through the shared SP alias, dependent SUBI.W/SUBI.L packets, and SUBI.L
  through the shared SP alias, followed by nondestructive CMPI.W/CMPI.L
  comparisons and CMPI.W through the shared SP alias, MOVI.W/L commits,
  dependent MOVX/MOVY half-register commits, and dependent A-to-B then B-to-A
  full-register MOVE commits, followed by RL.K/RL.R commits that verify
  count-zero carry clearing and dependent register-count selection, GETPC to a
  B register, EXGPC through both an A register and shared SP, and JUMP through
  an ordinary A register and shared SP without state writes. These
  checks also include dependent ADDXY/SUBXY register commits, shared-SP
  source/destination commits, BTST.K/R commits that read shared SP and change
  only Z, SETF/SEXT/ZEXT commits through both field banks and shared SP, and
  atomic EXGF register/bank exchange through both banks, A/B, and shared SP,
  followed by PUTST full-width replacement from dependent A and shared-SP
  sources.
  They prove that scalar and XY compares suppress register writes and that a
  later operation observes the
  preceding committed register/ST state; they do not assign an architectural
  cycle count to the commit edge. Encoded-zero ADDK, SUBK, and MOVK checks prove
  that K=0 adds, subtracts, or writes 32, including through the shared SP alias.

The testbench must emit `PASS: tms34020 verified leaf RTL`; simulator exit
status alone is not accepted.

`make cache-tests` separately builds the cache leaf with Verilator and requires
`PASS: tms34020 cache native completion RTL`. It checks reset metadata,
segment/subsegment miss refill, all four demand-word refill rotations,
low/high half hits, no early present-bit commit, four-segment LRU
allocation/touch/replacement, `CD` preservation, an idle `CF` flush/bypass,
and stable request/response payloads under backpressure. It also checks retry
and fault resume at all four refill sequence indices, bypass retry/fault,
fault abort after a prior successful beat, full refill restart, bypass abort,
reset in the request and response-wait states of every refill index, and no
early present commit. Four enabled SystemVerilog assertions check stalled
payloads, retry/fault present safety, and fault-state quiescence in simulation;
they are not formal proofs. Other abort/control combinations, the CPU fault
controller/interrupt, `SIZE16`, page mode, reset in other cache states, flush
during refill, and cycle timing remain unverified.

The cache command also runs three deterministic randomized seeds. The initial
run covered 396 fetches and 1,226 accepted native reads with randomized
backpressure/latency, 36 retries, 83 faults, and 43 aborts. It checks every
returned word against an independent address-derived memory function and
records a failing seed under ignored `build/` for replay. This is protocol
stress, not differential silicon evidence or architectural cycle validation.

`make fetch-tests` separately verifies the serialized instruction-packet
assembler. It checks aligned PC load and redirect, one-word and three-word
packets, extension order, per-word cache classifications, request and packet
backpressure, explicit completion gating, unclassified-word isolation,
cache-abort discard/reload, and 32-bit PC wrap. Four runtime assertions cover
request stability, packet stability, alignment, and post-abort packet safety.
This handshake regression does not establish machine-state timing or pipeline
overlap.

`make frontend-tests` composes the real cache and fetch blocks. It verifies
cold demand-word-last refill, a NOP packet, cache-hit ORI opcode/extensions,
disabled-cache retry, bypass fault abort, PC reload, and preservation of the
enabled cache across the bypass sequence.

`make scalar-slice-tests` composes cache, packet fetch, register execution, and
atomic state commit. It checks twelve bypass-fetched dependent
field/XY/bit-test/PUTST commits, stable noncommit for one-word BLMOVE and the
POPST/PUSHST forms, plus unclassified packets, complete JACC taken/false paths,
complete
ORI/XORI/ANDNI packet commits,
two dependent ADDXYI packet commits, dependent ADDXY/SUBXY one-word commits,
dependent ADDI.W/ADDI.L/ADDI.W and
SUBI.W/SUBI.L packet commits, nondestructive CMPI.W/CMPI.L packet commits,
encoded-zero ADDK and SUBK shared-SP commits, an encoded-zero MOVK commit with
ST preservation, complete MOVI.W/MOVI.L packet commits, dependent MOVX/MOVY
packet commits, dependent A-to-B and B-to-A MOVE packet commits,
dependent RL.K then source-counted RL.R commits, LMO against the preceding
shift result, BTST.K/R against dependent ADDXY/SUBXY results with no register
write, a dependent SETF-to-ZEXT-to-SEXT-to-EXGF-to-PUTST sequence covering both field
banks, GETPC sequential-PC capture,
all eight SLA/SLL/SRA/SRL forms in a dependent sequence with preserved versus
replaced status fields,
EXGPC atomic register exchange and aligned nonsequential completion redirect,
a GETPC at that redirect target, JUMP through the sequential address that
EXGPC stored in A0, an unconditional JACC aligned absolute target and false
JA.C sequential fallthrough, an unconditional JR.L taken target and a false
JR.C sequential fallthrough, unclassified-word noncommit at each target, a
backward maximum-magnitude DSJS shared-SP decrement and wrapping redirect, and
a cache-enabled pass that feeds eight dependent commits, including
same-register CMPXY after GETST, from exactly four refill long-word reads.
Twenty-five runtime assertions
across the scalar and commit
owners constrain acceptance, blocked writes, single-pulse commit, mutually
exclusive execution ownership, atomic LMO/shift/XY/field-extension/EXGF writes,
status-only CMPXY ownership, Z-only BTST writes, selected-bank-only SETF
writes, aligned
committed/pending redirects, JUMP redirect-only ownership, JACC predicate and
aligned absolute-target ownership, JR.L predicate and signed-target ownership,
and PUTST full-width status-only writes, plus DSJS decrement/redirect conditioning and exact
unsigned-magnitude targeting. These
FPGA handshakes are not architectural cycle evidence.

`make quartus-leaf-smoke` runs warning-free Quartus Analysis & Synthesis for
the leaf qualification wrapper on Cyclone V device `5CSEBA6U23I7`. The wrapper
keeps both register-file read ports, arithmetic flags, decoder outputs, PSIZE
data paths, unary, binary, and logical arithmetic, LMO, RMO, and RPIX timing outputs
observable. It also keeps every output of the register-execution router
observable and instantiates CMPXY both directly and through the commit
composition. The wrapper deliberately
retains both the original raw state leaves and the integrated commit instance,
so its 12,826 logic-cell/2,230-register/9-DSP resource count is not a core-area
estimate. This is an early portability check only:
Analysis & Synthesis is not placement, routing, TimeQuest closure, or
full-core qualification.

`make quartus-cache-smoke` independently runs warning-free Analysis &
Synthesis for the cache leaf. Quartus infers the 128×32 data array as 4,096
block-memory bits; the diagnostic top uses 375 logic cells and 200 registers.
This is not fit, routing, TimeQuest, a complete cache, or a core-area/timing
result.

`make quartus-fetch-smoke` runs warning-free Analysis & Synthesis for the
packet assembler and generated decoder. Its observability wrapper uses 453
logic cells and 175 registers. This is not fit, routing, TimeQuest, a complete
frontend, or a core-area/timing result.

`make quartus-frontend-smoke` synthesizes the cache/fetch composition with
zero errors/warnings to 806 logic cells, 373 registers, and 4,096 block-memory
bits. This is Analysis & Synthesis only, not fit, TimeQuest, or a full-core
resource/timing result.

`make quartus-scalar-smoke` synthesizes the bounded cache/fetch/register
composition with zero errors/warnings to 5,365 logic cells, 1,414 registers,
and 4,096 block-memory bits. The observability wrapper is not a core-area
estimate, and no fit or TimeQuest result exists.

## Explicitly absent

There is a bounded serialized opcode-to-register execution path for only 69
register/status/control-flow operations. There is no timing sequencer,
processor-derived retirement boundary, interrupt logic, complete memory
access, page mode,
complete bus-fault/retry subsystem, host interface, multiprocessor interface,
coprocessor interface, display subsystem, original-pin bus, or game wrapper.
The cache has transaction completion outcomes but no pin-level decoder, fault
registers, interrupt entry/return sequencer, or dynamic-width/page-mode memory
controller. The RETI/RETM leaf is classification/result metadata only. The scalar
slice advances only after its conservative internal
handshake and supplies no architectural timing, so it is not a complete
executable processor core. In particular, EXGPS does not implement its
documented hidden internal-I/O write cycle and is not routed through this
composition. BTST.K and BTST.R are functional Z-only scalar operations, but
their one documented TMS34020 machine state has not been mapped onto this FPGA
handshake and therefore supplies no cycle-accuracy evidence. PUTST,
SETF/EXGF/SEXT/ZEXT have verified functional commit paths, but their
instruction-specific machine-state timing is not implemented.
