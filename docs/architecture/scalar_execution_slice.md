# Bounded scalar execution slice

`rtl/core/tms34020_scalar_slice.sv` composes the serialized cache/fetch
frontend with `tms34020_register_commit`. It is a deliberately bounded
execution path for 29 register/status operations already verified against their
individual TI instruction pages:

- NOP, CLRC, DINT, EINT, SETC, and GETST;
- ABS, NEG, NEGB, and NOT;
- ADD, ADDC, SUB, SUBB, CMP, INC, and DEC; and
- AND, ANDN, OR, XOR, CMPK, and RMO; plus
- the three-word ANDNI, ORI, and XORI immediate-logical family; and
- the three-word ADDXYI immediate XY operation; plus
- the two-word ADDI.W and three-word ADDI.L forms.

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
enable. A supported packet therefore commits at most once. The frontend then
receives a sequential completion handshake. Three runtime assertions check
that only the supported one-, two-, or three-word packet classes commit, blocked
packets cannot assert state writes, and a commit cannot remain asserted on the
next FPGA clock.

Decoded instructions outside the verified scalar set and unclassified packets
remain presented with `packet_blocked_o=1`. They are neither consumed nor
treated as illegal instructions, because the architectural exception and other
execution behavior are not yet implemented.

For ANDNI/ORI/XORI, ADDXYI, and ADDI.L, the packet owner supplies extension
word 1 as the low half and word 2 as the high half of the immediate. ADDI.W
sign-extends extension word 1. No state write can occur until the frontend has
collected the complete two- or three-word packet.
ADDXYI adds its X and Y halves independently and replaces NCZV with the
instruction-specific zero/sign meanings. ADDI.W and ADDI.L perform 32-bit
addition and replace all four NCZV bits. This verifies atomic packet
consumption, not the documented alignment-dependent two- versus
three-machine-state cases.

## Directed verification

`make scalar-slice-tests` uses disabled-cache word fetches to isolate
fetch-to-commit ordering. It executes this dependency chain:

```text
EINT -> SETC -> GETST B2 -> INC B2 -> DINT
     -> DEC A0 -> INC SP -> ADD SP,A0 -> NOP
```

The test observes every accepted PC/opcode, register and status write intent,
post-edge ST/SP state, and dependent result. It then verifies that decoded
one-word BLMOVE remains stable for three clocks with no commit, register write,
status write, or state change. A separate sequence commits ORI, a dependent
XORI, and ANDNI from complete fetched packets; executes two dependent ADDXYI
packets with independent half arithmetic and full NCZV replacement; executes
dependent ADDI.W, ADDI.L, and sign-extending ADDI.W packets with full NCZV
replacement; then proves complete decoded SUBI.W and unclassified packets
remain blocked and state-stable.

A second pass enables the cache, checks the demand-word-last refill sequence,
and executes the first eight dependent instructions with exactly four native
long-word reads. This couples cache present/tag state, hit delivery, sequential
PC progression, and register/ST dependencies without assigning those FPGA
handshakes a TMS34020 cycle count.

`make quartus-scalar-smoke` performs warning-free Cyclone V Analysis &
Synthesis for this composition. The diagnostic wrapper uses 3,679 logic cells,
1,357 registers, 82 pins, and 4,096 block-memory bits, with no DSP blocks or
PLLs. Quartus retains the cache data array as a 128×32 dual-port `altsyncram`.
These are wrapper-heavy Analysis & Synthesis figures, not placement,
TimeQuest, full-core utilization, or a timing-closure result.

## Explicit non-claims

The automatic handshake sequence is an FPGA implementation protocol, not a
documented TMS34020 machine-state schedule. The slice has no authentic
fetch/execute overlap, interrupt recognition, branch or trap execution,
reset-vector controller, data-memory operations, graphics operations, complete
fault continuation, or original-pin timing. It is not an instruction-complete
or cycle-accurate processor core.
