#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Fail on English-sentence keys left in addon/Glue Lua call sites."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / "addon" / "HordesOfAzeroth"
GLUE = ROOT / "glue" / "GlueXML"
L_INDEX = re.compile(r'L\["((?:[^"\\]|\\.)*)"\]')
L_CALL = re.compile(r'L\(\s*"((?:[^"\\]|\\.)*)"')
TEXT_CALL = re.compile(
    r'VanillaBonkLocale\.Text\(\s*[A-Za-z_.]+\s*,\s*"((?:[^"\\]|\\.)*)"'
)


def unescape(value: str) -> str:
    return (
        value.replace('\\"', '"')
        .replace("\\'", "'")
        .replace("\\n", "\n")
        .replace("\\r", "\r")
        .replace("\\t", "\t")
        .replace("\\\\", "\\")
    )


def scan(root: Path, skip: set[str]) -> list[str]:
    errors = []
    for path in sorted(root.rglob("*.lua")):
        if path.name in skip:
            continue
        text = path.read_text(encoding="utf-8")
        for regex in (L_INDEX, L_CALL, TEXT_CALL):
            for match in regex.finditer(text):
                key = unescape(match.group(1))
                if not key.startswith("hoa."):
                    line = text.count("\n", 0, match.start()) + 1
                    errors.append(f"{path.relative_to(ROOT)}:{line}: English L key {key!r}")
    return errors


def scan_launcher() -> list[str]:
    errors = []
    launcher = ROOT / "launcher"
    call = re.compile(r'Loc\.(?:T|Key)\(\s*"((?:[^"\\]|\\.)*)"')
    for path in sorted(launcher.glob("*.cs")):
        if path.name in {"LauncherStrings.g.cs", "Loc.cs"}:
            continue
        text = path.read_text(encoding="utf-8")
        for match in call.finditer(text):
            key = unescape(match.group(1))
            if not key.startswith("hoa.launcher."):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"{path.relative_to(ROOT)}:{line}: English launcher key {key!r}")
    attr = re.compile(r'\b(?:Text|Title|Header|Content|Tip)="([^"]+)"')
    for path in sorted(launcher.glob("*.axaml")):
        text = path.read_text(encoding="utf-8")
        for match in attr.finditer(text):
            value = match.group(1)
            if not value or value.startswith(("{", "http", "/", "avares", "pack")):
                continue
            if value.startswith("hoa.launcher."):
                continue
            if any(char.isalpha() for char in value):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"{path.relative_to(ROOT)}:{line}: literal launcher UI text {value!r}")
    return errors


def main() -> int:
    errors = scan(ADDON, {"VanillaBonkLocaleData.lua", "VanillaBonkLocale.lua"})
    errors += scan(GLUE, {"BonkGlueLocale.lua"})
    errors += scan_launcher()
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print("addon/glue/launcher call sites: stable IDs only")
    return 0


if __name__ == "__main__":
    sys.exit(main())
