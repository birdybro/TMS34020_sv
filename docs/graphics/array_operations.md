# Array and continuous-block operations

## Current evidence boundary

The complete TMS34020 array engine, graphics continuation state, and
request-by-request bus behavior remain `TMS20-0018` and `TMS20-0024`–`0026`.
This document currently covers only the successful architectural boundary of
BLMOVE.

Primary source: TI *TMS34020 User's Guide*, August 1990
(`SPVU019 / 2564006-9721`), §13.8 printed p.13-30 and BLMOVE printed
pp.13-44..13-45. Page-mode eligibility is stated in §8.4, printed p.8-16.

## BLMOVE

BLMOVE moves a continuous count of bits rather than pixels. Its one-word
encoding is `0000_0000_1111_00SD`, giving four forms at `00F0h`–`00F3h`.
It uses:

| Register | Name | Successful-boundary role |
|---|---|---|
| B0 | SADDR | Starting source bit address; finishes at start plus original B7 |
| B2 | DADDR | Starting destination bit address; finishes at start plus original B7 |
| B7 | DYDX | Initial bit count; finishes at zero |

ST is unaffected. Address additions wrap modulo `2^32`.

S and D select permitted alignment and the architecturally observable
mid-instruction update policy:

| S | D | B0 requirement | B2 requirement | State during an interrupted move |
|---:|---:|---|---|---|
| 0 | 0 | 32-bit aligned | 32-bit aligned | B0/B2 fixed until completion |
| 0 | 1 | 32-bit aligned | Any bit | B0 fixed; B2 tracks progress |
| 1 | 0 | Any bit | 32-bit aligned | B0/B2 fixed until completion |
| 1 | 1 | Any bit | Any bit | B0 fixed; B2 tracks progress |

B7 decrements as data is moved and therefore records the remaining bit count.
If interrupted, PC points back to BLMOVE; the handler must preserve the B-file
operands so re-execution continues. Sources: instruction pp.13-44..13-45.

TI gives only `complex instruction` for the state count. It also identifies
BLMOVE as eligible for page-mode sequences, but the instruction page does not
define a complete request decomposition for the four modes, dynamic 16-bit
targets, waits, faults, or retries.

## Independent-model contract

The current model implements an atomic, successful, non-overlapping
instruction boundary:

- validates every S/D alignment requirement;
- copies the requested bit range, including unaligned and wrapping ranges;
- advances B0 and B2 by the original B7;
- clears B7;
- preserves ST; and
- records one `abstract_block_move` transaction with the starting addresses,
  bit count, and S/D mode.

The abstraction intentionally has no machine-state count. It does not expose
intermediate B0/B2/B7 values, page-mode requests, 16/32-bit beats, waits,
interrupt entry, bus faults, retry, or continuation. Overlapping but
nonidentical ranges are rejected by the model because the acquired primary
text does not define their transfer result; that rejection is a verification
guard, not claimed silicon behavior. Equal source and destination addresses
are supported.

Pinned MAME is unsuitable as the expected result for the missing details. Its
current implementation tests 16-bit rather than TI's 32-bit alignment,
transfers 16-bit chunks independent of S/D, and contains an explicit TODO for
the documented intermediate register updates. See RSC-0017.
