"""Directed tests for the independent primary-verified model slice."""

from __future__ import annotations

import json
import unittest

from tools.model import (
    CONVDP_ADDRESS,
    CONVMP_ADDRESS,
    CONVSP_ADDRESS,
    CONTROL_ADDRESS,
    HSTCTLH_ADDRESS,
    ModelError,
    ProcessorState,
    Tms34020Model,
    UnclassifiedEncoding,
)
from tools.model.state import CONFIG_ADDRESS, PSIZE_ADDRESS


def status_with_field_size(status: int, bank: int, width: int) -> int:
    encoded_width = width & 0x1F
    shift = bank * 6
    return (status & ~(0x1F << shift)) | (encoded_width << shift)


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

    def test_cold_fetch_records_demand_longword_last_refill(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0300])
        event = model.step()
        lookups = [
            transaction
            for transaction in event.transactions
            if transaction["class"] == "instruction_cache_lookup"
        ]
        fills = [
            transaction
            for transaction in event.transactions
            if transaction["class"] == "cache_fill"
        ]
        self.assertEqual(lookups[0]["result"], "segment_miss")
        self.assertEqual(
            [transaction["bit_address"] for transaction in fills],
            [0x20, 0x40, 0x60, 0x00],
        )
        self.assertFalse(model.state.timing_complete)
        self.assertIn("excludes cache miss", event.notes[0])

    def test_following_instruction_hits_loaded_subsegment(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0300, 0x0300])
        first = model.step()
        second = model.step()
        self.assertEqual(first.mnemonic, "NOP")
        self.assertEqual(second.mnemonic, "NOP")
        self.assertEqual(
            [
                transaction["result"]
                for transaction in second.transactions
                if transaction["class"] == "instruction_cache_lookup"
            ],
            ["hit"],
        )
        self.assertFalse(
            any(
                transaction["class"] == "cache_fill"
                for transaction in second.transactions
            )
        )

    def test_extension_crossing_subsegment_records_second_refill(self) -> None:
        model = Tms34020Model()
        model.load_program(
            [0x0B80, 0xFFFF, 0xFFFF],
            bit_address=0x70,
        )
        model.state.write_reg("A", 0, 0x12345678)
        event = model.step()
        self.assertEqual(
            [
                transaction["result"]
                for transaction in event.transactions
                if transaction["class"] == "instruction_cache_lookup"
            ],
            ["segment_miss", "subsegment_miss", "hit"],
        )
        self.assertEqual(
            sum(
                transaction["class"] == "cache_fill"
                for transaction in event.transactions
            ),
            8,
        )

    def test_cache_disable_fetches_each_instruction_word_directly(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0BA0, 0x5678, 0x1234])
        model.state.write_io(CONTROL_ADDRESS, 1 << 15)
        event = model.step()
        direct = [
            transaction
            for transaction in event.transactions
            if transaction["class"] == "instruction_fetch"
        ]
        self.assertEqual(len(direct), 3)
        self.assertTrue(all(item["width"] == 16 for item in direct))
        self.assertEqual(model.cache.present, [0, 0, 0, 0])
        self.assertFalse(model.state.timing_complete)

    def test_cache_flush_exposes_modified_instruction(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0300])
        self.assertEqual(model.step().mnemonic, "NOP")
        model.state.memory.write_bits(0, 16, 0x0320)
        model.state.pc = 0
        self.assertEqual(model.step().mnemonic, "NOP")

        model.state.pc = 0
        model.state.write_io(HSTCTLH_ADDRESS, 1 << 14)
        flushed = model.step()
        self.assertEqual(flushed.mnemonic, "CLRC")
        self.assertEqual(
            [
                transaction["result"]
                for transaction in flushed.transactions
                if transaction["class"] == "instruction_cache_lookup"
            ],
            ["flush_bypass"],
        )

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

    def test_clrc_and_setc_primary_examples_preserve_other_status(self) -> None:
        cases = (
            (0x0320, 0xF0000000, 0xB0000000),
            (0x0320, 0x40000010, 0x00000010),
            (0x0320, 0xB000001F, 0xB000001F),
            (0x0DE0, 0x00000000, 0x40000000),
            (0x0DE0, 0xB0000010, 0xF0000010),
            (0x0DE0, 0x4000001F, 0x4000001F),
        )
        for opcode, before, after in cases:
            with self.subTest(opcode=f"{opcode:04X}", before=f"{before:08X}"):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.st = before
                event = model.step()
                self.assertEqual(model.state.st, after)
                self.assertEqual(event.machine_states, 1)

    def test_dint_and_eint_only_update_ie(self) -> None:
        cases = (
            (0x0360, 0x00000010, 0x00000010),
            (0x0360, 0x00200010, 0x00000010),
            (0x0D60, 0x00000010, 0x00200010),
            (0x0D60, 0x00200010, 0x00200010),
        )
        for opcode, before, after in cases:
            with self.subTest(opcode=f"{opcode:04X}", before=f"{before:08X}"):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.st = before
                event = model.step()
                self.assertEqual(model.state.st, after)
                self.assertEqual(event.machine_states, 3)

    def test_getst_copies_complete_status_to_selected_register(self) -> None:
        cases = (
            (0x0181, "A", 1, 0x20200010),
            (0x0192, "B", 2, 0x00000010),
        )
        for opcode, register_file, index, status in cases:
            with self.subTest(opcode=f"{opcode:04X}", status=f"{status:08X}"):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.st = status
                event = model.step()
                self.assertEqual(
                    model.state.read_reg(register_file, index), status
                )
                self.assertEqual(model.state.st, status)
                self.assertEqual(event.machine_states, 1)

    def test_getpc_primary_rows_files_shared_sp_and_status(self) -> None:
        cases = (
            (0x0000_1BD0, 0x0141, "A", 1),
            (0x0000_1C10, 0x0141, "A", 1),
            (0x1234_5600, 0x0152, "B", 2),
            (0xFFFF_FFE0, 0x014F, "A", 15),
        )
        for start_pc, opcode, register_file, index in cases:
            with self.subTest(
                start_pc=f"{start_pc:08X}",
                opcode=f"{opcode:04X}",
            ):
                model = Tms34020Model()
                model.load_program([opcode], bit_address=start_pc)
                model.state.st = 0xF020_001F
                event = model.step()
                expected_pc = (start_pc + 16) & 0xFFFF_FFFF
                self.assertEqual(event.mnemonic, "GETPC")
                self.assertEqual(
                    model.state.read_reg(register_file, index),
                    expected_pc,
                )
                self.assertEqual(model.state.pc, expected_pc)
                self.assertEqual(event.next_pc, expected_pc)
                self.assertEqual(event.machine_states, 1)
                self.assertEqual(model.state.st, 0xF020_001F)

    def test_exgpc_primary_rows_files_shared_sp_and_alignment(self) -> None:
        cases = (
            (0x0121, "A", 1, 0x0000_1C10, 0x0000_1C10),
            (0x0121, "A", 1, 0x0000_1C50, 0x0000_1C50),
            (0x0132, "B", 2, 0x1234_567F, 0x1234_5670),
            (0x013F, "B", 15, 0xFFFF_FFFF, 0xFFFF_FFF0),
        )
        for opcode, register_file, index, old_register, expected_pc in cases:
            with self.subTest(
                opcode=f"{opcode:04X}",
                old_register=f"{old_register:08X}",
            ):
                model = Tms34020Model()
                model.load_program([opcode], bit_address=0x0000_2080)
                model.state.write_reg(register_file, index, old_register)
                model.state.st = 0x9020_0015
                event = model.step()
                self.assertEqual(event.mnemonic, "EXGPC")
                self.assertEqual(
                    model.state.read_reg(register_file, index),
                    0x0000_2090,
                )
                self.assertEqual(model.state.pc, expected_pc)
                self.assertEqual(event.next_pc, expected_pc)
                self.assertEqual(event.machine_states, 2)
                self.assertEqual(model.state.st, 0x9020_0015)

    def test_addk_primary_examples(self) -> None:
        cases = (
            (1, 0xFFFFFFFF, 0x00000000, 0b0110),
            (2, 0xFFFFFFFF, 0x00000001, 0b0100),
            (1, 0x7FFFFFFF, 0x80000000, 0b1001),
            (1, 0x80000000, 0x80000001, 0b1000),
            (32, 0x80000000, 0x80000020, 0b1000),
            (32, 0x00000002, 0x00000022, 0b0000),
        )
        for constant, value, result, nczv in cases:
            with self.subTest(
                constant=constant,
                value=f"{value:08X}",
            ):
                model = Tms34020Model()
                opcode = 0x1000 | ((constant & 0x1F) << 5)
                model.load_program([opcode])
                model.state.write_reg("A", 0, value)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.mnemonic, "ADDK")
                self.assertEqual(event.machine_states, 1)

    def test_inc_alias_primary_examples_decode_as_addk(self) -> None:
        cases = (
            (0x00000000, 0x00000001, 0b0000),
            (0x0000000F, 0x00000010, 0b0000),
            (0xFFFFFFFF, 0x00000000, 0b0110),
            (0xFFFFFFFE, 0xFFFFFFFF, 0b1000),
            (0x7FFFFFFF, 0x80000000, 0b1001),
        )
        for value, result, nczv in cases:
            with self.subTest(value=f"{value:08X}"):
                model = Tms34020Model()
                model.load_program([0x1021])
                model.state.write_reg("A", 1, value)
                event = model.step()
                self.assertEqual(event.mnemonic, "ADDK")
                self.assertEqual(model.state.read_reg("A", 1), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.machine_states, 1)

    def test_addk_b_file_and_encoded_zero_shared_sp(self) -> None:
        model = Tms34020Model()
        model.load_program([0x13F2, 0x101F])
        model.state.write_reg("B", 2, 1)
        model.state.sp = 0x7FFFFFE0
        first = model.step()
        second = model.step()
        self.assertEqual(first.mnemonic, "ADDK")
        self.assertEqual(model.state.read_reg("B", 2), 32)
        self.assertEqual(second.mnemonic, "ADDK")
        self.assertEqual(model.state.sp, 0x80000000)
        self.assertEqual((model.state.st >> 28) & 0xF, 0b1001)

    def test_subk_primary_examples(self) -> None:
        cases = (
            (5, 0x00000009, 0x00000004, 0b0000),
            (9, 0x00000009, 0x00000000, 0b0010),
            (32, 0x00000009, 0xFFFFFFE9, 0b1100),
            (1, 0x80000000, 0x7FFFFFFF, 0b0001),
        )
        for constant, value, result, nczv in cases:
            with self.subTest(
                constant=constant,
                value=f"{value:08X}",
            ):
                model = Tms34020Model()
                opcode = 0x1400 | ((constant & 0x1F) << 5)
                model.load_program([opcode])
                model.state.write_reg("A", 0, value)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.mnemonic, "SUBK")
                self.assertEqual(event.machine_states, 1)

    def test_dec_alias_primary_examples_decode_as_subk(self) -> None:
        cases = (
            (0x00000010, 0x0000000F, 0b0000),
            (0x00000001, 0x00000000, 0b0010),
            (0x00000000, 0xFFFFFFFF, 0b1100),
            (0xFFFFFFFF, 0xFFFFFFFE, 0b1000),
            (0x80000000, 0x7FFFFFFF, 0b0001),
        )
        for value, result, nczv in cases:
            with self.subTest(value=f"{value:08X}"):
                model = Tms34020Model()
                model.load_program([0x1431])
                model.state.write_reg("B", 1, value)
                event = model.step()
                self.assertEqual(event.mnemonic, "SUBK")
                self.assertEqual(model.state.read_reg("B", 1), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.machine_states, 1)

    def test_subk_b_file_and_encoded_zero_shared_sp(self) -> None:
        model = Tms34020Model()
        model.load_program([0x17F2, 0x140F])
        model.state.write_reg("B", 2, 32)
        model.state.sp = 0x8000001F
        first = model.step()
        second = model.step()
        self.assertEqual(first.mnemonic, "SUBK")
        self.assertEqual(model.state.read_reg("B", 2), 1)
        self.assertEqual(second.mnemonic, "SUBK")
        self.assertEqual(model.state.sp, 0x7FFFFFFF)
        self.assertEqual((model.state.st >> 28) & 0xF, 0b0001)

    def test_subk_all_constants_zero_result(self) -> None:
        for constant in range(1, 33):
            with self.subTest(constant=constant):
                model = Tms34020Model()
                opcode = 0x1400 | ((constant & 0x1F) << 5)
                model.load_program([opcode])
                model.state.write_reg("A", 0, constant)
                event = model.step()
                self.assertEqual(event.mnemonic, "SUBK")
                self.assertEqual(model.state.read_reg("A", 0), 0)
                self.assertEqual((model.state.st >> 28) & 0xF, 0b0010)
                self.assertEqual(event.machine_states, 1)

    def test_movk_primary_examples_and_status_preservation(self) -> None:
        for constant in (1, 8, 16, 32):
            with self.subTest(constant=constant):
                model = Tms34020Model()
                opcode = 0x1800 | ((constant & 0x1F) << 5)
                model.load_program([opcode])
                model.state.st = 0xF020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "MOVK")
                self.assertEqual(model.state.read_reg("A", 0), constant)
                self.assertEqual(model.state.st, 0xF020_0010)
                self.assertEqual(event.machine_states, 1)

    def test_movk_all_constants_b_file_and_shared_sp(self) -> None:
        words = [
            0x1812 | ((constant & 0x1F) << 5)
            for constant in range(1, 33)
        ]
        words.append(0x180F)
        model = Tms34020Model()
        model.load_program(words)
        model.state.sp = 0xDEADBEEF
        for constant in range(1, 33):
            event = model.step()
            self.assertEqual(event.mnemonic, "MOVK")
            self.assertEqual(model.state.read_reg("B", 2), constant)
            self.assertEqual(event.machine_states, 1)
        final = model.step()
        self.assertEqual(final.mnemonic, "MOVK")
        self.assertEqual(model.state.sp, 32)

    def test_movi_word_primary_rows_and_status_resolution(self) -> None:
        cases = (
            (0x7FFF, 0x0000_7FFF, 0b0100),
            (0x0001, 0x0000_0001, 0b0100),
            (0x0000, 0x0000_0000, 0b0110),
            (0xFFFF, 0xFFFF_FFFF, 0b1100),
            (0x8000, 0xFFFF_8000, 0b1100),
            (0x0000, 0x0000_0000, 0b0110),
            (0x7FFF, 0x0000_7FFF, 0b0100),
        )
        for encoded, expected, expected_nczv in cases:
            with self.subTest(encoded=f"{encoded:04X}"):
                model = Tms34020Model()
                model.load_program([0x09C0, encoded])
                model.state.st = 0x5020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "MOVI.W")
                self.assertEqual(model.state.read_reg("A", 0), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(model.state.st & 0x0FFF_FFFF, 0x0020_0010)
                self.assertEqual(event.machine_states, 2)

        b_file = Tms34020Model()
        b_file.load_program([0x09D2, 0x8000])
        b_file.step()
        self.assertEqual(b_file.state.read_reg("B", 2), 0xFFFF_8000)

    def test_movi_long_primary_rows_alignment_and_shared_sp(self) -> None:
        values = (
            0x7FFF_FFFF,
            0x0000_8000,
            0xFFFF_7FFF,
            0x8000_0000,
            0x0000_8000,
            0xFFFF_FFFF,
            0xFFFF_FFFF,
            0x0000_0000,
        )
        for value in values:
            with self.subTest(value=f"{value:08X}"):
                model = Tms34020Model()
                model.load_program(
                    [0x09E0, value & 0xFFFF, value >> 16]
                )
                model.state.st = 0x5020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "MOVI.L")
                self.assertEqual(model.state.read_reg("A", 0), value)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF,
                    (
                        (0b1000 if value & 0x8000_0000 else 0)
                        | 0b0100
                        | (0b0010 if value == 0 else 0)
                    ),
                )
                self.assertEqual(model.state.st & 0x0FFF_FFFF, 0x0020_0010)
                self.assertEqual(event.machine_states, 3)

        aligned_sp = Tms34020Model()
        aligned_sp.load_program(
            [0x09FF, 0x5678, 0x1234],
            bit_address=0x10,
        )
        aligned_event = aligned_sp.step()
        self.assertEqual(aligned_sp.state.sp, 0x1234_5678)
        self.assertEqual(aligned_event.machine_states, 2)

    def test_movx_and_movy_primary_rows_preserve_status(self) -> None:
        cases = (
            (0xEC01, 0x0000_0000, 0xFFFF_FFFF, 0xFFFF_0000),
            (0xEC01, 0x1234_5678, 0x0000_0000, 0x0000_5678),
            (0xEC01, 0xFFFF_FFFF, 0x0000_0000, 0x0000_FFFF),
            (0xEE01, 0x0000_0000, 0xFFFF_FFFF, 0x0000_FFFF),
            (0xEE01, 0x1234_5678, 0x0000_0000, 0x1234_0000),
            (0xEE01, 0xFFFF_FFFF, 0x0000_0000, 0xFFFF_0000),
        )
        for opcode, source, destination, expected in cases:
            with self.subTest(opcode=f"{opcode:04X}", source=f"{source:08X}"):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.write_reg("A", 0, source)
                model.state.write_reg("A", 1, destination)
                model.state.st = 0xF020_001F
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(model.state.read_reg("A", 0), source)
                self.assertEqual(model.state.st, 0xF020_001F)
                self.assertEqual(event.machine_states, 1)

    def test_movx_movy_b_file_shared_sp_and_same_register(self) -> None:
        model = Tms34020Model()
        model.load_program([0xEDF2, 0xEE5F, 0xECB5])
        model.state.sp = 0x1234_5678
        model.state.write_reg("B", 2, 0xABCD_EF01)
        model.state.write_reg("B", 5, 0xCAFE_BABE)

        movx = model.step()
        self.assertEqual(movx.mnemonic, "MOVX")
        self.assertEqual(model.state.read_reg("B", 2), 0xABCD_5678)

        movy = model.step()
        self.assertEqual(movy.mnemonic, "MOVY")
        self.assertEqual(model.state.sp, 0xABCD_5678)

        same = model.step()
        self.assertEqual(same.mnemonic, "MOVX")
        self.assertEqual(model.state.read_reg("B", 5), 0xCAFE_BABE)

    def test_move_primary_rows_same_and_cross_file(self) -> None:
        cases = (
            (0x0000_FFFF, 0b0100),
            (0x0000_0000, 0b0110),
            (0xFFFF_FFFF, 0b1100),
        )
        for opcode, destination_file in ((0x4C01, "A"), (0x4E01, "B")):
            for source, expected_nczv in cases:
                with self.subTest(
                    opcode=f"{opcode:04X}", source=f"{source:08X}"
                ):
                    model = Tms34020Model()
                    model.load_program([opcode])
                    model.state.write_reg("A", 0, source)
                    model.state.write_reg(destination_file, 1, 0xA5A5_5A5A)
                    model.state.st = 0x5020_0010
                    event = model.step()
                    self.assertEqual(event.mnemonic, "MOVE")
                    self.assertEqual(
                        model.state.read_reg(destination_file, 1), source
                    )
                    self.assertEqual(
                        (model.state.st >> 28) & 0xF, expected_nczv
                    )
                    self.assertEqual(
                        model.state.st & 0x0FFF_FFFF, 0x0020_0010
                    )
                    self.assertEqual(event.machine_states, 1)

    def test_move_b_to_a_shared_sp_and_same_register(self) -> None:
        model = Tms34020Model()
        model.load_program([0x4E51, 0x4DE2, 0x4C63])
        model.state.write_reg("B", 2, 0x1234_5678)
        model.state.sp = 0xCAFE_BABE
        model.state.write_reg("A", 3, 0x8000_0000)
        model.state.st = 0xF020_001F

        cross = model.step()
        self.assertEqual(cross.mnemonic, "MOVE")
        self.assertEqual(model.state.read_reg("A", 1), 0x1234_5678)
        self.assertEqual((model.state.st >> 28) & 0xF, 0b0100)

        shared_sp = model.step()
        self.assertEqual(shared_sp.mnemonic, "MOVE")
        self.assertEqual(model.state.read_reg("A", 2), 0xCAFE_BABE)
        self.assertEqual((model.state.st >> 28) & 0xF, 0b1100)

        same = model.step()
        self.assertEqual(same.mnemonic, "MOVE")
        self.assertEqual(model.state.read_reg("A", 3), 0x8000_0000)
        self.assertEqual((model.state.st >> 28) & 0xF, 0b1100)

    def test_rl_constant_primary_rows_preserve_n_and_v(self) -> None:
        cases = (
            (0, 0x0000_000F, 0x0000_000F, 0b1001),
            (1, 0xF000_0000, 0xE000_0001, 0b1101),
            (4, 0xF000_0000, 0x0000_000F, 0b1101),
            (5, 0xF000_0000, 0x0000_001E, 0b1001),
            (30, 0xF000_0000, 0x3C00_0000, 0b1001),
            (5, 0x0000_0000, 0x0000_0000, 0b1011),
        )
        for count, before, expected, expected_nczv in cases:
            with self.subTest(count=count, before=f"{before:08X}"):
                model = Tms34020Model()
                model.load_program([0x3001 | (count << 5)])
                model.state.write_reg("A", 1, before)
                model.state.st = 0x9020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "RL.K")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_rl_register_primary_rows_use_low_five_source_bits(self) -> None:
        cases = (
            (0b00000, 0x0000_000F, 0x0000_000F, 0b0000),
            (0b00100, 0xF000_0000, 0x0000_000F, 0b0100),
            (0b00101, 0xF000_0000, 0x0000_001E, 0b0000),
            (0b11111, 0xF000_0000, 0x7800_0000, 0b0000),
            (0xFFFF_FFE5, 0x0000_0000, 0x0000_0000, 0b0010),
        )
        for count_source, before, expected, expected_nczv in cases:
            with self.subTest(count_source=f"{count_source:08X}"):
                model = Tms34020Model()
                model.load_program([0x6801])
                model.state.write_reg("A", 0, count_source)
                model.state.write_reg("A", 1, before)
                model.state.st = 0x0020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "RL.R")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_rl_b_file_shared_sp_and_same_register(self) -> None:
        model = Tms34020Model()
        model.load_program([0x69F2, 0x6873, 0x33FF])
        model.state.sp = 4
        model.state.write_reg("B", 2, 0xF000_0000)
        model.state.write_reg("B", 3, 4)

        register_sp = model.step()
        self.assertEqual(register_sp.mnemonic, "RL.R")
        self.assertEqual(model.state.read_reg("B", 2), 0x0000_000F)

        same_register = model.step()
        self.assertEqual(same_register.mnemonic, "RL.R")
        self.assertEqual(model.state.read_reg("B", 3), 0x0000_0040)

        constant_sp = model.step()
        self.assertEqual(constant_sp.mnemonic, "RL.K")
        self.assertEqual(model.state.sp, 0x0000_0002)
        self.assertEqual(constant_sp.machine_states, 1)

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

    def test_addxy_all_primary_examples_and_status_replacement(self) -> None:
        cases = (
            (0x00000000, 0x00000000, 0x00000000, 0b1010),
            (0x00000000, 0x00000001, 0x00000001, 0b0010),
            (0x00000000, 0x00010000, 0x00010000, 0b1000),
            (0x00000000, 0x00010001, 0x00010001, 0b0000),
            (0x0000FFFF, 0x00000001, 0x00000000, 0b1010),
            (0x0000FFFF, 0x00010001, 0x00010000, 0b1000),
            (0x0000FFFF, 0x00000002, 0x00000001, 0b0010),
            (0x0000FFFF, 0x00010002, 0x00010001, 0b0000),
            (0xFFFF0000, 0x00010000, 0x00000000, 0b1010),
            (0xFFFF0000, 0x00010001, 0x00000001, 0b0010),
            (0xFFFF0000, 0x00020000, 0x00010000, 0b1000),
            (0xFFFF0000, 0x00020001, 0x00010001, 0b0000),
            (0xFFFFFFFF, 0x00010001, 0x00000000, 0b1010),
            (0xFFFFFFFF, 0x00010002, 0x00000001, 0b0010),
            (0xFFFFFFFF, 0x00020001, 0x00010000, 0b1000),
            (0xFFFFFFFF, 0x00020002, 0x00010001, 0b0000),
        )
        for source, destination, expected_result, expected_nczv in cases:
            with self.subTest(
                source=f"{source:08X}", destination=f"{destination:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0xE020])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                model.state.st = 0x0ABC_DEF0
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    model.state.st,
                    (expected_nczv << 28) | 0x0ABC_DEF0,
                )
                self.assertEqual(event.machine_states, 1)

    def test_subxy_all_primary_examples_and_status_replacement(self) -> None:
        cases = (
            (0x00010001, 0x00090009, 0x00080008, 0b0000),
            (0x00090001, 0x00090009, 0x00000008, 0b0010),
            (0x00010009, 0x00090009, 0x00080000, 0b1000),
            (0x00090009, 0x00090009, 0x00000000, 0b1010),
            (0x00000010, 0x00090009, 0x0009FFF9, 0b0001),
            (0x00090010, 0x00090009, 0x0000FFF9, 0b0011),
            (0x00100000, 0x00090009, 0xFFF90009, 0b0100),
            (0x00100009, 0x00090009, 0xFFF90000, 0b1100),
            (0x00100010, 0x00090009, 0xFFF9FFF9, 0b0101),
        )
        for source, destination, expected_result, expected_nczv in cases:
            with self.subTest(
                source=f"{source:08X}", destination=f"{destination:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0xE220])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                model.state.st = 0x0ABC_DEF0
                event = model.step()
                self.assertEqual(
                    model.state.read_reg("A", 0), expected_result
                )
                self.assertEqual(
                    model.state.st,
                    (expected_nczv << 28) | 0x0ABC_DEF0,
                )
                self.assertEqual(event.machine_states, 1)

    def test_xy_arithmetic_b_file_same_register_and_shared_sp(self) -> None:
        model = Tms34020Model()
        model.load_program([
            0xE052,
            0xE252,
            0xE1E0,
            0xE23F,
        ])
        model.state.write_reg("B", 2, 0x00010002)
        model.state.sp = 0x00030004

        add_same = model.step()
        self.assertEqual(model.state.read_reg("B", 2), 0x00020004)
        self.assertEqual(add_same.machine_states, 1)

        sub_same = model.step()
        self.assertEqual(model.state.read_reg("B", 2), 0)
        self.assertEqual((model.state.st >> 28) & 0xF, 0b1010)

        add_sp_source = model.step()
        self.assertEqual(model.state.read_reg("A", 0), 0x00030004)

        model.state.write_reg("B", 1, 0x00010001)
        sub_sp_destination = model.step()
        self.assertEqual(model.state.sp, 0x00020003)
        self.assertEqual(model.state.read_reg("A", 15), 0x00020003)

    def test_addi_word_sign_extension_flags_and_files(self) -> None:
        cases = (
            ("A", 0xFFFF_FFFF, 0x0001, 0x0000_0000, 0b0110),
            ("B", 0xFFFF_FFFF, 0x0002, 0x0000_0001, 0b0100),
            ("A", 0x7FFF_FFFF, 0x0001, 0x8000_0000, 0b1001),
            ("B", 0x0000_0002, 0x0002, 0x0000_0004, 0b0000),
            ("A", 0x0000_0002, 0x7FFF, 0x0000_8001, 0b0000),
            ("B", 0xFFFF_FFF0, 0x0010, 0x0000_0000, 0b0110),
            ("A", 0x0000_0020, 0xFFF0, 0x0000_0010, 0b0100),
        )
        for register_file, destination, immediate, result, nczv in cases:
            file_bit = 0x10 if register_file == "B" else 0
            with self.subTest(
                register_file=register_file,
                destination=f"{destination:08X}",
                immediate=f"{immediate:04X}",
            ):
                model = Tms34020Model()
                model.load_program([0x0B00 | file_bit, immediate])
                model.state.write_reg(register_file, 0, destination)
                event = model.step()
                self.assertEqual(model.state.read_reg(register_file, 0), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.mnemonic, "ADDI.W")
                self.assertEqual(event.machine_states, 2)

    def test_addi_long_primary_edges_and_alignment(self) -> None:
        cases = (
            (0x10, 0xFFFF_FFFF, 0xFFFF_FFFF, 0xFFFF_FFFE, 0b1100),
            (0x00, 0xFFFF_FFFF, 0x8000_0000, 0x7FFF_FFFF, 0b0101),
            (0x10, 0x7FFF_FFFF, 0x8000_0000, 0xFFFF_FFFF, 0b1000),
            (0x00, 0x7FFF_FFFF, 0x0000_8000, 0x8000_7FFF, 0b1001),
            (0x10, 0xFFFF_FFFF, 0x0000_0002, 0x0000_0001, 0b0100),
        )
        for start_address, destination, immediate, result, nczv in cases:
            with self.subTest(
                start_address=f"{start_address:08X}",
                immediate=f"{immediate:08X}",
            ):
                model = Tms34020Model()
                model.load_program(
                    [0x0B20, immediate & 0xFFFF, immediate >> 16],
                    bit_address=start_address,
                )
                model.state.write_reg("A", 0, destination)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.mnemonic, "ADDI.L")
                self.assertEqual(
                    event.machine_states,
                    2 if start_address == 0x10 else 3,
                )

    def test_addi_long_destination_15_updates_shared_sp(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0B3F, 0x0002, 0x0000], bit_address=0x10)
        model.state.sp = 0xFFFF_FFFF
        model.step()
        self.assertEqual(model.state.sp, 1)
        self.assertEqual(model.state.read_reg("A", 15), 1)

    def test_subi_word_primary_rows_and_complemented_encoding(self) -> None:
        cases = (
            (32765, 0x0000_7FFE, 0x0000_0001, 0b0000),
            (32766, 0x0000_7FFE, 0x0000_0000, 0b0010),
            (32767, 0x0000_7FFE, 0xFFFF_FFFF, 0b1100),
            (32766, 0x8000_7FFE, 0x8000_0000, 0b1000),
            (32767, 0x8000_7FFE, 0x7FFF_FFFF, 0b0001),
            (-32766, 0xFFFF_8001, 0xFFFF_FFFF, 0b1100),
            (-32767, 0xFFFF_8001, 0x0000_0000, 0b0010),
            (-32768, 0xFFFF_8001, 0x0000_0001, 0b0000),
            (-32767, 0x7FFF_8000, 0x7FFF_FFFF, 0b0100),
            (-32768, 0x7FFF_8000, 0x8000_0000, 0b1101),
        )
        for immediate, destination, result, nczv in cases:
            encoded = (~immediate) & 0xFFFF
            with self.subTest(
                immediate=immediate,
                destination=f"{destination:08X}",
            ):
                model = Tms34020Model()
                model.load_program([0x0BE0, encoded])
                model.state.write_reg("A", 0, destination)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.mnemonic, "SUBI.W")
                self.assertEqual(event.instruction_words[1], encoded)
                self.assertEqual(event.machine_states, 2)

    def test_subi_long_primary_rows_alignment_and_source_conflict(self) -> None:
        cases = (
            (2147483647, 0x7FFF_FFFF, 0x0000_0000, 0b0010),
            (32768, 0x0000_8001, 0x0000_0001, 0b0000),
            (32769, 0x0000_8001, 0x0000_0000, 0b0010),
            (32770, 0x0000_8001, 0xFFFF_FFFF, 0b1100),
            (32768, 0x8000_8000, 0x8000_0000, 0b1000),
            (32769, 0x8000_8000, 0x7FFF_FFFF, 0b0001),
            (-2147483648, 0x8000_0000, 0x0000_0000, 0b0010),
            (-32769, 0xFFFF_7FFE, 0xFFFF_FFFF, 0b1100),
            (-32770, 0xFFFF_7FFE, 0x0000_0000, 0b0010),
            (-32771, 0xFFFF_7FFE, 0x0000_0001, 0b0000),
            (-32770, 0x7FFF_7FFD, 0x7FFF_FFFF, 0b0100),
            (-32771, 0x7FFF_7FFD, 0x8000_0000, 0b1101),
        )
        for case_index, (
            immediate,
            destination,
            result,
            nczv,
        ) in enumerate(cases):
            encoded = (~immediate) & 0xFFFF_FFFF
            start_address = 0x10 if case_index & 1 else 0
            with self.subTest(
                immediate=immediate,
                destination=f"{destination:08X}",
                start_address=f"{start_address:08X}",
            ):
                model = Tms34020Model()
                model.load_program(
                    [0x0D00, encoded & 0xFFFF, encoded >> 16],
                    bit_address=start_address,
                )
                model.state.write_reg("A", 0, destination)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.mnemonic, "SUBI.L")
                self.assertEqual(
                    event.instruction_words[1:],
                    [encoded & 0xFFFF, encoded >> 16],
                )
                self.assertEqual(
                    event.machine_states,
                    2 if start_address == 0x10 else 3,
                )

    def test_subi_destination_15_updates_shared_sp(self) -> None:
        immediate = 2
        encoded = (~immediate) & 0xFFFF_FFFF
        model = Tms34020Model()
        model.load_program(
            [0x0D1F, encoded & 0xFFFF, encoded >> 16],
            bit_address=0x10,
        )
        model.state.sp = 1
        model.step()
        self.assertEqual(model.state.sp, 0xFFFF_FFFF)
        self.assertEqual(model.state.read_reg("A", 15), 0xFFFF_FFFF)

    def test_cmpi_word_primary_rows_are_nondestructive(self) -> None:
        cases = (
            (1, 0x0000_0002, 0b0000),
            (1, 0x0000_0001, 0b0010),
            (1, 0x0000_0000, 0b1100),
            (1, 0xFFFF_FFFF, 0b1000),
            (1, 0x8000_0000, 0b0001),
            (-2, 0x0000_0000, 0b0100),
            (-2, 0xFFFF_FFFF, 0b0000),
            (-2, 0xFFFF_FFFE, 0b0010),
            (-2, 0xFFFF_FFFD, 0b1100),
            (-1, 0x7FFF_FFFF, 0b1101),
        )
        for case_index, (immediate, destination, nczv) in enumerate(cases):
            register_file = "B" if case_index & 1 else "A"
            file_bit = 0x10 if register_file == "B" else 0
            encoded = (~immediate) & 0xFFFF
            with self.subTest(
                immediate=immediate,
                destination=f"{destination:08X}",
                register_file=register_file,
            ):
                model = Tms34020Model()
                model.load_program([0x0B40 | file_bit, encoded])
                model.state.write_reg(register_file, 0, destination)
                status_low = model.state.st & 0x0FFF_FFFF
                event = model.step()
                self.assertEqual(
                    model.state.read_reg(register_file, 0), destination
                )
                self.assertEqual(event.register_writes, [])
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(model.state.st & 0x0FFF_FFFF, status_low)
                self.assertEqual(event.mnemonic, "CMPI.W")
                self.assertEqual(event.instruction_words[1], encoded)
                self.assertEqual(event.machine_states, 2)

    def test_cmpi_long_primary_rows_and_alignment_are_nondestructive(
        self,
    ) -> None:
        cases = (
            (0x0000_8000, 0x0000_8001, 0b0000),
            (0x0000_8000, 0x0000_8000, 0b0010),
            (0x0000_8000, 0x0000_7FFF, 0b1100),
            (0x0000_8000, 0xFFFF_FFFF, 0b1000),
            (0x0000_8000, 0x8000_7FFF, 0b0001),
            (0xFFFF_7FFF, 0x0000_0000, 0b0100),
            (0xFFFF_7FFE, 0xFFFF_7FFF, 0b0000),
            (0xFFFF_7FFE, 0xFFFF_7FFE, 0b0010),
            (0xFFFF_7FFE, 0xFFFF_7FFD, 0b1100),
            (0xFFFF_7FFF, 0x7FFF_7FFF, 0b1101),
        )
        for case_index, (immediate, destination, nczv) in enumerate(cases):
            encoded = (~immediate) & 0xFFFF_FFFF
            start_address = 0x10 if case_index & 1 else 0
            with self.subTest(
                immediate=f"{immediate:08X}",
                destination=f"{destination:08X}",
                start_address=f"{start_address:08X}",
            ):
                model = Tms34020Model()
                model.load_program(
                    [0x0B60, encoded & 0xFFFF, encoded >> 16],
                    bit_address=start_address,
                )
                model.state.write_reg("A", 0, destination)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 0), destination)
                self.assertEqual(event.register_writes, [])
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.mnemonic, "CMPI.L")
                self.assertEqual(
                    event.instruction_words[1:],
                    [encoded & 0xFFFF, encoded >> 16],
                )
                self.assertEqual(
                    event.machine_states,
                    2 if start_address == 0x10 else 3,
                )

    def test_cmpi_long_reads_shared_sp_without_modifying_it(self) -> None:
        immediate = 2
        encoded = (~immediate) & 0xFFFF_FFFF
        model = Tms34020Model()
        model.load_program(
            [0x0B7F, encoded & 0xFFFF, encoded >> 16],
            bit_address=0x10,
        )
        model.state.sp = 1
        event = model.step()
        self.assertEqual(model.state.sp, 1)
        self.assertEqual(event.register_writes, [])
        self.assertEqual((model.state.st >> 28) & 0xF, 0b1100)

    def test_logical_primary_examples_and_only_z_changes(self) -> None:
        cases = (
            (0x5000, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF),
            (0x5000, 0xFFFFFFFF, 0x00000000, 0x00000000),
            (0x5000, 0x00000000, 0x00000000, 0x00000000),
            (0x5000, 0xAAAAAAAA, 0x55555555, 0x00000000),
            (0x5000, 0xAAAAAAAA, 0xAAAAAAAA, 0xAAAAAAAA),
            (0x5000, 0x55555555, 0x55555555, 0x55555555),
            (0x5000, 0x55555555, 0xAAAAAAAA, 0x00000000),
            (0x5200, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000),
            (0x5200, 0xFFFFFFFF, 0x00000000, 0x00000000),
            (0x5200, 0x00000000, 0x00000000, 0x00000000),
            (0x5200, 0xAAAAAAAA, 0x55555555, 0x55555555),
            (0x5200, 0xAAAAAAAA, 0xAAAAAAAA, 0x00000000),
            (0x5200, 0x55555555, 0x55555555, 0x00000000),
            (0x5200, 0x55555555, 0xAAAAAAAA, 0xAAAAAAAA),
            (0x5400, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF),
            (0x5400, 0x00000000, 0xFFFFFFFF, 0xFFFFFFFF),
            (0x5400, 0x55555555, 0xAAAAAAAA, 0xFFFFFFFF),
            (0x5400, 0x00000000, 0x00000000, 0x00000000),
            (0x5600, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF),
            (0x5600, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555),
            (0x5600, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000),
        )
        for case_index, (
            opcode_base,
            source,
            destination,
            expected,
        ) in enumerate(cases):
            register_file = "B" if case_index & 1 else "A"
            file_bit = 0x10 if register_file == "B" else 0
            opcode = opcode_base | 0x20 | file_bit
            with self.subTest(
                opcode=f"{opcode:04X}",
                source=f"{source:08X}",
                destination=f"{destination:08X}",
            ):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.write_reg(register_file, 1, source)
                model.state.write_reg(register_file, 0, destination)
                model.state.st = 0xD000_0010
                event = model.step()
                self.assertEqual(
                    model.state.read_reg(register_file, 0), expected
                )
                self.assertEqual(
                    (model.state.st >> 29) & 1, int(expected == 0)
                )
                self.assertEqual(
                    model.state.st & 0xD000_0000, 0xD000_0000
                )
                self.assertEqual(event.machine_states, 1)

    def test_immediate_logical_primary_examples_flags_and_alignment(self) -> None:
        cases = (
            (0x0B80, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000),
            (0x0B80, 0xFFFFFFFF, 0x00000000, 0x00000000),
            (0x0B80, 0x00000000, 0x00000000, 0x00000000),
            (0x0B80, 0xAAAAAAAA, 0x55555555, 0x55555555),
            (0x0B80, 0xAAAAAAAA, 0xAAAAAAAA, 0x00000000),
            (0x0B80, 0x55555555, 0x55555555, 0x00000000),
            (0x0B80, 0x55555555, 0xAAAAAAAA, 0xAAAAAAAA),
            (0x0BA0, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF),
            (0x0BA0, 0x00000000, 0xFFFFFFFF, 0xFFFFFFFF),
            (0x0BA0, 0xAAAAAAAA, 0x55555555, 0xFFFFFFFF),
            (0x0BA0, 0x00000000, 0x00000000, 0x00000000),
            (0x0BC0, 0xFFFFFFFF, 0x00000000, 0xFFFFFFFF),
            (0x0BC0, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555),
            (0x0BC0, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000),
            (0x0BC0, 0x00000000, 0x00000000, 0x00000000),
            (0x0BC0, 0x00000000, 0xFFFFFFFF, 0xFFFFFFFF),
        )
        for case_index, (
            opcode_base,
            immediate,
            destination,
            expected,
        ) in enumerate(cases):
            register_file = "B" if case_index & 1 else "A"
            file_bit = 0x10 if register_file == "B" else 0
            start_address = 0x10 if case_index & 2 else 0
            expected_states = 2 if start_address == 0x10 else 3
            with self.subTest(
                opcode=f"{opcode_base | file_bit:04X}",
                immediate=f"{immediate:08X}",
                destination=f"{destination:08X}",
            ):
                model = Tms34020Model()
                model.load_program(
                    [
                        opcode_base | file_bit,
                        immediate & 0xFFFF,
                        immediate >> 16,
                    ],
                    bit_address=start_address,
                )
                model.state.write_reg(register_file, 0, destination)
                model.state.st = 0xD000_0010
                event = model.step()
                self.assertEqual(
                    model.state.read_reg(register_file, 0), expected
                )
                self.assertEqual(
                    (model.state.st >> 29) & 1, int(expected == 0)
                )
                self.assertEqual(
                    model.state.st & 0xD000_0000, 0xD000_0000
                )
                self.assertEqual(event.machine_states, expected_states)

    def test_andi_alias_encodes_complement_for_andni_execution(self) -> None:
        requested_and_immediate = 0x0F0F_F0F0
        encoded_andni_immediate = (~requested_and_immediate) & 0xFFFF_FFFF
        model = Tms34020Model()
        model.load_program([
            0x0B80,
            encoded_andni_immediate & 0xFFFF,
            encoded_andni_immediate >> 16,
        ])
        model.state.write_reg("A", 0, 0xFFFF_00FF)
        event = model.step()
        self.assertEqual(model.state.read_reg("A", 0), 0x0F0F_00F0)
        self.assertEqual(event.mnemonic, "ANDNI")

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
            [
                transaction
                for transaction in event.transactions
                if transaction["class"] == "internal_io_write"
            ],
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

    def test_lmo_primary_examples_and_only_updates_z(self) -> None:
        cases = (
            (0x00000000, 0x00000000, 1),
            (0x00000001, 0x0000001F, 0),
            (0x00000010, 0x0000001B, 0),
            (0x08000000, 0x00000004, 0),
            (0x80000000, 0x00000000, 0),
        )
        for source, expected, expected_z in cases:
            with self.subTest(source=f"{source:08X}"):
                model = Tms34020Model()
                model.load_program([0x6A01])
                model.state.write_reg("A", 0, source)
                model.state.write_reg("A", 1, 0xDEAD_BEEF)
                model.state.st = 0xD123_4567
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 29) & 1, expected_z
                )
                self.assertEqual(
                    model.state.st & 0xDFFF_FFFF,
                    0xD123_4567,
                )
                self.assertEqual(event.machine_states, 1)

    def test_lmo_same_register_b_file_and_shared_sp_hazards(self) -> None:
        model = Tms34020Model()
        model.load_program([0x6A00, 0x6A53, 0x6BF4, 0x6A5F])
        model.state.write_reg("A", 0, 0x00000010)
        model.state.write_reg("B", 2, 0x00000010)
        model.state.sp = 0x80000000

        same_register = model.step()
        self.assertEqual(model.state.read_reg("A", 0), 27)
        self.assertEqual(same_register.machine_states, 1)

        b_file = model.step()
        self.assertEqual(model.state.read_reg("B", 3), 27)

        sp_source = model.step()
        self.assertEqual(model.state.read_reg("B", 4), 0)
        self.assertEqual(model.state.sp, 0x80000000)

        sp_destination = model.step()
        self.assertEqual(model.state.sp, 27)

    def test_mwait_consumes_abstract_pending_write_states(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0080])
        model.state.pending_write_states = 2
        event = model.step()
        self.assertEqual(event.machine_states, 3)
        self.assertEqual(model.state.pending_write_states, 0)

    def test_setc_pitch_primary_conversion_rows(self) -> None:
        variants = (
            (0x0273, 3, CONVDP_ADDRESS),
            (0x02FB, 11, CONVMP_ADDRESS),
            (0x0251, 1, CONVSP_ADDRESS),
        )
        rows = (
            (0x0000_1000, 0x0013, 4),
            (0x0000_0400, 0x0015, 4),
            (0x0000_1400, 0x1513, 6),
            (0x0000_0019, 0x0000, 3),
        )
        for opcode, source_index, destination_address in variants:
            for pitch, conversion, machine_states in rows:
                with self.subTest(
                    opcode=f"{opcode:04X}",
                    pitch=f"{pitch:08X}",
                ):
                    model = Tms34020Model()
                    model.load_program([opcode])
                    model.state.write_reg("B", source_index, pitch)
                    model.state.st = 0xF020_001F
                    event = model.step()
                    self.assertEqual(
                        model.state.read_io(destination_address),
                        conversion,
                    )
                    self.assertEqual(event.machine_states, machine_states)
                    self.assertEqual(model.state.st, 0xF020_001F)
                    self.assertEqual(model.state.pending_write_states, 1)

    def test_setc_pitch_uses_each_implied_source_and_destination(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0251, 0x0273, 0x02FB])
        model.state.write_reg("B", 1, 0x0000_0400)
        model.state.write_reg("B", 3, 0x0000_1000)
        model.state.write_reg("B", 11, 0x0000_1400)
        events = [model.step(), model.step(), model.step()]
        self.assertEqual(model.state.read_io(CONVSP_ADDRESS), 0x0015)
        self.assertEqual(model.state.read_io(CONVDP_ADDRESS), 0x0013)
        self.assertEqual(model.state.read_io(CONVMP_ADDRESS), 0x1513)
        self.assertEqual(
            [event.machine_states for event in events],
            [4, 4, 6],
        )
        self.assertEqual(
            [
                event.transactions[-1]["bit_address"]
                for event in events
            ],
            [CONVSP_ADDRESS, CONVDP_ADDRESS, CONVMP_ADDRESS],
        )

    def test_setc_pitch_conversion_encoding_boundaries(self) -> None:
        cases = (
            (0x0000_0001, 0x001F, 4),
            (0x0000_0005, 0x1F1D, 6),
            (0x0000_0000, 0x0000, 3),
            (0x8000_0000, 0x0000, 3),
        )
        for pitch, conversion, machine_states in cases:
            with self.subTest(pitch=f"{pitch:08X}"):
                model = Tms34020Model()
                model.load_program([0x0273])
                model.state.write_reg("B", 3, pitch)
                event = model.step()
                self.assertEqual(
                    model.state.read_io(CONVDP_ADDRESS),
                    conversion,
                )
                self.assertEqual(event.machine_states, machine_states)
                self.assertEqual(
                    event.transactions[-1],
                    {
                        "class": "internal_io_write",
                        "bit_address": CONVDP_ADDRESS,
                        "width": 16,
                        "value": conversion,
                    },
                )
                self.assertIn("hidden conversion-register", event.notes[-1])

    def test_vlcol_successful_special_cycle_contract(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0A00])
        model.state.write_reg("B", 9, 0xA5C3_5A3C)
        model.state.write_io(PSIZE_ADDRESS, 3)
        model.state.st = 0xF020_001F
        event = model.step()
        self.assertEqual(model.state.vram_color_latch, 0xA5C3_5A3C)
        self.assertEqual(model.state.st, 0xF020_001F)
        self.assertEqual(event.machine_states, 2)
        self.assertEqual(model.state.pending_write_states, 1)
        self.assertEqual(
            event.transactions[-1],
            {
                "class": "special_vram_color_load",
                "bit_address": 0,
                "width": 32,
                "value": 0xA5C3_5A3C,
                "status_code": 0b0111,
            },
        )
        self.assertIn("fault/retry pending", event.notes[-1])

    def test_vlcol_uses_full_color1_and_replaces_external_latch(self) -> None:
        for color in (0, 1, 0xFFFF_0000, 0xFFFF_FFFF):
            with self.subTest(color=f"{color:08X}"):
                model = Tms34020Model()
                model.load_program([0x0A00])
                model.state.vram_color_latch = 0x1234_5678
                model.state.write_reg("B", 9, color)
                event = model.step()
                self.assertEqual(model.state.vram_color_latch, color)
                self.assertEqual(event.register_writes, [])

    def test_trapl_primary_vector_examples_and_stack_frame(self) -> None:
        fixtures = (
            (-1, 0x0000_0000, 0xFF0F_0000),
            (0, 0xFFFF_FFE0, 0xFFA0_0000),
            (31, 0xFFFF_FC00, 0xFFE0_0000),
            (33, 0xFFFF_FBC0, 0xFF0E_0000),
        )
        for trap_number, vector_address, target in fixtures:
            with self.subTest(trap_number=trap_number):
                model = Tms34020Model()
                model.load_program(
                    [0x080F, trap_number & 0xFFFF],
                    bit_address=0x0000_1000,
                )
                model.state.sp = 0x8000_0000
                model.state.st = 0xF123_4567
                model.state.memory.write_bits(vector_address, 32, target)
                event = model.step()

                self.assertEqual(model.state.pc, target)
                self.assertEqual(model.state.st, 0x0000_0010)
                self.assertEqual(model.state.sp, 0x7FFF_FFC0)
                self.assertEqual(
                    model.state.memory.read_bits(0x7FFF_FFE0, 32),
                    0x0000_1020,
                )
                self.assertEqual(
                    model.state.memory.read_bits(0x7FFF_FFC0, 32),
                    0xF123_4567,
                )
                self.assertEqual(event.machine_states, 10)
                self.assertEqual(event.next_pc, target)
                self.assertEqual(
                    event.transactions[-1],
                    {
                        "class": "interrupt_vector_fetch",
                        "bit_address": vector_address,
                        "width": 32,
                        "value": target,
                    },
                )
                self.assertIn("fault and retry pending", event.notes[-1])

    def test_trapl_signed_extremes_alignment_and_pc_mask(self) -> None:
        fixtures = (
            (-32768, 0x000F_FFE0),
            (-1, 0x0000_0000),
            (0, 0xFFFF_FFE0),
            (1, 0xFFFF_FFC0),
            (32767, 0xFFF0_0000),
        )
        for trap_number, vector_address in fixtures:
            with self.subTest(trap_number=trap_number):
                model = Tms34020Model()
                model.load_program(
                    [0x080F, trap_number & 0xFFFF],
                    bit_address=0x0000_1000,
                )
                model.state.sp = 0x8000_0007
                model.state.st = 0xFFFF_FFFF
                model.state.memory.write_bits(
                    vector_address, 32, 0x1234_567F
                )
                event = model.step()

                self.assertEqual(model.state.pc, 0x1234_5670)
                self.assertEqual(model.state.sp, 0x7FFF_FFC7)
                self.assertEqual(event.machine_states, 12)
                writes = [
                    transaction
                    for transaction in event.transactions
                    if transaction["class"] == "data_write"
                ]
                self.assertEqual(
                    writes,
                    [
                        {
                            "class": "data_write",
                            "purpose": "trap_return_pc",
                            "bit_address": 0x7FFF_FFE7,
                            "width": 32,
                            "value": 0x0000_1020,
                        },
                        {
                            "class": "data_write",
                            "purpose": "trap_saved_st",
                            "bit_address": 0x7FFF_FFC7,
                            "width": 32,
                            "value": 0xFFFF_FFFF,
                        },
                    ],
                )

    def test_blmove_all_modes_successful_boundary(self) -> None:
        fixtures = (
            (0x00F0, 0x0000_0400, 0x0000_0800, 0, 0),
            (0x00F1, 0x0000_0400, 0x0000_0805, 0, 1),
            (0x00F2, 0x0000_0403, 0x0000_0800, 1, 0),
            (0x00F3, 0x0000_0403, 0x0000_0805, 1, 1),
        )
        chunks = ((32, 0x89AB_CDEF), (32, 0x1357_9BDF), (1, 1))
        for (
            opcode,
            source,
            destination,
            source_mode,
            destination_mode,
        ) in fixtures:
            with self.subTest(opcode=f"{opcode:04X}"):
                model = Tms34020Model()
                model.load_program([opcode], bit_address=0x2000)
                offset = 0
                for width, value in chunks:
                    model.state.memory.write_bits(
                        source + offset, width, value
                    )
                    offset += width
                model.state.memory.write_bits(destination - 1, 1, 1)
                model.state.memory.write_bits(destination + 65, 1, 1)
                model.state.write_reg("B", 0, source)
                model.state.write_reg("B", 2, destination)
                model.state.write_reg("B", 7, 65)
                model.state.st = 0xF123_4567
                event = model.step()

                offset = 0
                for width, value in chunks:
                    self.assertEqual(
                        model.state.memory.read_bits(
                            destination + offset, width
                        ),
                        value,
                    )
                    offset += width
                self.assertEqual(
                    model.state.memory.read_bits(destination - 1, 1), 1
                )
                self.assertEqual(
                    model.state.memory.read_bits(destination + 65, 1), 1
                )
                self.assertEqual(
                    model.state.read_reg("B", 0), source + 65
                )
                self.assertEqual(
                    model.state.read_reg("B", 2), destination + 65
                )
                self.assertEqual(model.state.read_reg("B", 7), 0)
                self.assertEqual(model.state.st, 0xF123_4567)
                self.assertIsNone(event.machine_states)
                self.assertFalse(model.state.timing_complete)
                self.assertEqual(
                    event.transactions[-1],
                    {
                        "class": "abstract_block_move",
                        "source_bit_address": source,
                        "destination_bit_address": destination,
                        "width": 65,
                        "source_unaligned_mode": source_mode,
                        "destination_unaligned_mode": destination_mode,
                    },
                )

    def test_blmove_alignment_guards_roll_back(self) -> None:
        fixtures = (
            (0x00F0, 0x0000_0401, 0x0000_0800),
            (0x00F0, 0x0000_0400, 0x0000_0801),
            (0x00F1, 0x0000_0401, 0x0000_0801),
            (0x00F2, 0x0000_0401, 0x0000_0801),
        )
        for opcode, source, destination in fixtures:
            with self.subTest(opcode=f"{opcode:04X}"):
                model = Tms34020Model()
                model.load_program([opcode], bit_address=0x2000)
                model.state.write_reg("B", 0, source)
                model.state.write_reg("B", 2, destination)
                model.state.write_reg("B", 7, 32)
                before = model.snapshot()
                with self.assertRaises(ModelError):
                    model.step()
                self.assertEqual(model.snapshot(), before)

    def test_blmove_overlap_guard_is_not_silicon_behavior(self) -> None:
        model = Tms34020Model()
        model.load_program([0x00F3], bit_address=0x2000)
        model.state.write_reg("B", 0, 0x400)
        model.state.write_reg("B", 2, 0x410)
        model.state.write_reg("B", 7, 32)
        before = model.snapshot()
        with self.assertRaises(ModelError):
            model.step()
        self.assertEqual(model.snapshot(), before)

    def test_blmove_zero_self_and_wrapping_ranges(self) -> None:
        zero = Tms34020Model()
        zero.load_program([0x00F3], bit_address=0x2000)
        zero.state.write_reg("B", 0, 0x401)
        zero.state.write_reg("B", 2, 0x801)
        event = zero.step()
        self.assertEqual(zero.state.read_reg("B", 0), 0x401)
        self.assertEqual(zero.state.read_reg("B", 2), 0x801)
        self.assertEqual(zero.state.read_reg("B", 7), 0)
        self.assertEqual(event.transactions[-1]["width"], 0)

        same = Tms34020Model()
        same.load_program([0x00F3], bit_address=0x2000)
        same.state.memory.write_bits(0x403, 32, 0xA5C3_5A3C)
        same.state.write_reg("B", 0, 0x403)
        same.state.write_reg("B", 2, 0x403)
        same.state.write_reg("B", 7, 32)
        same.step()
        self.assertEqual(
            same.state.memory.read_bits(0x403, 32), 0xA5C3_5A3C
        )
        self.assertEqual(same.state.read_reg("B", 0), 0x423)
        self.assertEqual(same.state.read_reg("B", 2), 0x423)

        wrapping = Tms34020Model()
        wrapping.load_program([0x00F3], bit_address=0x2000)
        wrapping.state.memory.write_bits(
            0xFFFF_FFF0, 32, 0xC35A_A53C
        )
        wrapping.state.write_reg("B", 0, 0xFFFF_FFF0)
        wrapping.state.write_reg("B", 2, 0x100)
        wrapping.state.write_reg("B", 7, 32)
        wrapping.step()
        self.assertEqual(
            wrapping.state.memory.read_bits(0x100, 32), 0xC35A_A53C
        )
        self.assertEqual(wrapping.state.read_reg("B", 0), 0x10)
        self.assertEqual(wrapping.state.read_reg("B", 2), 0x120)

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

    def test_unclassified_instruction_does_not_advance(self) -> None:
        model = Tms34020Model()
        model.load_program([0x0000], bit_address=0x80)
        before = model.snapshot()
        with self.assertRaises(UnclassifiedEncoding):
            model.step()
        self.assertEqual(model.snapshot(), before)

    def test_putst_primary_full_status_copy_and_timing(self) -> None:
        model = Tms34020Model()
        model.load_program([0x01A0], bit_address=0x80)
        model.state.st = 0xF000_0FFF
        model.state.write_reg("A", 0, 0x0000_0010)

        event = model.step()

        self.assertEqual(model.state.st, 0x0000_0010)
        self.assertEqual(model.state.read_reg("A", 0), 0x0000_0010)
        self.assertEqual(event.mnemonic, "PUTST")
        self.assertEqual(event.machine_states, 3)
        self.assertEqual(event.status_before, 0xF000_0FFF)
        self.assertEqual(event.status_after, 0x0000_0010)
        self.assertEqual(event.register_writes, [])

    def test_putst_all_files_indices_and_full_width_values(self) -> None:
        values = (0x0000_0000, 0xFFFF_FFFF, 0xA5C3_5A3C)
        for register_file, file_bit in (("A", 0), ("B", 1)):
            for source_index in (0, 14, 15):
                for value in values:
                    with self.subTest(
                        register_file=register_file,
                        source_index=source_index,
                        value=f"{value:08X}",
                    ):
                        opcode = 0x01A0 | (file_bit << 4) | source_index
                        model = Tms34020Model()
                        model.load_program([opcode], bit_address=0x80)
                        model.state.st = 0x1234_5678
                        model.state.write_reg(
                            register_file, source_index, value
                        )

                        event = model.step()

                        self.assertEqual(model.state.st, value)
                        self.assertEqual(
                            model.state.read_reg(
                                register_file, source_index
                            ),
                            value,
                        )
                        self.assertEqual(event.machine_states, 3)
                        self.assertEqual(event.register_writes, [])
                        if source_index == 15:
                            other_file = (
                                "B" if register_file == "A" else "A"
                            )
                            self.assertEqual(
                                model.state.read_reg(other_file, 15),
                                value,
                            )

    def test_popst_aligned_read_replaces_status_then_increments_sp(self) -> None:
        model = Tms34020Model()
        model.load_program([0x01C0], bit_address=0x80)
        model.state.st = 0xA5C3_5A3C
        model.state.sp = 0x0000_0400
        model.state.memory.write_bits(0x0000_0400, 32, 0xC000_0010)

        event = model.step()

        self.assertEqual(model.state.st, 0xC000_0010)
        self.assertEqual(model.state.sp, 0x0000_0420)
        self.assertEqual(
            model.state.memory.read_bits(0x0000_0400, 32),
            0xC000_0010,
        )
        self.assertEqual(event.machine_states, 6)
        self.assertEqual(event.status_before, 0xA5C3_5A3C)
        self.assertEqual(event.status_after, 0xC000_0010)
        self.assertEqual(
            event.transactions[-1],
            {
                "class": "data_read",
                "purpose": "pop_status",
                "bit_address": 0x0000_0400,
                "width": 32,
                "value": 0xC000_0010,
            },
        )
        self.assertEqual(
            event.register_writes,
            [{
                "file": "SP",
                "index": 15,
                "old": 0x0000_0400,
                "new": 0x0000_0420,
            }],
        )
        self.assertIn("fault, retry", event.notes[-1])

    def test_jump_primary_examples_align_register_target(self) -> None:
        for source, expected_pc in (
            (0x0000_1EE0, 0x0000_1EE0),
            (0x0000_1EE5, 0x0000_1EE0),
            (0xFFFF_FFFF, 0xFFFF_FFF0),
        ):
            with self.subTest(source=f"{source:08X}"):
                model = Tms34020Model()
                model.load_program([0x0161], bit_address=0x0055_5550)
                model.state.write_reg("A", 1, source)
                model.state.st = 0xA5C3_5A3C

                event = model.step()

                self.assertEqual(model.state.pc, expected_pc)
                self.assertEqual(model.state.read_reg("A", 1), source)
                self.assertEqual(model.state.st, 0xA5C3_5A3C)
                self.assertEqual(event.next_pc, expected_pc)
                self.assertEqual(event.machine_states, 2)
                self.assertEqual(event.register_writes, [])

    def test_jump_all_files_and_shared_sp_preserve_source(self) -> None:
        for register_file, file_bit in (("A", 0), ("B", 1)):
            for source_index in (0, 14, 15):
                with self.subTest(
                    register_file=register_file,
                    source_index=source_index,
                ):
                    opcode = 0x0160 | (file_bit << 4) | source_index
                    model = Tms34020Model()
                    model.load_program([opcode], bit_address=0x80)
                    model.state.write_reg(
                        register_file, source_index, 0x1234_567F
                    )

                    event = model.step()

                    self.assertEqual(model.state.pc, 0x1234_5670)
                    self.assertEqual(
                        model.state.read_reg(register_file, source_index),
                        0x1234_567F,
                    )
                    self.assertEqual(event.machine_states, 2)
                    self.assertEqual(event.register_writes, [])

    def test_popst_unaligned_read_crosses_address_wrap(self) -> None:
        model = Tms34020Model()
        model.load_program([0x01C0], bit_address=0x80)
        model.state.st = 0xFFFF_FFFF
        model.state.sp = 0xFFFF_FFF7
        model.state.memory.write_bits(0xFFFF_FFF7, 32, 0x1234_5678)

        event = model.step()

        self.assertEqual(model.state.st, 0x1234_5678)
        self.assertEqual(model.state.sp, 0x0000_0017)
        self.assertEqual(event.machine_states, 7)
        self.assertEqual(event.transactions[-1]["bit_address"], 0xFFFF_FFF7)
        self.assertEqual(model.state.pending_write_states, 0)

    def test_pushst_aligned_predecrements_and_tracks_hidden_write(self) -> None:
        model = Tms34020Model()
        model.load_program([0x01E0], bit_address=0x80)
        model.state.st = 0xA5C3_5A3C
        model.state.sp = 0x0000_0420

        event = model.step()

        self.assertEqual(model.state.st, 0xA5C3_5A3C)
        self.assertEqual(model.state.sp, 0x0000_0400)
        self.assertEqual(
            model.state.memory.read_bits(0x0000_0400, 32),
            0xA5C3_5A3C,
        )
        self.assertEqual(event.machine_states, 2)
        self.assertEqual(model.state.pending_write_states, 1)
        self.assertEqual(
            event.transactions[-1],
            {
                "class": "data_write",
                "purpose": "push_status",
                "bit_address": 0x0000_0400,
                "width": 32,
                "value": 0xA5C3_5A3C,
            },
        )
        self.assertEqual(
            event.register_writes,
            [{
                "file": "SP",
                "index": 15,
                "old": 0x0000_0420,
                "new": 0x0000_0400,
            }],
        )
        self.assertIn("fault, retry", event.notes[-1])

    def test_pushst_popst_unaligned_round_trip_and_hidden_overlap(self) -> None:
        model = Tms34020Model()
        model.load_program([0x01E0, 0x01C0], bit_address=0x80)
        model.state.st = 0xFFFF_FFFF
        model.state.sp = 0x0000_0010

        pushed = model.step()
        self.assertEqual(model.state.sp, 0xFFFF_FFF0)
        self.assertEqual(
            model.state.memory.read_bits(0xFFFF_FFF0, 32),
            0xFFFF_FFFF,
        )
        self.assertEqual(pushed.machine_states, 2)
        self.assertEqual(model.state.pending_write_states, 2)

        model.state.st = 0x0000_0010
        popped = model.step()

        self.assertEqual(model.state.st, 0xFFFF_FFFF)
        self.assertEqual(model.state.sp, 0x0000_0010)
        self.assertEqual(popped.machine_states, 7)
        self.assertEqual(model.state.pending_write_states, 0)

    def test_exgf_primary_examples(self) -> None:
        for field_bank, opcode, expected_status in (
            (0, 0xD505, 0xF000_0FC0),
            (1, 0xD705, 0xF000_003F),
        ):
            with self.subTest(field_bank=field_bank):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.st = 0xF000_0FFF
                model.state.write_reg("A", 5, 0xFFFF_FFC0)
                event = model.step()
                self.assertEqual(model.state.read_reg("A", 5), 0x3F)
                self.assertEqual(model.state.st, expected_status)
                self.assertEqual(event.mnemonic, "EXGF")
                self.assertEqual(event.machine_states, field_bank + 1)

    def test_exgf_all_banks_files_and_shared_sp(self) -> None:
        initial_status = 0xB5A3_4A95
        for field_bank in (0, 1):
            for register_file, file_bit in (("A", 0), ("B", 1)):
                for destination in (0, 14, 15):
                    with self.subTest(
                        field_bank=field_bank,
                        register_file=register_file,
                        destination=destination,
                    ):
                        opcode = (
                            0xD500
                            | (field_bank << 9)
                            | (file_bit << 4)
                            | destination
                        )
                        register_before = (
                            0xA5C3_5A00
                            | (field_bank << 5)
                            | (file_bit << 4)
                            | destination
                        )
                        shift = field_bank * 6
                        mask = 0x3F << shift
                        expected_register = (
                            initial_status >> shift
                        ) & 0x3F
                        expected_status = (
                            (initial_status & ~mask)
                            | ((register_before & 0x3F) << shift)
                        )

                        model = Tms34020Model()
                        model.load_program([opcode])
                        model.state.st = initial_status
                        model.state.write_reg(
                            register_file,
                            destination,
                            register_before,
                        )
                        event = model.step()
                        self.assertEqual(
                            model.state.read_reg(
                                register_file, destination
                            ),
                            expected_register,
                        )
                        self.assertEqual(model.state.st, expected_status)
                        self.assertEqual(
                            event.machine_states, field_bank + 1
                        )
                        if destination == 15:
                            other_file = (
                                "B" if register_file == "A" else "A"
                            )
                            self.assertEqual(
                                model.state.read_reg(other_file, 15),
                                expected_register,
                            )

    def test_setf_primary_rows_and_masked_status_banks(self) -> None:
        cases = (
            (0x0540, 0, 0x00),
            (0x0560, 0, 0x20),
            (0x057F, 0, 0x3F),
            (0x0550, 0, 0x10),
            (0x0740, 1, 0x00),
            (0x0760, 1, 0x20),
            (0x077F, 1, 0x3F),
            (0x0750, 1, 0x10),
        )
        for opcode, bank, parameters in cases:
            with self.subTest(opcode=f"{opcode:04X}"):
                model = Tms34020Model()
                model.load_program([opcode])
                initial_st = 0xF123_4A55
                model.state.st = initial_st
                event = model.step()
                shift = bank * 6
                mask = 0x3F << shift
                expected_st = (
                    (initial_st & ~mask) | (parameters << shift)
                )
                self.assertEqual(model.state.st, expected_st)
                self.assertEqual(event.mnemonic, "SETF")
                self.assertEqual(event.machine_states, 1)
                self.assertEqual(event.register_writes, [])

    def test_sext_primary_rows_status_and_register_files(self) -> None:
        cases = (
            (17, 0x0000_8000, 0x0000_8000, 0, 0),
            (16, 0x0000_8000, 0xFFFF_8000, 1, 0),
            (15, 0x0000_8000, 0x0000_0000, 0, 1),
        )
        for bank in (0, 1):
            for width, before, expected, expected_n, expected_z in cases:
                with self.subTest(bank=bank, width=width):
                    model = Tms34020Model()
                    register_file = "B" if bank else "A"
                    opcode = 0x0502 | (bank << 9) | (bank << 4)
                    model.load_program([opcode])
                    model.state.write_reg(register_file, 2, before)
                    initial_st = status_with_field_size(
                        0x7123_4A55, bank, width
                    )
                    model.state.st = initial_st
                    event = model.step()
                    expected_st = initial_st & ~0xA000_0000
                    expected_st |= expected_n << 31
                    expected_st |= expected_z << 29
                    self.assertEqual(
                        model.state.read_reg(register_file, 2), expected
                    )
                    self.assertEqual(model.state.st, expected_st)
                    self.assertEqual(event.mnemonic, "SEXT")
                    self.assertEqual(event.machine_states, 2)

    def test_zext_primary_rows_status_and_register_files(self) -> None:
        cases = (
            (32, 0xFFFF_FFFF, 0xFFFF_FFFF, 0),
            (31, 0xFFFF_FFFF, 0x7FFF_FFFF, 0),
            (1, 0xFFFF_FFFF, 0x0000_0001, 0),
            (16, 0xFFFF_0000, 0x0000_0000, 1),
        )
        for bank in (0, 1):
            for width, before, expected, expected_z in cases:
                with self.subTest(bank=bank, width=width):
                    model = Tms34020Model()
                    register_file = "B" if bank else "A"
                    opcode = 0x0523 | (bank << 9) | (bank << 4)
                    model.load_program([opcode])
                    model.state.write_reg(register_file, 3, before)
                    initial_st = status_with_field_size(
                        0xD123_4A55, bank, width
                    )
                    model.state.st = initial_st
                    event = model.step()
                    expected_st = initial_st & ~0x2000_0000
                    expected_st |= expected_z << 29
                    self.assertEqual(
                        model.state.read_reg(register_file, 3), expected
                    )
                    self.assertEqual(model.state.st, expected_st)
                    self.assertEqual(event.mnemonic, "ZEXT")
                    self.assertEqual(event.machine_states, 1)

    def test_field_extensions_all_sizes_banks_and_shared_sp(self) -> None:
        for bank in (0, 1):
            for width in range(1, 33):
                with self.subTest(bank=bank, width=width):
                    mask = (
                        0xFFFF_FFFF
                        if width == 32
                        else (1 << width) - 1
                    )
                    value = (0xA5A5_5A5A & mask) | (1 << (width - 1))
                    expected_zero = value & mask
                    expected_sign = expected_zero
                    if width < 32:
                        expected_sign |= 0xFFFF_FFFF ^ mask

                    for base, expected, states in (
                        (0x0500, expected_sign, 2),
                        (0x0520, expected_zero, 1),
                    ):
                        model = Tms34020Model()
                        opcode = base | (bank << 9) | 4
                        model.load_program([opcode])
                        model.state.write_reg("A", 4, value)
                        initial_st = status_with_field_size(
                            0x5123_4A55, bank, width
                        )
                        model.state.st = initial_st
                        event = model.step()
                        self.assertEqual(
                            model.state.read_reg("A", 4), expected
                        )
                        expected_st = (
                            initial_st | 0x8000_0000
                            if base == 0x0500
                            else initial_st
                        )
                        self.assertEqual(model.state.st, expected_st)
                        self.assertEqual(event.machine_states, states)

        sign_sp = Tms34020Model()
        sign_sp.load_program([0x051F])
        sign_sp.state.sp = 0x0000_0080
        sign_sp.state.st = status_with_field_size(0x4000_0000, 0, 8)
        sign_event = sign_sp.step()
        self.assertEqual(sign_sp.state.sp, 0xFFFF_FF80)
        self.assertEqual(
            sign_event.register_writes[0],
            {
                "file": "SP",
                "index": 15,
                "old": 0x0000_0080,
                "new": 0xFFFF_FF80,
            },
        )

        zero_sp = Tms34020Model()
        zero_sp.load_program([0x072F])
        zero_sp.state.sp = 0xFFFF_FF80
        zero_sp.state.st = status_with_field_size(0x8000_0000, 1, 8)
        zero_event = zero_sp.step()
        self.assertEqual(zero_sp.state.sp, 0x0000_0080)
        self.assertEqual(
            zero_event.register_writes[0],
            {
                "file": "SP",
                "index": 15,
                "old": 0xFFFF_FF80,
                "new": 0x0000_0080,
            },
        )

    def test_btst_constant_primary_examples(self) -> None:
        cases = (
            (0, 0x5555_5555, 0),
            (15, 0x5555_5555, 1),
            (31, 0x5555_5555, 1),
            (0, 0xAAAA_AAAA, 1),
            (15, 0xAAAA_AAAA, 0),
            (31, 0xAAAA_AAAA, 0),
            (0, 0xFFFF_FFFF, 0),
            (15, 0xFFFF_FFFF, 0),
            (31, 0xFFFF_FFFF, 0),
            (0, 0x0000_0000, 1),
            (15, 0x0000_0000, 1),
            (31, 0x0000_0000, 1),
        )
        for bit_index, destination, expected_z in cases:
            with self.subTest(
                bit_index=bit_index, destination=f"{destination:08X}"
            ):
                model = Tms34020Model()
                encoded_bit = (~bit_index) & 0x1F
                model.load_program([0x1C00 | (encoded_bit << 5)])
                model.state.write_reg("A", 0, destination)
                initial_st = (
                    0xD020_001F if expected_z else 0xF020_001F
                )
                model.state.st = initial_st
                event = model.step()
                expected_st = (
                    (initial_st & ~(1 << 29)) | (expected_z << 29)
                )
                self.assertEqual(model.state.st, expected_st)
                self.assertEqual(model.state.read_reg("A", 0), destination)
                self.assertEqual(event.register_writes, [])
                self.assertEqual(event.machine_states, 1)
                self.assertEqual(event.mnemonic, "BTST.K")

    def test_btst_register_primary_examples(self) -> None:
        cases = (
            (0x0000_0000, 0x5555_5555, 0),
            (0x0000_000F, 0x5555_5555, 1),
            (0x0000_001F, 0x5555_5555, 1),
            (0x0000_0000, 0xAAAA_AAAA, 1),
            (0x0000_000F, 0xAAAA_AAAA, 0),
            (0x0000_001F, 0xAAAA_AAAA, 0),
            (0xFFFF_FF8F, 0xFFFF_7FFF, 1),
            (0x0000_0000, 0xFFFF_FFFF, 0),
            (0x0000_000F, 0xFFFF_FFFF, 0),
            (0x0000_001F, 0xFFFF_FFFF, 0),
            (0x0000_0000, 0x0000_0000, 1),
            (0x0000_000F, 0x0000_0000, 1),
            (0x0000_001F, 0x0000_0000, 1),
        )
        for source, destination, expected_z in cases:
            with self.subTest(
                source=f"{source:08X}", destination=f"{destination:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0x4A20])
                model.state.write_reg("A", 1, source)
                model.state.write_reg("A", 0, destination)
                initial_st = (
                    0xD020_001F if expected_z else 0xF020_001F
                )
                model.state.st = initial_st
                event = model.step()
                expected_st = (
                    (initial_st & ~(1 << 29)) | (expected_z << 29)
                )
                self.assertEqual(model.state.st, expected_st)
                self.assertEqual(model.state.read_reg("A", 1), source)
                self.assertEqual(model.state.read_reg("A", 0), destination)
                self.assertEqual(event.register_writes, [])
                self.assertEqual(event.machine_states, 1)
                self.assertEqual(event.mnemonic, "BTST.R")

    def test_btst_register_files_same_register_and_shared_sp(self) -> None:
        cases = (
            (0x4A30, "B", 1, 0xFFFF_FFEF, "B", 0, 0x0000_8000, 0),
            (0x4A42, "A", 2, 0x8000_001F, "A", 2, 0x8000_001F, 0),
            (0x4BF0, "B", 15, 0xFFFF_FFE4, "B", 0, 0x0000_0000, 1),
            (0x4A2F, "A", 1, 0x0000_0000, "A", 15, 0x0000_0001, 0),
        )
        for (
            opcode,
            source_file,
            source_index,
            source_value,
            destination_file,
            destination_index,
            destination_value,
            expected_z,
        ) in cases:
            with self.subTest(opcode=f"{opcode:04X}"):
                model = Tms34020Model()
                model.load_program([opcode])
                model.state.write_reg(
                    source_file, source_index, source_value
                )
                model.state.write_reg(
                    destination_file, destination_index, destination_value
                )
                before_state = model.state.snapshot()
                before_registers = (
                    before_state["a"],
                    before_state["b"],
                    before_state["sp"],
                )
                model.state.st = (
                    0xD020_001F if expected_z else 0xF020_001F
                )
                event = model.step()
                after_state = model.state.snapshot()
                self.assertEqual(
                    (
                        after_state["a"],
                        after_state["b"],
                        after_state["sp"],
                    ),
                    before_registers,
                )
                self.assertEqual((model.state.st >> 29) & 1, expected_z)
                self.assertEqual(event.register_writes, [])
                self.assertEqual(event.machine_states, 1)

        constant_sp = Tms34020Model()
        constant_sp.load_program([0x1C1F])
        constant_sp.state.sp = 0x7FFF_FFFF
        constant_sp.state.st = 0xD020_001F
        event = constant_sp.step()
        self.assertEqual(constant_sp.state.sp, 0x7FFF_FFFF)
        self.assertEqual(constant_sp.state.st, 0xF020_001F)
        self.assertEqual(event.register_writes, [])

    def test_sla_constant_primary_examples(self) -> None:
        cases = (
            (0, 0x3333_3333, 0x3333_3333, 0b0000),
            (0, 0xCCCC_CCCC, 0xCCCC_CCCC, 0b1000),
            (1, 0xCCCC_CCCC, 0x9999_9998, 0b1100),
            (2, 0x3333_3333, 0xCCCC_CCCC, 0b1001),
            (2, 0xCCCC_CCCC, 0x3333_3330, 0b0101),
            (3, 0xCCCC_CCCC, 0x6666_6660, 0b0001),
            (5, 0xCCCC_CCCC, 0x9999_9980, 0b1101),
            (30, 0xCCCC_CCCC, 0x0000_0000, 0b0111),
            (31, 0xCCCC_CCCC, 0x0000_0000, 0b0011),
            (31, 0x0000_0000, 0x0000_0000, 0b0010),
        )
        for count, before, expected, expected_nczv in cases:
            with self.subTest(count=count, before=f"{before:08X}"):
                model = Tms34020Model()
                model.load_program([0x2001 | (count << 5)])
                model.state.write_reg("A", 1, before)
                model.state.st = 0xF020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "SLA.K")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(
                    model.state.st & 0x0FFF_FFFF, 0x0020_0010
                )
                self.assertEqual(event.machine_states, 3)

    def test_sla_register_primary_examples(self) -> None:
        cases = (
            (0, 0x3333_3333, 0x3333_3333, 0b0000),
            (0, 0xCCCC_CCCC, 0xCCCC_CCCC, 0b1000),
            (1, 0xCCCC_CCCC, 0x9999_9998, 0b1100),
            (2, 0x3333_3333, 0xCCCC_CCCC, 0b1001),
            (2, 0xCCCC_CCCC, 0x3333_3330, 0b0101),
            (3, 0xCCCC_CCCC, 0x6666_6660, 0b0001),
            (5, 0xCCCC_CCCC, 0x9999_9980, 0b1101),
            (30, 0xCCCC_CCCC, 0x0000_0000, 0b0111),
            (31, 0xCCCC_CCCC, 0x0000_0000, 0b0011),
            (31, 0x0000_0000, 0x0000_0000, 0b0010),
        )
        for count_source, before, expected, expected_nczv in cases:
            with self.subTest(
                count=count_source, before=f"{before:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0x6001])
                model.state.write_reg("A", 0, count_source)
                model.state.write_reg("A", 1, before)
                event = model.step()
                self.assertEqual(event.mnemonic, "SLA.R")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 3)

    def test_sla_all_counts_match_iterative_overflow_oracle(self) -> None:
        values = (
            0x0000_0000,
            0xFFFF_FFFF,
            0x0000_0001,
            0x8000_0000,
            0x4000_0000,
            0x7FFF_FFFF,
            0xAAAA_AAAA,
            0x5555_5555,
            0x3333_3333,
            0xCCCC_CCCC,
            0x0123_4567,
            0x89AB_CDEF,
        )
        model = Tms34020Model()
        for count in range(32):
            for value in values:
                with self.subTest(count=count, value=f"{value:08X}"):
                    expected = value
                    original_sign = bool(value & 0x8000_0000)
                    expected_carry = False
                    expected_overflow = False
                    for _ in range(count):
                        expected_carry = bool(expected & 0x8000_0000)
                        expected = (expected << 1) & 0xFFFF_FFFF
                        expected_overflow |= (
                            expected_carry != original_sign
                            or bool(expected & 0x8000_0000)
                            != original_sign
                        )

                    model.state.st = 0
                    model.state.write_reg("A", 1, value)
                    states = model._execute_shift(
                        "A",
                        1,
                        count,
                        left=True,
                        arithmetic=True,
                    )
                    self.assertEqual(model.state.read_reg("A", 1), expected)
                    self.assertEqual(
                        bool(model.state.st & (1 << 31)),
                        bool(expected & 0x8000_0000),
                    )
                    self.assertEqual(
                        bool(model.state.st & (1 << 30)),
                        expected_carry,
                    )
                    self.assertEqual(
                        bool(model.state.st & (1 << 29)),
                        expected == 0,
                    )
                    self.assertEqual(
                        bool(model.state.st & (1 << 28)),
                        expected_overflow,
                    )
                    self.assertEqual(states, 3)

    def test_sll_constant_primary_examples_preserve_n_and_v(self) -> None:
        cases = (
            (0, 0x0000_0000, 0x0000_0000, 0b1011),
            (0, 0x8888_8888, 0x8888_8888, 0b1001),
            (1, 0x8888_8888, 0x1111_1110, 0b1101),
            (4, 0x8888_8888, 0x8888_8880, 0b1001),
            (30, 0xFFFF_FFFC, 0x0000_0000, 0b1111),
            (31, 0xFFFF_FFFC, 0x0000_0000, 0b1011),
        )
        for count, before, expected, expected_nczv in cases:
            with self.subTest(count=count, before=f"{before:08X}"):
                model = Tms34020Model()
                model.load_program([0x2401 | (count << 5)])
                model.state.write_reg("A", 1, before)
                model.state.st = 0x9020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "SLL.K")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_sll_register_primary_examples_use_low_five_bits(self) -> None:
        cases = (
            (0xFFFF_FFE0, 0x0000_0000, 0x0000_0000, 0b1011),
            (0, 0x8888_8888, 0x8888_8888, 0b1001),
            (1, 0x8888_8888, 0x1111_1110, 0b1101),
            (4, 0x8888_8888, 0x8888_8880, 0b1001),
            (30, 0xFFFF_FFFC, 0x0000_0000, 0b1111),
            (31, 0xFFFF_FFFC, 0x0000_0000, 0b1011),
        )
        for count_source, before, expected, expected_nczv in cases:
            with self.subTest(count_source=f"{count_source:08X}"):
                model = Tms34020Model()
                model.load_program([0x6201])
                model.state.write_reg("A", 0, count_source)
                model.state.write_reg("A", 1, before)
                model.state.st = 0x9020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "SLL.R")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_sra_constant_primary_examples_use_twos_complement_field(
        self,
    ) -> None:
        cases = (
            (0, 0x0000_0000, 0x0000_0000, 0b0011),
            (0, 0xFFFF_0000, 0xFFFF_0000, 0b1001),
            (8, 0x7FFF_0000, 0x007F_FF00, 0b0001),
            (8, 0xFFFF_0000, 0xFFFF_FF00, 0b1001),
            (30, 0x7FFF_0000, 0x0000_0001, 0b0101),
            (31, 0x7FFF_0000, 0x0000_0000, 0b0111),
            (31, 0xFFFF_0000, 0xFFFF_FFFF, 0b1101),
        )
        for count, before, expected, expected_nczv in cases:
            with self.subTest(count=count, before=f"{before:08X}"):
                encoded_count = (-count) & 0x1F
                model = Tms34020Model()
                model.load_program([0x2801 | (encoded_count << 5)])
                model.state.write_reg("A", 1, before)
                model.state.st = 0x1020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "SRA.K")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_sra_register_primary_examples_decode_negated_low_five_bits(
        self,
    ) -> None:
        cases = (
            (0, 0x0000_0000, 0x0000_0000, 0b0011),
            (0, 0xFFFF_0000, 0xFFFF_0000, 0b1001),
            (31, 0x7FFF_0000, 0x3FFF_8000, 0b0001),
            (31, 0xFFFF_0000, 0xFFFF_8000, 0b1001),
            (24, 0x7FFF_0000, 0x007F_FF00, 0b0001),
            (24, 0xFFFF_0000, 0xFFFF_FF00, 0b1001),
            (2, 0x7FFF_0000, 0x0000_0001, 0b0101),
            (1, 0x7FFF_0000, 0x0000_0000, 0b0111),
            (1, 0xFFFF_0000, 0xFFFF_FFFF, 0b1101),
        )
        for encoded_count, before, expected, expected_nczv in cases:
            with self.subTest(
                encoded_count=encoded_count, before=f"{before:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0x6401])
                model.state.write_reg("A", 0, encoded_count)
                model.state.write_reg("A", 1, before)
                model.state.st = 0x1020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "SRA.R")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_srl_constant_primary_examples_preserve_n_and_v(self) -> None:
        cases = (
            (0, 0x0000_0000, 0x0000_0000, 0b1011),
            (0, 0x7FFF_FFFF, 0x7FFF_FFFF, 0b1001),
            (1, 0x7FFF_FFFF, 0x3FFF_FFFF, 0b1101),
            (8, 0x7FFF_0000, 0x007F_FF00, 0b1001),
            (30, 0x7FFF_0000, 0x0000_0001, 0b1101),
            (31, 0x7FFF_0000, 0x0000_0000, 0b1111),
            (31, 0x3FFF_0000, 0x0000_0000, 0b1011),
        )
        for count, before, expected, expected_nczv in cases:
            with self.subTest(count=count, before=f"{before:08X}"):
                encoded_count = (-count) & 0x1F
                model = Tms34020Model()
                model.load_program([0x2C01 | (encoded_count << 5)])
                model.state.write_reg("A", 1, before)
                model.state.st = 0x9020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "SRL.K")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_srl_register_primary_examples_decode_negated_low_five_bits(
        self,
    ) -> None:
        cases = (
            (0, 0x0000_0000, 0x0000_0000, 0b1011),
            (0, 0x7FFF_FFFF, 0x7FFF_FFFF, 0b1001),
            (31, 0x7FFF_FFFF, 0x3FFF_FFFF, 0b1101),
            (24, 0x7FFF_0000, 0x007F_FF00, 0b1001),
            (2, 0x7FFF_0000, 0x0000_0001, 0b1101),
            (1, 0x7FFF_0000, 0x0000_0000, 0b1111),
            (1, 0x3FFF_0000, 0x0000_0000, 0b1011),
        )
        for encoded_count, before, expected, expected_nczv in cases:
            with self.subTest(
                encoded_count=encoded_count, before=f"{before:08X}"
            ):
                model = Tms34020Model()
                model.load_program([0x6601])
                model.state.write_reg("A", 0, encoded_count)
                model.state.write_reg("A", 1, before)
                model.state.st = 0x9020_0010
                event = model.step()
                self.assertEqual(event.mnemonic, "SRL.R")
                self.assertEqual(model.state.read_reg("A", 1), expected)
                self.assertEqual(
                    (model.state.st >> 28) & 0xF, expected_nczv
                )
                self.assertEqual(event.machine_states, 1)

    def test_shift_forms_b_file_shared_sp_and_same_register_hazards(
        self,
    ) -> None:
        model = Tms34020Model()
        model.load_program([0x6273, 0x65F2, 0x283F])
        model.state.write_reg("B", 3, 4)
        model.state.sp = 31
        model.state.write_reg("B", 2, 0x8000_0001)

        same_register = model.step()
        self.assertEqual(same_register.mnemonic, "SLL.R")
        self.assertEqual(model.state.read_reg("B", 3), 0x0000_0040)

        shared_sp_source = model.step()
        self.assertEqual(shared_sp_source.mnemonic, "SRA.R")
        self.assertEqual(model.state.read_reg("B", 2), 0xC000_0000)

        shared_sp_destination = model.step()
        self.assertEqual(shared_sp_destination.mnemonic, "SRA.K")
        self.assertEqual(model.state.sp, 0)

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
