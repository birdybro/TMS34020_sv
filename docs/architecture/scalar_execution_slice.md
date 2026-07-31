# Bounded scalar execution slice

`rtl/core/tms34020_scalar_slice.sv` composes the serialized cache/fetch
frontend with `tms34020_register_commit`. It is a deliberately bounded
execution path for 52 register/status operations already verified against their
individual TI instruction pages:

- NOP, CLRC, DINT, EINT, SETC, and GETST;
- ABS, NEG, NEGB, and NOT;
- ADD, ADDC, SUB, SUBB, CMP, ADDK/INC, SUBK/DEC, and MOVK; and
- AND, ANDN, OR, XOR, CMPK, LMO, RMO, MOVE, MOVX, MOVY, RL.K, and RL.R; plus
- SLA.K/R, SLL.K/R, SRA.K/R, and SRL.K/R; plus
- GETPC and EXGPC; plus
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
handshake. EXGPC instead holds its aligned old-register target across the
commit-to-completion boundary and presents that redirect with the completion
handshake. Seven scalar runtime assertions check that only supported packets
commit, blocked packets cannot assert state writes, a commit cannot remain
asserted on the next FPGA clock, and EXGPC committed and pending redirect
targets stay identified and aligned; shift commits must assert atomic register
and status writes without redirect; LMO commits must likewise atomically write
their destination and the exact Z-only mask. Two additional assertions in the
commit owner check execution-owner exclusion and committed redirect alignment.

Decoded instructions outside the verified scalar set and unclassified packets
remain presented with `packet_blocked_o=1`. They are neither consumed nor
treated as illegal instructions, because the architectural exception and other
execution behavior are not yet implemented.

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
next address; shared A15/B15 SP follows the same rule.
ADDXYI adds its X and Y halves independently and replaces NCZV with the
instruction-specific zero/sign meanings. ADDI.W/L, CMPI.W/L, and SUBI.W/L
perform 32-bit addition or subtraction and replace all four NCZV bits. CMPI
suppresses the register write while preserving the same compare result flags.
This verifies atomic packet consumption, not the documented
alignment-dependent machine-state cases.

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
EXGPC to the prior A0 value, and GETPC at the redirected address before a
separate unclassified packet remains blocked without changing that sequence.
The direct-PC checks prove ordering and target selection, not the documented
one- and two-machine-state timings. The
earlier INC and DEC spellings exercise the canonical
ADDK K=1 and SUBK K=1 object codes.

A second pass enables the cache, checks the demand-word-last refill sequence,
and executes the first eight dependent instructions, including the cache-fed
GETST-to-LMO dependency, with exactly four native
long-word reads. This couples cache present/tag state, hit delivery, sequential
PC progression, and register/ST dependencies without assigning those FPGA
handshakes a TMS34020 cycle count.

`make quartus-scalar-smoke` performs warning-free Cyclone V Analysis &
Synthesis for this composition. The diagnostic wrapper uses 4,559 logic cells,
1,387 registers, 82 pins, and 4,096 block-memory bits, with no DSP blocks or
PLLs. Quartus retains the cache data array as a 128×32 dual-port `altsyncram`.
These are wrapper-heavy Analysis & Synthesis figures, not placement,
TimeQuest, full-core utilization, or a timing-closure result.

## Explicit non-claims

The automatic handshake sequence is an FPGA implementation protocol, not a
documented TMS34020 machine-state schedule. The slice has no authentic
fetch/execute overlap, interrupt recognition, branch or trap execution beyond
the bounded EXGPC direct redirect,
reset-vector controller, data-memory operations, graphics operations, complete
fault continuation, or original-pin timing. It is not an instruction-complete
or cycle-accurate processor core.
