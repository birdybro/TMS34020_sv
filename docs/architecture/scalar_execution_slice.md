# Bounded scalar execution slice

`rtl/core/tms34020_scalar_slice.sv` composes the serialized cache/fetch
frontend with `tms34020_register_commit`. It is a deliberately bounded
execution path for 67 register/status/control-flow operations already verified
against their individual TI instruction pages:

- NOP, CLRC, DINT, EINT, SETC, GETST, and PUTST;
- ABS, NEG, NEGB, and NOT;
- ADD, ADDC, ADDXY, SUB, SUBB, SUBXY, CMP, ADDK/INC, SUBK/DEC, and MOVK; and
- AND, ANDN, OR, XOR, BTST.K, BTST.R, SETF, EXGF, SEXT, ZEXT, CMPK, LMO, RMO,
  MOVE, MOVX, MOVY,
  RL.K, and RL.R; plus
- SLA.K/R, SLL.K/R, SRA.K/R, and SRL.K/R; plus
- GETPC, EXGPC, JUMP, JR.L, DSJ, DSJEQ, DSJNE, and DSJS; plus
- the three-word ANDNI, ORI, and XORI immediate-logical family; and
- the three-word ADDXYI immediate XY operation; plus
- the two-word ADDI.W/CMPI.W/SUBI.W and three-word
  ADDI.L/CMPI.L/SUBI.L forms; and
- the two-word MOVI.W and three-word MOVI.L forms.

The canonical encodings, operands, status effects, and printed-page citations
remain in `docs/generated/tms34020_isa.yaml`. The register-file and status
ownership rules derive from TI *TMS34020 User's Guide*, August 1990, §4.1,
printed pp.4-2..4-3. Each instruction's individual primary citation is also
listed in `docs/architecture/verified_rtl_slice.md`.

## Acceptance boundary

A packet is accepted only when all of these conditions are true:

1. the frontend has produced a complete packet;
2. the generated decoder classifies the first word;
3. the supplied packet length matches the generated decode length; and
4. the register-execution owner reports that complete packet as supported.

The same acceptance event supplies the existing atomic register/ST commit
enable. A supported packet therefore commits at most once. For an ordinary
instruction or GETPC, the frontend then receives a sequential completion
handshake. EXGPC, JUMP, and taken JR.L/DSJ-family instructions instead hold their
redirect target across the commit-to-completion boundary and present it with
the completion handshake. Twenty scalar runtime assertions check that only
supported packets commit, blocked packets cannot assert state writes, a commit
cannot remain
asserted on the next FPGA clock, and committed and pending redirect targets
stay identified and aligned; JUMP must redirect without a register or status
write; JR.L must never write a register or status, must redirect exactly when
its selected condition is true, and must use the sign-extended 16-bit word
displacement; DSJ-family commits must match their Z condition, never write status, and
redirect exactly by their signed 16-bit word displacement only when the
decrement result is nonzero; DSJS commits must always decrement, never write
status, and redirect by their encoded unsigned word magnitude and direction
only when the result is nonzero; shift commits must assert atomic register
and status writes without redirect; LMO commits must likewise atomically write
their destination and the exact Z-only mask; ADDXY/SUBXY commits must atomically
write their destination and all four NCZV bits; BTST.K/R commits must suppress
the register write and update only Z; SETF must suppress the register write and
write only its selected six-bit status bank; SEXT/ZEXT must atomically write
their destination and exact partial status mask; EXGF must atomically write its
destination and only its selected six-bit status bank; PUTST must write all ST
bits without register writeback or redirect. Two additional
assertions in
the commit owner check execution-owner exclusion and committed redirect
alignment.

PUTST commits only a full-width status write: the selected A/B source port
supplies all 32 data bits, register writeback is suppressed, and the mask is
`FFFFFFFFh`. A dedicated scalar assertion also forbids a redirect on that
commit. The serialized acceptance edge is not the instruction's documented
three-machine-state retirement. Source: TI *TMS34020 User's Guide*, August
1990, printed pp.4-2..4-3, 13-216, and 15-7.

JR.L reads the encoded condition from the packet first word and N/C/Z/V from
ST. A true predicate redirects from the sequential two-word PC by the signed
extension word multiplied by 16; a false predicate falls through. It never
writes a register or ST. Direct verification exhausts the 16 condition codes
against all 16 NCZV combinations and checks signed displacement/PC-wrap
boundaries; cache-fed tests cover both taken and false completion paths. Two
scalar assertions independently constrain redirect ownership and the exact
target. This functional ordering does not implement the documented
two-/three-state retirement. Source: TI *TMS34020 User's Guide*, August 1990,
printed pp.13-27, 13-138..13-140, and 15-5.

DSJS always decrements its A/B/shared-SP destination modulo `2^32` and never
writes ST. A nonzero result redirects from the sequential one-word PC by the
encoded five-bit magnitude times 16, adding when D is zero and subtracting
when D is one; zero falls through. Two dedicated scalar assertions require the
unconditional write/conditioned-redirect relationship and exact encoded
target. This functional
ordering does not implement the documented two-/three-state retirement.
Source: TI *TMS34020 User's Guide*, August 1990, printed pp.13-12, 13-108,
and 15-4.

