import importlib.util
import sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("gen_gear", HERE / "gen-gear.py")
gear = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gear)

DUNGEON_LOOK_FIRST = 933000
LOOKS_PER_BAND = 3
EPIC = 4
ZUL_GURUB, RUINS_OF_AHNQIRAJ = 309, 509
BANDS = [ZUL_GURUB, RUINS_OF_AHNQIRAJ]
gear.RAID_BOSSES[ZUL_GURUB] = [14834, 14517, 14507, 14510, 14509, 14515, 11380, 11382, 15114, 15082, 15083, 15084, 15085, 14750]
gear.RAID_BOSSES[RUINS_OF_AHNQIRAJ] = [15348, 15341, 15340, 15370, 15369, 15339]
VISIBLE_INVENTORY = {1, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 25, 26}
WEAPON_GROUP = {15: "dagger", 0: "one", 4: "one", 7: "one", 13: "one", 1: "two", 5: "two", 6: "two", 8: "two", 10: "two",
                2: "ranged", 3: "ranged", 16: "ranged", 18: "ranged", 19: "ranged"}


def dungeon_entry(band_index, kind, look):
    return DUNGEON_LOOK_FIRST + (band_index * gear.GEAR_KINDS + kind) * LOOKS_PER_BAND + look - 1


def look_key(item):
    if item["class"] == 2:
        return ("weapon", WEAPON_GROUP.get(item["subclass"]), "one" if item["inventory"] in gear.ONE_HANDED else item["inventory"])
    if item["class"] == 4 and item["subclass"] == 6:
        return ("shield",)
    if item["inventory"] in gear.CHEST:
        return ("armor", "chest")
    return ("armor", item["inventory"])


def band_pool(items, obtainable, band):
    members = gear.raid_items([band])
    pool = defaultdict(list)
    for item in items.values():
        if (item["entry"] < gear.OWN_ITEMS_FIRST and item["entry"] in members and item["quality"] >= 3 and item["display"] > 0
                and item["inventory"] in VISIBLE_INVENTORY and not gear.JUNK_NAME.search(item["name"])):
            pool[look_key(item)].append(item)
    for key in pool:
        pool[key].sort(key=lambda item: (-item["quality"], item["item_level"], item["entry"]))
    return pool


def distinct_looks(choices, count):
    picked, displays = [], set()
    for item in choices:
        if item["display"] not in displays:
            picked.append(item)
            displays.add(item["display"])
        if len(picked) == count:
            break
    return picked


def build_rows(items, stats):
    obtainable = gear.obtainable_items()
    rows, missing = [], []
    for band_index, band in enumerate(BANDS):
        pool = band_pool(items, obtainable, band)
        for kind in range(gear.GEAR_KINDS):
            template = gear.gear_entry(kind, EPIC, 1)
            source = items.get(template)
            if not source or source["inventory"] not in VISIBLE_INVENTORY or template not in stats:
                continue
            looks = distinct_looks(pool.get(look_key(source), []), LOOKS_PER_BAND)
            if not looks:
                missing.append((band, kind, source["name"]))
                continue
            for look_index, look in enumerate(looks, start=1):
                rows.append({"entry": dungeon_entry(band_index, kind, look_index), "source": template, "name": look["name"],
                             "display": look["display"], "stats": stats[template]["stats"]})
    return rows, missing


def world_body(rows):
    columns = gear.GROWING + gear.FLAT
    first, last = DUNGEON_LOOK_FIRST, DUNGEON_LOOK_FIRST + len(BANDS) * gear.GEAR_KINDS * LOOKS_PER_BAND - 1
    body = [
        f"DELETE FROM `item_template` WHERE `entry` BETWEEN {first} AND {last};",
        f"DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN {first} AND {last};",
        "DROP TEMPORARY TABLE IF EXISTS `look_map`;",
        "CREATE TEMPORARY TABLE `look_map` (`new_entry` INT UNSIGNED NOT NULL PRIMARY KEY, `src_entry` INT UNSIGNED NOT NULL, "
        "`new_name` VARCHAR(255) NOT NULL, `new_display` INT UNSIGNED NOT NULL);",
    ]
    for part in gear.chunked(rows):
        body.append("INSERT INTO `look_map` VALUES " + ", ".join(
            f"({row['entry']}, {row['source']}, {gear.sql_text(row['name'])}, {row['display']})" for row in part) + ";")
    body += [
        "DROP TEMPORARY TABLE IF EXISTS `look_items`;",
        "CREATE TEMPORARY TABLE `look_items` AS SELECT m.`new_entry`, m.`new_name`, m.`new_display`, t.* FROM `look_map` m "
        "JOIN `item_template` t ON t.`entry` = m.`src_entry` AND t.`patch` = 0;",
        "UPDATE `look_items` SET `entry` = `new_entry`, `name` = `new_name`, `display_id` = `new_display`;",
        "ALTER TABLE `look_items` DROP COLUMN `new_entry`, DROP COLUMN `new_name`, DROP COLUMN `new_display`;",
        "INSERT INTO `item_template` SELECT * FROM `look_items`;",
        "INSERT INTO `bonk_item_stat` (`entry`, " + ", ".join(f"`{c}`" for c in columns) + ")",
        "SELECT m.`new_entry`, " + ", ".join(f"s.`{c}`" for c in columns) + " FROM `look_map` m JOIN `bonk_item_stat` s ON s.`entry` = m.`src_entry`;",
        "DROP TEMPORARY TABLE IF EXISTS `look_map`;",
        "DROP TEMPORARY TABLE IF EXISTS `look_items`;",
    ]
    return body


def load_stats_current():
    columns = ", ".join(f"`{c}`" for c in gear.GROWING + gear.FLAT)
    return {int(row[0]): {"stats": [float(v) for v in row[1:]]} for row in gear.query(f"SELECT entry, {columns} FROM bonk_item_stat")}


def main():
    migration_id = sys.argv[1]
    items = gear.load_items()
    stats = load_stats_current()
    rows, missing = build_rows(items, stats)
    path = gear.MIGRATIONS / f"{migration_id}_world.sql"
    with open(path, "x", encoding="utf-8", newline="\n") as handle:
        handle.write(gear.wrap(migration_id, world_body(rows)))
    print(path, len(rows), "looks")
    for band, kind, name in missing:
        print("no look for band", band, "kind", kind, name)


if __name__ == "__main__":
    main()
