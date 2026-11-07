"""Compile the custom aura source into SQL, C++ ids and the client display table.

An aura names the card/mastery/weapon/glyph row it belongs to; its name, icon and description
are inherited from that row unless `display` overrides a field with a stated reason. Auras with
no single owning row (core mechanics, shared behaviors) spell out their display and say why.

The compiler writes:
  - server/sql/content/hoa_spells.sql        spell_template clone rows
  - server/sql/content/hoa_aura.sql          hoa_aura + hoa_aura_locale rows
  - server/src/game/Bonk/BonkSpellIds.h      BONK_SPELL_* constants

The client gets names/icons/descriptions from the server-pushed aura catalog, so it keeps no
copy of this data.
"""

from __future__ import annotations

import re
from pathlib import Path

import yaml

from tables import load_table_dicts, load_table_rows

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "shared" / "content" / "spells" / "spells.yaml"
SQL_TARGET = ROOT / "server" / "sql" / "content" / "hoa_spells.sql"
AURA_SQL_TARGET = ROOT / "server" / "sql" / "content" / "hoa_aura.sql"
CPP_TARGET = ROOT / "server" / "src" / "game" / "Bonk" / "BonkSpellIds.h"
ADDON_TARGET = ROOT / "addon" / "HordesOfAzeroth" / "VanillaBonkAuraIds.lua"

BASE_ENTRY = 5302
BASE_BUILD = 5086
SPELL_BUILD = 5875
ID_FIRST = 60001
ID_LAST = 60099

TIMED_DURATION_INDEX = 28

SOURCE_KINDS = {"card", "mastery", "weapon", "glyph", "keyword", "behavior", "none"}
STACK_SOURCES = {"none", "aura", "copies", "kills", "seconds", "wounds"}
DYNAMIC_KINDS = {"none", "shield_absorb", "wounds_heal_cut", "stack_percent", "card_total"}
DYNAMIC_TEMPLATE_KINDS = {"shield_absorb", "wounds_heal_cut", "stack_percent"}
DYNAMIC_IDS = {
    "none": 0,
    "shield_absorb": 1,
    "wounds_heal_cut": 2,
    "stack_percent": 3,
    "card_total": 4,
}
ENTRY_KEYS = {"id", "key", "cpp", "native", "source", "source_field", "reason", "display", "stacks", "permanent", "dynamic"}
DISPLAY_KEYS = {"name", "name_zhCN", "icon", "description", "description_zhCN", "reason"}
STACK_KEYS = {"source", "max"}
DYNAMIC_KEYS = {"kind", "enUS", "zhCN"}

PLACEHOLDER_RE = re.compile(r"\{(\d+)\}")


class SourceIndex:
    """The card/mastery/weapon/glyph rows an aura may bind to, with their zhCN text."""

    def __init__(self) -> None:
        self.cards = {
            int(row["id"]): row for row in yaml.safe_load((ROOT / "shared" / "content" / "cards" / "cards.yaml").read_text(encoding="utf-8"))
        }
        self.tables: dict[str, dict[int, dict]] = {}
        self.locales: dict[str, dict[tuple[int, str], dict]] = {}
        for kind in ("mastery", "weapon", "glyph", "keyword"):
            self.tables[kind] = {int(row["id"]): row for row in load_table_dicts(f"bonk_{kind}")}
            columns, rows = load_table_rows(f"bonk_{kind}_locale")
            index = {column: position for position, column in enumerate(columns)}
            self.locales[kind] = {
                (int(row[index["id"]]), str(row[index["locale"]])): {
                    column: row[position]
                    for column, position in index.items()
                    if column not in ("id", "locale")
                }
                for row in rows
            }
        self.behaviors: dict[int, list[dict]] = {}
        for row in self.tables["weapon"].values():
            behavior = int(row.get("behavior") or 0)
            self.behaviors.setdefault(behavior, []).append(row)


def parse_source(value) -> tuple[str, int | None]:
    if not isinstance(value, str) or not value.strip():
        raise SystemExit("spells.yaml: every aura needs a source")
    value = value.strip()
    if value == "none":
        return "none", None
    kind, separator, ident = value.partition(":")
    if kind not in SOURCE_KINDS - {"none"} or not separator or not ident.isdigit():
        raise SystemExit(f"spells.yaml: bad source {value!r}")
    return kind, int(ident)


