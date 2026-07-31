#!/usr/bin/env python3
"""Run Quartus Analysis & Synthesis for the bounded scalar slice."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT_DIR = ROOT / "fpga/quartus"
PROJECT = "tms34020_scalar_smoke"
PASS_MARKER = "PASS: Quartus Cyclone V scalar Analysis & Synthesis"


def main() -> None:
    quartus_map = shutil.which("quartus_map")
    if quartus_map is None:
        raise SystemExit("FAIL: quartus_map is unavailable")
    completed = subprocess.run(
        [quartus_map, PROJECT],
        cwd=PROJECT_DIR,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    print(completed.stdout, end="")
    if completed.returncode:
        raise SystemExit(completed.returncode)
    summary = (
        ROOT
        / "build/quartus_scalar_smoke/tms34020_scalar_smoke.map.summary"
    )
    if not summary.is_file():
        raise SystemExit("FAIL: Quartus scalar summary was not produced")
    summary_text = summary.read_text(encoding="utf-8", errors="replace")
    if "Analysis & Synthesis Status : Successful" not in summary_text:
        raise SystemExit("FAIL: Quartus scalar summary is not successful")
    if "Total block memory bits : 4,096" not in summary_text:
        raise SystemExit("FAIL: scalar slice did not retain cache block RAM")
    if "0 errors, 0 warnings" not in completed.stdout:
        raise SystemExit("FAIL: Quartus emitted scalar errors or warnings")
    print(PASS_MARKER)


if __name__ == "__main__":
    main()
