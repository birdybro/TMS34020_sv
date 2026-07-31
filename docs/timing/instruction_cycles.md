# Instruction-cycle evidence and interpretation

## Timing unit

The TMS34020 machine state is one local-clock period, equal to four `CLKIN`
periods. Instruction references and chapter 15 report execution in machine
states. Source: TI *TMS34020 User's Guide*, August 1990, architecture
overview, printed p.1-7.

This repository reserves the term **machine state** for that documented unit.
An FPGA implementation clock, a ready/valid handshake cycle, a Verilator clock
edge, and a TMS34020 machine state are not interchangeable unless a specific
clock-enable mapping has been verified.

## Chapter 15 assumptions

The tables in chapter 15 assume:

- the instruction cache is enabled;
- all instruction words hit in cache;
- all memory requests are granted immediately;
- requested page-mode access is granted;
- no wait states occur; and
- no retries occur.

Source: User's Guide chapter 15 introduction, printed p.15-1.

Therefore a table entry is not, by itself, an end-to-end time from an arbitrary
PC request to completion. Cache miss/fill, disabled-cache fetch, local-memory
arbitration, wait, retry, and dynamic-width costs must be composed from their
own documented cases.

## Hidden trailing writes

Parenthesized states in chapter 15 are hidden memory-write states at the end of
an instruction. The following instruction can execute while those writes
continue. If a following instruction needs the local bus before all hidden
states have been overlapped, it waits for the remainder. Source: User's Guide
chapter 15 introduction, printed p.15-1.

The architectural model's `pending_write_states` field is a disclosed abstract
counter for the few extracted cases that need this dependency. It is not a
complete memory-controller schedule. `MWAIT` consumes the abstract pending
states; full request-by-request validation remains pending.

## Cache-fetch interaction

A cache hit reads an instruction word in one machine state, normally overlapped
with preceding completion for effective zero fetch overhead. A disabled-cache
instruction-word fetch with no waits adds three machine states. An example
page-mode refill loads four long words in five states and then uses one
additional state to begin instruction processing. Sources: User's Guide
§5.3.1, printed p.5-5; §5.4, printed p.5-9.

These are bounded facts, not a universal cache timing formula. The exact
dynamic-16-bit, non-page, wait, retry, branch, line-crossing, and interrupt
cases remain unqualified.

## Required machine-readable timing work

Every ISA database entry must ultimately identify:

- its base cache-hit execution cases;
- first-word and extension alignment cases;
- visible and hidden states separately;
- local-memory reads and writes;
- interruptible checkpoints;
- cache-miss and bypass-fetch composition;
- 16-bit and 32-bit transfer effects;
- page-mode eligibility and loss;
- wait and retry extension; and
- source page/table/formula.

The current database includes only the timing information extracted alongside
its partial instruction set. It is not a complete timing database, and no
aggregate cycle-accuracy claim is permitted.
