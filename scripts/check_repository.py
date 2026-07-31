#!/usr/bin/env python3
"""Validate repository governance and the stable milestone registry."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = (
    "AGENTS.md",
    "README.md",
    "tasks.md",
    "changelog.md",
    "LICENSE",
    "CONTRIBUTING.md",
    ".gitignore",
    ".gitattributes",
    "Makefile",
)

REQUIRED_DIRS = (
    "docs/architecture",
    "docs/instructions",
    "docs/timing",
    "docs/memory",
    "docs/graphics",
    "docs/display",
    "docs/host",
    "docs/cache",
    "docs/bus",
    "docs/coprocessor",
    "docs/interrupts",
    "docs/integration/battletoads",
    "docs/integration/revx",
    "docs/references",
    "docs/research",
    "docs/reuse",
    "docs/decisions",
    "docs/generated",
    "docs/diagrams",
    "rtl/core",
    "rtl/execute",
    "rtl/graphics",
    "rtl/memory",
    "rtl/cache",
    "rtl/io",
    "rtl/host",
    "rtl/video",
    "rtl/bus",
    "rtl/coprocessor",
    "rtl/cdc",
    "rtl/wrappers",
    "sim/models",
    "sim/tb",
    "sim/programs",
    "sim/traces",
    "sim/differential",
    "sim/integration/battletoads",
    "sim/integration/revx",
    "formal/properties",
    "formal/harnesses",
    "tools/isa",
    "tools/assembler",
    "tools/disassembler",
    "tools/trace",
    "tools/differential",
    "tools/generators",
    "tools/reduction",
    "tests/asm",
    "tests/binaries",
    "tests/expected",
    "tests/vectors",
    "tests/regressions",
    "tests/fuzz",
    "scripts",
    "fpga/quartus",
    "fpga/mister",
    "third_party",
    "reference_cache",
    "artifacts",
    "build",
    ".github/workflows",
)

EXPECTED_TASKS = tuple(f"TMS20-{number:04d}" for number in range(1, 43))
VALID_STATUSES = {
    "NOT STARTED",
    "RESEARCHING",
    "BLOCKED",
    "IMPLEMENTING",
    "VERIFYING",
    "COMPLETE",
}
VALID_CONFIDENCE = {
    "VERIFIED_PRIMARY",
    "VERIFIED_HARDWARE",
    "CORROBORATED",
    "INFERRED",
    "PROVISIONAL",
    "UNKNOWN",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    missing_files = [name for name in REQUIRED_FILES if not (ROOT / name).is_file()]
    missing_dirs = [name for name in REQUIRED_DIRS if not (ROOT / name).is_dir()]
    if missing_files:
        fail(f"required files missing: {', '.join(missing_files)}")
    if missing_dirs:
        fail(f"required directories missing: {', '.join(missing_dirs)}")

    tasks_text = (ROOT / "tasks.md").read_text(encoding="utf-8")
    found = tuple(
        dict.fromkeys(re.findall(r"\bTMS20-\d{4}\b", tasks_text)).keys()
    )
    missing_tasks = [task for task in EXPECTED_TASKS if task not in found]
    if missing_tasks:
        fail(f"milestone tasks missing: {', '.join(missing_tasks)}")
    for task in EXPECTED_TASKS:
        row = next(
            (line for line in tasks_text.splitlines() if f"| {task} |" in line),
            "",
        )
        if not row:
            fail(f"{task} has no task table row")
        if len(row.split("|")) < 13:
            fail(f"{task} does not contain every required field")
        if not any(status in row for status in VALID_STATUSES):
            fail(f"{task} has no valid status")
        if not any(confidence in row for confidence in VALID_CONFIDENCE):
            fail(f"{task} has no valid confidence")

    changelog = (ROOT / "changelog.md").read_text(encoding="utf-8")
    for heading in (
        "Added",
        "Changed",
        "Fixed",
        "Verified",
        "Documentation",
        "Integration",
        "Known Issues",
    ):
        if f"### {heading}" not in changelog:
            fail(f"changelog section missing: {heading}")

    print("PASS: repository governance and milestone registry")


if __name__ == "__main__":
    main()
