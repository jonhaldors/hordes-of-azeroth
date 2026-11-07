"""Generic table source dump/compile for the design-content tables."""

from __future__ import annotations

import subprocess
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
TABLE_DIR = ROOT / "shared" / "content" / "tables"
SQL_DIR = ROOT / "server" / "sql" / "content"

# Spawn tables and the generated string table stay in the database; these are the
# hand-authored design tables.
DESIGN_TABLES = [
    "bonk_archetype",
    "bonk_archetype_locale",
    "bonk_bolt_look",
    "bonk_boss_line",
    "bonk_glossary",
    "bonk_glyph",
    "bonk_glyph_locale",
    "bonk_hidden",
    "bonk_hidden_locale",
    "bonk_item_card",
    "bonk_item_stat",
    "bonk_keyword",
    "bonk_keyword_locale",
    "bonk_level",
    "bonk_map",
    "bonk_map_creature",
    "bonk_map_event",
    "bonk_map_locale",
    "bonk_map_start",
    "bonk_mastery",
    "bonk_mastery_locale",
    "bonk_mastery_tree",
    "bonk_mastery_tree_locale",
    "bonk_mob",
    "bonk_mob_ability",
    "bonk_passive",
    "bonk_passive_locale",
    "bonk_pet_ability",
    "bonk_pet_family",
    "bonk_pet_family_locale",
    "bonk_powerup",
    "bonk_quest",
    "bonk_quest_locale",
    "bonk_scaling",
    "bonk_shop_tree",
    "bonk_shop_tree_locale",
    "bonk_talent",
    "bonk_talent_locale",
    "bonk_tier",
    "bonk_tier_locale",
    "bonk_title",
    "bonk_title_locale",
    "bonk_upgrade",
    "bonk_upgrade_locale",
    "bonk_wave",
    "bonk_wave_locale",
    "bonk_weapon",
    "bonk_weapon_locale",
    "bonk_weapon_upgrade",
]


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


def convert(value: str, column_type: str):
    if value == "NULL":
        return None
    lowered = column_type.lower()
    if "int" in lowered:
        return int(value)
    if any(kind in lowered for kind in ("float", "double", "decimal")):
        return float(value)
    return value


def dump_tables(maria: str, database: str, tables: list[str] | None = None) -> list[str]:
    written = []
    for table in tables or DESIGN_TABLES:
        columns = query(maria, database, f"SHOW COLUMNS FROM `{database}`.`{table}`")
        names = [column[0] for column in columns]
        types = [column[1] for column in columns]
        order = ", ".join(str(index) for index in range(1, len(names) + 1))
        raw = query(maria, database, f"SELECT * FROM `{database}`.`{table}` ORDER BY {order}")
        rows = []
        for row in raw:
            if len(row) != len(names):
                raise RuntimeError(f"{table}: expected {len(names)} fields, got {len(row)}")
            rows.append([convert(value, types[index]) for index, value in enumerate(row)])
        path = TABLE_DIR / f"{table}.yaml"
        path.parent.mkdir(parents=True, exist_ok=True)
        body = yaml.safe_dump(
            {"table": table, "columns": names, "rows": rows},
            allow_unicode=True,
            sort_keys=False,
            width=4096,
        )
        path.write_text(
            f"# Imported by tools/content/dump_tables.py from {table}. "
            "Edit this file, then run tools/content/compile.py.\n" + body,
            encoding="utf-8",
        )
        written.append(str(path.relative_to(ROOT)))
    return written


def quote(text: str) -> str:
    return "'" + str(text).replace("\\", "\\\\").replace("'", "''") + "'"


def literal(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return format(value, ".10g")
    return quote(value)


def load_table_rows(table: str) -> tuple[list[str], list[list]]:
    path = TABLE_DIR / f"{table}.yaml"
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("table") != table:
        raise SystemExit(f"{path.name}: expected table {table!r}")
    return data["columns"], data["rows"]


def load_table_dicts(table: str) -> list[dict]:
    columns, rows = load_table_rows(table)
    return [dict(zip(columns, row)) for row in rows]


def compile_table(path: Path) -> bytes:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    table = data["table"]
    columns = data["columns"]
    rows = data["rows"]
    if path.stem != table:
        raise SystemExit(f"{path.name}: table field {table!r} does not match the file name")
    for row in rows:
        if len(row) != len(columns):
            raise SystemExit(f"{path.name}: row has {len(row)} fields, expected {len(columns)}")
    lines = [
        f"-- Generated by tools/content/compile.py from shared/content/tables/{path.name}.",
        "-- Do not edit by hand.",
        "",
        f"DELETE FROM `{table}`;",
    ]
    if rows:
        lines += [
            f"INSERT INTO `{table}` (" + ", ".join(f"`{column}`" for column in columns) + ")",
            "VALUES",
            ",\n".join(
                "  (" + ", ".join(literal(value) for value in row) + ")" for row in rows
            )
            + ";",
        ]
    lines.append("")
    return "\n".join(lines).encode("utf-8")


def compile_tables() -> list[tuple[Path, bytes]]:
    outputs = []
    for path in sorted(TABLE_DIR.glob("*.yaml")):
        outputs.append((path, compile_table(path)))
    return outputs