Decoded instructions outside the verified scalar set and unclassified packets
remain presented with `packet_blocked_o=1`. They are neither consumed nor
treated as illegal instructions, because the architectural exception and other
execution behavior are not yet implemented.

DSJ always decrements its selected destination. DSJEQ does so only for Z=1,
and DSJNE only for Z=0. An enabled modulo-`2^32` decrement writes the A/B/shared
SP destination; a nonzero result redirects from the packet's sequential PC by
the sign-extended second word multiplied by 16. Suppressed conditions and
decrement-to-zero results continue sequentially, and ST is never written.
Directed leaf tests cover both conditions, wrap, forward/backward displacement,
and PC wrap; the cache-fed scalar test checks an A-file decrement and taken
redirect. This remains functional ordering, not two-/three-state retirement.

For ANDNI/ORI/XORI, ADDXYI, ADDI.L, CMPI.L, and SUBI.L, the packet owner supplies
extension word 1 as the low half and word 2 as the high half of the immediate.
ADDI.W sign-extends extension word 1. CMPI.W/L and SUBI.W/L first complement
their documented one's-complement object word or words; recovered word
operands are then sign-extended. No state write can occur until the frontend
has collected the complete two- or three-word packet.
MOVI.W sign-extends extension word 1, while MOVI.L consumes extension word 1
as the low half and extension word 2 as the high half. Both replace N/Z/V,
preserve C, and write the selected A/B destination, including shared SP.
MOVX replaces the destination low half with the source low half; MOVY replaces
the destination high half with the source high half. Both use one register
file selected by bit 4, honor shared SP as either operand, and leave ST
unchanged.
MOVE copies all 32 source bits. Encoding bit 4 selects the source file, while
the destination file is bit 4 XOR the cross-file bit 9. This preserves the
same-file forms and admits both cross-file directions without breaking the
shared A15/B15 SP alias. MOVE replaces N/Z/V from the copied value and
preserves C.
RL.K rotates its destination by the embedded five-bit count. RL.R uses the
low five bits of a same-file source register as its count. Both write C from
the last bit rotated out (and clear C for count zero), derive Z from the
result, and preserve N/V.
BTST.K recovers the selected bit number by complementing its five-bit object
field. BTST.R uses only the low five bits of its same-file source register and
ignores the upper 27 bits. Both read the destination without modifying it,
replace only Z according to the selected bit, and honor the A15/B15 shared-SP
alias. Sources: TI *TMS34020 User's Guide*, August 1990, printed pp.13-46..13-47.
SETF writes the selected FS/FE bank without changing the other bank or NCZV.
SEXT and ZEXT read the selected FS bank, interpret encoded zero as 32 bits,
extend the right-justified destination field, and update N/Z or Z respectively.
Both register files and shared SP follow the ordinary destination rules.
Sources: the same guide, printed pp.13-230..13-232 and 13-268.
EXGF reads the selected six-bit FS/FE bank and the old destination before either
write, zero-extends the old bank into the destination, and writes the old
destination low six bits into only that bank. Both A/B files and the shared SP
alias follow ordinary destination selection. This functional exchange does not
implement the documented one-state `F=0` versus two-state `F=1` retirement
split. Source: the same guide, EXGF printed p.13-111 and chapter 15 printed
p.15-4.
SLA/SLL use direct left-shift counts from either the object word or a same-file
source register. SRA/SRL take the five-bit two's complement of that encoded
field or source value to recover the right-shift count. SLA replaces NCZV and
detects any new-sign or shifted-bit disagreement with the original sign; SLL
and SRL replace only C/Z; SRA replaces N/C/Z and preserves V. The scalar
handshake does not yet implement SLA's documented three machine states.
LMO reads its same-file source before destination writeback, stores the count
of leading zero bits, and replaces only Z; the A15/B15 shared-SP alias follows
the same source and destination rules.
GETPC writes the packet's sequential next address to its selected A/B
destination without changing ST. EXGPC captures the old destination as an
aligned redirect before atomically replacing that register with the sequential
next address; shared A15/B15 SP follows the same rule. JUMP reads the selected
A/B register or shared SP, clears target bits `[3:0]`, and redirects without
changing its source or ST. These handshakes do not reproduce the documented
machine-state timing.
ADDXYI adds its X and Y halves independently and replaces NCZV with the
instruction-specific zero/sign meanings. ADDI.W/L, CMPI.W/L, and SUBI.W/L
perform 32-bit addition or subtraction and replace all four NCZV bits. CMPI
suppresses the register write while preserving the same compare result flags.
This verifies atomic packet consumption, not the documented
alignment-dependent machine-state cases.
ADDXY and SUBXY also operate on independent 16-bit X/Y halves. ADDXY flags
come from the two result halves, while SUBXY flags encode source/destination
half equality and unsigned greater-than comparisons. Both use a same-file
source/destination pair, replace NCZV, and honor A15/B15 as shared SP. Sources:
TI *TMS34020 User's Guide*, August 1990, printed pp.13-38 and 13-246.

