"""Directed tests for the transaction-level instruction-cache model."""

from __future__ import annotations

import unittest

from tools.model import BitMemory, CacheModelError, InstructionCache


def complete_from_memory(
    cache: InstructionCache,
    memory: BitMemory,
    result,
):
    while not result.complete:
        request = result.request
        assert request is not None
        data = memory.read_bits(request.bit_address, request.width_bits)
        result = cache.accept_read(data)
    return result


class CacheModelTests(unittest.TestCase):
    def setUp(self) -> None:
        self.memory = BitMemory()
        self.memory.load_words(
            0,
            [0x1000 + index for index in range(128)],
        )

    def test_reset_fields_and_snapshot_round_trip(self) -> None:
        cache = InstructionCache()
        self.assertEqual(cache.ssa, [None, None, None, None])
        self.assertEqual(cache.present, [0, 0, 0, 0])
        self.assertEqual(cache.lru, [0, 1, 2, 3])
        self.assertIsNone(cache.pending)
        self.assertEqual(
            InstructionCache.from_snapshot(cache.snapshot()).snapshot(),
            cache.snapshot(),
        )

    def test_address_partition_matches_figure_5_2(self) -> None:
        address = (0x2ABCDE << 10) | (5 << 7) | (2 << 5) | (1 << 4)
        self.assertEqual(
            InstructionCache.address_fields(address),
            (0x2ABCDE, 5, 2, 1),
        )
        with self.assertRaises(ValueError):
            InstructionCache.address_fields(address + 1)

    def test_all_demand_longword_last_refill_orders(self) -> None:
        expected_offsets = (
            (0x20, 0x40, 0x60, 0x00),
            (0x40, 0x60, 0x00, 0x20),
            (0x60, 0x00, 0x20, 0x40),
            (0x00, 0x20, 0x40, 0x60),
        )
        for requested_index, offsets in enumerate(expected_offsets):
            address = 0x400 + requested_index * 0x20 + 0x10
            with self.subTest(requested_index=requested_index):
                cache = InstructionCache()
                result = cache.request_word(address)
                seen = []
                while not result.complete:
                    request = result.request
                    assert request is not None
                    seen.append(request.bit_address)
                    data = self.memory.read_bits(
                        request.bit_address, request.width_bits
                    )
                    result = cache.accept_read(data)
                self.assertEqual(
                    seen, [0x400 + offset for offset in offsets]
                )
                self.assertEqual(
                    result.word, self.memory.read_bits(address, 16)
                )
                self.assertEqual(result.classification, "segment_miss")
                self.assertEqual(cache.lru, [3, 0, 1, 2])
                self.assertEqual(cache.present[3], 0x01)

    def test_hit_moves_each_lru_position_to_front(self) -> None:
        cache = InstructionCache()
        for segment, base in zip((3, 2, 1, 0), (0x000, 0x400, 0x800, 0xC00)):
            result = complete_from_memory(
                cache, self.memory, cache.request_word(base)
            )
            self.assertEqual(result.segment, segment)
        self.assertEqual(cache.lru, [0, 1, 2, 3])

        expected_orders = {
            0x000: [3, 0, 1, 2],
            0x400: [2, 3, 0, 1],
            0x800: [1, 2, 3, 0],
            0xC00: [0, 1, 2, 3],
        }
        for address, expected in expected_orders.items():
            result = cache.request_word(address)
            self.assertTrue(result.complete)
            self.assertEqual(result.classification, "hit")
            self.assertEqual(cache.lru, expected)

    def test_subsegment_miss_reuses_segment_and_preserves_other_present(self) -> None:
        cache = InstructionCache()
        first = complete_from_memory(
            cache, self.memory, cache.request_word(0x000)
        )
        segment = first.segment
        assert segment is not None
        second = complete_from_memory(
            cache, self.memory, cache.request_word(0x080)
        )
        self.assertEqual(second.classification, "subsegment_miss")
        self.assertEqual(second.segment, segment)
        self.assertEqual(cache.present[segment], 0b00000011)
        self.assertEqual(cache.ssa[segment], 0)

    def test_disable_bypasses_without_mutating_cache_metadata(self) -> None:
        cache = InstructionCache()
        complete_from_memory(cache, self.memory, cache.request_word(0x000))
        before = (
            list(cache.ssa),
            list(cache.present),
            list(cache.lru),
            [list(segment) for segment in cache.data],
        )
        result = cache.request_word(0x400, cache_disable=True)
        self.assertEqual(result.classification, "disabled_bypass")
        self.assertEqual(result.request.width_bits, 16)
        result = cache.accept_read(self.memory.read_bits(0x400, 16))
        self.assertEqual(result.word, self.memory.read_bits(0x400, 16))
        after = (
            list(cache.ssa),
            list(cache.present),
            list(cache.lru),
            [list(segment) for segment in cache.data],
        )
        self.assertEqual(after, before)

    def test_self_modification_is_stale_until_flush(self) -> None:
        cache = InstructionCache()
        initial = complete_from_memory(
            cache, self.memory, cache.request_word(0x000)
        )
        self.assertEqual(initial.word, 0x1000)
        self.memory.write_bits(0x000, 16, 0xBEEF)
        stale = cache.request_word(0x000)
        self.assertEqual(stale.classification, "hit")
        self.assertEqual(stale.word, 0x1000)

        flushed = cache.request_word(0x000, cache_flush=True)
        self.assertEqual(flushed.classification, "flush_bypass")
        flushed = cache.accept_read(self.memory.read_bits(0x000, 16))
        self.assertEqual(flushed.word, 0xBEEF)
        self.assertEqual(cache.present, [0, 0, 0, 0])
        self.assertEqual(cache.lru, [0, 1, 2, 3])

        refilled = complete_from_memory(
            cache, self.memory, cache.request_word(0x000)
        )
        self.assertEqual(refilled.word, 0xBEEF)

    def test_retry_reissues_only_current_refill_cycle(self) -> None:
        cache = InstructionCache()
        result = cache.request_word(0x000)
        first_request = result.request
        assert first_request is not None
        result = cache.accept_read(
            self.memory.read_bits(
                first_request.bit_address, first_request.width_bits
            )
        )
        second_request = result.request
        assert second_request is not None
        self.assertEqual(cache.retry_current(), second_request)
        self.assertEqual(cache.current_request(), second_request)
        self.assertEqual(cache.pending.next_index, 1)
        self.assertEqual(cache.present[3], 0)

        result = complete_from_memory(cache, self.memory, result)
        successful_addresses = [
            event["bit_address"]
            for event in cache.transactions
            if event["outcome"] == "success"
        ]
        self.assertEqual(successful_addresses, [0x20, 0x40, 0x60, 0x00])
        self.assertEqual(result.word, 0x1000)

    def test_fault_pauses_and_resumes_same_refill_cycle(self) -> None:
        cache = InstructionCache()
        result = cache.request_word(0x0A0)
        first = result.request
        assert first is not None
        cache.fault_current()
        with self.assertRaises(CacheModelError):
            cache.current_request()
        with self.assertRaises(CacheModelError):
            cache.accept_read(0)
        self.assertEqual(cache.resume_fault(), first)
        result = complete_from_memory(cache, self.memory, result)
        self.assertEqual(result.word, self.memory.read_bits(0x0A0, 16))

    def test_aborted_fault_never_commits_present_flag(self) -> None:
        cache = InstructionCache()
        result = cache.request_word(0x000)
        request = result.request
        assert request is not None
        cache.accept_read(
            self.memory.read_bits(request.bit_address, request.width_bits)
        )
        cache.fault_current()
        cache.abort_fault()
        self.assertIsNone(cache.pending)
        self.assertEqual(cache.present[3], 0)
        with self.assertRaises(CacheModelError):
            cache.accept_read(0)

    def test_pending_refill_snapshot_replays_deterministically(self) -> None:
        cache = InstructionCache()
        result = cache.request_word(0x060)
        request = result.request
        assert request is not None
        cache.accept_read(
            self.memory.read_bits(request.bit_address, request.width_bits)
        )
        restored = InstructionCache.from_snapshot(cache.snapshot())
        self.assertEqual(restored.snapshot(), cache.snapshot())
        self.assertEqual(restored.current_request(), cache.current_request())


if __name__ == "__main__":
    unittest.main()
