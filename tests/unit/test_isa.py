"""Primary-source ISA schema, fixture, and partial-space checks."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from tools.isa.isa_db import IsaDatabase

ROOT = Path(__file__).resolve().parents[2]
ISA_PATH = ROOT / "docs/generated/tms34020_isa.yaml"

REQUIRED_FIELDS = {
    "mnemonic",
    "aliases",
    "instruction_length_words",
    "opcode_mask",
    "opcode_value",
    "operand_fields",
    "register_file",
    "immediate_fields",
    "condition_fields",
    "addressing_modes",
    "source_registers",
    "destination_registers",
    "status_bits_read",
    "status_bits_written",
    "undefined_status_bits",
    "memory_transactions",
    "graphics_register_dependencies",
    "cache_interactions",
    "pipeline_interactions",
    "interruptibility",
    "restartability",
    "bus_fault_behavior",
    "documented_cycles",
    "cache_hit_cycles",
    "cache_miss_cycles",
    "bus_16_effects",
    "bus_32_effects",
    "page_mode_effects",
    "source_citations",
    "compatible_with_tms34010",
    "confidence",
}


class IsaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.raw = json.loads(ISA_PATH.read_text(encoding="utf-8"))
        cls.database = IsaDatabase(cls.raw)

    def test_schema_fields_and_claim_boundary(self) -> None:
        self.assertEqual(
            self.raw["coverage"]["status"], "INCOMPLETE_PRIMARY_EXTRACTION"
        )
        self.assertFalse(
            self.raw["coverage"]["unmatched_first_words_are_reserved"]
        )
        self.assertEqual(
            self.raw["coverage"]["entry_count"],
            len(self.raw["instructions"]),
        )
        for instruction in self.raw["instructions"]:
            with self.subTest(mnemonic=instruction["mnemonic"]):
                self.assertEqual(set(instruction), REQUIRED_FIELDS)
                self.assertTrue(instruction["source_citations"])
                self.assertEqual(instruction["confidence"], "VERIFIED_PRIMARY")

    def test_independent_hand_checked_first_words(self) -> None:
        fixtures = {
            0x0300: ("NOP", 1),
            0x0380: ("ABS", 1),
            0x039F: ("ABS", 1),
            0x03A0: ("NEG", 1),
            0x03BF: ("NEG", 1),
            0x03C0: ("NEGB", 1),
            0x03DF: ("NEGB", 1),
            0x03E0: ("NOT", 1),
            0x03FF: ("NOT", 1),
            0x0320: ("CLRC", 1),
            0x0360: ("DINT", 1),
            0x0D60: ("EINT", 1),
            0x0DE0: ("SETC", 1),
            0x0180: ("GETST", 1),
            0x019F: ("GETST", 1),
            0x1000: ("ADDK", 1),
            0x1020: ("ADDK", 1),
            0x13FF: ("ADDK", 1),
            0x1400: ("SUBK", 1),
            0x1420: ("SUBK", 1),
            0x17FF: ("SUBK", 1),
            0x1800: ("MOVK", 1),
            0x1820: ("MOVK", 1),
            0x1BFF: ("MOVK", 1),
            0x09C0: ("MOVI.W", 2),
            0x09DF: ("MOVI.W", 2),
            0x09E0: ("MOVI.L", 3),
            0x09FF: ("MOVI.L", 3),
            0x4C00: ("MOVE", 1),
            0x4FFF: ("MOVE", 1),
            0xEC00: ("MOVX", 1),
            0xEDFF: ("MOVX", 1),
            0xEE00: ("MOVY", 1),
            0xEFFF: ("MOVY", 1),
            0x4000: ("ADD", 1),
            0x41FF: ("ADD", 1),
            0x4200: ("ADDC", 1),
            0x43FF: ("ADDC", 1),
            0x0B00: ("ADDI.W", 2),
            0x0B1F: ("ADDI.W", 2),
            0x0B20: ("ADDI.L", 3),
            0x0B3F: ("ADDI.L", 3),
            0x0B40: ("CMPI.W", 2),
            0x0B5F: ("CMPI.W", 2),
            0x0B60: ("CMPI.L", 3),
            0x0B7F: ("CMPI.L", 3),
            0x0BE0: ("SUBI.W", 2),
            0x0BFF: ("SUBI.W", 2),
            0x0D00: ("SUBI.L", 3),
            0x0D1F: ("SUBI.L", 3),
            0x4400: ("SUB", 1),
            0x45FF: ("SUB", 1),
            0x4600: ("SUBB", 1),
            0x47FF: ("SUBB", 1),
            0x4800: ("CMP", 1),
            0x49FF: ("CMP", 1),
            0x5000: ("AND", 1),
            0x51FF: ("AND", 1),
            0x5200: ("ANDN", 1),
            0x53FF: ("ANDN", 1),
            0x5400: ("OR", 1),
            0x55FF: ("OR", 1),
            0x5600: ("XOR", 1),
            0x57FF: ("XOR", 1),
            0x0B80: ("ANDNI", 3),
            0x0B9F: ("ANDNI", 3),
            0x0BA0: ("ORI", 3),
            0x0BBF: ("ORI", 3),
            0x0BC0: ("XORI", 3),
            0x0BDF: ("XORI", 3),
            0x0040: ("IDLE", 1),
            0x0080: ("MWAIT", 1),
            0x0C00: ("ADDXYI", 3),
            0x0C1E: ("ADDXYI", 3),
            0x00F0: ("BLMOVE", 1),
            0x00F3: ("BLMOVE", 1),
            0x0280: ("RPIX", 1),
            0x029E: ("RPIX", 1),
            0x3400: ("CMPK", 1),
            0x37FF: ("CMPK", 1),
            0x02A0: ("EXGPS", 1),
            0x02BF: ("EXGPS", 1),
            0x02C0: ("GETPS", 1),
            0x02DF: ("GETPS", 1),
            0x7A00: ("RMO", 1),
            0x7BFF: ("RMO", 1),
            0x0273: ("SETCDP", 1),
            0x02FB: ("SETCMP", 1),
            0x0251: ("SETCSP", 1),
            0x080F: ("TRAPL", 2),
            0x0A00: ("VLCOL", 1),
        }
        for word, expected in fixtures.items():
            with self.subTest(word=f"{word:04X}"):
                decoded = self.database.decode(word)
                self.assertIsNotNone(decoded)
                self.assertEqual(
                    (decoded.mnemonic, decoded.length_words), expected
                )

    def test_nearby_reserved_or_other_words_do_not_alias_fixed_opcodes(self) -> None:
        for word in (0x0041, 0x0081, 0x017F, 0x01A0, 0x0250, 0x0252,
                     0x0272, 0x0274, 0x02FA, 0x02FC, 0x0301, 0x0321,
                     0x0361, 0x080E, 0x081F, 0x0A01, 0x0D61, 0x0DE1,
                     0x0FFF, 0x1C00, 0x33FF, 0x3800,
                     0x0AFF, 0x0C20, 0x3FFF, 0x4A00,
                     0x5800,
                     0x79FF, 0x7C00):
            with self.subTest(word=f"{word:04X}"):
                self.assertIsNone(self.database.decode(word))

    def test_partial_65536_word_sweep_is_unique_and_disclosed(self) -> None:
        matched, unclassified = self.database.coverage()
        self.assertEqual(matched, 11920)
        self.assertEqual(unclassified, 65536 - 11920)
        self.assertGreater(unclassified, 0)

    def test_trapl_primary_length_disagrees_with_pinned_mame_disassembly(self) -> None:
        trapl = self.database.decode(0x080F)
        self.assertEqual(trapl.length_words, 2)
        self.assertIn(
            "ISA-DISC-0001-TRAPL-length",
            self.raw["coverage"]["known_secondary_discrepancies"],
        )

    def test_fixed_low_bits_follow_ti_not_secondary_aliases(self) -> None:
        for word in (0x0301, 0x0321, 0x0361, 0x0D61, 0x0DE1):
            with self.subTest(word=f"{word:04X}"):
                self.assertIsNone(self.database.decode(word))
        self.assertIn(
            "ISA-DISC-0002-fixed-low-bits",
            self.raw["coverage"]["known_secondary_discrepancies"],
        )

    def test_andi_alias_records_complemented_extension_encoding(self) -> None:
        andni = self.database.decode(0x0B80)
        self.assertIsNotNone(andni)
        self.assertIn("ANDI", andni.metadata["aliases"])
        immediate = andni.metadata["immediate_fields"][0]
        self.assertIn("ones-complement", immediate["alias_encoding"])

    def test_addi_encoding_forms_retain_ti_mnemonic_and_widths(self) -> None:
        short = self.database.decode(0x0B00)
        long = self.database.decode(0x0B20)
        self.assertEqual(short.metadata["aliases"], ["ADDI"])
        self.assertEqual(long.metadata["aliases"], ["ADDI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])

    def test_subi_encoding_forms_record_complemented_object_words(self) -> None:
        short = self.database.decode(0x0BE0)
        long = self.database.decode(0x0D00)
        self.assertEqual(short.metadata["aliases"], ["SUBI"])
        self.assertEqual(long.metadata["aliases"], ["SUBI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])
        for instruction in (short, long):
            self.assertEqual(
                instruction.metadata["immediate_fields"][0][
                    "object_encoding"
                ],
                "ones_complement_of_source_immediate",
            )

    def test_cmpi_encoding_forms_are_nondestructive_and_complemented(self) -> None:
        short = self.database.decode(0x0B40)
        long = self.database.decode(0x0B60)
        self.assertEqual(short.metadata["aliases"], ["CMPI"])
        self.assertEqual(long.metadata["aliases"], ["CMPI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])
        for instruction in (short, long):
            self.assertEqual(instruction.metadata["destination_registers"], [])
            self.assertEqual(
                instruction.metadata["immediate_fields"][0][
                    "object_encoding"
                ],
                "ones_complement_of_source_immediate",
            )

    def test_addk_canonicalizes_inc_alias_and_encoded_zero(self) -> None:
        addk_32 = self.database.decode(0x1000)
        inc_alias = self.database.decode(0x1020)
        self.assertEqual(addk_32.mnemonic, "ADDK")
        self.assertIs(addk_32, inc_alias)
        self.assertEqual(addk_32.metadata["aliases"], ["INC when K=1"])
        immediate = addk_32.metadata["immediate_fields"][0]
        self.assertEqual(immediate["width"], 5)
        self.assertFalse(immediate["signed"])
        self.assertEqual(immediate["zero_encoding"], 32)

    def test_subk_canonicalizes_dec_alias_and_encoded_zero(self) -> None:
        subk_32 = self.database.decode(0x1400)
        dec_alias = self.database.decode(0x1420)
        self.assertEqual(subk_32.mnemonic, "SUBK")
        self.assertIs(subk_32, dec_alias)
        self.assertEqual(subk_32.metadata["aliases"], ["DEC when K=1"])
        immediate = subk_32.metadata["immediate_fields"][0]
        self.assertEqual(immediate["width"], 5)
        self.assertFalse(immediate["signed"])
        self.assertEqual(immediate["zero_encoding"], 32)

    def test_movk_metadata_and_encoded_zero(self) -> None:
        movk_32 = self.database.decode(0x1800)
        movk_1 = self.database.decode(0x1820)
        self.assertEqual(movk_32.mnemonic, "MOVK")
        self.assertIs(movk_32, movk_1)
        self.assertEqual(movk_32.metadata["status_bits_written"], [])
        immediate = movk_32.metadata["immediate_fields"][0]
        self.assertEqual(immediate["width"], 5)
        self.assertFalse(immediate["signed"])
        self.assertEqual(immediate["zero_encoding"], 32)

    def test_movi_forms_record_width_status_and_alignment(self) -> None:
        short = self.database.decode(0x09C0)
        long = self.database.decode(0x09E0)
        self.assertEqual(short.metadata["aliases"], ["MOVI"])
        self.assertEqual(long.metadata["aliases"], ["MOVI"])
        self.assertEqual(short.metadata["immediate_fields"][0]["width"], 16)
        self.assertTrue(short.metadata["immediate_fields"][0]["signed"])
        self.assertEqual(long.metadata["immediate_fields"][0]["width"], 32)
        self.assertTrue(long.metadata["immediate_fields"][0]["signed"])
        for instruction in (short, long):
            self.assertEqual(
                instruction.metadata["status_bits_written"],
                ["N", "Z", "V"],
            )
            self.assertNotIn(
                "C", instruction.metadata["status_bits_written"]
            )

    def test_movx_movy_are_same_file_status_neutral_half_moves(self) -> None:
        for opcode, mnemonic, half in (
            (0xEC00, "MOVX", "X half"),
            (0xEE00, "MOVY", "Y half"),
        ):
            instruction = self.database.decode(opcode)
            self.assertEqual(instruction.mnemonic, mnemonic)
            self.assertIn("same file", instruction.metadata["register_file"])
            self.assertEqual(instruction.metadata["status_bits_written"], [])
            self.assertEqual(
                instruction.metadata["destination_registers"],
                [f"Rd {half}"],
            )
            self.assertEqual(
                instruction.metadata["documented_cycles"]["machine_states"],
                1,
            )

    def test_move_records_cross_file_and_implicit_compare(self) -> None:
        same_file = self.database.decode(0x4C01)
        cross_file = self.database.decode(0x4E01)
        self.assertEqual(same_file.mnemonic, "MOVE")
        self.assertEqual(cross_file.mnemonic, "MOVE")
        self.assertIn("destination is R when M=0",
                      same_file.metadata["register_file"])
        self.assertEqual(
            same_file.metadata["status_bits_written"],
            ["N", "Z", "V"],
        )
        self.assertEqual(
            same_file.metadata["documented_cycles"]["machine_states"],
            1,
        )


if __name__ == "__main__":
    unittest.main()
