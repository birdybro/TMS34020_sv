"""Directed tests for the independent primary-verified model slice."""

from __future__ import annotations

import json
import unittest

from tools.model import (
    CONTROL_ADDRESS,
    HSTCTLH_ADDRESS,
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

    def test_inc_primary_examples(self) -> None:
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
                self.assertEqual(model.state.read_reg("A", 1), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
                self.assertEqual(event.machine_states, 1)

    def test_dec_primary_examples(self) -> None:
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
                self.assertEqual(model.state.read_reg("B", 1), result)
                self.assertEqual((model.state.st >> 28) & 0xF, nczv)
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
