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
            0x0040: ("IDLE", 1),
            0x0080: ("MWAIT", 1),
            0x0C00: ("ADDXYI", 3),
            0x0C1E: ("ADDXYI", 3),
            0x00F0: ("BLMOVE", 1),
            0x00F3: ("BLMOVE", 1),
            0x0280: ("RPIX", 1),
            0x029E: ("RPIX", 1),
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
        for word in (0x0041, 0x0081, 0x0250, 0x0252, 0x0272, 0x0274,
                     0x02FA, 0x02FC, 0x0301, 0x080E, 0x081F, 0x0A01):
            with self.subTest(word=f"{word:04X}"):
                self.assertIsNone(self.database.decode(word))

    def test_partial_65536_word_sweep_is_unique_and_disclosed(self) -> None:
        matched, unclassified = self.database.coverage()
        self.assertEqual(matched, 76)
        self.assertEqual(unclassified, 65536 - 76)
        self.assertGreater(unclassified, 0)

    def test_trapl_primary_length_disagrees_with_pinned_mame_disassembly(self) -> None:
        trapl = self.database.decode(0x080F)
        self.assertEqual(trapl.length_words, 2)
        self.assertIn(
            "ISA-DISC-0001-TRAPL-length",
            self.raw["coverage"]["known_secondary_discrepancies"],
        )


if __name__ == "__main__":
    unittest.main()