def normalize_icon(icon: str) -> str:
    icon = icon.strip().replace("/", "\\")
    if not icon:
        raise SystemExit("spells.yaml: empty icon")
    if icon.startswith("Interface\\Icons\\"):
        return icon
    if "\\" in icon:
        return icon
    return "Interface\\Icons\\" + icon


def source_display(kind: str, source_id: int | None, sources: SourceIndex, field: str = "description") -> dict | None:
    """The inherited display row, or None for sources that own no single row."""
    if kind == "none":
        return None
    if kind == "behavior":
        owners = sources.behaviors.get(int(source_id))
        if not owners:
            raise SystemExit(f"spells.yaml: behavior {source_id} has no weapon row")
        return None
    if kind == "card":
        if field != "description":
            raise SystemExit("spells.yaml: source_field only applies to glyphs")
        card = sources.cards.get(int(source_id))
        if not card:
            raise SystemExit(f"spells.yaml: card {source_id} does not exist")
        for name in ("name", "name_zhCN", "description", "description_zhCN"):
            if not card.get(name):
                raise SystemExit(f"spells.yaml: card {source_id} is missing {name}")
        return {
            "name": card["name"],
            "name_zhCN": card["name_zhCN"],
            "icon": normalize_icon(card["icon"]),
            "description": card["description"],
            "description_zhCN": card["description_zhCN"],
        }
    if field == "drawback" and kind != "glyph":
        raise SystemExit("spells.yaml: source_field only applies to glyphs")
    row = sources.tables[kind].get(int(source_id))
    if not row:
        raise SystemExit(f"spells.yaml: {kind} {source_id} does not exist")
    localized = sources.locales[kind].get((int(source_id), "zhCN"), {})
    for name in ("name", field):
        if not row.get(name):
            raise SystemExit(f"spells.yaml: {kind} {source_id} is missing {name}")
        if not localized.get(name):
            raise SystemExit(f"spells.yaml: {kind} {source_id} has no zhCN {name}")
    return {
        "name": row["name"],
        "name_zhCN": localized["name"],
        "icon": normalize_icon(row["icon"]),
        "description": row[field],
        "description_zhCN": localized[field],
    }


def resolve_display(entry: dict, kind: str, source_id: int | None, sources: SourceIndex, field: str, native: bool) -> dict:
    display = entry.get("display")
    inherited = source_display(kind, source_id, sources, field)
    if display is None:
        if inherited is None:
            raise SystemExit(f"spells.yaml: aura {entry['id']} needs a display block")
        return inherited
    if not isinstance(display, dict):
        raise SystemExit(f"spells.yaml: aura {entry['id']} display must be a mapping")
    extra = set(display) - DISPLAY_KEYS
    if extra:
        raise SystemExit(f"spells.yaml: aura {entry['id']} has unknown display keys {sorted(extra)}")
    reason = display.get("reason") or entry.get("reason")
    if not isinstance(reason, str) or not reason.strip():
        raise SystemExit(f"spells.yaml: aura {entry['id']} display needs a reason")
    overrides = {key: value for key, value in display.items() if key != "reason"}
    if inherited is not None and not overrides:
        raise SystemExit(f"spells.yaml: aura {entry['id']} display has a reason but no override")
    if inherited is None:
        if native:
            missing = {"description", "description_zhCN"} - set(overrides)
            if missing:
                raise SystemExit(f"spells.yaml: native aura {entry['id']} display is missing {sorted(missing)}")
            return {
                "name": overrides.get("name", ""),
                "name_zhCN": overrides.get("name_zhCN", ""),
                "icon": normalize_icon(overrides["icon"]) if overrides.get("icon") else "",
                "description": overrides["description"],
                "description_zhCN": overrides["description_zhCN"],
            }
        missing = {"name", "name_zhCN", "icon", "description", "description_zhCN"} - set(overrides)
        if missing:
            raise SystemExit(f"spells.yaml: aura {entry['id']} display is missing {sorted(missing)}")
        return {
            "name": overrides["name"],
            "name_zhCN": overrides["name_zhCN"],
            "icon": normalize_icon(overrides["icon"]),
            "description": overrides["description"],
            "description_zhCN": overrides["description_zhCN"],
        }
    resolved = dict(inherited)
    for field, value in overrides.items():
        if not isinstance(value, str) or not value.strip():
            raise SystemExit(f"spells.yaml: aura {entry['id']} display.{field} is empty")
        if field == "icon":
            value = normalize_icon(value)
            if value == inherited[field]:
                raise SystemExit(f"spells.yaml: aura {entry['id']} display.icon does not differ from its source")
        elif value == inherited[field]:
            raise SystemExit(f"spells.yaml: aura {entry['id']} display.{field} does not differ from its source")
        resolved[field] = value
    return resolved


