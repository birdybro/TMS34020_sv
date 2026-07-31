#!/usr/bin/env python3
"""Lawfully fetch hash-pinned public references into the ignored cache."""

from __future__ import annotations

import argparse
import os
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

from reference_manifest import (
    ManifestError,
    load_manifest,
    local_path,
    sha256_file,
    source_by_id,
    verify_source,
)

USER_AGENT = "TMS34020_sv-reference-fetcher/1.0"


def download(url: str, target: Path, expected: str) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    temporary_name: str | None = None
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            with tempfile.NamedTemporaryFile(
                dir=target.parent,
                prefix=f".{target.name}.",
                suffix=".partial",
                delete=False,
            ) as temporary:
                temporary_name = temporary.name
                while chunk := response.read(1024 * 1024):
                    temporary.write(chunk)
        temporary_path = Path(temporary_name)
        actual = sha256_file(temporary_path)
        if actual != expected:
            temporary_path.unlink()
            raise ManifestError(
                f"download hash mismatch for {target.name}: "
                f"expected {expected}, got {actual}"
            )
        os.replace(temporary_path, target)
    except Exception:
        if temporary_name is not None:
            partial = Path(temporary_name)
            if partial.exists():
                partial.unlink()
        raise


def fetch_file(source: dict[str, object], force: bool) -> None:
    target = local_path(source)
    if target.exists() and not force:
        valid, detail = verify_source(source)
        if valid:
            print(f"VERIFIED {source['id']} {detail}")
            return
        raise ManifestError(
            f"{source['id']}: existing cache entry is invalid ({detail}); "
            "inspect it, then rerun with --force only if replacement is intended"
        )
    url = source.get("url")
    expected = source.get("sha256")
    if not isinstance(url, str) or not isinstance(expected, str):
        raise ManifestError(f"{source['id']}: no fetchable URL/hash")
    download(url, target, expected)
    print(f"FETCHED {source['id']} {target}")


def fetch_git_files(source: dict[str, object], force: bool) -> None:
    commit = source["commit"]
    base = f"https://raw.githubusercontent.com/mamedev/mame/{commit}/"
    root = local_path(source)
    for item in source["files"]:
        target = root / item["path"]
        if target.is_file() and not force:
            actual = sha256_file(target)
            if actual == item["sha256"]:
                continue
            raise ManifestError(
                f"{source['id']}: invalid existing file {item['path']}"
            )
        download(base + item["path"], target, item["sha256"])
    valid, detail = verify_source(source)
    if not valid:
        raise ManifestError(f"{source['id']}: source-set verify failed: {detail}")
    print(f"FETCHED {source['id']} {root}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fetch public hash-pinned references into reference_cache/"
    )
    parser.add_argument("--id", action="append", dest="ids")
    parser.add_argument(
        "--all",
        action="store_true",
        help="fetch every automatic or git_files record",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="replace an existing invalid/changed cache entry",
    )
    args = parser.parse_args()
    try:
        manifest = load_manifest()
        if args.all:
            sources = [
                source for source in manifest["sources"]
                if source["fetch"] in {"automatic", "git_files"}
            ]
        elif args.ids:
            sources = [source_by_id(manifest, value) for value in args.ids]
        else:
            parser.error("provide --id ID or --all")
        for source in sources:
            if "binary" in source["document_type"]:
                raise ManifestError(
                    f"{source['id']}: legacy binaries require isolated manual setup"
                )
            if source["fetch"] == "automatic":
                fetch_file(source, args.force)
            elif source["fetch"] == "git_files":
                fetch_git_files(source, args.force)
            else:
                raise ManifestError(
                    f"{source['id']}: manual acquisition required"
                )
    except (ManifestError, OSError, urllib.error.URLError) as error:
        raise SystemExit(f"FAIL: {error}") from error


if __name__ == "__main__":
    main()
