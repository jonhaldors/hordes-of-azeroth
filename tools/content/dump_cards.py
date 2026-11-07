#!/usr/bin/env python3
"""Dump the current bonk_card tables into the shared content source.

One-time import from the running database; after this, edit
`shared/content/cards/cards.yaml` and run `tools/content/compile.py`.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "shared" / "content" / "cards" / "cards.yaml"


def query(maria: str, database: str, sql: str) -> list[list[str]]:
    result = subprocess.run(
        [
            maria,
            "--skip-ssl",
            "-h",
            "127.0.0.1",
            "-P",
            "3306",
            "-u",
            "root",
            "-proot",
            "--default-character-set=utf8mb4",
            "--batch",
            "--raw",
            "-N",
            database,
            "-e",
            sql,
        ],
        capture_output=True,
        check=True,
    )
    return [line.split("\t") for line in result.stdout.decode("utf-8").splitlines() if line]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--maria", required=True, help="path to the mariadb client")
    parser.add_argument("--database", default="mangos_052")
    args = parser.parse_args()

    rows = query(
        args.maria,
        args.database,
        "SELECT `id`,`name`,`icon`,`description`,`rarity`,`stat1`,`stat1_value`,`stat2`,`stat2_value`,"
        "`effect`,`value1`,`value2`,`value3`,`cooldown_ms`,`max_copies`,`in_chests` "
        "FROM `bonk_card` ORDER BY `id`",
    )
    localized = {}
    for row in query(args.maria, args.database, "SELECT `id`,`name`,`description` FROM `bonk_card_locale` WHERE `locale`='zhCN'"):
        localized[int(row[0])] = (row[1], row[2])

    entries = []
    for row in rows:
        card_id = int(row[0])
        stats = []
        for effect, value in ((int(row[5]), float(row[6])), (int(row[7]), float(row[8]))):
            if effect != 255:
                stats.append({"effect": effect, "value": value})
        entry = {
            "id": card_id,
            "name": row[1],
            "icon": row[2],
            "description": row[3],
            "rarity": int(row[4]),
            "stats": stats,
            "effect": int(row[9]),
            "values": [float(row[10]), float(row[11]), float(row[12])],
            "cooldown_ms": int(row[13]),
            "max_copies": int(row[14]),
            "in_chests": row[15] == "1",
        }
        if card_id in localized:
            entry["name_zhCN"], entry["description_zhCN"] = localized[card_id]
        entries.append(entry)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    body = yaml.safe_dump(entries, allow_unicode=True, sort_keys=False, width=4096)
    OUT.write_text(
        "# Imported by tools/content/dump_cards.py from bonk_card and bonk_card_locale.\n"
        "# Edit this file, then run tools/content/compile.py.\n" + body,
        encoding="utf-8",
    )
    print(f"wrote {OUT.relative_to(ROOT)}: {len(entries)} cards")
    return 0


if __name__ == "__main__":
    sys.exit(main())
