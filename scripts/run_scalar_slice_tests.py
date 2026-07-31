#!/usr/bin/env python3
"""Build and run the bounded cache/fetch/register scalar slice test."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build/verilator_scalar_slice"
PASS_MARKER = "PASS: tms34020 bounded scalar slice"
SOURCES = [
    ROOT / "rtl/tms34020_pkg.sv",
    ROOT / "rtl/core/tms34020_decode.sv",
    ROOT / "rtl/core/tms34020_pc_execute.sv",
    ROOT / "rtl/execute/tms34020_binary_arithmetic.sv",
    ROOT / "rtl/execute/tms34020_unary.sv",
    ROOT / "rtl/execute/tms34020_cmpk.sv",
    ROOT / "rtl/execute/tms34020_lmo.sv",
    ROOT / "rtl/execute/tms34020_rmo.sv",
    ROOT / "rtl/execute/tms34020_rotate_left.sv",
    ROOT / "rtl/execute/tms34020_shift.sv",
    ROOT / "rtl/execute/tms34020_logical.sv",
    ROOT / "rtl/execute/tms34020_addxyi.sv",
    ROOT / "rtl/execute/tms34020_register_execute.sv",
    ROOT / "rtl/core/tms34020_regfile.sv",
    ROOT / "rtl/core/tms34020_status.sv",
    ROOT / "rtl/core/tms34020_register_commit.sv",
    ROOT / "rtl/cache/tms34020_icache.sv",
    ROOT / "rtl/core/tms34020_instruction_fetch.sv",
    ROOT / "rtl/core/tms34020_frontend.sv",
    ROOT / "rtl/core/tms34020_scalar_slice.sv",
    ROOT / "sim/tb/tb_tms34020_scalar_slice.sv",
]


def main() -> None:
    verilator = shutil.which("verilator")
    if verilator is None:
        raise SystemExit("FAIL: Verilator is required for scalar slice tests")
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
        "tb_tms34020_scalar_slice",
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
        raise SystemExit("FAIL: Verilator emitted scalar slice RTL warnings")
    completed = subprocess.run(
        [str(BUILD / "Vtb_tms34020_scalar_slice")],
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
        raise SystemExit("FAIL: scalar slice testbench omitted pass marker")


if __name__ == "__main__":
    main()
