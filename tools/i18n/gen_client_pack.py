#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Generate the client UI language packs from shared/i18n/ui."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from catalogue import ROOT, load

OUT_DIR = ROOT / "client" / "crates" / "benilla-app" / "assets" / "i18n"


def global_name(entry: dict) -> str:
    return entry.get("global") or entry["id"].upper().replace(".", "_")


def render() -> dict[str, bytes]:
    result = load()
    if result.errors:
        raise SystemExit("i18n errors; run tools/i18n/check.py")

    entries = [entry for entry in result.entries if entry["id"].startswith("hoa.ui.")]
    globals_map: dict[str, str] = {}
    aliases: dict[str, str] = {}
    alias_text: dict[str, str] = {}
    fallback = {entry["id"]: entry["enUS"] for entry in entries}
    messages = {
        "enUS": fallback,
        "zhCN": {entry["id"]: entry["zhCN"] for entry in entries},
        "zhTW": {entry["id"]: entry.get("zhTW", entry["enUS"]) for entry in entries},
    }

    for entry in entries:
        name = global_name(entry)
        if name in globals_map:
            raise SystemExit(
                f"duplicate global {name}: {globals_map[name]} and {entry['id']}"
            )
        globals_map[name] = entry["id"]
        if name.startswith(("BINDING_", "KEY_")):
            # Stock key labels can share an English word with UI prose ("Delete"); they are not
            # English-sentence aliases for Lua call sites.
            continue
        english = entry["enUS"]
        existing = alias_text.get(english)
        if existing is not None and existing != entry["zhCN"]:
            raise SystemExit(
                f"duplicate enUS {english!r} has two zhCN texts: {aliases[english]} and {entry['id']}"
            )
        aliases.setdefault(english, entry["id"])
        alias_text.setdefault(english, entry["zhCN"])

    packs: dict[str, bytes] = {}
    for locale in ("enUS", "zhCN", "zhTW"):
        document = {
            "version": 1,
            "locale": locale,
            "fallback": "enUS",
            "messages": messages[locale],
            "fallbackMessages": fallback,
            "globals": globals_map,
            "aliases": aliases,
        }
        packs[locale] = (
            json.dumps(document, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
            + "\n"
        ).encode("utf-8")
    return packs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if generated files differ")
    args = parser.parse_args()

    packs = render()
    if args.check:
        for locale, payload in packs.items():
            path = OUT_DIR / f"{locale}.json"
            current = path.read_bytes() if path.exists() else b""
            if current != payload:
                print(f"{path.relative_to(ROOT)} is out of date; run tools/i18n/gen_client_pack.py")
                return 1
        print("client language packs: ok")
        return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for locale, payload in packs.items():
        path = OUT_DIR / f"{locale}.json"
        path.write_bytes(payload)
        print(f"wrote {path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
