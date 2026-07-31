#!/usr/bin/env python3
"""Build and run the integrated cache/instruction-fetch frontend test."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build/verilator_frontend"
PASS_MARKER = "PASS: tms34020 cache/fetch frontend"
SOURCES = [
    ROOT / "rtl/tms34020_pkg.sv",
    ROOT / "rtl/core/tms34020_decode.sv",
    ROOT / "rtl/cache/tms34020_icache.sv",
    ROOT / "rtl/core/tms34020_instruction_fetch.sv",
    ROOT / "rtl/core/tms34020_frontend.sv",
    ROOT / "sim/tb/tb_tms34020_frontend.sv",
]


def main() -> None:
    verilator = shutil.which("verilator")
    if verilator is None:
        raise SystemExit("FAIL: Verilator is required for frontend tests")
    subprocess.run(
        [sys.executable, "tools/generators/generate_isa_rtl.py", "--check"],
        cwd=ROOT,
        check=True,
    )
    command = [
        verilator,
        "--binary",
        "--timing",
        "--assert",
        "--Wall",
        "--Wno-fatal",
        "--Wno-UNUSEDPARAM",
        f"-I{ROOT / 'rtl'}",
        "--top-module",
        "tb_tms34020_frontend",
        "--Mdir",
        str(BUILD),
        *[str(source) for source in SOURCES],
    ]
    build = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    print(build.stdout, end="")
    if build.returncode:
        raise SystemExit(build.returncode)
    if "%Warning" in build.stdout:
        raise SystemExit("FAIL: Verilator emitted frontend RTL warnings")
    completed = subprocess.run(
        [str(BUILD / "Vtb_tms34020_frontend")],
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    print(completed.stdout, end="")
    if completed.returncode:
        raise SystemExit(completed.returncode)
    if PASS_MARKER not in completed.stdout:
        raise SystemExit("FAIL: frontend testbench omitted pass marker")


if __name__ == "__main__":
    main()
