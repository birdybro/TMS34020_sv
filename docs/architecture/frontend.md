# Bounded cache/fetch frontend

`rtl/core/tms34020_frontend.sv` directly composes
`tms34020_instruction_fetch` with `tms34020_icache`. It is the first RTL path
from an explicit instruction PC through cache lookup/native refill to a
complete decoded instruction packet.

## Implemented path

```text
explicit PC load
      |
      v
instruction packet fetch <----> instruction cache <----> native read interface
      |
      v
stable decoded packet
      |
      v
external completion or redirect
```

The frontend forwards `CD` and `CF`, native success/retry/fault completion,
fault resume/abort, packet metadata, and cache debug state. Cache abort is
connected directly to the packet assembler: an abandoned native instruction
request discards any partial packet and requires an explicit PC reload.

This module remains a serialized functional frontend. The separate
`tms34020_scalar_slice` composes it with a bounded register/ST executor, but the
frontend itself does not include execution, interrupt entry, reset-vector
fetch, page-mode or dynamic-width scheduling, pin timing, or machine-state
timing.

## Verification

`make frontend-tests` uses the real cache and packet RTL together. It verifies:

- a cold segment miss at PC zero and native refill order `20h`, `40h`, `60h`,
  `00h`;
- a complete NOP packet only after refill present-bit commit;
- sequential progression to a three-word ORI whose opcode and extensions all
  hit in the newly loaded subsegment;
- `CD=1` one-word bypass with current-request retry and successful reissue;
- a bypass bus fault followed by abort and propagation to the PC-reload
  boundary; and
- `CD=0` reload of PC zero hitting the preserved cache after bypass abort.

The testbench checks packet words, per-word cache classifications, native
width/class/sequence metadata, cache present/tag/LRU state, and explicit pass
marker `PASS: tms34020 cache/fetch frontend`.

`make quartus-frontend-smoke` performs warning-free Cyclone V Analysis &
Synthesis. The diagnostic wrapper uses 765 logic cells, 373 registers, and
4,096 block-memory bits; Quartus retains the portable cache data array as a
128×32 dual-port `altsyncram`. This is Analysis & Synthesis only, not fit,
TimeQuest, cycle accuracy, or a complete-core area result.

## Downstream composition

`scalar_execution_slice.md` documents the bounded consumer that accepts 42
page-verified one-word register/status operations plus two-word
ADDI.W/CMPI.W/MOVI.W/SUBI.W and three-word
ANDNI/ORI/XORI/ADDXYI/ADDI.L/CMPI.L/MOVI.L/SUBI.L operations. Other
multiword, control-flow, faulted, and interrupting operations remain
noncommitting until their individual ordering is implemented and tested.
