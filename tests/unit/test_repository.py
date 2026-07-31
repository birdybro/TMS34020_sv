"""Independent smoke tests for repository governance."""

from __future__ import annotations

import unittest
from pathlib import Path
import re

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

    def test_reuse_audit_covers_every_upstream_module(self) -> None:
        upstream = ROOT / "third_party" / "TMS34010_sv_reference"
        if not upstream.is_dir():
            self.skipTest("TMS34010 reference submodule not initialized")
        audit = (
            ROOT / "docs" / "reuse" / "tms34010_reuse_audit.md"
        ).read_text(encoding="utf-8")
        source_files = sorted((upstream / "rtl").rglob("*.sv"))
        source_files += sorted((upstream / "sim" / "models").glob("*.sv"))
        self.assertGreater(len(source_files), 30)
        for path in source_files:
            relative = path.relative_to(upstream).as_posix()
            with self.subTest(path=relative):
                self.assertIn(f"`{relative}`", audit)
        classifications = re.findall(
            r"\| `[^`]+\.sv` \| ([A-Z_]+) \|", audit
        )
        valid = {
            "REUSE_UNCHANGED",
            "REUSE_WITH_DEVICE_PARAMETER",
            "COPY_AND_ADAPT",
            "REIMPLEMENT",
            "NOT_APPLICABLE",
            "REFERENCE_ONLY",
            "UNKNOWN_PENDING_RESEARCH",
        }
        self.assertTrue(classifications)
        self.assertTrue(set(classifications) <= valid)
        self.assertNotIn("REUSE_UNCHANGED", classifications)


if __name__ == "__main__":
    unittest.main()
