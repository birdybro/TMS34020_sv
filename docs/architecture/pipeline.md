# Pipeline and internal parallelism

## What the primary source establishes

The August 1990 *TMS34020 User's Guide* does not present a conventional named
stage diagram such as fetch/decode/execute/writeback. It does establish the
following externally relevant facts:

1. A machine state is one local-clock period and four `CLKIN` periods. Assembly
   instruction timings are expressed in machine states. Source: User's Guide
   architecture overview, printed p.1-7.
2. A cache hit performs a one-machine-state cache read. Because instruction
   fetch is pipelined with completion of preceding instructions, its effective
   overhead is normally zero. Source: §5.3.1, printed p.5-5.
3. During a pair of machine states, the hardware can perform one external
   memory cycle, two instruction-word fetches from cache, and four reads plus
   two writes to the dual register files. Conflicting operations can restrict
   this parallelism. Source: §5.5, printed pp.5-10–5-11, Figures 5-3 and 5-4.
4. A memory read required by an instruction must complete before the next
   instruction can execute. A memory write can complete while the next
   instruction begins execution. Source: §5.5, printed pp.5-10–5-11.
5. Chapter 15 timings assume an enabled cache hit, immediate memory grants,
   granted page mode where requested, no wait states, and no retries. Source:
   chapter 15 introduction, printed p.15-1.
6. Parenthesized chapter 15 states are hidden trailing memory-write states.
   Subsequent instruction execution can overlap them, but a subsequent local
   bus user must wait for any hidden states not yet absorbed. Source: chapter
   15 introduction, printed p.15-1.
7. An enabled interrupt is taken at an instruction boundary or at the next
   documented interruptible point within an interruptible instruction. Source:
   §§6.5–6.6, printed pp.6-9 and 6-13.

These facts are `VERIFIED_PRIMARY`. They establish overlap and ordering
requirements, not every inaccessible internal latch or microcontrol-ROM state.

## Architectural ordering constraints

The implementation must preserve these orderings even if it uses a faster FPGA
clock and explicit clock enables:

- all opcode and extension fetches precede semantic use of those words;
- a cache miss, retry, or fault cannot expose an incomplete instruction packet;
- an instruction's register and ST changes appear together at its documented
  completion checkpoint;
- a data read blocks dependent completion and prevents the next instruction
  from executing prematurely;
- a trailing write may remain pending after the producing instruction's visible
  work, but its address, data, byte enables, and transaction identity remain
  stable until completion;
- a later local-memory user waits for unhidden pending-write states;
- a redirect invalidates younger implementation fetch state;
- interrupt and bus-fault entry use the correct ordinary or continuation PC,
  not an arbitrarily advanced fetch cursor.

The bounded `tms34020_scalar_slice` connects the serialized frontend to
`tms34020_register_commit` for 23 verified one-word operations and blocks
everything else. This verifies a conservative fetch-to-commit ordering, but
does not implement or measure documented pipeline overlap.

## Portable implementation decomposition

The initial portable implementation uses explicit handshake boundaries:

```text
reset/vector or completed redirect
                |
                v
       instruction fetch cursor
                |
                v
      cache request / response
                |
                v
     complete instruction packet
                |
                v
       decode and operand read
                |
                v
     execution / memory sequencing
                |
                v
     architectural state commit
```

This is an RTL decomposition chosen for verification. It is not asserted to be
the physical TMS34020 stage topology. `tms34020_instruction_fetch` now
serializes one instruction packet and waits for explicit completion, so it does
not implement the zero-overhead cache-hit overlap. Later timing work may add
buffering or overlap only when tests preserve the same packet, redirect, fault,
and commit invariants. Its signal contract is documented in
`instruction_fetch.md`; its cache composition is documented in `frontend.md`,
and the bounded downstream path in `scalar_execution_slice.md`.

## Initial instruction-packet contract

The first executable fetch boundary currently:

- accept only a 16-bit-aligned bit-address PC;
- request the opcode word through `tms34020_icache`;
- use the generated ISA decoder to determine the currently extracted length;
- fetch each extension word from successive `+16` bit addresses;
- hold a completed packet stable under downstream backpressure;
- report the instruction start and sequential next PC;
- never emit a partial packet after cache abort or reset;
- stop on an unclassified first word without consuming guessed extensions; and
- accept an aligned redirect only when no cache request is orphaned.

An unclassified word forms a one-word illegal-opcode candidate for the future
interrupt controller. The packet boundary must label it invalid; it must not
invent a legal instruction or a length greater than one.

The cache internally handles current-beat retry and fault pause/resume.
If the cache controller reports an abort, the packet assembler discards all
collected words and requires a documented PC reload/continuation decision from
the future fault controller.

## Cycle model boundary

Packet handshakes are expressed in FPGA clock cycles for functional
verification. They do **not** define TMS34020 machine-state counts.

Cycle qualification requires a separate state-enable layer that accounts for:

- the one-state cache access and its overlap;
- opcode and extension alignment;
- cache refill, disabled-cache access, page mode, and dynamic 16-bit targets;
- instruction execution cases from chapters 13–15;
- hidden pending writes;
- branch redirection and fetch loss;
- interrupt recognition and context switch;
- retry/fault pause and continuation; and
- display, refresh, host, and multiprocessor competition for local memory.

Until those cases have named trace tests, `TMS20-0013` remains incomplete and
the RTL must not be described as cycle accurate.

## Evidence still required

- Whether primary or patent material exposes additional named internal stages
  or branch-prefetch rules.
- Exact fetch cancellation and continuation behavior when an interrupt or bus
  fault intersects a cache miss.
- Exact timing when an instruction straddles cache subsegments or long-word
  alignment boundaries.
- Complete chapter 15 case extraction into machine-readable timing data.
- Data-sheet local-clock phase mapping for machine-state enables.
- Hardware or diagnostic evidence for any ambiguity not resolved by TI text.
