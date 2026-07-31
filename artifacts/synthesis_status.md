# Synthesis status

- Portable RTL: first verified leaf slice only; no processor top exists
- Yosys: not installed in the local environment
- Quartus: Prime Lite 17.0.2 Build 602 at
  `/home/aberu/intelFPGA_lite/17.0/quartus/bin/quartus_sh`
- Target: DE10-Nano Cyclone V `5CSEBA6U23I7`
- Command: `make quartus-leaf-smoke`
- Result: Analysis & Synthesis successful, 0 errors, 0 warnings
- Analysis resources: 1,664 logic cells after synthesis, 992 registers,
  127 pins, 0 block-memory bits, 0 DSP blocks, and 0 PLLs
- Scope: generated partial decoder, A/B/SP register file, six instruction
  semantic leaves, and an observability-only synthesis wrapper
- Fit/placement/routing: not run
- TimeQuest/setup/hold: not run; no timing-closure claim
- CDC: no architectural crossings exist in this leaf slice; full CDC audit not
  started
- Unconstrained paths: not assessed by fitter/TimeQuest
- Qualification claim: only warning-free Cyclone V Analysis & Synthesis of the
  named leaf slice
