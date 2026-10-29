import subprocess
import sys

MARIADB = r"G:\WoW Vanilla\server\mariadb\bin\mariadb.exe"
MIGRATION_ID = "20261028600002"
OUT = rf"G:\WoW Vanilla-mythic\server\core\sql\migrations\{MIGRATION_ID}_world.sql"

FIRST_ENTRY = 905000
TIERS = 20
LEGACY_LEGENDARIES = list(range(901420, 901428))

GROWTH = 1.12
GROWING = ("power", "max_health", "armor")
FLAT = ("dodge", "crit", "crit_damage", "shield", "haste", "area", "pickup_range", "luck")
SELL_GROWTH = 1.11


def query(sql):
    result = subprocess.run([MARIADB, "--host=127.0.0.1", "--skip-ssl", "-umangos", "-pmangos", "-N", "-B", "-e", sql],
                            capture_output=True, text=True, check=True)
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def legendaries():
    listed = ", ".join(str(e) for e in LEGACY_LEGENDARIES)
    columns = ", ".join(f"s.`{c}`" for c in GROWING + FLAT)
    rows = query(f"SELECT i.entry, i.sell_price, i.item_level, s.unlock_tier, {columns} FROM mangos.item_template i "
                 f"JOIN mangos.bonk_item_stat s ON s.entry = i.entry WHERE i.entry IN ({listed})")
    found = {int(r[0]): r for r in rows}
    missing = [e for e in LEGACY_LEGENDARIES if e not in found]
    if missing:
        sys.exit(f"legendaries missing: {missing}")
    result = []
    for entry in LEGACY_LEGENDARIES:
        row = found[entry]
        stats = dict(zip(GROWING + FLAT, (float(v) for v in row[4:])))
        result.append({"source": entry, "sell": int(row[1]), "level": int(row[2]), "unlock": int(row[3]), "stats": stats})
    return result


def write_migration(kinds):
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
        "DROP TEMPORARY TABLE IF EXISTS `legendary_map`;",
        "CREATE TEMPORARY TABLE `legendary_map` (`new_entry` INT UNSIGNED NOT NULL PRIMARY KEY, `src_entry` INT UNSIGNED NOT NULL, "
        "`tier` TINYINT UNSIGNED NOT NULL, `sell` INT UNSIGNED NOT NULL, `level` SMALLINT UNSIGNED NOT NULL, `unlock` INT UNSIGNED NOT NULL, "
        + ", ".join(f"`{c}` FLOAT NOT NULL" for c in GROWING + FLAT) + ");",
    ]
    values = []
    for index, kind in enumerate(kinds):
        for tier in range(1, TIERS + 1):
            entry = FIRST_ENTRY + index * TIERS + tier - 1
            growth = GROWTH ** (tier - 1)
            stats = [round(kind["stats"][c] * growth, 1) for c in GROWING] + [kind["stats"][c] for c in FLAT]
            sell = round(kind["sell"] * SELL_GROWTH ** (tier - 1))
            values.append(f"({entry}, {kind['source']}, {tier}, {sell}, {kind['level'] + tier - 1}, {kind['unlock']}, "
                          + ", ".join(f"{v:g}" for v in stats) + ")")
    for start in range(0, len(values), 100):
        lines.append("INSERT INTO `legendary_map` VALUES " + ", ".join(values[start:start + 100]) + ";")
    lines += [
        "",
        "DROP TEMPORARY TABLE IF EXISTS `legendary_items`;",
        "CREATE TEMPORARY TABLE `legendary_items` AS SELECT m.`new_entry`, m.`tier`, m.`sell`, m.`level`, t.* FROM `legendary_map` m "
        "JOIN `item_template` t ON t.`entry` = m.`src_entry`;",
        "UPDATE `legendary_items` SET `entry` = `new_entry`, `patch` = 0, `quality` = 5, `flags` = 0,",
        "    `buy_count` = 1, `buy_price` = 0, `sell_price` = `sell`, `item_level` = `level`, `required_level` = 0, `max_count` = 0, `bonding` = 1,",
        "    `random_property` = 0, `set_id` = 0, `disenchant_id` = 0;",
        "ALTER TABLE `legendary_items` DROP COLUMN `new_entry`, DROP COLUMN `tier`, DROP COLUMN `sell`, DROP COLUMN `level`;",
        f"DELETE FROM `item_template` WHERE `entry` BETWEEN {FIRST_ENTRY} AND {FIRST_ENTRY + len(kinds) * TIERS - 1};",
        "INSERT INTO `item_template` SELECT * FROM `legendary_items`;",
        "",
        f"DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN {FIRST_ENTRY} AND {FIRST_ENTRY + len(kinds) * TIERS - 1};",
        "INSERT INTO `bonk_item_stat` (`entry`, " + ", ".join(f"`{c}`" for c in GROWING + FLAT) + ", `set_id`, `unlock_tier`)",
        "SELECT `new_entry`, " + ", ".join(f"`{c}`" for c in GROWING + FLAT) + ", 0, `unlock` FROM `legendary_map`;",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `legendary_map`;",
        "DROP TEMPORARY TABLE IF EXISTS `legendary_items`;",
        "",
        "END IF;",
        "END??",
        "DELIMITER ;",
        "CALL add_migration();",
        "DROP PROCEDURE IF EXISTS add_migration;",
        "",
    ]
    with open(OUT, "x", encoding="utf-8", newline="\r\n") as handle:
        handle.write("\n".join(lines))


def main():
    kinds = legendaries()
    write_migration(kinds)
    print(f"{len(kinds) * TIERS} legendaries in {len(kinds)} kinds written to {OUT}")


if __name__ == "__main__":
    main()
