# Local bus

The architectural local-bus implementation is not yet present. The current
portable RTL exposes only the instruction-cache native transaction interface
and semantic execution leaves; it does not reproduce LAD/RAS/CAS/ALTCH/RCA,
LCLK1/LCLK2, SIZE16, PGMD, LRDY, or BUSFLT pin timing.

## Verified requirement added by SWAPF

SWAPF requires a distinct bus-locked read/modify/write request class. Its
32-bit read must be followed immediately by the matching write, host requests
must remain excluded, and retry/fault or an intervening refresh/grant loss
restarts the entire operation from the read. The locked operation does not
sample SIZE16 and outputs only the first-half S=0 cycle. Sources: TI
*TMS34020 User's Guide*, August 1990, printed pp.8-13, 8-26, and 13-247.

The model transaction names `bus_locked_data_read` and
`bus_locked_data_write` preserve this ownership distinction, but they are
instruction-boundary evidence only. The `tms34020_swap_field` RTL leaf
constructs word data and field status but never requests or drives the bus.

## Required future interface state

The native request interface must retain request class, bit address, access
width, byte enables, transfer sequence, page eligibility, lock ownership,
retry identity, and fault/continuation checkpoint. The later pin wrapper must
map those transactions onto documented address/status and data subcycles
without placing electrical delays in the portable core.

No bus-cycle, cycle-accuracy, dynamic-width, page-mode, retry-idempotence, or
pin-compatibility claim is made yet.
