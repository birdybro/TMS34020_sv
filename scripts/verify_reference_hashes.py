#!/usr/bin/env python3
"""Validate the reference manifest and verify cached source hashes."""

from __future__ import annotations

import argparse

from reference_manifest import (
    ManifestError,
    load_manifest,
    source_by_id,
    verify_source,
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", action="append", dest="ids")
    parser.add_argument("--require-all", action="store_true")
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    try:
        manifest = load_manifest()
        print(f"PASS: manifest schema ({len(manifest['sources'])} sources)")
        if args.validate_only:
            return
        sources = (
            [source_by_id(manifest, value) for value in args.ids]
            if args.ids
            else manifest["sources"]
        )
        failures = 0
        verified = 0
        for source in sources:
            valid, detail = verify_source(source)
            if valid:
                verified += 1
                print(f"VERIFIED {source['id']} {detail}")
            else:
                print(f"MISSING_OR_INVALID {source['id']} {detail}")
                if args.require_all or args.ids:
                    failures += 1
        if failures:
            raise ManifestError(f"{failures} required verification failure(s)")
        print(f"PASS: {verified} cached reference(s) verified")
    except ManifestError as error:
        raise SystemExit(f"FAIL: {error}") from error


if __name__ == "__main__":
    main()
