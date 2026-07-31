"""Manifest policy and optional local-cache hash tests."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

from reference_manifest import load_manifest, local_path, verify_source


class ReferenceManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = load_manifest()

    def test_primary_baseline_ids_exist(self) -> None:
        ids = {source["id"] for source in self.manifest["sources"]}
        self.assertTrue(
            {
                "TI-TMS34020-UG-1990",
                "TI-TMS34020-DS-SPVS004D",
                "TI-SM34020A-DS-SGUS057",
                "TI-SMJ34020A-DS-SGUS011D",
                "MAME-TMS34020-20260731",
            }
            <= ids
        )

    def test_unredistributable_sources_are_not_committed(self) -> None:
        for source in self.manifest["sources"]:
            with self.subTest(source=source["id"]):
                if "do_not_commit" in source["redistribution_status"]:
                    self.assertFalse(source["committed"])

    def test_available_cached_sources_match_hashes(self) -> None:
        checked = 0
        for source in self.manifest["sources"]:
            path = local_path(source)
            if path.exists() and source["sha256"] is not None:
                valid, detail = verify_source(source)
                with self.subTest(source=source["id"], detail=detail):
                    self.assertTrue(valid)
                checked += 1
        if checked == 0:
            self.skipTest("reference cache intentionally absent")

    def test_mame_paths_are_pinned_and_current_for_commit(self) -> None:
        source = next(
            item for item in self.manifest["sources"]
            if item["id"] == "MAME-TMS34020-20260731"
        )
        paths = {item["path"] for item in source["files"]}
        self.assertIn("src/mame/rare/btoads.cpp", paths)
        self.assertIn("src/mame/williams/midxunit.cpp", paths)
        self.assertNotIn("src/mame/midway/midxunit.cpp", paths)
        self.assertEqual(len(source["commit"]), 40)

    def test_toolchain_editions_are_not_conflated(self) -> None:
        sources = {
            source["id"]: source for source in self.manifest["sources"]
        }
        self.assertEqual(
            sources["TI-TMS340-CODEGEN-SPVU004"]["publication_number"],
            "SPVU004",
        )
        self.assertEqual(
            sources["TI-TMS340-CODEGEN-TOOLS"]["publication_number"],
            "SPVU020",
        )
        tiga = sources["TI-TMS340-INTERFACE-SPVU015C"]
        self.assertEqual(tiga["publication_number"], "SPVU015C")
        self.assertEqual(len(tiga["sha256"]), 64)


if __name__ == "__main__":
    unittest.main()
