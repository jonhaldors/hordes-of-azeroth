# SPDX-License-Identifier: GPL-3.0-only
"""Load and validate the shared i18n message catalogue."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
MESSAGES = ROOT / "shared" / "i18n" / "messages"
ADDON = ROOT / "shared" / "i18n" / "addon"
UI = ROOT / "shared" / "i18n" / "ui"
LAUNCHER = ROOT / "shared" / "i18n" / "launcher"
CONFIG = ROOT / "shared" / "i18n" / "config.yaml"

ID_RE = re.compile(r"^hoa\.[a-z0-9_]+(\.[a-z0-9_]+)*$")
GLOBAL_RE = re.compile(r"^(?:HOA|BINDING|KEY)_[A-Z0-9_]+$")
PLACEHOLDER_RE = re.compile(r"\{(\d+)\}")


@dataclass
class Result:
    entries: list[dict[str, Any]]
    errors: list[str]
    warnings: list[str]
    languages: list[str]
    required: list[str]
    optional: list[str]
    source: str


def placeholders(text: str) -> list[int]:
    return sorted({int(value) for value in PLACEHOLDER_RE.findall(text)})


def load() -> Result:
    config = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))
    source = config["source_language"]
    required = list(config.get("required") or [source])
    optional = list(config.get("optional") or [])
    languages = list(dict.fromkeys([source, *required, *optional]))
    allowed = {"id", "legacy_server_id", "placeholders", "global", "ref", *languages}

    entries: list[dict[str, Any]] = []
    errors: list[str] = []
    warnings: list[str] = []
    seen_ids: set[str] = set()
    seen_legacy: set[int] = set()

    for path in sorted([*MESSAGES.glob("*.yaml"), *ADDON.glob("*.yaml"), *UI.glob("*.yaml"), *LAUNCHER.glob("*.yaml")]):
        relative = path.relative_to(ROOT)
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            errors.append(f"{relative}: top level must be a list")
            continue
        for index, entry in enumerate(data):
            where = f"{relative}[{index}]"
            if not isinstance(entry, dict):
                errors.append(f"{where}: entry must be a mapping")
                continue
            unknown = set(entry) - allowed
            if unknown:
                errors.append(f"{where}: unknown keys {sorted(unknown)}")
            message_id = entry.get("id")
            if not isinstance(message_id, str) or not ID_RE.match(message_id):
                errors.append(f"{where}: invalid id {message_id!r}")
                continue
            if message_id in seen_ids:
                errors.append(f"{where}: duplicate id {message_id}")
                continue
            seen_ids.add(message_id)
            if "legacy_server_id" in entry:
                legacy = entry["legacy_server_id"]
                if not isinstance(legacy, int):
                    errors.append(f"{message_id}: legacy_server_id must be an integer")
                elif legacy in seen_legacy:
                    errors.append(f"{message_id}: duplicate legacy_server_id {legacy}")
                else:
                    seen_legacy.add(legacy)
            if "ref" in entry:
                ref = entry["ref"]
                if not isinstance(ref, str) or not ID_RE.match(ref):
                    errors.append(f"{message_id}: invalid ref {ref!r}")
                for language in languages:
                    if language in entry:
                        errors.append(f"{message_id}: a ref entry must not carry {language}")
                if "placeholders" in entry:
                    errors.append(f"{message_id}: a ref entry must not carry placeholders")
            entries.append(entry)

    by_id = {entry["id"]: entry for entry in entries}

    def resolve(entry: dict[str, Any], trail: tuple[str, ...] = ()) -> None:
        ref = entry.get("ref")
        if ref is None:
            return
        if ref in trail:
            errors.append(f"{entry['id']}: ref cycle {' -> '.join([*trail, ref])}")
            return
        target = by_id.get(ref)
        if target is None:
            errors.append(f"{entry['id']}: ref target {ref} does not exist")
            return
        resolve(target, (*trail, entry["id"]))
        for language in languages:
            if language in target:
                entry[language] = target[language]
        if "placeholders" in target:
            entry["placeholders"] = target["placeholders"]

    for entry in entries:
        resolve(entry)

    seen_globals: set[str] = set()
    for entry in entries:
        message_id = entry["id"]
        global_name = entry.get("global")
        if global_name is not None:
            if not isinstance(global_name, str) or not GLOBAL_RE.match(global_name):
                errors.append(f"{message_id}: invalid global {global_name!r}")
            elif global_name in seen_globals:
                errors.append(f"{message_id}: duplicate global {global_name}")
            else:
                seen_globals.add(global_name)
        source_text = entry.get(source)
        if not isinstance(source_text, str) or not source_text.strip():
            errors.append(f"{message_id}: missing {source}")
            continue
        expected = placeholders(source_text)
        declared = entry.get("placeholders")
        if declared is not None and declared != expected:
            errors.append(
                f"{message_id}: declared placeholders {declared} != source placeholders {expected}"
            )
        for language in languages:
            if language == source:
                continue
            text = entry.get(language)
            if text is None or (isinstance(text, str) and not text.strip()):
                if language in required:
                    errors.append(f"{message_id}: missing required language {language}")
                else:
                    warnings.append(f"{message_id}: missing optional language {language}")
                continue
            if not isinstance(text, str):
                errors.append(f"{message_id}: {language} must be a string")
                continue
            found = placeholders(text)
            if found != expected:
                errors.append(
                    f"{message_id}: {language} placeholders {found} != {expected}"
                )

    entries.sort(key=lambda item: item["id"])
    return Result(entries, errors, warnings, languages, required, optional, source)
