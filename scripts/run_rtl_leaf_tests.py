#!/usr/bin/env python3
"""Build and run the self-checking verified-leaf Verilator testbench."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build/verilator_verified_leaves"
PASS_MARKER = "PASS: tms34020 verified leaf RTL"

SOURCES = [
    ROOT / "rtl/tms34020_pkg.sv",
    ROOT / "rtl/core/tms34020_decode.sv",
    ROOT / "rtl/core/tms34020_pc_execute.sv",
    ROOT / "rtl/core/tms34020_regfile.sv",
    ROOT / "rtl/core/tms34020_status.sv",
    ROOT / "rtl/core/tms34020_register_commit.sv",
    ROOT / "rtl/execute/tms34020_xy_arithmetic.sv",
    ROOT / "rtl/execute/tms34020_cmpxy.sv",
    ROOT / "rtl/execute/tms34020_addxyi.sv",
    ROOT / "rtl/execute/tms34020_binary_arithmetic.sv",
    ROOT / "rtl/execute/tms34020_divider.sv",
    ROOT / "rtl/execute/tms34020_multiplier.sv",
    ROOT / "rtl/memory/tms34020_swap_field.sv",
    ROOT / "rtl/memory/tms34020_field_store.sv",
    ROOT / "rtl/memory/tms34020_byte_store.sv",
    ROOT / "rtl/memory/tms34020_byte_load.sv",
    ROOT / "rtl/memory/tms34020_field_address_update.sv",
    ROOT / "rtl/memory/tms34020_field_pair_postincrement.sv",
    ROOT / "rtl/memory/tms34020_field_pair_predecrement.sv",
    ROOT / "rtl/memory/tms34020_field_offset_address.sv",
    ROOT / "rtl/memory/tms34020_absolute_address.sv",
    ROOT / "rtl/memory/tms34020_field_source_offset_postincrement.sv",
    ROOT / "rtl/memory/tms34020_field_load.sv",
    ROOT / "rtl/memory/tms34020_field_move.sv",
    ROOT / "rtl/memory/tms34020_byte_move.sv",
    ROOT / "rtl/memory/tms34020_multiple_register_control.sv",
    ROOT / "rtl/interrupts/tms34020_interrupt_return_control.sv",
    ROOT / "rtl/coprocessor/tms34020_coprocessor_command.sv",
    ROOT / "rtl/execute/tms34020_bit_test.sv",
    ROOT / "rtl/execute/tms34020_field_extend.sv",
    ROOT / "rtl/execute/tms34020_cmpk.sv",
    ROOT / "rtl/execute/tms34020_lmo.sv",
    ROOT / "rtl/execute/tms34020_logical.sv",
    ROOT / "rtl/execute/tms34020_rmo.sv",
    ROOT / "rtl/execute/tms34020_rotate_left.sv",
    ROOT / "rtl/execute/tms34020_shift.sv",
    ROOT / "rtl/execute/tms34020_unary.sv",
    ROOT / "rtl/execute/tms34020_register_execute.sv",
    ROOT / "rtl/graphics/tms34020_pitch_conversion.sv",
    ROOT / "rtl/graphics/tms34020_pixel_size_ops.sv",
    ROOT / "rtl/graphics/tms34020_pixel_replicate.sv",
    ROOT / "rtl/graphics/tms34020_window_compare.sv",
    ROOT / "rtl/graphics/tms34020_xy_to_linear.sv",
    ROOT / "sim/tb/tb_tms34020_verified_leaves.sv",
]


def main() -> None:
    verilator = shutil.which("verilator")
    if verilator is None:
        raise SystemExit("FAIL: Verilator is required for verified leaf tests")
    subprocess.run(
        [sys.executable, "tools/generators/generate_isa_rtl.py", "--check"],
        cwd=ROOT,
        check=True,
    )
    command = [
        verilator,
        "--binary",
        "--timing",
        "--Wall",
        "--Wno-fatal",
        f"-I{ROOT / 'rtl'}",
        "--top-module",
        "tb_tms34020_verified_leaves",
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
        raise SystemExit("FAIL: Verilator emitted verified-leaf RTL warnings")
    completed = subprocess.run(
        [str(BUILD / "Vtb_tms34020_verified_leaves")],
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
        raise SystemExit("FAIL: RTL testbench omitted explicit pass marker")


if __name__ == "__main__":
    main()
