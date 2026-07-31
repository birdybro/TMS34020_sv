#!/usr/bin/env python3
"""Build and run deterministic randomized cache-native RTL tests."""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build/verilator_icache_random"
FAILURE_LOG = ROOT / "build/cache_random_failures.txt"
PASS_MARKER = "PASS: tms34020 cache randomized"
SEEDS = (0x34020001, 0xB7A17EAD, 0x5EEDC0DE)

SOURCES = [
    ROOT / "rtl/tms34020_pkg.sv",
    ROOT / "rtl/cache/tms34020_icache.sv",
    ROOT / "sim/tb/tb_tms34020_icache_random.sv",
]


def record_failure(seed: int, output: str) -> None:
    FAILURE_LOG.parent.mkdir(parents=True, exist_ok=True)
    with FAILURE_LOG.open("a", encoding="utf-8") as failure_log:
        failure_log.write(f"seed={seed:08x}\n")
        failure_log.write(output)
        if output and not output.endswith("\n"):
            failure_log.write("\n")


def parse_seed(value: str) -> int:
    seed = int(value, 16)
    if not 0 < seed <= 0xFFFF_FFFF:
        raise argparse.ArgumentTypeError(
            "seed must be a nonzero 32-bit hexadecimal value"
        )
    return seed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--seed",
        action="append",
        type=parse_seed,
        help="run one replay seed in hexadecimal; may be repeated",
    )
    args = parser.parse_args()
    seeds = tuple(args.seed) if args.seed else SEEDS

    verilator = shutil.which("verilator")
    if verilator is None:
        raise SystemExit("FAIL: Verilator is required for cache random tests")
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
        "tb_tms34020_icache_random",
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
        raise SystemExit("FAIL: Verilator emitted cache random RTL warnings")

    binary = BUILD / "Vtb_tms34020_icache_random"
    for seed in seeds:
        completed = subprocess.run(
            [str(binary), f"+SEED={seed:08x}"],
            cwd=ROOT,
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        print(completed.stdout, end="")
        if completed.returncode or PASS_MARKER not in completed.stdout:
            record_failure(seed, completed.stdout)
            if completed.returncode:
                raise SystemExit(completed.returncode)
            raise SystemExit(
                "FAIL: cache random testbench omitted pass marker"
            )


if __name__ == "__main__":
    main()
