# Progress

- Current milestone: primary ISA extraction and independently verified
  model/RTL leaves
- Completed task IDs: `TMS20-0001`, `TMS20-0003`
- Latest verified baseline commit: `7b5aaa6ea37dcbfc525bf2afd08f3fa140d15d1f`
- Passing tests: foundation, reference/hash, delta, 21-case ISA sweep, 106 directed model
  cases, warning-free Verilator lint, directed RTL leaf/cache simulation, three
  deterministic randomized cache seeds, bounded instruction-packet and
  integrated cache/fetch frontend and bounded scalar-composition tests, and
  warning-free Quartus Cyclone V leaf/cache/fetch/frontend/scalar Analysis &
  Synthesis
- Failing tests: none observed
- Model status: 65 of 67 currently extracted encoding forms have bounded
  successful semantics, including complete
  ADDK/INC, SUBK/DEC, MOVK, MOVI, MOVE, MOVX/MOVY, RL constant/register, and
  SLA/SLL/SRA/SRL constant/register forms, LMO, SETCDP/SETCMP/SETCSP, bounded
  BLMOVE, and successful TRAPL/VLCOL forms;
  fetch opcodes/extensions through
  transaction-level cache/retry state with traces, rollback and snapshot
  replay, including GETPC/EXGPC sequential-PC, redirect, alignment, A/B, and
  shared-SP behavior, plus every published ADDXY/SUBXY row and B-file,
  same-register, and shared-SP hazards. The extracted ISA is far from complete;
  BLMOVE overlap,
  continuation/timing, non-cache fault/retry, and full ISA/interfaces remain.
  BTST.K/R decode but have exact snapshot-rollback guards until semantic
  implementation
  (`TMS20-0006`, `TMS20-0007`)
- RTL status: generated 67-entry partial decode, A/B/SP and masked ST state,
  unary/binary/logical arithmetic plus ADDXYI/CMPK/EXGPS/GETPS/LMO/RMO/RPIX and
  SETC-pitch conversion semantic leaves, and decoder-controlled register/ST
  write intents for 42 one-word instructions, with externally gated one-edge
  state commit and
  ordered-state tests, including same-file and cross-file MOVE with N/Z/V
  replacement and C preservation, MOVX/MOVY half-register merges with
  complete ST preservation, and RL.K/RL.R C/Z replacement with N/V
  preservation, plus all eight SLA/SLL/SRA/SRL forms with direct or
  two's-complement count recovery and instruction-specific status masks;
  standalone native-completion cache lookup/refill RTL;
  a dedicated GETPC/EXGPC direct-PC leaf, an integrated serialized
  cache/instruction-packet frontend with explicit completion and abort/reload;
  and a bounded fetch-to-commit path for those 40
  one-word operations plus complete two-word ADDI.W/CMPI.W/MOVI.W/SUBI.W and
  three-word ANDNI/ORI/XORI/ADDXYI/ADDI.L/CMPI.L/MOVI.L/SUBI.L packets.
  GETPC consumes the packet sequential PC, while EXGPC atomically writes that
  address and redirects to the aligned old destination. MOVI.W
  sign-extends its extension word; both MOVI forms
  replace N/Z/V while preserving C.
  LMO uses a dedicated leading-priority leaf, Z-only masked update, same-file
  selection, shared-SP aliasing, and cache-fed dependent commit coverage.
  ADDXY/SUBXY use a shared independent-half arithmetic leaf, replace NCZV,
  and pass all 25 primary example rows plus A/B, same-register, shared-SP, and
  dependent scalar-commit tests.
  BTST.K/R have primary-verified decode boundaries and remain atomically blocked
  from register execution and commit.
  There is no architectural completion timing or
  complete executable processor core (`TMS20-0009`–`TMS20-0011`)
- Cache status: primary organization/refill/reset/disable/flush and
  current-cycle fault/retry contracts are covered by the model and bounded RTL;
  RTL covers lookup/refill/LRU, CD/idle-CF, delayed P commit, backpressure,
  retry, fault resume/abort, refill-state reset, and three randomized seeds.
  CPU fault/interrupt state, bus-width/page scheduling and pin timing remain
  (`TMS20-0012`, `TMS20-0017`)
- Graphics status: not implemented (`TMS20-0024`–`TMS20-0026`)
- Bus status: cache-native completion subset only; no width/page/pin controller
  (`TMS20-0014`–`TMS20-0019`, `TMS20-0030`)
- Formal status: four cache, four fetch, eight scalar, and two commit-owner
  SVAs run in simulation only;
  SymbiYosys unavailable, so no bounded or unbounded proof result exists
- Synthesis status: leaf, bounded-cache/fetch, composed frontend, and scalar
  composition Quartus 17.0.2 Analysis & Synthesis pass with 0 errors/0
  warnings; the leaf wrapper uses 7,986 logic cells and 2,021 registers, while
  the fetch, frontend, and scalar wrappers use 393, 765, and 4,806 logic cells;
  the scalar wrapper has 1,387 registers and 4,096 block-memory bits; Yosys
  unavailable; no fit or TimeQuest result
- Documentation acquired: nine hash-verified TI documents plus an eleven-file
  pinned MAME source set; all payloads are gitignored
- Provisional behavior: the cache model represents architecturally
  uninitialized SSAs as abstract `None` tags and exposes native 32-bit refill
  transactions rather than pin-level dynamic-width cycles
- Unresolved conflicts: exact game parts, original/A errata and first-silicon
  history
- Battletoads readiness: not ready
- Revolution X readiness: not ready
- Next task: implement and independently verify BTST.K/R architectural-model
  semantics without using the RTL as an oracle
