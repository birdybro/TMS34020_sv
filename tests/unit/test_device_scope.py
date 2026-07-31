"""Mechanical checks for device-scope evidence and overclaim boundaries."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class DeviceScopeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.scope = (ROOT / "docs/device_scope.md").read_text(encoding="utf-8")
        self.matrix = (ROOT / "docs/device_variant_matrix.md").read_text(
            encoding="utf-8"
        )
        self.games = (ROOT / "docs/game_device_identification.md").read_text(
            encoding="utf-8"
        )

    def test_every_required_variant_is_distinguished(self) -> None:
        for device in (
            "TMS34020",
            "TMS34020A",
            "SMJ34020",
            "SMJ34020A",
            "SM34020A",
        ):
            with self.subTest(device=device):
                self.assertIn(device, self.scope)
                self.assertIn(device, self.matrix)

    def test_matrix_has_every_required_category(self) -> None:
        for category in (
            "Instruction set",
            "Opcode encodings",
            "Status register",
            "I/O registers",
            "Instruction cache",
            "Memory controller",
            "Host interface",
            "Display controller",
            "Interrupt system",
            "Bus-fault behavior",
            "Multiprocessor behavior",
            "Coprocessor behavior",
            "Reset behavior",
            "Electrical qualification",
            "Package and pins",
            "Documented errata",
        ):
            with self.subTest(category=category):
                self.assertIn(f"| {category} |", self.matrix)

    def test_clock_stretch_claim_is_bounded(self) -> None:
        for required in ("CONFIG.CSE", "Q4b", "reset", "SPVS004D"):
            self.assertIn(required, self.scope)
        self.assertIn("no other delta is assumed", self.scope)

    def test_game_markings_are_not_overclaimed(self) -> None:
        for game in ("Battletoads", "Revolution X"):
            self.assertIn(game, self.games)
        self.assertIn("exact production CPU top marking has yet been verified", self.games)
        self.assertIn("release default and no selection RTL exists", self.games)
        self.assertIn("No game-ready or release-ready status may be claimed", self.games)
        self.assertIn("a562e947b22f4f5acff0c182c26fd649d72dad0e", self.games)


if __name__ == "__main__":
    unittest.main()
