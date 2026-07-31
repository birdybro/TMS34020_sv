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

    def test_abs_primary_examples_and_unaffected_carry(self) -> None:
        cases = (
            (0x7FFFFFFF, 0x7FFFFFFF, 0b1100),
            (0xFFFFFFFF, 0x00000001, 0b0100),
            (0x80000000, 0x80000000, 0b1101),
            (0x80000001, 0x7FFFFFFF, 0b0100),
            (0x00000001, 0x00000001, 0b1100),
            (0x00000000, 0x00000000, 0b0110),
            (0xFFFA0011, 0x0005FFEF, 0b0100),
        )
        for value, expected_result, expected_nczv in cases:
            with self.subTest(value=f"{value:08X}"):
                model = Tms34020Model()
                model.load_program([0x0392])
                model.state.write_reg("B", 2, value)
                model.state.st = 1 << 30
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("B", 2), expected_result
                )
                nczv = (model.state.st >> 28) & 0xF
                self.assertEqual(nczv, expected_nczv)
                self.assertEqual(event.machine_states, 1)

    def test_neg_primary_examples(self) -> None:
        cases = (
            (0x00000000, 0x00000000, 0b0010),
            (0x55555555, 0xAAAAAAAB, 0b1100),
            (0x7FFFFFFF, 0x80000001, 0b1100),
            (0x80000000, 0x80000000, 0b1101),
            (0x80000001, 0x7FFFFFFF, 0b0100),
            (0xFFFFFFFF, 0x00000001, 0b0100),
        )
        for value, expected_result, expected_nczv in cases:
            with self.subTest(value=f"{value:08X}"):
                model = Tms34020Model()
                model.load_program([0x03A0])
                model.state.write_reg("A", 0, value)
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_negb_primary_examples(self) -> None:
        cases = (
            (0x00000000, 0, 0x00000000, 0b0010),
            (0x00000000, 1, 0xFFFFFFFF, 0b1100),
            (0x55555555, 0, 0xAAAAAAAB, 0b1100),
            (0x55555555, 1, 0xAAAAAAAA, 0b1100),
            (0x7FFFFFFF, 0, 0x80000001, 0b1100),
            (0x7FFFFFFF, 1, 0x80000000, 0b1100),
            (0x80000000, 0, 0x80000000, 0b1101),
            (0x80000000, 1, 0x7FFFFFFF, 0b0100),
            (0x80000001, 0, 0x7FFFFFFF, 0b0100),
            (0x80000001, 1, 0x7FFFFFFE, 0b0100),
            (0xFFFFFFFF, 0, 0x00000001, 0b0100),
            (0xFFFFFFFF, 1, 0x00000000, 0b0110),
        )
        for value, borrow, expected_result, expected_nczv in cases:
            with self.subTest(value=f"{value:08X}", borrow=borrow):
                model = Tms34020Model()
                model.load_program([0x03C0])
                model.state.write_reg("A", 0, value)
                model.state.st = borrow << 30
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_not_primary_examples_and_unaffected_flags(self) -> None:
        cases = (
            (0x00000000, 0xFFFFFFFF, 0),
            (0x55555555, 0xAAAAAAAA, 0),
            (0xFFFFFFFF, 0x00000000, 1),
            (0x80000000, 0x7FFFFFFF, 0),
        )
        for value, expected_result, expected_z in cases:
            with self.subTest(value=f"{value:08X}"):
                model = Tms34020Model()
                model.load_program([0x03E0])
                model.state.write_reg("A", 0, value)
                model.state.st = 0xD0000010
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    model.state.st & 0xD0000000, 0xD0000000
                )
                self.assertEqual(
                    (model.state.st >> 29) & 1, expected_z
                )
                self.assertEqual(event.machine_states, 1)

    def test_add_primary_examples(self) -> None:
        cases = (
            (0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFE, 0b1100),
            (0xFFFFFFFF, 0x00000001, 0x00000000, 0b0110),
            (0xFFFFFFFF, 0x00000002, 0x00000001, 0b0100),
            (0xFFFFFFFF, 0x80000000, 0x7FFFFFFF, 0b0101),
            (0xFFFFFFFF, 0x80000001, 0x80000000, 0b1100),
            (0x7FFFFFFF, 0x80000001, 0x00000000, 0b0110),
            (0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 0b1000),
            (0x7FFFFFFF, 0x00000001, 0x80000000, 0b1001),
            (0x00000002, 0x00000002, 0x00000004, 0b0000),
        )
        for source, destination, expected_result, expected_nczv in cases:
            with self.subTest(
                source=f"{source:08X}", destination=f"{destination:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0x4020])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_addc_uses_carry_and_handles_sign_boundary(self) -> None:
        cases = (
            (0xFFFFFFFF, 0xFFFFFFFF, 1, 0xFFFFFFFF, 0b1100),
            (0xFFFFFFFF, 0x00000001, 1, 0x00000001, 0b0100),
            (0x7FFFFFFF, 0x00000001, 1, 0x80000001, 0b1001),
            (0x00000002, 0x00000002, 1, 0x00000005, 0b0000),
            (0xFFFFFFFF, 0x00000001, 0, 0x00000000, 0b0110),
        )
        for source, destination, carry, expected_result, expected_nczv in cases:
            with self.subTest(
                source=f"{source:08X}",
                destination=f"{destination:08X}",
                carry=carry,
            ):
                model = Tms34020Model()
                model.load_program([0x4220])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                model.state.st = carry << 30
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_sub_primary_examples(self) -> None:
        cases = (
            (0x7FFFFFF1, 0x7FFFFFF2, 0x00000001, 0b0000),
            (0x7FFFFFF2, 0x7FFFFFF2, 0x00000000, 0b0010),
            (0x7FFFFFF2, 0x7FFFFFF1, 0xFFFFFFFF, 0b1100),
            (0xFFFFFFFF, 0x7FFFFFF1, 0x7FFFFFF2, 0b0100),
            (0xFFFFFFFF, 0x7FFFFFFF, 0x80000000, 0b1101),
            (0x00000001, 0xFFFFFFFF, 0xFFFFFFFE, 0b1000),
            (0x00000001, 0x80000000, 0x7FFFFFFF, 0b0001),
        )
        for source, destination, expected_result, expected_nczv in cases:
            with self.subTest(
                source=f"{source:08X}", destination=f"{destination:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0x4420])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_subb_uses_borrow_and_handles_sign_boundary(self) -> None:
        cases = (
            (0x00000001, 0x00000002, 0, 0x00000001, 0b0000),
            (0x00000001, 0x00000002, 1, 0x00000000, 0b0010),
            (0x00000002, 0x00000002, 1, 0xFFFFFFFF, 0b1100),
            (0xFFFFFFFE, 0xFFFFFFFF, 1, 0x00000000, 0b0010),
            (0x00000001, 0x80000001, 0, 0x80000000, 0b1000),
            (0x00000001, 0x80000001, 1, 0x7FFFFFFF, 0b0001),
        )
        for source, destination, borrow, expected_result, expected_nczv in cases:
            with self.subTest(
                source=f"{source:08X}",
                destination=f"{destination:08X}",
                borrow=borrow,
            ):
                model = Tms34020Model()
                model.load_program([0x4620])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                model.state.st = borrow << 30
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_cmp_primary_examples_are_nondestructive(self) -> None:
        cases = (
            (0x00000001, 0x00000001, 0b0010),
            (0x00000001, 0x00000002, 0b0000),
            (0x00000001, 0xFFFFFFFF, 0b1000),
            (0x00000001, 0x80000000, 0b0001),
            (0xFFFFFFFF, 0x7FFFFFFF, 0b1101),
            (0xFFFFFFFF, 0x80000000, 0b1100),
            (0x80000000, 0x7FFFFFFF, 0b1101),
        )
        for source, destination, expected_nczv in cases:
            with self.subTest(
                source=f"{source:08X}", destination=f"{destination:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0x4820])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 1), source)
                self.assertEqual(model.state.read_reg("A", 0), destination)
                self.assertEqual(event.register_writes, [])
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_binary_arithmetic_reads_shared_sp_source(self) -> None:
        model = Tms34020Model()
        model.load_program([0x41F2])
        model.state.sp = 0x00000003
        model.state.write_reg("B", 2, 0x00000004)
        model.step()
        self.assertEqual(model.state.read_reg("B", 2), 0x00000007)

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

    def test_cmpk_constant_encoding_flags_and_nondestructive_register(self) -> None:
        cases = (
            (0x3440, 2, 0b0010),
            (0x3400, 0, 0b1100),
            (0x3420, 0x80000000, 0b0001),
        )
        for opcode, value, expected_nczv in cases:
            with self.subTest(opcode=f"{opcode:04X}", value=f"{value:08X}"):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.write_reg("A", 0, value)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), value)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_exgps_exchanges_low_word_with_psize(self) -> None:
        model = Tms34020Model()
        model.load_program([0x02A0])
        model.state.write_reg("A", 0, 0x12340001)
        model.state.write_io(PSIZE_ADDRESS, 8)
        status_before = model.state.st
        event = model.step()
        self.assertEqual(model.state.read_reg("A", 0), 8)
        self.assertEqual(model.state.read_io(PSIZE_ADDRESS), 1)
        self.assertEqual(model.state.st, status_before)
        self.assertEqual(event.machine_states, 2)
        self.assertEqual(model.state.pending_write_states, 1)
        self.assertEqual(
            event.transactions,
            [{
                "class": "internal_io_write",
                "bit_address": PSIZE_ADDRESS,
                "width": 16,
                "value": 1,
            }],
        )
        model.load_program([0x0300], bit_address=model.state.pc)
        model.step()
        self.assertEqual(model.state.pending_write_states, 0)

    def test_getps_zero_extends_into_selected_register(self) -> None:
        model = Tms34020Model()
        model.load_program([0x02D2])
        model.state.write_reg("B", 2, 0xFFFF_FFFF)
        model.state.write_io(PSIZE_ADDRESS, 16)
        event = model.step()
        self.assertEqual(model.state.read_reg("B", 2), 16)
        self.assertEqual(event.machine_states, 2)

    def test_rmo_finds_lsb_and_only_updates_z(self) -> None:
        cases = ((0, 0, 1), (0x80000000, 31, 0), (0x08000010, 4, 0))
        for source, expected, expected_z in cases:
            with self.subTest(source=f"{source:08X}"):
                model = Tms34020Model()
                model.load_program([0x7A01])
                model.state.write_reg("A", 0, source)
                model.state.st = 0xD000_0010
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 29) & 1, expected_z
                )
                self.assertEqual(
                    model.state.st & 0xD000_0000,
                    0xD000_0000,
                )
                self.assertEqual(event.machine_states, 1)

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
