"""Transaction-level TMS34020 instruction-cache architectural model.

This models the primary-documented organization, lookup, replacement, refill,
disable, flush, retry, and bus-fault-resume contract. It deliberately does not
assign machine-state or pin timing.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .state import MASK32

CACHE_SEGMENTS = 4
SUBSEGMENTS_PER_SEGMENT = 8
LONG_WORDS_PER_SUBSEGMENT = 4
LONG_WORDS_PER_SEGMENT = (
    SUBSEGMENTS_PER_SEGMENT * LONG_WORDS_PER_SUBSEGMENT
)
INITIAL_LRU = (0, 1, 2, 3)


class CacheModelError(RuntimeError):
    """Invalid transaction or corrupt cache-model state."""


@dataclass(frozen=True)
class MemoryReadRequest:
    """One native, bit-addressed memory request."""

    kind: str
    bit_address: int
    width_bits: int
    sequence_index: int
    sequence_length: int
    page_mode_eligible: bool

    def snapshot(self) -> dict[str, int | str | bool]:
        return {
            "kind": self.kind,
            "bit_address": self.bit_address,
            "width_bits": self.width_bits,
            "sequence_index": self.sequence_index,
            "sequence_length": self.sequence_length,
            "page_mode_eligible": self.page_mode_eligible,
        }


@dataclass(frozen=True)
class CacheWordResult:
    """Result of a lookup or one accepted memory response."""

    classification: str
    bit_address: int
    word: int | None
    request: MemoryReadRequest | None
    segment: int | None
    subsegment: int

    @property
    def complete(self) -> bool:
        return self.word is not None


@dataclass
class _PendingRead:
    classification: str
    requested_address: int
    segment: int | None
    subsegment: int
    refill_indices: list[int]
    next_index: int = 0
    faulted: bool = False

    def snapshot(self) -> dict[str, Any]:
        return {
            "classification": self.classification,
            "requested_address": self.requested_address,
            "segment": self.segment,
            "subsegment": self.subsegment,
            "refill_indices": list(self.refill_indices),
            "next_index": self.next_index,
            "faulted": self.faulted,
        }

    @classmethod
    def from_snapshot(cls, raw: dict[str, Any]) -> "_PendingRead":
        return cls(
            classification=str(raw["classification"]),
            requested_address=int(raw["requested_address"]),
            segment=(
                None if raw["segment"] is None else int(raw["segment"])
            ),
            subsegment=int(raw["subsegment"]),
            refill_indices=[int(value) for value in raw["refill_indices"]],
            next_index=int(raw["next_index"]),
            faulted=bool(raw["faulted"]),
        )


class InstructionCache:
    """Cycle-independent model of the four-segment TMS34020 cache."""

    def __init__(self) -> None:
        self.ssa: list[int | None] = [None] * CACHE_SEGMENTS
        self.present: list[int] = [0] * CACHE_SEGMENTS
        self.data: list[list[int]] = [
            [0] * LONG_WORDS_PER_SEGMENT for _ in range(CACHE_SEGMENTS)
        ]
        self.lru: list[int] = list(INITIAL_LRU)
        self.pending: _PendingRead | None = None
        self.transactions: list[dict[str, Any]] = []

    def reset(self) -> None:
        """Apply the documented empty-cache and LRU reset state.

        SSA values are represented by ``None`` because the guide declares them
        uninitialized. Data RAM is not cleared because no word is observable
        while all present flags are clear.
        """

        self.ssa = [None] * CACHE_SEGMENTS
        self.present = [0] * CACHE_SEGMENTS
        self.lru = list(INITIAL_LRU)
        self.pending = None

    def flush(self) -> None:
        """Return metadata to the same abstract empty state as reset."""

        self.reset()

    @staticmethod
    def address_fields(bit_address: int) -> tuple[int, int, int, int]:
        """Return SSA, subsegment, long-word, and half-word indices."""

        if not 0 <= bit_address <= MASK32:
            raise ValueError("bit_address must fit in 32 bits")
        if bit_address & 0xF:
            raise ValueError("instruction address must be 16-bit aligned")
        return (
            bit_address >> 10,
            (bit_address >> 7) & 0x7,
            (bit_address >> 5) & 0x3,
            (bit_address >> 4) & 0x1,
        )

    @staticmethod
    def refill_addresses(bit_address: int) -> tuple[int, int, int, int]:
        """Return the documented demand-long-word-last refill order."""

        _, _, requested_index, _ = InstructionCache.address_fields(
            bit_address
        )
        base = bit_address & 0xFFFF_FF80
        indices = (
            (requested_index + 1) & 3,
            (requested_index + 2) & 3,
            (requested_index + 3) & 3,
            requested_index,
        )
        return tuple(base + index * 0x20 for index in indices)

    def request_word(
        self,
        bit_address: int,
        *,
        cache_disable: bool = False,
        cache_flush: bool = False,
    ) -> CacheWordResult:
        """Begin one instruction-word lookup.

        Misses and bypass accesses return a native memory request. The caller
        advances them with :meth:`accept_read`. Cache hits return immediately.
        """

        if self.pending is not None:
            raise CacheModelError("a cache memory request is already pending")
        tag, subsegment, long_index, half_index = self.address_fields(
            bit_address
        )

        if cache_flush:
            self.flush()
        if cache_disable or cache_flush:
            classification = (
                "flush_bypass" if cache_flush else "disabled_bypass"
            )
            self.pending = _PendingRead(
                classification=classification,
                requested_address=bit_address,
                segment=None,
                subsegment=subsegment,
                refill_indices=[],
            )
            return self._pending_result()

        matching_segments = [
            segment
            for segment in range(CACHE_SEGMENTS)
            if self.ssa[segment] == tag
        ]
        if len(matching_segments) > 1:
            raise CacheModelError("multiple cache segments have the same SSA")
        if matching_segments:
            segment = matching_segments[0]
            if self.present[segment] & (1 << subsegment):
                self._touch(segment)
                word = self._read_cached_word(
                    segment, subsegment, long_index, half_index
                )
                return CacheWordResult(
                    classification="hit",
                    bit_address=bit_address,
                    word=word,
                    request=None,
                    segment=segment,
                    subsegment=subsegment,
                )
            classification = "subsegment_miss"
        else:
            segment = self.lru[-1]
            classification = "segment_miss"
            self.present[segment] = 0
            self.ssa[segment] = tag

        requested_index = long_index
        refill_indices = [
            (requested_index + offset) & 3 for offset in (1, 2, 3, 0)
        ]
        self.pending = _PendingRead(
            classification=classification,
            requested_address=bit_address,
            segment=segment,
            subsegment=subsegment,
            refill_indices=refill_indices,
        )
        return self._pending_result()

    def current_request(self) -> MemoryReadRequest:
        if self.pending is None:
            raise CacheModelError("no cache memory request is pending")
        pending = self.pending
        if pending.faulted:
            raise CacheModelError("faulted request must be resumed first")
        if pending.segment is None:
            return MemoryReadRequest(
                kind="instruction_fetch",
                bit_address=pending.requested_address,
                width_bits=16,
                sequence_index=0,
                sequence_length=1,
                page_mode_eligible=False,
            )
        long_index = pending.refill_indices[pending.next_index]
        base = pending.requested_address & 0xFFFF_FF80
        return MemoryReadRequest(
            kind="cache_fill",
            bit_address=base + long_index * 0x20,
            width_bits=32,
            sequence_index=pending.next_index,
            sequence_length=LONG_WORDS_PER_SUBSEGMENT,
            page_mode_eligible=True,
        )

    def accept_read(self, data: int) -> CacheWordResult:
        """Accept a successful response and advance or complete the lookup."""

        request = self.current_request()
        if data < 0 or data >> request.width_bits:
            raise ValueError("read data does not fit request width")
        pending = self.pending
        assert pending is not None
        self.transactions.append(
            {
                **request.snapshot(),
                "outcome": "success",
                "data": data,
            }
        )

        if pending.segment is None:
            result = CacheWordResult(
                classification=pending.classification,
                bit_address=pending.requested_address,
                word=data,
                request=None,
                segment=None,
                subsegment=pending.subsegment,
            )
            self.pending = None
            return result

        long_index = pending.refill_indices[pending.next_index]
        data_index = (
            pending.subsegment * LONG_WORDS_PER_SUBSEGMENT + long_index
        )
        self.data[pending.segment][data_index] = data
        pending.next_index += 1
        if pending.next_index != LONG_WORDS_PER_SUBSEGMENT:
            return self._pending_result()

        self.present[pending.segment] |= 1 << pending.subsegment
        self._touch(pending.segment)
        _, _, requested_long, requested_half = self.address_fields(
            pending.requested_address
        )
        word = self._read_cached_word(
            pending.segment,
            pending.subsegment,
            requested_long,
            requested_half,
        )
        result = CacheWordResult(
            classification=pending.classification,
            bit_address=pending.requested_address,
            word=word,
            request=None,
            segment=pending.segment,
            subsegment=pending.subsegment,
        )
        self.pending = None
        return result

    def retry_current(self) -> MemoryReadRequest:
        """Record a retry; the same native cycle remains current."""

        request = self.current_request()
        self.transactions.append({**request.snapshot(), "outcome": "retry"})
        return request

    def fault_current(self) -> MemoryReadRequest:
        """Pause the current native cycle for a CPU bus-fault handler."""

        request = self.current_request()
        assert self.pending is not None
        self.pending.faulted = True
        self.transactions.append({**request.snapshot(), "outcome": "fault"})
        return request

    def resume_fault(self) -> MemoryReadRequest:
        """Resume the same native cycle after bus-fault return."""

        if self.pending is None or not self.pending.faulted:
            raise CacheModelError("no faulted cache request is pending")
        self.pending.faulted = False
        return self.current_request()

    def abort_fault(self) -> None:
        """Model BSFLTST=FFFFh abandoning the saved memory-controller cycle."""

        if self.pending is None or not self.pending.faulted:
            raise CacheModelError("no faulted cache request is pending")
        self.pending = None

    def _pending_result(self) -> CacheWordResult:
        assert self.pending is not None
        return CacheWordResult(
            classification=self.pending.classification,
            bit_address=self.pending.requested_address,
            word=None,
            request=self.current_request(),
            segment=self.pending.segment,
            subsegment=self.pending.subsegment,
        )

    def _read_cached_word(
        self,
        segment: int,
        subsegment: int,
        long_index: int,
        half_index: int,
    ) -> int:
        data_index = (
            subsegment * LONG_WORDS_PER_SUBSEGMENT + long_index
        )
        return (self.data[segment][data_index] >> (16 * half_index)) & 0xFFFF

    def _touch(self, segment: int) -> None:
        if segment not in self.lru:
            raise CacheModelError("LRU stack is not a segment permutation")
        self.lru = [segment] + [
            entry for entry in self.lru if entry != segment
        ]

    def snapshot(self) -> dict[str, Any]:
        return {
            "cache_schema_version": 1,
            "ssa": list(self.ssa),
            "present": list(self.present),
            "data": [list(segment) for segment in self.data],
            "lru": list(self.lru),
            "pending": None if self.pending is None else self.pending.snapshot(),
            "transactions": list(self.transactions),
        }

    @classmethod
    def from_snapshot(cls, snapshot: dict[str, Any]) -> "InstructionCache":
        if snapshot.get("cache_schema_version") != 1:
            raise ValueError("unsupported cache snapshot")
        cache = cls()
        cache.ssa = [
            None if value is None else int(value)
            for value in snapshot["ssa"]
        ]
        cache.present = [int(value) for value in snapshot["present"]]
        cache.data = [
            [int(value) for value in segment]
            for segment in snapshot["data"]
        ]
        cache.lru = [int(value) for value in snapshot["lru"]]
        cache.pending = (
            None
            if snapshot["pending"] is None
            else _PendingRead.from_snapshot(snapshot["pending"])
        )
        cache.transactions = list(snapshot["transactions"])
        cache._validate()
        return cache

    def _validate(self) -> None:
        if len(self.ssa) != CACHE_SEGMENTS:
            raise ValueError("cache snapshot must contain four SSA values")
        if len(self.present) != CACHE_SEGMENTS or any(
            not 0 <= value <= 0xFF for value in self.present
        ):
            raise ValueError("cache snapshot has invalid present flags")
        if len(self.data) != CACHE_SEGMENTS or any(
            len(segment) != LONG_WORDS_PER_SEGMENT for segment in self.data
        ):
            raise ValueError("cache snapshot has invalid data dimensions")
        if any(
            value < 0 or value > MASK32
            for segment in self.data
            for value in segment
        ):
            raise ValueError("cache snapshot data must be 32 bits")
        if sorted(self.lru) != list(range(CACHE_SEGMENTS)):
            raise ValueError("cache snapshot LRU is not a permutation")
        initialized_tags = [tag for tag in self.ssa if tag is not None]
        if len(initialized_tags) != len(set(initialized_tags)):
            raise ValueError("cache snapshot has duplicate initialized SSAs")
        if self.pending is not None:
            if self.pending.segment is not None and not (
                0 <= self.pending.segment < CACHE_SEGMENTS
            ):
                raise ValueError("pending cache segment is invalid")
            if not 0 <= self.pending.subsegment < SUBSEGMENTS_PER_SEGMENT:
                raise ValueError("pending cache subsegment is invalid")
            if not 0 <= self.pending.next_index < LONG_WORDS_PER_SUBSEGMENT:
                raise ValueError("pending refill index is invalid")
            if (
                self.pending.segment is not None
                and sorted(self.pending.refill_indices)
                != list(range(LONG_WORDS_PER_SUBSEGMENT))
            ):
                raise ValueError("pending refill order is invalid")
