#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Validate the shipped client UI against the generated language packs."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "client" / "crates" / "benilla-app" / "assets"
PACKS = ASSETS / "i18n"
UI_XML = ASSETS / "ui"
GLUE_XML = ROOT / "glue" / "GlueXML"
GLUE_LUA = [
    GLUE_XML / "BonkGlue.lua",
    GLUE_XML / "BonkCoop.lua",
    GLUE_XML / "BonkClassInfo.lua",
    GLUE_XML / "BonkGluePad.lua",
]
HOA_KEY = re.compile(r"\bHOA_UI_[A-Z0-9_]+\b")
TEXT_ATTR = re.compile(r'\btext="([^"]*)"')
LUA_TEXT_ASSIGN = re.compile(r'\btext\s*=\s*"([^"]*)"')
SET_TEXT_LITERAL = re.compile(r'\bSetText\("([^"]*)"\)')
L_INDEX = re.compile(r'L\["((?:[^"\\]|\\.)*)"\]')
L_CALL = re.compile(r'L\("((?:[^"\\]|\\.)*)"')


def is_literal_ui_text(value: str) -> bool:
    if not value or HOA_KEY.fullmatch(value):
        return False
    if value.isdigit() or value.startswith("|c"):
        return False
    return any(char.isalpha() for char in value)


def unescape(value: str) -> str:
    return (
        value.replace('\\"', '"')
        .replace("\\'", "'")
        .replace("\\n", "\n")
        .replace("\\r", "\r")
        .replace("\\t", "\t")
        .replace("\\\\", "\\")
    )


def strip_xml_comments(text: str) -> str:
    return re.sub(r"<!--.*?-->", "", text, flags=re.S)


def load_pack(locale: str) -> dict:
    return json.loads((PACKS / f"{locale}.json").read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    locales = ("enUS", "zhCN", "zhTW")
    packs = {locale: load_pack(locale) for locale in locales}
    globals_en = packs["enUS"]["globals"]
    aliases = packs["enUS"]["aliases"]

    def missing_key(key: str) -> str | None:
        for locale in locales:
            if key not in packs[locale]["globals"]:
                return locale
        return None

    for path in sorted(UI_XML.glob("*.xml")):
        text = strip_xml_comments(path.read_text(encoding="utf-8"))
        for key in sorted(set(HOA_KEY.findall(text))):
            locale = missing_key(key)
            if locale:
                errors.append(f"{path.name}: {key} is missing from {locale}")
        for value in (
            TEXT_ATTR.findall(text)
            + LUA_TEXT_ASSIGN.findall(text)
            + SET_TEXT_LITERAL.findall(text)
        ):
            if is_literal_ui_text(value):
                errors.append(f"{path.name}: non-key UI text {value!r}")
        for key in ("OPTION_TOOLTIP_", "BENILLA_TOOLTIP_"):
            for match in re.finditer(key, text):
                # BENILLA_TOOLTIP_* are now global-key string constants, not untranslated keys.
                if key == "BENILLA_TOOLTIP_":
                    continue
                errors.append(f"{path.name}: leftover {key} at byte {match.start()}")

    for path in [GLUE_XML / "BonkGlue.xml", GLUE_XML / "BonkCoop.xml", GLUE_XML / "BonkGluePad.xml"]:
        text = strip_xml_comments(path.read_text(encoding="utf-8"))
        for key in sorted(set(HOA_KEY.findall(text))):
            locale = missing_key(key)
            if locale:
                errors.append(f"{path.name}: {key} is missing from {locale}")
        for value in (
            TEXT_ATTR.findall(text)
            + LUA_TEXT_ASSIGN.findall(text)
            + SET_TEXT_LITERAL.findall(text)
        ):
            if is_literal_ui_text(value):
                errors.append(f"{path.name}: non-key UI text {value!r}")

    for path in GLUE_LUA:
        text = path.read_text(encoding="utf-8")
        values = {unescape(value) for value in L_INDEX.findall(text)}
        values.update(unescape(value) for value in L_CALL.findall(text))
        for value in sorted(values):
            if value.startswith("hoa."):
                if value not in packs["enUS"]["messages"]:
                    errors.append(f"{path.name}: L id {value!r} is not in the pack")
                continue
            if value not in aliases:
                errors.append(f"{path.name}: L key {value!r} has no language-pack alias")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(
        f"client UI: {len(globals_en)} globals checked across "
        f"{len(list(UI_XML.glob('*.xml')))} layer files and 3 Glue files"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
