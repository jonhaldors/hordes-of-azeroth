#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Build the generated i18n catalogue and check it for drift."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import argparse
import hashlib
import json
from catalogue import ROOT, load

OUT_DIR = ROOT / "shared" / "i18n" / "generated"
OUT_JSON = OUT_DIR / "messages.json"
OUT_HASH = OUT_DIR / "messages.hash"


def render() -> tuple[bytes, bytes]:
    result = load()
    if result.errors:
        raise SystemExit("i18n errors; run tools/i18n/check.py")
    messages: dict[str, dict] = {}
    for entry in result.entries:
        message = {
            key: value
            for key, value in entry.items()
            if key not in ("id", "global", "ref")
        }
        messages[entry["id"]] = message
    document = {"version": 1, "source": result.source, "messages": messages}
    payload = (
        json.dumps(document, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n"
    ).encode("utf-8")
    digest = ("sha256:" + hashlib.sha256(payload).hexdigest() + "\n").encode("ascii")
    return payload, digest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if generated files differ")
    args = parser.parse_args()

    payload, digest = render()
    if args.check:
        current_json = OUT_JSON.read_bytes() if OUT_JSON.exists() else b""
        current_hash = OUT_HASH.read_bytes() if OUT_HASH.exists() else b""
        if current_json != payload or current_hash != digest:
            print("generated i18n catalogue is out of date; run tools/i18n/build.py")
            return 1
        print(f"i18n generated catalogue: ok ({digest.decode().strip()})")
        return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_bytes(payload)
    OUT_HASH.write_bytes(digest)
    print(f"wrote {OUT_JSON.relative_to(ROOT)} ({len(payload)} bytes)")
    print(f"wrote {OUT_HASH.relative_to(ROOT)} ({digest.decode().strip()})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
