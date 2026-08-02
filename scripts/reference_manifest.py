#!/usr/bin/env python3
"""Shared manifest validation and hashing helpers."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "references" / "manifest.yaml"
CACHE_ROOT = ROOT / "reference_cache"

REQUIRED_FIELDS = {
    "id",
    "title",
    "publisher",
    "author",
    "publication_number",
    "date",
    "revision",
    "url",
    "retrieval_date",
    "local_filename",
    "sha256",
    "document_type",
    "applicable_device",
    "applicable_silicon_revision",
    "authority_level",
    "redistribution_status",
    "license",
    "relevant_chapters_or_pages",
    "committed",
    "notes",
}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
ID_RE = re.compile(r"^[A-Z0-9][A-Z0-9_-]*$")


class ManifestError(ValueError):
    """Manifest structure or policy violation."""


def load_manifest() -> dict[str, Any]:
    try:
        data = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ManifestError(f"cannot read manifest: {error}") from error
    validate_manifest(data)
    return data


def validate_manifest(data: dict[str, Any]) -> None:
    if data.get("schema_version") != 1:
        raise ManifestError("schema_version must equal 1")
    sources = data.get("sources")
    if not isinstance(sources, list) or not sources:
        raise ManifestError("sources must be a nonempty list")
    seen: set[str] = set()
    for index, source in enumerate(sources):
        if not isinstance(source, dict):
            raise ManifestError(f"source {index} is not an object")
        missing = REQUIRED_FIELDS - source.keys()
        if missing:
            raise ManifestError(
                f"source {index} lacks fields: {', '.join(sorted(missing))}"
            )
        source_id = source["id"]
        if not isinstance(source_id, str) or not ID_RE.fullmatch(source_id):
            raise ManifestError(f"invalid source id: {source_id!r}")
        if source_id in seen:
            raise ManifestError(f"duplicate source id: {source_id}")
        seen.add(source_id)
        local = Path(source["local_filename"])
        if local.is_absolute() or ".." in local.parts:
            raise ManifestError(f"{source_id}: unsafe local_filename")
        digest = source["sha256"]
        if digest is not None and (
            not isinstance(digest, str) or not SHA256_RE.fullmatch(digest)
        ):
            raise ManifestError(f"{source_id}: invalid SHA-256")
        if source["committed"] and "do_not_commit" in source["redistribution_status"]:
            raise ManifestError(
                f"{source_id}: prohibited source marked committed"
            )
        if not isinstance(source["applicable_device"], list):
            raise ManifestError(f"{source_id}: applicable_device must be a list")
        if not isinstance(source["relevant_chapters_or_pages"], list):
            raise ManifestError(
                f"{source_id}: relevant_chapters_or_pages must be a list"
            )
        if source["document_type"] == "git_source_set":
            repository = source.get("repository")
            if not isinstance(repository, str) or not repository.startswith(
                "https://github.com/"
            ):
                raise ManifestError(
                    f"{source_id}: source set lacks an HTTPS GitHub repository"
                )
            if not SHA256_RE.fullmatch(source.get("commit", "")):
                # Git commits are SHA-1 in this pinned MAME repository.
                if not re.fullmatch(r"[0-9a-f]{40}", source.get("commit", "")):
                    raise ManifestError(f"{source_id}: invalid git commit")
            files = source.get("files")
            if not isinstance(files, list) or not files:
                raise ManifestError(f"{source_id}: source set has no files")
            for item in files:
                path = Path(item.get("path", ""))
                if path.is_absolute() or ".." in path.parts:
                    raise ManifestError(f"{source_id}: unsafe source-set path")
                if not SHA256_RE.fullmatch(item.get("sha256", "")):
                    raise ManifestError(
                        f"{source_id}: invalid file hash for {path}"
                    )


def source_by_id(data: dict[str, Any], source_id: str) -> dict[str, Any]:
    for source in data["sources"]:
        if source["id"] == source_id:
            return source
    raise ManifestError(f"unknown source id: {source_id}")


def local_path(source: dict[str, Any]) -> Path:
    return CACHE_ROOT / source["local_filename"]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_source_set(source: dict[str, Any]) -> str:
    root = local_path(source)
    digest = hashlib.sha256()
    for item in sorted(source["files"], key=lambda value: value["path"]):
        relative = item["path"].encode("utf-8")
        path = root / item["path"]
        data = path.read_bytes()
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        digest.update(len(data).to_bytes(8, "big"))
        digest.update(data)
    return digest.hexdigest()


def verify_source(source: dict[str, Any]) -> tuple[bool, str]:
    path = local_path(source)
    if source["sha256"] is None:
        return False, "no expected hash recorded"
    if source["document_type"] == "git_source_set":
        missing = [
            item["path"] for item in source["files"]
            if not (path / item["path"]).is_file()
        ]
        if missing:
            return False, f"missing {len(missing)} source-set files"
        for item in source["files"]:
            actual = sha256_file(path / item["path"])
            if actual != item["sha256"]:
                return False, f"hash mismatch: {item['path']}"
        actual = sha256_source_set(source)
    else:
        if not path.is_file():
            return False, "missing"
        actual = sha256_file(path)
    if actual != source["sha256"]:
        return False, f"hash mismatch: expected {source['sha256']}, got {actual}"
    return True, actual
