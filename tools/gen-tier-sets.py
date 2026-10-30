import subprocess
import sys

MARIADB = r"G:\WoW Vanilla\server\mariadb\bin\mariadb.exe"
MIGRATION_ID = "20261027300006"
OUT = rf"G:\WoW Vanilla\server\core\sql\migrations\{MIGRATION_ID}_world.sql"

FIRST_ENTRY = 903000
TIERS = 20
SLOTS = [(1,), (3,), (5, 20), (6,), (7,), (8,), (9,), (10,)]
STARTING_ARMOR = {1: 3, 2: 3, 3: 2, 4: 2, 5: 1, 7: 2, 8: 1, 9: 1, 11: 2}
CLASS_SETS = [
    (1, (209, 218, 523)),
    (2, (208, 217, 528)),
    (3, (206, 215, 530)),
    (4, (204, 213, 524)),
    (5, (202, 211, 525)),
    (7, (207, 216, 527)),
    (8, (201, 210, 526)),
    (9, (203, 212, 529)),
    (11, (205, 214, 521)),
]
LOOK_BANDS = [(1, 10), (11, 19), (20, 20)]

VENDOR_ENTRY = 900150
VENDOR_GUID = 900013
VENDOR_NAME = "Varrok Steelbrand"
VENDOR_SUBNAME = "Mythic Quartermaster"
VENDOR_DISPLAY = 3342
VENDOR_POSITION = (16246.0, 16300.5, 20.846, 5.5)
SOURCE_VENDOR_ENTRY = 900004
SOURCE_VENDOR_GUID = 900004

GROWTH = 1.12
GROWING = {"power": 6.0, "max_health": 7.0, "armor": 3.5}
FLAT = {"dodge": 1.9, "crit": 2.0, "crit_damage": 3.0, "shield": 3.5}
UNLOCK_TIER = 3
PRICE_FIRST = 60000
PRICE_GROWTH = 1.11


def query(sql):
    result = subprocess.run([MARIADB, "--host=127.0.0.1", "-umangos", "-pmangos", "-N", "-B", "-e", sql],
                            capture_output=True, text=True, check=True)
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def source_piece(set_id, inventory_types):
    types = ", ".join(str(t) for t in inventory_types)
    rows = query(f"SELECT entry, MAX(patch) FROM mangos.item_template WHERE set_id = {set_id} AND inventory_type IN ({types}) GROUP BY entry")
    if len(rows) != 1:
        sys.exit(f"set {set_id} slot {inventory_types}: expected one piece, found {rows}")
    return int(rows[0][0]), int(rows[0][1])


def look_for_tier(tier):
    for index, (low, high) in enumerate(LOOK_BANDS):
        if low <= tier <= high:
            return index
    sys.exit(f"tier {tier} has no look")


def build_rows():
    sources = set()
    mapping = []
    for class_index, (_, set_ids) in enumerate(CLASS_SETS):
        for tier in range(1, TIERS + 1):
            set_id = set_ids[look_for_tier(tier)]
            for slot_index, inventory_types in enumerate(SLOTS):
                entry, patch = source_piece(set_id, inventory_types)
                sources.add((entry, patch))
                new_entry = FIRST_ENTRY + (class_index * TIERS + tier - 1) * len(SLOTS) + slot_index
                mapping.append((new_entry, entry, tier, STARTING_ARMOR[CLASS_SETS[class_index][0]]))
    return sorted(sources), mapping


def chunks(values, size):
    for start in range(0, len(values), size):
        yield values[start:start + size]


