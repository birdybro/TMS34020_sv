# Register commit composition

`rtl/core/tms34020_register_commit.sv` is a bounded integration of the
page-verified register-execution router, A/B/SP register file, and masked status
owner. It exists to verify state dependency and writeback behavior before a
fetch/cache/pipeline sequencer is introduced.

## Contract

The module decodes the packet first word continuously. `supported_o` is
asserted only when its declared length matches one of the 51 one-word, eight
two-word, or eight three-word operations supported by the regular register
executor or direct-PC executor. State changes only on a rising `clk_i` edge for
which both `commit_i` and `supported_o` are asserted. The conjunction is
reported as `commit_accepted_o`.

Register and status event outputs expose the exact write that is presented to
the state owners on that edge. Unsupported instructions assert neither event
and cannot change architectural state. EXGPC, JUMP, and JR.L redirect outputs
are likewise gated by the accepted commit. NOP is supported and accepted but
produces no register, status, or redirect event.

Supported operations are:

- NOP, ABS, NEG, NEGB, NOT;
- CLRC, DINT, EINT, GETST, PUTST, SETF, EXGF, SEXT, ZEXT, ADDK/INC, SUBK/DEC,
  MOVK,
  SETC;
- ADD, ADDC, ADDXY, SUB, SUBB, SUBXY, CMP, CMPK, BTST.K, BTST.R, LMO, and RMO;
- AND, ANDN, OR, and XOR;
- MOVE, MOVX, MOVY, RL.K, RL.R, SLA.K/R, SLL.K/R, SRA.K/R, and SRL.K/R;
- GETPC, EXGPC, JUMP, and DSJS;
- two-word JR.L, DSJ, DSJEQ, and DSJNE;
- two-word ADDI.W, CMPI.W, MOVI.W, and SUBI.W; and
- three-word ADDI.L, ADDXYI, ANDNI, CMPI.L, MOVI.L, ORI, SUBI.L, and XORI.

The instruction definitions and primary citations are maintained in
`docs/generated/tms34020_isa.yaml`. Register-file and status layout are defined
by TI *TMS34020 User's Guide*, August 1990, §4.1, printed pp.4-2..4-3. The
specific operation semantics are cited in
`docs/architecture/verified_rtl_slice.md`.

## Claim boundary

`sequential_next_pc_i` must be the next address of this instruction packet, not
a speculative fetch cursor. GETPC writes that value to `Rd`. EXGPC reads the
old `Rd`, writes the sequential address on the same state-commit edge, and
emits the old value with bits `[3:0]` cleared as a redirect event. This module
does not store PC; the execution composition owns application of that event.
JUMP emits the selected old register or shared-SP value with bits `[3:0]`
cleared, without a register or status write.
JR.L reads its condition from N/C/Z/V without modifying them, emits a signed
16-bit word-relative target only when true, and otherwise emits no redirect.

`commit_i` is an integration contract, not a reconstructed TMS34020 pipeline
signal. A future sequencer must assert it at the documented architectural
completion boundary and must suppress it for stalls, faults, retries, and
interrupt checkpoints. This component does not fetch instructions, consume
extension words, count machine states, model cache behavior, access memory, or
implement hidden internal-I/O cycles.

The current register-file synchronous clear provides deterministic FPGA,
simulation, and future formal startup. It is not a claim that silicon clears
the general registers on reset; TI leaves them uninitialized. Source: TI
*TMS34020 User's Guide*, August 1990, §6.12.2, printed p.6-23.

## Verification

`make rtl-leaf-tests` executes ordered state-commit sequences plus
direct combinational instruction checks. The suite verifies prior-state
dependency, A/B selection, shared A15/B15 SP aliasing, partial ST masks,
register-plus-status updates on one edge, nondestructive CMP/CMPI, every SUBK
and MOVK constant, encoded-zero ADDK/SUBK/MOVK, MOVK status preservation,
MOVI short sign extension, long-word assembly, N/Z/V replacement with C
preservation, MOVX/MOVY half-word merging with complete ST preservation,
same-file and cross-file MOVE with independent source/destination file
selection, MOVE N/Z/V replacement with C preservation, Z-only logical flags,
constant/register rotate counts, RL C/Z replacement with N/V preservation,
direct and two's-complement shift counts, arithmetic/logical fill, SLA
overflow, the four shift-family status masks, LMO leading-zero results and
Z-only status writes, including a commit sourced from shared SP,
BTST.K complemented constant selection, BTST.R low-five-bit register selection,
Z-only status writes with no destination write, and shared-SP count and
destination access, SETF selected-bank-only status writes, and SEXT/ZEXT
field-bank selection, partial status writes, and shared-SP destinations, EXGF
atomic register/selected-bank exchange through ordinary A and shared-SP
destinations in both field banks,
PUTST full-width status replacement from a dependent ordinary A register and
the B-file shared-SP alias,
state-neutral NOP, GETPC into a B register, EXGPC old-value capture and aligned
redirect through an A register and shared SP, JUMP redirect-only ownership,
JR.L true redirect and false fallthrough with complete state preservation,
DSJ-family and DSJS decrement/redirect behavior through ordinary and shared-SP
destinations, and rejection of an otherwise decoded but unsupported BLMOVE
word. Two runtime assertions additionally
check mutual exclusion between execution owners and require every redirect to
be accepted and aligned. The
testbench requires the explicit marker
`PASS: tms34020 verified leaf RTL`.

`make quartus-leaf-smoke` includes the component in warning-enforcing Cyclone V
Analysis & Synthesis. The qualification top retains separate raw state leaves
for observability in addition to this integrated state, so its utilization is
not representative of a processor core.
