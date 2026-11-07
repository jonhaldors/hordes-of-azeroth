#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Static checks for documentation, provenance and bilingual pairs."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
PAIR_DIRS = [
    ROOT / "shared",
    ROOT / "shared" / "content",
    ROOT / "shared" / "i18n",
    ROOT / "shared" / "protocol",
    ROOT / "tools",
    ROOT / "scripts",
    ROOT / ".github" / "workflows",
]
PAIR_FILES = [
    ROOT / "README.md",
    ROOT / "BUILDING.md",
]
SCAN_ROOTS = [ROOT / "*.md", ROOT / "docs", ROOT / "shared", ROOT / "scripts", ROOT / ".github"]

errors: list[str] = []


def error(message: str) -> None:
    errors.append(message)


def check_pairs() -> None:
    files = list(PAIR_FILES)
    for directory in PAIR_DIRS:
        files.extend(directory.glob("*.md"))
    for directory in (ROOT / "docs").rglob("*"):
        if directory.is_dir():
            files.extend(directory.glob("*.md"))
    seen: set[Path] = set()
    for path in files:
        if path.name.startswith("README") or path.name == "UPSTREAM.md":
            continue
        base = path.stem
        if base.endswith("_zh"):
            continue
        zh = path.with_name(f"{base}_zh.md")
        if not zh.exists():
            error(f"missing Chinese pair: {path.relative_to(ROOT)}")
    for path in (ROOT / "docs").rglob("README_zh.md"):
        en = path.with_name("README.md")
        if not en.exists():
            error(f"missing English pair: {path.relative_to(ROOT)}")
    for path in (ROOT / "docs").rglob("README.md"):
        zh = path.with_name("README_zh.md")
        if not zh.exists():
            error(f"missing Chinese pair: {path.relative_to(ROOT)}")
    for base in PAIR_FILES:
        zh = base.with_name(base.stem + "_zh.md")
        if not zh.exists():
            error(f"missing Chinese pair: {base.relative_to(ROOT)}")
    for directory in PAIR_DIRS:
        if not (directory / "README.md").exists() or not (directory / "README_zh.md").exists():
            error(f"missing README pair in {directory.relative_to(ROOT)}")


def check_links() -> None:
    link_re = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
    files: list[Path] = []
    for pattern in SCAN_ROOTS:
        files.extend(ROOT.glob(pattern) if isinstance(pattern, str) else pattern.rglob("*.md"))
    files = [p for p in files if p.is_file() and p.suffix == ".md"]
    for path in sorted(set(files)):
        if ".git" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        for match in link_re.finditer(text):
            target = match.group(1).strip()
            if target.startswith(("http://", "https://", "#", "mailto:", "/")):
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            resolved = (path.parent / target).resolve()
            if not resolved.exists():
                error(f"broken link in {path.relative_to(ROOT)}: {target}")


def check_provenance() -> None:
    version_file = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    data = yaml.safe_load((ROOT / "provenance.yaml").read_text(encoding="utf-8"))
    if str(data.get("version")) != version_file:
        error(f"provenance version {data.get('version')} does not match VERSION {version_file}")
    snapshots = data.get("snapshots") or []
    if not snapshots:
        error("provenance.yaml has no snapshots")
    for item in snapshots:
        path = ROOT / item["path"]
        if not path.exists():
            error(f"provenance path does not exist: {item['path']}")
            continue
        upstream = item.get("upstream", "")
        source = item.get("source", "")
        for url in (upstream, source):
            if not url.startswith("https://"):
                error(f"provenance URL is not https in {item['path']}: {url}")
        commit = item.get("commit", "")
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            error(f"provenance commit is not a full SHA in {item['path']}: {commit}")
        if not item.get("license"):
            error(f"provenance has no license for {item['path']}")
        upstream_md = path / "UPSTREAM.md"
        if not upstream_md.exists():
            error(f"missing UPSTREAM.md in {item['path']}")
            continue
        text = upstream_md.read_text(encoding="utf-8")
        if commit not in text:
            error(f"UPSTREAM.md in {item['path']} does not record commit {commit}")


def main() -> int:
    check_pairs()
    check_links()
    check_provenance()
    if errors:
        for item in errors:
            print(f"ERROR: {item}")
        print(f"{len(errors)} documentation/provenance error(s)")
        return 1
    print("documentation, links and provenance: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
