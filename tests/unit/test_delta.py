"""Schema and required-coverage checks for the architectural delta ledger."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DELTA = ROOT / "docs/generated/tms34010_tms34020_delta.yaml"

REQUIRED_FIELDS = {
    "feature",
    "tms34010_behavior",
    "tms34020_behavior",
    "rtl_impact",
    "test_impact",
    "source_citation",
    "confidence",
    "unresolved_questions",
}

REQUIRED_FEATURES = {
    "inherited_opcode_compatibility",
    "new_opcodes",
    "removed_or_redefined_opcodes",
    "changed_instruction_timing",
    "changed_status_behavior",
    "instruction_cache",
    "cache_hit_and_miss_timing",
    "cache_organization_and_replacement",
    "cache_invalidation",
    "self_modifying_code",
    "host_writes_to_cached_code",
    "local_data_bus_32_bit",
    "dynamic_16_bit_bus_fallback",
    "size16_behavior",
    "four_byte_oriented_cas_strobes",
    "page_mode_access",
    "memory_and_instruction_overlap",
    "pipelined_writes",
    "expanded_64_register_io_map",
    "pmask_low_and_high",
    "convmp",
    "control2",
    "config",
    "additional_display_registers",
    "revised_display_sequencing",
    "bus_fault_detection",
    "retry",
    "instruction_continuation",
    "host_direct_addressing",
    "host_byte_selects",
    "multiprocessor_r0_r1_gi",
    "coprocessor_interface",
    "special_function_cycles",
    "one_megabit_vram_features",
    "reset_behavior",
    "local_clock_relationship",
    "emulator_debug_interface",
}

VALID_CONFIDENCE = {
    "VERIFIED_PRIMARY",
    "VERIFIED_HARDWARE",
    "CORROBORATED",
    "INFERRED",
    "PROVISIONAL",
    "UNKNOWN",
}


class DeltaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = json.loads(DELTA.read_text(encoding="utf-8"))
        cls.entries = cls.document["entries"]

    def test_schema_and_unique_features(self) -> None:
        self.assertEqual(self.document["schema_version"], 1)
        features = []
        for index, entry in enumerate(self.entries):
            with self.subTest(index=index):
                self.assertEqual(set(entry), REQUIRED_FIELDS)
                self.assertIn(entry["confidence"], VALID_CONFIDENCE)
                self.assertTrue(entry["source_citation"])
                self.assertIsInstance(entry["unresolved_questions"], list)
                for field in REQUIRED_FIELDS - {
                    "source_citation",
                    "unresolved_questions",
                }:
                    self.assertTrue(entry[field])
            features.append(entry["feature"])
        self.assertEqual(len(features), len(set(features)))

    def test_required_delta_coverage(self) -> None:
        actual = {entry["feature"] for entry in self.entries}
        self.assertEqual(REQUIRED_FEATURES - actual, set())

    def test_unknowns_are_not_hidden(self) -> None:
        by_feature = {entry["feature"]: entry for entry in self.entries}
        for feature in ("removed_or_redefined_opcodes", "control2"):
            with self.subTest(feature=feature):
                self.assertEqual(by_feature[feature]["confidence"], "UNKNOWN")
                self.assertTrue(by_feature[feature]["unresolved_questions"])

    def test_reference_pin_is_exact(self) -> None:
        self.assertEqual(
            self.document["comparison_baseline"]["tms34010_reference_commit"],
            "94a258e80a07ceb4303ce0b99818df832e96007f",
        )


if __name__ == "__main__":
    unittest.main()