## Directed verification

`make scalar-slice-tests` uses disabled-cache word fetches to isolate
fetch-to-commit ordering. It executes this dependency chain:

```text
EINT -> SETC -> GETST B2 -> LMO B2,B2 -> DINT
     -> SUBK/DEC A0 -> ADDK/INC SP -> ADD SP,A0 -> NOP
```

The test observes every accepted PC/opcode, register and status write intent,
post-edge ST/SP state, and dependent result. It then verifies that decoded
one-word BLMOVE remains stable for three clocks with no commit, register write,
status write, or state change. A separate sequence commits ORI, a dependent
XORI, and ANDNI from complete fetched packets; executes two dependent ADDXYI
packets with independent half arithmetic and full NCZV replacement; executes
dependent ADDI.W, ADDI.L, and sign-extending ADDI.W packets with full NCZV
replacement; executes complemented SUBI.W and dependent SUBI.L packets; then
executes nondestructive CMPI.W followed by CMPI.L against the preserved
destination; executes ADDK with encoded K=0 and then SUBK with encoded K=0
against shared SP; commits MOVK with encoded K=0 while preserving live ST; then,
after reset, commits a zero MOVI.W and a dependent MOVI.L to shared SP, followed
by MOVX and MOVY packets that read shared SP and observe the prior half-register
commit; then commits a cross-file A0-to-B1 MOVE followed by a dependent
B1-to-A2 MOVE; then commits RL.K against A2 followed by a dependent RL.R whose
count comes from the newly rotated A2 value. It next executes all eight
SLA/SLL/SRA/SRL forms as a dependency chain, checking direct and
two's-complement counts, arithmetic/logical fill, overflow, and partial status
preservation. It applies LMO to the final shifted A2 value, then executes GETPC,
EXGPC to the prior A0 value, GETPC at the redirected address, and JUMP through
the sequential address that EXGPC stored in A0. An unclassified packet at the
JUMP target then remains blocked without changing that sequence.
An isolated dependency sequence then seeds A0/A1 with MOVK, commits ADDXY,
feeds its new A0 value directly into SUBXY while checking both atomic register
and NCZV writes, and applies dependent BTST.K and BTST.R packets to the resulting
register state. The bit tests update only Z and do not modify their destination.
That sequence then sets field bank zero to size 16, zero-extends the dependent
A1 value, sign-extends the result, and performs dependent EXGF exchanges through
both banks, checking the register result and selected-bank status mask at every
commit. It finally commits PUTST from the dependent A0 value and checks exact
full-width ST replacement without register writeback.
The direct-PC checks prove ordering and target selection, not the documented
one- and two-machine-state timings. The
earlier INC and DEC spellings exercise the canonical
ADDK K=1 and SUBK K=1 object codes.

Additional direct-PC sequences fetch an unconditional forward JR.L and a
false JR.C, proving respectively that the held taken target and sequential
fallthrough are consumed without register or status writes. Separate JACC
sequences fetch all three words and prove an aligned `12345670h` absolute
redirect from low word `567Fh`/high word `1234h`, plus false JA.C fallthrough
after the complete packet; neither path writes registers or ST. Another sequence
fetches the backward, maximum-magnitude DSJS
shared-SP encoding at bit address `000000E0h`. It verifies the wrapping
decrement from zero to `FFFFFFFFh`, complete ST preservation, and the held
redirect from sequential PC `000000F0h` to `FFFFFF00h`.

A second pass enables the cache, checks the demand-word-last refill sequence,
and executes the first eight dependent instructions, including the cache-fed
GETST-to-LMO dependency, with exactly four native
long-word reads. This couples cache present/tag state, hit delivery, sequential
PC progression, and register/ST dependencies without assigning those FPGA
handshakes a TMS34020 cycle count.

`make quartus-scalar-smoke` performs warning-free Cyclone V Analysis &
Synthesis for this composition. The diagnostic wrapper uses 5,262 logic cells,
1,414 registers, 82 pins, and 4,096 block-memory bits, with no DSP blocks or
PLLs. Quartus retains the cache data array as a 128×32 dual-port `altsyncram`.
These are wrapper-heavy Analysis & Synthesis figures, not placement,
TimeQuest, full-core utilization, or a timing-closure result.

## Explicit non-claims

The automatic handshake sequence is an FPGA implementation protocol, not a
documented TMS34020 machine-state schedule. The slice has no authentic
fetch/execute overlap, interrupt recognition, control-flow execution beyond
the bounded direct-PC operations listed above,
reset-vector controller, data-memory operations, graphics operations, complete
fault continuation, or original-pin timing. It is not an instruction-complete
or cycle-accurate processor core.
