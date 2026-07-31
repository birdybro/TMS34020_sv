# Register commit composition

`rtl/core/tms34020_register_commit.sv` is a bounded integration of the
page-verified register-execution router, A/B/SP register file, and masked status
owner. It exists to verify state dependency and writeback behavior before a
fetch/cache/pipeline sequencer is introduced.

## Contract

The module decodes `first_word_i` continuously. When the word is one of the 24
one-word operations supported by `tms34020_register_execute`,
`supported_o` is asserted. State changes only on a rising `clk_i` edge for
which both `commit_i` and `supported_o` are asserted. The conjunction is
reported as `commit_accepted_o`.

Register and status event outputs expose the exact write that is presented to
the state owners on that edge. Unsupported instructions assert neither event
and cannot change architectural state. NOP is supported and accepted but
produces no register or status event.

Supported operations are:

- NOP, ABS, NEG, NEGB, NOT;
- CLRC, DINT, EINT, GETST, ADDK/INC, SUBK/DEC, MOVK, SETC;
- ADD, ADDC, SUB, SUBB, CMP, CMPK, and RMO;
- AND, ANDN, OR, and XOR.

The instruction definitions and primary citations are maintained in
`docs/generated/tms34020_isa.yaml`. Register-file and status layout are defined
by TI *TMS34020 User's Guide*, August 1990, §4.1, printed pp.4-2..4-3. The
specific operation semantics are cited in
`docs/architecture/verified_rtl_slice.md`.

## Claim boundary

`commit_i` is an integration contract, not a reconstructed TMS34020 pipeline
signal. A future sequencer must assert it at the documented architectural
completion boundary and must suppress it for stalls, faults, retries, and
interrupt checkpoints. This component does not own PC, fetch instructions,
consume extension words, count machine states, model cache behavior, access
memory, or implement hidden internal-I/O cycles.

The current register-file synchronous clear provides deterministic FPGA,
simulation, and future formal startup. It is not a claim that silicon clears
the general registers on reset; TI leaves them uninitialized. Source: TI
*TMS34020 User's Guide*, August 1990, §6.12.2, printed p.6-23.

## Verification

`make rtl-leaf-tests` executes thirty-seven ordered state-commit sequences plus
direct combinational instruction checks. The suite verifies prior-state
dependency, A/B selection, shared A15/B15 SP aliasing, partial ST masks,
register-plus-status updates on one edge, nondestructive CMP/CMPI, every SUBK
and MOVK constant, encoded-zero ADDK/SUBK/MOVK, MOVK status preservation,
Z-only logical flags, state-neutral NOP, and rejection of an otherwise decoded
but unsupported BLMOVE word. The
testbench requires the explicit marker
`PASS: tms34020 verified leaf RTL`.

`make quartus-leaf-smoke` includes the component in warning-enforcing Cyclone V
Analysis & Synthesis. The qualification top retains separate raw state leaves
for observability in addition to this integrated state, so its utilization is
not representative of a processor core.