def stack_max(entry: dict, kind: str, source_id: int | None, sources: SourceIndex) -> int:
    stacks = entry.get("stacks")
    if not isinstance(stacks, dict):
        raise SystemExit(f"spells.yaml: aura {entry['id']} needs a stacks mapping")
    extra = set(stacks) - STACK_KEYS
    if extra:
        raise SystemExit(f"spells.yaml: aura {entry['id']} has unknown stacks keys {sorted(extra)}")
    source = stacks.get("source")
    if source not in STACK_SOURCES:
        raise SystemExit(f"spells.yaml: aura {entry['id']} has a bad stack source {source!r}")
    explicit = stacks.get("max")
    if explicit is not None:
        if not isinstance(explicit, int) or not 0 <= explicit <= 255:
            raise SystemExit(f"spells.yaml: aura {entry['id']} has a bad stack max")
        return explicit
    if source == "copies":
        if kind == "card":
            return int(sources.cards[int(source_id)].get("max_copies") or 255)
        return 255
    if source == "kills":
        return 255
    if source == "seconds":
        if kind == "card":
            values = sources.cards[int(source_id)].get("values") or []
            if len(values) >= 2 and float(values[0]) > 0:
                return min(255, int(float(values[1]) / float(values[0])))
        return 255
    if source in ("aura",):
        if kind == "keyword":
            return int(sources.tables["keyword"][int(source_id)].get("max_stacks") or 0)
        raise SystemExit(f"spells.yaml: aura {entry['id']} stacks.aura needs an explicit max")
    return 0


def resolve_dynamic(entry: dict, kind: str) -> tuple[str, str, str]:
    dynamic = entry.get("dynamic")
    if not isinstance(dynamic, dict):
        raise SystemExit(f"spells.yaml: aura {entry['id']} needs a dynamic mapping")
    extra = set(dynamic) - DYNAMIC_KEYS
    if extra:
        raise SystemExit(f"spells.yaml: aura {entry['id']} has unknown dynamic keys {sorted(extra)}")
    dynamic_kind = dynamic.get("kind")
    if dynamic_kind not in DYNAMIC_KINDS:
        raise SystemExit(f"spells.yaml: aura {entry['id']} has a bad dynamic kind {dynamic_kind!r}")
    if dynamic_kind == "card_total" and kind != "card":
        raise SystemExit(f"spells.yaml: aura {entry['id']} dynamic card_total needs a card source")
    if dynamic_kind not in DYNAMIC_TEMPLATE_KINDS:
        # A card aura's text is the held card's description, sent per copy count, so its template
        # is optional; one that names a template (the surge window's live bonus) is honored.
        if dynamic_kind != "card_total":
            return dynamic_kind, "", ""
        if not any(isinstance(dynamic.get(locale), str) and dynamic.get(locale, "").strip()
                   for locale in ("enUS", "zhCN")):
            return dynamic_kind, "", ""
    templates = {}
    for locale in ("enUS", "zhCN"):
        template = dynamic.get(locale)
        if not isinstance(template, str) or not template.strip():
            raise SystemExit(f"spells.yaml: aura {entry['id']} dynamic.{locale} is missing")
        templates[locale] = template
    en_placeholders = sorted({int(value) for value in PLACEHOLDER_RE.findall(templates["enUS"])})
    zh_placeholders = sorted({int(value) for value in PLACEHOLDER_RE.findall(templates["zhCN"])})
    if not en_placeholders or en_placeholders != zh_placeholders:
        raise SystemExit(f"spells.yaml: aura {entry['id']} dynamic templates disagree on placeholders")
    if any(value < 1 for value in en_placeholders):
        raise SystemExit(f"spells.yaml: aura {entry['id']} dynamic placeholders start at 1")
    return dynamic_kind, templates["enUS"], templates["zhCN"]


