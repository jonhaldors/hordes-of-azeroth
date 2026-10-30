import subprocess
import sys

MARIADB = r"G:\WoW Vanilla\server\mariadb\bin\mariadb.exe"
MIGRATION_ID = "20261027800000"
OUT = rf"G:\WoW Vanilla-qm-core\sql\migrations\{MIGRATION_ID}_world.sql"

FIRST_ENTRY = 904500
TIERS = 20
GEAR_VENDOR_ENTRY = 900004
MYTHIC_UNLOCK_TIER = 3

GROWTH = 1.12
GROWING = ("power", "max_health", "armor")
FLAT = ("dodge", "crit", "crit_damage", "shield", "haste", "area", "pickup_range", "luck")
PRICE_PER_SOURCE_GOLD = 60000 / 400000
PRICE_GROWTH = 1.11

WEAPONS = [902262, 902265, 902268, 902271, 902274, 902277, 902280, 902283, 902286]
ACCESSORIES = [902111, 902102, 902105]
TRINKET_SOURCE = 902108
TRINKET_STATS = {"power": 22.5, "armor": 1.7, "dodge": 2.8}
TRINKETS = [
    ("Gnomish Battle Goggles", 22420),
    ("Goblin Land Mine", 7626),
    ("Nifty Stopwatch", 6540),
    ("Goblin Rocket Boots", 20622),
    ("Demonic Rune", 22952),
    ("Rumsey Rum", 18119),
    ("Grinning Skull of Wrath", 5215),
    ("Goblin Pocket Gold", 9649),
]


def query(sql):
    result = subprocess.run([MARIADB, "--host=127.0.0.1", "-umangos", "-pmangos", "-N", "-B", "-e", sql],
                            capture_output=True, text=True, check=True)
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def source_rows(entries):
    listed = ", ".join(str(e) for e in entries)
    columns = ", ".join(f"s.`{c}`" for c in GROWING + FLAT)
    rows = query(f"SELECT i.entry, i.name, i.buy_price, {columns} FROM mangos.item_template i "
                 f"JOIN mangos.bonk_item_stat s ON s.entry = i.entry WHERE i.entry IN ({listed})")
    found = {int(r[0]): r for r in rows}
    missing = [e for e in entries if e not in found]
    if missing:
        sys.exit(f"source items missing: {missing}")
    return found


def kinds():
    sources = source_rows(WEAPONS + ACCESSORIES + [TRINKET_SOURCE])
    result = []
    for entry in WEAPONS + ACCESSORIES:
        row = sources[entry]
        stats = dict(zip(GROWING + FLAT, (float(v) for v in row[3:])))
        result.append({"source": entry, "name": row[1].replace("Mythic ", "", 1), "display": None,
                       "price": int(row[2]) * PRICE_PER_SOURCE_GOLD, "stats": stats})
    trinket_price = int(sources[TRINKET_SOURCE][2]) * PRICE_PER_SOURCE_GOLD
    for name, display in TRINKETS:
        stats = {key: TRINKET_STATS.get(key, 0.0) for key in GROWING + FLAT}
        result.append({"source": TRINKET_SOURCE, "name": name, "display": display, "price": trinket_price, "stats": stats})
    return result


def sql_text(value):
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def write_migration(gear_kinds):
    lines = [
        "DROP PROCEDURE IF EXISTS add_migration;",
        "DELIMITER ??",
        "CREATE PROCEDURE `add_migration`()",
        "BEGIN",
        "DECLARE v INT DEFAULT 1;",
        f"SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='{MIGRATION_ID}');",
        "IF v = 0 THEN",
        f"INSERT INTO `migrations` VALUES ('{MIGRATION_ID}');",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `mythic_map`;",
        "CREATE TEMPORARY TABLE `mythic_map` (`new_entry` INT UNSIGNED NOT NULL PRIMARY KEY, `src_entry` INT UNSIGNED NOT NULL, "
        "`tier` TINYINT UNSIGNED NOT NULL, `new_name` VARCHAR(255) NOT NULL, `new_display` INT UNSIGNED NULL, `price` INT UNSIGNED NOT NULL, "
        + ", ".join(f"`{c}` FLOAT NOT NULL" for c in GROWING + FLAT) + ");",
    ]
    values = []
    for index, kind in enumerate(gear_kinds):
        for tier in range(1, TIERS + 1):
            entry = FIRST_ENTRY + index * TIERS + tier - 1
            growth = GROWTH ** (tier - 1)
            stats = [round(kind["stats"][c] * growth, 1) for c in GROWING] + [kind["stats"][c] for c in FLAT]
            display = "NULL" if kind["display"] is None else str(kind["display"])
            price = round(kind["price"] * PRICE_GROWTH ** (tier - 1))
            values.append(f"({entry}, {kind['source']}, {tier}, {sql_text(kind['name'])}, {display}, {price}, "
                          + ", ".join(f"{v:g}" for v in stats) + ")")
    for start in range(0, len(values), 100):
        lines.append("INSERT INTO `mythic_map` VALUES " + ", ".join(values[start:start + 100]) + ";")
    lines += [
        "",
        "DROP TEMPORARY TABLE IF EXISTS `mythic_items`;",
        "CREATE TEMPORARY TABLE `mythic_items` AS SELECT m.`new_entry`, m.`tier`, m.`new_name`, m.`new_display`, m.`price`, t.* FROM `mythic_map` m "
        "JOIN `item_template` t ON t.`entry` = m.`src_entry`;",
        "UPDATE `mythic_items` SET `entry` = `new_entry`, `patch` = 0, `name` = `new_name`, `display_id` = COALESCE(`new_display`, `display_id`),",
        "    `description` = CONCAT('Tier ', `tier`), `quality` = 4, `flags` = IF(`new_display` IS NULL, 0, 524288), `buy_count` = 1, `buy_price` = `price`, `sell_price` = ROUND(`price` / 10),",
        "    `item_level` = 60 + `tier`, `required_level` = 0, `max_count` = 0, `bonding` = 1, `random_property` = 0, `set_id` = 0, `disenchant_id` = 0;",
        "ALTER TABLE `mythic_items` DROP COLUMN `new_entry`, DROP COLUMN `tier`, DROP COLUMN `new_name`, DROP COLUMN `new_display`, DROP COLUMN `price`;",
        "INSERT INTO `item_template` SELECT * FROM `mythic_items`;",
        "",
        "INSERT INTO `bonk_item_stat` (`entry`, " + ", ".join(f"`{c}`" for c in GROWING + FLAT) + ", `set_id`, `unlock_tier`)",
        "SELECT `new_entry`, " + ", ".join(f"`{c}`" for c in GROWING + FLAT) + f", 0, {MYTHIC_UNLOCK_TIER} FROM `mythic_map`;",
        "",
        f"DELETE v FROM `npc_vendor` v JOIN `bonk_item_stat` s ON s.`entry` = v.`item` WHERE v.`entry` = {GEAR_VENDOR_ENTRY} AND s.`unlock_tier` = {MYTHIC_UNLOCK_TIER};",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `mythic_map`;",
        "DROP TEMPORARY TABLE IF EXISTS `mythic_items`;",
        "",
        "END IF;",
        "END??",
        "DELIMITER ;",
        "CALL add_migration();",
        "DROP PROCEDURE IF EXISTS add_migration;",
        "",
    ]
    with open(OUT, "x", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines))


def main():
    gear_kinds = kinds()
    write_migration(gear_kinds)
    print(f"{len(gear_kinds) * TIERS} items in {len(gear_kinds)} kinds written to {OUT}")


if __name__ == "__main__":
    main()
