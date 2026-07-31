# Synthesis status

- Portable RTL: verified execution/register leaves, serialized instruction
  packet fetch, and bounded native-completion instruction-cache leaf; no
  processor top exists
- Yosys: not installed in the local environment
- Quartus: Prime Lite 17.0.2 Build 602 at
  `/home/aberu/intelFPGA_lite/17.0/quartus/bin/quartus_sh`
- Target: DE10-Nano Cyclone V `5CSEBA6U23I7`
- Command: `make quartus-leaf-smoke`
- Result: Analysis & Synthesis successful, 0 errors, 0 warnings
- Analysis resources: 5,504 logic cells after synthesis, 2,021 registers,
  127 pins, 0 block-memory bits, 0 DSP blocks, and 0 PLLs
- Scope: generated 38-entry partial decoder, A/B/SP register file, masked ST state,
  nineteen instruction semantic leaves, decoder-controlled register-execution
  intents and externally gated state commit for 23 one-word instructions,
  and an observability-only synthesis wrapper
- Utilization caveat: the diagnostic top deliberately instantiates both the raw
  register/status leaves and a second integrated register/status pair inside
  the commit composition. This total is a portability regression metric, not a
  processor-core area estimate.
- Fit/placement/routing: not run
- TimeQuest/setup/hold: not run; no timing-closure claim
- CDC: no architectural crossings exist in this leaf slice; full CDC audit not
  started
- Unconstrained paths: not assessed by fitter/TimeQuest
- Qualification claim: only warning-free Cyclone V Analysis & Synthesis of the
  named leaf slice

## Bounded cache smoke

- Command: `make quartus-cache-smoke`
- Result: Analysis & Synthesis successful, 0 errors, 0 warnings
- Analysis resources: 375 logic cells, 200 registers, 108 pins, 4,096
  block-memory bits, 0 DSP blocks, and 0 PLLs
- Memory inference: one 128×32 simple dual-port `altsyncram`; the portable RTL
  contains no vendor primitive
- Scope: lookup/refill/bypass controller, native success/retry/fault outcomes,
  fault pause/resume/abort, four tags, 32 present bits, four-entry LRU,
  128-long-word data array, decoupled handshakes, and observability-only wrapper
- Fit/placement/routing: not run
- TimeQuest/setup/hold: not run; the 20 ns SDC is an analysis boundary, not a
  timing-closure result
- Qualification claim: warning-free Cyclone V Analysis & Synthesis and RAM
  inference for only the named bounded cache slice

## Bounded instruction-fetch smoke

- Command: `make quartus-fetch-smoke`
- Result: Analysis & Synthesis successful, 0 errors, 0 warnings
- Analysis resources: 343 logic cells, 174 registers, 74 pins, 0 block-memory
  bits, 0 DSP blocks, and 0 PLLs
- Scope: generated partial decoder, aligned instruction-start cursor,
  one-to-five-word packet storage, per-word cache classifications, decoupled
  cache/packet/completion handshakes, sequential/redirect selection, abort
  discard/reload, and an observability-only wrapper
- Fit/placement/routing: not run
- TimeQuest/setup/hold: not run; the 20 ns SDC is an analysis boundary, not a
  timing-closure result
- Qualification claim: warning-free Cyclone V Analysis & Synthesis for only the
  named serialized fetch slice

## Composed cache/fetch frontend smoke

- Command: `make quartus-frontend-smoke`
- Result: Analysis & Synthesis successful, 0 errors, 0 warnings
- Analysis resources: 709 logic cells, 372 registers, 82 pins, 4,096
  block-memory bits, 0 DSP blocks, and 0 PLLs
- Memory inference: the integrated cache retains one portable 128×32 dual-port
  RAM mapped to `altsyncram`
- Scope: cache, packet assembler, generated decode, native completion/fault
  handshakes, PC load/completion, and observability wrapper
- Fit/placement/routing and TimeQuest: not run; no timing-closure claim
- Qualification claim: warning-free Analysis & Synthesis for only the serialized
  cache/fetch composition
