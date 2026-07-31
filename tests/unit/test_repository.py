"""Independent smoke tests for repository governance."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


class RepositoryPolicyTests(unittest.TestCase):
    def test_license_is_mit(self) -> None:
        text = (ROOT / "LICENSE").read_text(encoding="utf-8")
        self.assertIn("MIT License", text)
        self.assertIn("Copyright (c) 2026 Kevin Coleman", text)

    def test_readme_disclaims_unproven_readiness(self) -> None:
        text = (ROOT / "README.md").read_text(encoding="utf-8")
        for claim in (
            "instruction-complete",
            "cycle-accurate",
            "pin-timing-accurate",
            "game-ready",
            "release-ready",
        ):
            self.assertIn(claim, text)

    def test_reference_cache_is_ignored(self) -> None:
        text = (ROOT / ".gitignore").read_text(encoding="utf-8")
        self.assertIn("/reference_cache/*", text)
        self.assertIn("*.rom", text)

    def test_tms34010_reference_not_in_rtl(self) -> None:
        makefile = (ROOT / "Makefile").read_text(encoding="utf-8")
        self.assertNotIn("third_party/TMS34010_sv_reference/rtl", makefile)


if __name__ == "__main__":
    unittest.main()
