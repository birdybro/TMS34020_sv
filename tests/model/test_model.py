"""Directed tests for the independent primary-verified model slice."""

from __future__ import annotations

import json
import unittest

from tools.model import (
    ModelError,
    ProcessorState,
    Tms34020Model,
    UnsupportedInstruction,
)
from tools.model.state import CONFIG_ADDRESS, PSIZE_ADDRESS


class StateTests(unittest.TestCase):
    def test_sp_aliases_a15_and_b15(self) -> None:
        state = ProcessorState()
        state.write_reg("A", 15, 0x12345678)
        self.assertEqual(state.read_reg("B", 15), 0x12345678)
        state.write_reg("B", 15, 0x89ABCDEF)
        self.assertEqual(state.read_reg("A", 15), 0x89ABCDEF)

    def test_bit_memory_crosses_byte_and_long_boundaries(self) -> None:
        state = ProcessorState()
        state.memory.write_bits(29, 17, 0x1A55A)
        self.assertEqual(state.memory.read_bits(29, 17), 0x1A55A)
        self.assertEqual(state.memory.read_bits(0, 29), 0)

    def test_reset_vector_loads_config_nibble_and_aligned_pc(self) -> None:
        state = ProcessorState.randomized(3)
        state.reset_from_vector(0x1234567D)
        self.assertEqual(state.pc, 0x12345670)
        self.assertEqual(state.st, 0x10)
        self.assertEqual(state.read_io(CONFIG_ADDRESS), 0xD)

    def test_randomized_state_is_seed_reproducible(self) -> None:
        first = ProcessorState.randomized(0x34020).snapshot()
        second = ProcessorState.randomized(0x34020).snapshot()
        third = ProcessorState.randomized(0x34021).snapshot()
        self.assertEqual(first, second)
        self.assertNotEqual(first, third)


class ExecutionTests(unittest.TestCase):
    def test_nop_advances_bit_addressed_pc(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0300], bit_address=0x20000)
        event = model.step()
        self.assertEqual(model.state.pc, 0x20010)
        self.assertEqual(event.machine_states, 1)
        self.assertEqual(event.register_writes, [])

    def test_addxyi_adds_halves_without_cross_carry_and_sets_nczv(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0C00, 0xFFFF, 0xFFFF], bit_address=0x10)
        model.state.write_reg("A", 0, 0x00010001)
        event = model.step()
        self.assertEqual(model.state.read_reg("A", 0), 0)
        self.assertEqual((model.state.st >> 28) & 0xF, 0b1010)
        self.assertEqual(event.machine_states, 2)

    def test_addxyi_unaligned_immediate_and_b_file(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0C11, 0x0002, 0x0003], bit_address=0)
        model.state.write_reg("B", 1, 0x00040005)
        event = model.step()
        self.assertEqual(model.state.read_reg("B", 1), 0x00070007)
        self.assertEqual(event.machine_states, 3)
        self.assertEqual(event.register_writes[0]["file"], "B")

    def test_addxyi_destination_15_updates_shared_sp(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0C0F, 0x0001, 0x0002], bit_address=0x10)
        model.state.sp = 0x00030004
        model.step()
        self.assertEqual(model.state.sp, 0x00050005)
        self.assertEqual(model.state.read_reg("B", 15), 0x00050005)

    def test_rpix_all_documented_sizes_and_cycles(self) -> None:
        cases = {
            32: (0x89ABCDEF, 2),
            16: (0xCDEFCDEF, 4),
            8: (0xEFEFEFEF, 5),
            4: (0xFFFFFFFF, 6),
            2: (0xFFFFFFFF, 7),
            1: (0xFFFFFFFF, 8),
        }
        for pixel_size, (expected, cycles) in cases.items():
            with self.subTest(pixel_size=pixel_size):
                model = Tms34020Model()
                model.load_program([0x0280])
                model.state.write_reg("A", 0, 0x89ABCDEF)
                model.state.write_io(PSIZE_ADDRESS, pixel_size)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), expected)
                self.assertEqual(event.machine_states, cycles)

    def test_rpix_rejects_unverified_psize_without_committing(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0280])
        model.state.write_reg("A", 0, 0x1234)
        model.state.write_io(PSIZE_ADDRESS, 3)
        before = model.snapshot()
        with self.assertRaises(ModelError):
            model.step()
        self.assertEqual(model.snapshot(), before)

    def test_mwait_consumes_abstract_pending_write_states(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0080])
        model.state.pending_write_states = 2
        event = model.step()
        self.assertEqual(event.machine_states, 3)
        self.assertEqual(model.state.pending_write_states, 0)

    def test_idle_retains_pc_and_marks_timing_incomplete(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0040], bit_address=0x100)
        event = model.step()
        self.assertEqual(model.state.pc, 0x100)
        self.assertTrue(model.state.halted)
        self.assertFalse(model.state.timing_complete)
        self.assertIsNone(event.machine_states)
        with self.assertRaises(ModelError):
            model.step()

    def test_decoded_but_unimplemented_instruction_does_not_advance(self) -> None:
        model = Tms34020Model()
        model.load_program([0x00F3], bit_address=0x80)
        before = model.snapshot()
        with self.assertRaises(UnsupportedInstruction):
            model.step()
        self.assertEqual(model.snapshot(), before)

    def test_snapshot_json_round_trip_and_deterministic_replay(self) -> None:
        original = Tms34020Model(ProcessorState.randomized(17))
        original.load_program([0x0300, 0x0280])
        original.state.write_io(PSIZE_ADDRESS, 8)
        original.step()
        encoded = json.dumps(original.snapshot(), sort_keys=True)
        restored = Tms34020Model.from_snapshot(json.loads(encoded))
        original_event = original.step().snapshot()
        restored_event = restored.step().snapshot()
        self.assertEqual(original_event, restored_event)
        self.assertEqual(original.snapshot(), restored.snapshot())


if __name__ == "__main__":
    unittest.main()
