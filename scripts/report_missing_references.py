#!/usr/bin/env python3
"""Report missing, unhashed, or invalid cached references."""

from __future__ import annotations

import argparse

from reference_manifest import ManifestError, load_manifest, verify_source


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--required-only", action="store_true")
    args = parser.parse_args()
    try:
        manifest = load_manifest()
        missing = []
        for source in manifest["sources"]:
            if args.required_only and not source.get("required", False):
                continue
            valid, detail = verify_source(source)
            if not valid:
                missing.append((source, detail))
        if not missing:
            print("PASS: no selected references are missing")
            return
        for source, detail in missing:
            method = source["fetch"]
            print(
                f"{source['id']}: {detail}; acquisition={method}; "
                f"title={source['title']}"
            )
        print(f"REPORT: {len(missing)} selected reference(s) need attention")
    except ManifestError as error:
        raise SystemExit(f"FAIL: {error}") from error


if __name__ == "__main__":
    main()