def write_migration(sources, mapping):
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
        "DROP TEMPORARY TABLE IF EXISTS `tier_map`;",
        "CREATE TEMPORARY TABLE `tier_map` (`new_entry` INT UNSIGNED NOT NULL PRIMARY KEY, `src_entry` INT UNSIGNED NOT NULL, "
        "`src_patch` TINYINT UNSIGNED NOT NULL, `tier` TINYINT UNSIGNED NOT NULL, `armor_type` TINYINT UNSIGNED NOT NULL);",
    ]
    patches = dict(sources)
    for part in chunks(mapping, 120):
        values = ", ".join(f"({new}, {src}, {patches[src]}, {tier}, {armor})" for new, src, tier, armor in part)
        lines.append(f"INSERT INTO `tier_map` VALUES {values};")
    lines += [
        "",
        "DROP TEMPORARY TABLE IF EXISTS `tier_items`;",
        "CREATE TEMPORARY TABLE `tier_items` AS SELECT m.`new_entry`, m.`tier`, m.`armor_type`, t.* FROM `tier_map` m "
        "JOIN `item_template` t ON t.`entry` = m.`src_entry` AND t.`patch` = m.`src_patch`;",
        "UPDATE `tier_items` SET `entry` = `new_entry`, `patch` = 0, `subclass` = `armor_type`, `description` = CONCAT('Tier ', `tier`), `quality` = 4, `flags` = 0,",
        f"    `buy_count` = 1, `buy_price` = ROUND({PRICE_FIRST} * POW({PRICE_GROWTH}, `tier` - 1)), `sell_price` = ROUND({PRICE_FIRST} * POW({PRICE_GROWTH}, `tier` - 1) / 10),",
        "    `item_level` = 60 + `tier`, `required_level` = 0, `allowable_race` = -1, `required_reputation_faction` = 0, `required_reputation_rank` = 0,",
        "    `required_honor_rank` = 0, `max_count` = 0, `armor` = 0, `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0, `arcane_res` = 0,",
        "    " + ", ".join(f"`stat_type{i}` = 0, `stat_value{i}` = 0" for i in range(1, 11)) + ",",
        "    " + ", ".join(f"`spellid_{i}` = 0, `spelltrigger_{i}` = 0" for i in range(1, 6)) + ",",
        "    `bonding` = 1, `random_property` = 0, `set_id` = 0, `disenchant_id` = 0;",
        "ALTER TABLE `tier_items` DROP COLUMN `new_entry`, DROP COLUMN `tier`, DROP COLUMN `armor_type`;",
        "INSERT INTO `item_template` SELECT * FROM `tier_items`;",
        "",
        "INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`, `unlock_tier`)",
        "SELECT `new_entry`, " + ", ".join(f"ROUND({value} * POW({GROWTH}, `tier` - 1), 1)" for value in GROWING.values()) + ", "
        + ", ".join(str(value) for value in FLAT.values()) + f", 0, 0, 0, 0, 0, {UNLOCK_TIER} FROM `tier_map`;",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `tier_vendor`;",
        f"CREATE TEMPORARY TABLE `tier_vendor` AS SELECT * FROM `creature_template` WHERE `entry` = {SOURCE_VENDOR_ENTRY};",
        f"UPDATE `tier_vendor` SET `entry` = {VENDOR_ENTRY}, `name` = '{VENDOR_NAME}', `subname` = '{VENDOR_SUBNAME}', `display_id1` = {VENDOR_DISPLAY};",
        "INSERT INTO `creature_template` SELECT * FROM `tier_vendor`;",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `tier_vendor_spawn`;",
        f"CREATE TEMPORARY TABLE `tier_vendor_spawn` AS SELECT * FROM `creature` WHERE `guid` = {SOURCE_VENDOR_GUID};",
        f"UPDATE `tier_vendor_spawn` SET `guid` = {VENDOR_GUID}, `id` = {VENDOR_ENTRY}, `position_x` = {VENDOR_POSITION[0]}, "
        f"`position_y` = {VENDOR_POSITION[1]}, `position_z` = {VENDOR_POSITION[2]}, `orientation` = {VENDOR_POSITION[3]};",
        "INSERT INTO `creature` SELECT * FROM `tier_vendor_spawn`;",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `tier_map`;",
        "DROP TEMPORARY TABLE IF EXISTS `tier_items`;",
        "DROP TEMPORARY TABLE IF EXISTS `tier_vendor`;",
        "DROP TEMPORARY TABLE IF EXISTS `tier_vendor_spawn`;",
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
    sources, mapping = build_rows()
    write_migration(sources, mapping)
    print(f"{len(mapping)} items from {len(sources)} source pieces written to {OUT}")


if __name__ == "__main__":
    main()
