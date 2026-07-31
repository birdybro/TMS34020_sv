#!/usr/bin/env python3
"""Single, explicit command dispatcher for local and CI verification."""

from __future__ import annotations

import argparse
import compileall
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SUITES = {
    "foundation": ("IMPLEMENTED", "TMS20-0001"),
    "lint": ("IMPLEMENTED", "TMS20-0001"),
    "references": ("IMPLEMENTED", "TMS20-0002"),
    "delta": ("IMPLEMENTED", "TMS20-0005"),
    "model": ("NOT_IMPLEMENTED", "TMS20-0007"),
    "decode": ("NOT_IMPLEMENTED", "TMS20-0006"),
    "instruction": ("NOT_IMPLEMENTED", "TMS20-0009/TMS20-0010"),
    "compatibility": ("NOT_IMPLEMENTED", "TMS20-0009/TMS20-0031"),
    "cache": ("NOT_IMPLEMENTED", "TMS20-0012"),
    "memory": ("NOT_IMPLEMENTED", "TMS20-0014"),
    "graphics": ("NOT_IMPLEMENTED", "TMS20-0024"),
    "video": ("NOT_IMPLEMENTED", "TMS20-0027"),
    "host": ("NOT_IMPLEMENTED", "TMS20-0020"),
    "fault": ("NOT_IMPLEMENTED", "TMS20-0017"),
    "coprocessor": ("NOT_IMPLEMENTED", "TMS20-0021"),
    "bus": ("NOT_IMPLEMENTED", "TMS20-0030"),
    "differential": ("NOT_IMPLEMENTED", "TMS20-0031"),
    "fuzz": ("NOT_IMPLEMENTED", "TMS20-0031"),
    "formal": ("NOT_IMPLEMENTED", "TMS20-0032"),
    "synth-yosys": ("NOT_IMPLEMENTED", "TMS20-0033"),
    "synth-quartus": ("NOT_IMPLEMENTED", "TMS20-0034"),
    "battletoads": ("NOT_IMPLEMENTED", "TMS20-0037"),
    "revx": ("NOT_IMPLEMENTED", "TMS20-0040"),
}


def run(command: list[str]) -> None:
    completed = subprocess.run(command, cwd=ROOT, check=False)
    if completed.returncode:
        raise SystemExit(completed.returncode)


def foundation() -> None:
    run([sys.executable, "scripts/check_repository.py"])
    run(
        [
            sys.executable,
            "-m",
            "unittest",
            "discover",
            "-s",
            "tests/unit",
            "-p",
            "test_*.py",
        ]
    )
    print("PASS: foundation")


def lint() -> None:
    if not compileall.compile_dir(
        ROOT / "scripts", quiet=1, rx=re.compile(r".*/reference_cache/.*")
    ):
        raise SystemExit("FAIL: Python compilation")
    rtl_files = sorted((ROOT / "rtl").rglob("*.sv"))
    verilator = shutil.which("verilator")
    if rtl_files and verilator:
        run(
            [
                verilator,
                "--lint-only",
                "--Wall",
                "--Wno-fatal",
                *[str(path) for path in rtl_files],
            ]
        )
    elif rtl_files:
        print("SKIP: Verilator unavailable; RTL lint not executed")
    else:
        print("SKIP: no SystemVerilog RTL exists yet (TMS20-0009)")
    print("PASS: implemented lint checks")


def references() -> None:
    run([sys.executable, "scripts/verify_reference_hashes.py", "--validate-only"])
    run(
        [
            sys.executable,
            "-m",
            "unittest",
            "discover",
            "-s",
            "tests/unit",
            "-p",
            "test_references.py",
        ]
    )
    print("PASS: reference manifest and available-cache hashes")


def delta() -> None:
    run(
        [
            sys.executable,
            "-m",
            "unittest",
            "discover",
            "-s",
            "tests/unit",
            "-p",
            "test_delta.py",
        ]
    )
    print("PASS: architectural delta schema and required-feature coverage")


def doctor() -> None:
    required = ("git", "make", "python3")
    optional = (
        "verilator",
        "iverilog",
        "yosys",
        "sby",
        "quartus_sh",
        "gh",
    )
    missing = [tool for tool in required if shutil.which(tool) is None]
    for tool in required + optional:
        state = shutil.which(tool) or "NOT FOUND"
        print(f"{tool:12} {state}")
    if missing:
        raise SystemExit(f"FAIL: missing required tools: {', '.join(missing)}")
    print("PASS: required development tools")


def clean() -> None:
    for directory in (ROOT / "build", ROOT / "obj_dir"):
        if directory.name == "build":
            for path in directory.iterdir():
                if path.name != ".gitignore":
                    if path.is_dir():
                        shutil.rmtree(path)
                    else:
                        path.unlink()
        elif directory.exists():
            shutil.rmtree(directory)
    for cache in ROOT.rglob("__pycache__"):
        if ".git" not in cache.parts and "third_party" not in cache.parts:
            shutil.rmtree(cache)
    print("PASS: clean")


def list_suites() -> None:
    print("TMS34020_sv command suites")
    print("  make doctor             report required and optional tools")
    for name, (status, task) in SUITES.items():
        target = f"{name}-tests" if name in {
            "delta", "model", "decode", "instruction", "compatibility", "cache",
            "memory", "graphics", "video", "host", "fault", "coprocessor",
        } else name
        print(f"  make {target:18} {status:15} {task}")
    print("  make test               run every currently implemented required suite")
    print("  make clean              remove generated local output")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("suite", nargs="?")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    if args.list:
        list_suites()
        return
    if args.suite == "doctor":
        doctor()
        return
    if args.suite == "clean":
        clean()
        return
    if args.suite not in SUITES:
        parser.error("choose a suite or use --list")
    status, task = SUITES[args.suite]
    if status != "IMPLEMENTED":
        print(f"SKIP: {args.suite} suite not implemented; tracked by {task}")
        return
    if args.suite == "foundation":
        foundation()
    elif args.suite == "lint":
        lint()
    elif args.suite == "references":
        references()
    elif args.suite == "delta":
        delta()


if __name__ == "__main__":
    main()
