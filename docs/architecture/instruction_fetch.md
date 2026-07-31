# Bounded instruction-packet fetch

## Purpose and claim boundary

`rtl/core/tms34020_instruction_fetch.sv` is the first synthesizable owner of an
instruction start address and sequential/redirect progression. It assembles a
complete instruction packet from the bounded cache word interface before
allowing downstream execution to accept it.

This block is deliberately serialized. It does not fetch the next instruction
until the current packet has been accepted and an external execution controller
reports completion. It therefore preserves a safe PC and abort boundary but
does **not** yet reproduce the TMS34020's documented cache-fetch/execution
overlap or machine-state timing.

The architectural basis is:

- PC word alignment and `+16` per instruction word: TI *TMS34020 User's
  Guide*, August 1990, §4.2, printed p.4-4;
- cache use for opcodes and extension words: §5.1, printed p.5-3;
- pipelined cache-hit overlap: §5.3.1, printed p.5-5; and
- instruction-boundary/interruptible-point completion: §§6.5–6.6, printed
  pp.6-9 and 6-13.

The full evidence and vocabulary are in `control_flow.md` and `pipeline.md`.

## State progression

```text
NEEDS_PC
   | accepted explicit PC load, low four bits cleared
   v
REQUEST <--------------------------+
   | cache request accepted        |
   v                               |
WAIT_RESPONSE -- extension word ---+
   |
   | opcode plus all decoded extension words collected
   v
PACKET
   | downstream accepts stable packet
   v
WAIT_COMPLETION
   | sequential completion or aligned redirect
   +------------------------------> REQUEST
```

A cache abort from `WAIT_RESPONSE` discards all collected words, pulses
`fetch_aborted_o`, and returns to `NEEDS_PC`. The future fault controller must
then select and explicitly reload the documented continuation or vector PC.
The fetch block does not guess that decision.

## Interfaces

### PC load

`pc_load_valid_i/pc_load_ready_o` is accepted only in `NEEDS_PC`.
`pc_load_bit_address_i[3:0]` is cleared on acceptance. This input represents a
reset-vector, host-start, or fault-controller decision made outside the block.
Reset itself does not start a fetch.

### Cache word request

`cache_request_valid_o/cache_request_ready_i` carries one aligned 16-bit
instruction-word bit address at a time. Once accepted, the block waits for
`cache_response_valid_i/cache_response_ready_o`.

The response carries:

- the 16-bit instruction word;
- hit, segment-miss, subsegment-miss, or bypass classification; and
- a separate cache-abort indication for a fault path that abandoned the
  instruction request.

Retry and fault hold/resume are internal to `tms34020_icache`; this boundary
sees either a completed word or a final abort.

### Packet

The stable packet outputs are:

| Signal | Meaning |
|---|---|
| `packet_decode_valid_o` | First word matched the current partial ISA database |
| `packet_opcode_id_o` | Generated opcode identifier or `UNCLASSIFIED` |
| `packet_length_words_o` | One through five words; unclassified is forced to one |
| `packet_words_o` | Five packed 16-bit slots; word 0 is bits `[15:0]` |
| `packet_cache_results_o` | Five packed 2-bit cache classifications corresponding to the word slots |
| `packet_start_pc_o` | Aligned opcode bit address |
| `packet_sequential_next_pc_o` | Start plus 16 times decoded length, modulo 32 bits |
| `packet_first_cache_result_o` | Convenience copy of word 0's cache classification |

Unused word and classification slots are zero. An unclassified word is emitted
as an invalid one-word packet so a future illegal-opcode controller can act on
the exact first word without the fetch block guessing extension length.

### Completion

After `packet_valid_o/packet_ready_i`, the block asserts
`completion_ready_o` and issues no younger cache request. An accepted
`completion_valid_i` selects:

- `packet_sequential_next_pc_o` when `completion_redirect_i=0`; or
- `completion_redirect_bit_address_i` with bits `[3:0]` cleared when redirect
  is asserted.

This completion handshake is a correctness boundary, not a TMS34020 machine
state. The external controller must eventually distinguish normal retirement,
branches, calls/returns, interrupts, and continuation.

## Assertions and directed verification

Four simulation-enabled assertions check:

- stable cache request and address under backpressure;
- stable complete packet and metadata under downstream backpressure;
- aligned cache word requests; and
- no packet emission immediately after a cache abort.

`make fetch-tests` checks:

- explicit PC-load requirement after reset;
- low-bit clearing on PC load and redirect;
- a one-word NOP packet;
- three-word ORI extension ordering and cache metadata;
- cache-request and packet backpressure;
- no next fetch before explicit completion;
- an unclassified one-word packet;
- cache-abort discard and PC-reload requirement; and
- modulo-`2^32` sequential-PC wrap.

The testbench requires `PASS: tms34020 instruction packet fetch`.

`make quartus-fetch-smoke` performs warning-free Cyclone V Analysis &
Synthesis of this block plus the current generated decoder. The diagnostic
wrapper uses 363 logic cells and 174 registers. This is neither a processor
area estimate nor fit/TimeQuest timing evidence.

## Explicit exclusions

- Cache and fetch are composed in `tms34020_frontend`. The downstream bounded
  `tms34020_scalar_slice` connects 27 verified one-word operations and the
  two-word ADDI.W/CMPI.W/MOVI.W/SUBI.W and three-word
  ANDNI/ORI/XORI/ADDXYI/ADDI.L/CMPI.L/MOVI.L/SUBI.L operations to register/ST commit;
  every other packet remains blocked.
- No reset-vector memory transaction or host-halt controller exists.
- No branch instruction, interrupt, illegal-opcode trap, or bus-fault
  continuation controller drives completion.
- No speculative fetch, branch flush, pipeline overlap, or timing state enable
  exists.
- No instruction beyond the partial ISA database has a known packet length.
- The assertions have run in simulation only; no formal proof has been run.