def load_spells() -> list[dict]:
    data = yaml.safe_load(SOURCE.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit("spells.yaml: top level must be a list")
    sources = SourceIndex()
    seen_ids: set[int] = set()
    seen_keys: set[str] = set()
    seen_cpp: set[str] = set()
    resolved: list[dict] = []
    for entry in data:
        if not isinstance(entry, dict):
            raise SystemExit("spells.yaml: every entry must be a mapping")
        extra = set(entry) - ENTRY_KEYS
        if extra:
            raise SystemExit(f"spells.yaml: aura {entry.get('id')} has unknown keys {sorted(extra)}")
        native = entry.get("native", False)
        if not isinstance(native, bool):
            raise SystemExit(f"spells.yaml: aura {entry.get('id')} native must be true/false")
        spell_id = entry.get("id")
        if not isinstance(spell_id, int) or not (1 <= spell_id <= 0xFFFF):
            raise SystemExit(f"spells.yaml: bad id {spell_id!r}")
        if not native and not ID_FIRST <= spell_id <= ID_LAST:
            raise SystemExit(f"spells.yaml: custom aura id {spell_id} is outside {ID_FIRST}-{ID_LAST}")
        if spell_id in seen_ids:
            raise SystemExit(f"spells.yaml: duplicate id {spell_id}")
        seen_ids.add(spell_id)
        key = entry.get("key")
        if not isinstance(key, str) or not key or key in seen_keys:
            raise SystemExit(f"spells.yaml: spell {spell_id} has a bad or duplicate key")
        seen_keys.add(key)
        cpp = entry.get("cpp")
        if native:
            if cpp is not None:
                raise SystemExit(f"spells.yaml: native aura {spell_id} must not declare a cpp constant")
        else:
            if not isinstance(cpp, str) or not cpp.startswith("BONK_SPELL_") or cpp in seen_cpp:
                raise SystemExit(f"spells.yaml: spell {spell_id} has a bad or duplicate cpp name")
            seen_cpp.add(cpp)
        kind, source_id = parse_source(entry.get("source"))
        source_field = entry.get("source_field", "description")
        if source_field not in ("description", "drawback"):
            raise SystemExit(f"spells.yaml: aura {spell_id} has a bad source_field {source_field!r}")
        if source_field != "description" and kind != "glyph":
            raise SystemExit(f"spells.yaml: aura {spell_id} source_field only applies to glyphs")
        display = resolve_display(entry, kind, source_id, sources, source_field, native)
        permanent = entry.get("permanent")
        if not isinstance(permanent, bool):
            raise SystemExit(f"spells.yaml: aura {spell_id} needs a permanent true/false")
        dynamic_kind, template_en, template_zh = resolve_dynamic(entry, kind)
        resolved.append(
            {
                "id": spell_id,
                "key": key,
                "cpp": cpp,
                "native": native,
                "source_kind": kind,
                "source_id": source_id,
                "name": display["name"],
                "name_zhCN": display["name_zhCN"],
                "icon": display["icon"],
                "description": display["description"],
                "description_zhCN": display["description_zhCN"],
                "stack_amount": stack_max(entry, kind, source_id, sources),
                "duration_index": 0 if permanent else TIMED_DURATION_INDEX,
                "dynamic_kind": dynamic_kind,
                "dynamic_template": template_en,
                "dynamic_template_zhCN": template_zh,
            }
        )
    return resolved


def quote(text: str) -> str:
    return "'" + str(text).replace("\\", "\\\\").replace("'", "''") + "'"


def compile_sql(spells: list[dict]) -> bytes:
    custom = [spell for spell in spells if not spell["native"]]
    lines = [
        "-- Generated by tools/content/compile.py from shared/content/spells/spells.yaml.",
        "-- Do not edit by hand.",
        "",
        f"DELETE FROM `spell_template` WHERE `entry` BETWEEN {ID_FIRST} AND {ID_LAST};",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `hoa_spell_clone`;",
        "CREATE TEMPORARY TABLE `hoa_spell_clone` LIKE `spell_template`;",
        "INSERT INTO `hoa_spell_clone` SELECT * FROM `spell_template` "
        f"WHERE `entry` = {BASE_ENTRY} AND `build` = {BASE_BUILD};",
    ]
    for spell in custom:
        lines.append(f"UPDATE `hoa_spell_clone` SET `entry` = {spell['id']}, `build` = {SPELL_BUILD};")
        lines.append("INSERT INTO `spell_template` SELECT * FROM `hoa_spell_clone`;")
    lines += ["DROP TEMPORARY TABLE `hoa_spell_clone`;", ""]
    for spell in custom:
        lines += [
            "UPDATE `spell_template` SET",
            f"  `name` = {quote(spell['name'])},",
            "  `nameSubtext` = '',",
            f"  `description` = {quote(spell['description'])},",
            f"  `auraDescription` = {quote(spell['description'])},",
            f"  `spellIconId` = {spell['id']},",
            f"  `stackAmount` = {int(spell['stack_amount'])},",
            f"  `durationIndex` = {int(spell['duration_index'])},",
            "  `attributes` = 0,",
            "  `attributesEx` = 0,",
            "  `attributesEx2` = 0,",
            "  `attributesEx3` = 0,",
            "  `attributesEx4` = 0",
            f"WHERE `entry` = {spell['id']} AND `build` = {SPELL_BUILD};",
            "",
        ]
    return "\n".join(lines).encode("utf-8")


def compile_aura_sql(spells: list[dict]) -> bytes:
    lines = [
        "-- Generated by tools/content/compile.py from shared/content/spells/spells.yaml.",
        "-- Do not edit by hand. Schema lives in server/sql/migrations/20261104130000_world.sql.",
        "",
        "DELETE FROM `hoa_aura`;",
        "INSERT INTO `hoa_aura` (`entry`, `key`, `icon`, `name`, `description`, `stack_max`, `duration_index`, "
        "`visible`, `dynamic_kind`, `dynamic_template`, `source_kind`, `source_id`)",
        "VALUES",
    ]
    rows = []
    for spell in spells:
        source_id = "NULL" if spell["source_id"] is None else str(spell["source_id"])
        rows.append(
            "  ("
            + ", ".join(
                [
                    str(spell["id"]),
                    quote(spell["key"]),
                    quote(spell["icon"]),
                    quote(spell["name"]),
                    quote(spell["description"]),
                    str(spell["stack_amount"]),
                    str(spell["duration_index"]),
                    "1",
                    str(DYNAMIC_IDS[spell["dynamic_kind"]]),
                    quote(spell["dynamic_template"]),
                    quote(spell["source_kind"]),
                    source_id,
                ]
            )
            + ")"
        )
    lines += [",\n".join(rows) + ";", "", "DELETE FROM `hoa_aura_locale`;"]
    locale_rows = [
        "  ("
        + ", ".join(
            [
                str(spell["id"]),
                quote("zhCN"),
                quote(spell["name_zhCN"]),
                quote(spell["description_zhCN"]),
                quote(spell["dynamic_template_zhCN"]),
            ]
        )
        + ")"
        for spell in spells
    ]
    lines += [
        "INSERT INTO `hoa_aura_locale` (`entry`, `locale`, `name`, `description`, `dynamic_template`)",
        "VALUES",
        ",\n".join(locale_rows) + ";",
        "",
    ]
    return "\n".join(lines).encode("utf-8")


def compile_cpp(spells: list[dict]) -> bytes:
    lines = [
        "#pragma once",
        "",
        "// Generated by tools/content/compile.py from shared/content/spells/spells.yaml.",
        "// Do not edit by hand.",
        "",
    ]
    lines += [f"uint32 const {spell['cpp']} = {spell['id']};" for spell in spells if not spell["native"]]
    lines.append("")
    return "\n".join(lines).encode("utf-8")


def compile_addon_ids(spells: list[dict]) -> bytes:
    lines = [
        "-- Generated by tools/content/compile.py from shared/content/spells/spells.yaml.",
        "-- Do not edit by hand.",
        "",
        "HOA_AURA_IDS = {",
    ]
    for spell in spells:
        lines.append(f"    {spell['key']} = {spell['id']},")
    lines += ["}", ""]
    return "\n".join(lines).encode("utf-8")


def spell_outputs() -> list[tuple[str, Path, bytes]]:
    spells = load_spells()
    return [
        ("spells sql", SQL_TARGET, compile_sql(spells)),
        ("auras sql", AURA_SQL_TARGET, compile_aura_sql(spells)),
        ("spells cpp", CPP_TARGET, compile_cpp(spells)),
        ("addon aura ids", ADDON_TARGET, compile_addon_ids(spells)),
    ]
