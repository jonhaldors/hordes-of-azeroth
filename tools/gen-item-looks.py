import re
import subprocess
from collections import defaultdict

MARIADB = r"G:\WoW Vanilla\server\mariadb\bin\mariadb.exe"
MIGRATION_ID = "20261030290000"
OUT = rf"G:\WoW Vanilla-benilla\server\core\sql\migrations\{MIGRATION_ID}_world.sql"

SHOP_VENDOR = 900004
SHOP_GREY_OFFSET = 20000
SET_FIRST, CLASS_COUNT, TIERS, SET_SLOTS = 903000, 9, 20, 8
MYTHIC_FIRST, LOOK_KINDS = 904500, 12
EPIC_OFFSET = 7000
OWN_ITEMS_FIRST = 900000

GREEN_LEVELS = (20, 30)
BLUE_LEVELS = (45, 60)
MOLTEN_CORE, BLACKWING_LAIR, AHNQIRAJ, NAXXRAMAS = 409, 469, 531, 533
EPIC_BANDS = [(12, [MOLTEN_CORE]), (16, [BLACKWING_LAIR]), (18, [AHNQIRAJ]), (20, [NAXXRAMAS])]
RAID_BOSSES = {
    MOLTEN_CORE: [12118, 11982, 12259, 12057, 12264, 12056, 12098, 11988, 12018, 11502],
    BLACKWING_LAIR: [12435, 13020, 12017, 11983, 14601, 11981, 14020, 11583],
    AHNQIRAJ: [15263, 15544, 15511, 15543, 15516, 15510, 15299, 15509, 15275, 15276, 15517, 15727, 15589],
    NAXXRAMAS: [15956, 15953, 15952, 15954, 15936, 16011, 16061, 16060, 16028, 15931, 15932, 15928, 15989, 15990],
}
RAID_CHESTS = {MOLTEN_CORE: [179703], NAXXRAMAS: [181366]}
JUNK_NAME = re.compile(r"(^Monster|Deprecated|^Test|TEST|^QA|\bOLD\b|\[PH\]|Unused|DEBUG)", re.IGNORECASE)
ONE_HANDED = {13, 21, 22}
CHEST = {5, 20}


def query(sql):
    out = subprocess.run([MARIADB, "--skip-ssl", "-h", "127.0.0.1", "-u", "root", "-proot", "-N", "-B", "mangos", "-e", sql],
                         capture_output=True, text=True, encoding="utf-8", check=True).stdout
    return [line.split("\t") for line in out.splitlines() if line]


def slot_key(item_class, subclass, inventory_type):
    if item_class == 2:
        if inventory_type in ONE_HANDED:
            return (2, subclass, "one")
        return (2, subclass, inventory_type)
    if inventory_type in CHEST:
        return (4, subclass, "chest")
    return (4, subclass, inventory_type)


def load_items():
    items = {}
    for row in query("SELECT entry, patch, class, subclass, name, display_id, quality, inventory_type, item_level, required_level, set_id, bonding "
                     "FROM item_template ORDER BY entry, patch"):
        entry, patch = int(row[0]), int(row[1])
        items[entry] = {
            "entry": entry, "class": int(row[2]), "subclass": int(row[3]), "name": row[4], "display": int(row[5]),
            "quality": int(row[6]), "inventory": int(row[7]), "item_level": int(row[8]), "required": int(row[9]),
            "set": int(row[10]), "bonding": int(row[11]),
        }
    return items


def obtainable_items():
    found = set()
    for table in ("creature_loot_template", "reference_loot_template", "gameobject_loot_template", "item_loot_template"):
        found.update(int(row[0]) for row in query(f"SELECT DISTINCT item FROM {table} WHERE mincountOrRef > 0"))
    found.update(int(row[0]) for row in query("SELECT DISTINCT item FROM npc_vendor"))
    return found


def raid_items(maps):
    creatures = {boss for raid in maps for boss in RAID_BOSSES.get(raid, [])}
    loot_ids = {int(row[1]) for row in query("SELECT entry, loot_id FROM creature_template WHERE loot_id <> 0")
                if int(row[0]) in creatures}
    loot = defaultdict(list)
    for entry, item, ref in query("SELECT entry, item, mincountOrRef FROM creature_loot_template"):
        loot[int(entry)].append((int(item), int(ref)))
    chests = [chest for raid in maps for chest in RAID_CHESTS.get(raid, [])]
    if chests:
        chest_list = ",".join(str(chest) for chest in chests)
        chest_loot = {int(row[0]) for row in query(f"SELECT data1 FROM gameobject_template WHERE entry IN ({chest_list}) AND data1 <> 0")}
        for entry, item, ref in query("SELECT entry, item, mincountOrRef FROM gameobject_loot_template"):
            if int(entry) in chest_loot:
                loot[-int(entry)].append((int(item), int(ref)))
        loot_ids.update(-entry for entry in chest_loot)
    references = defaultdict(list)
    for entry, item, ref in query("SELECT entry, item, mincountOrRef FROM reference_loot_template"):
        references[int(entry)].append((int(item), int(ref)))

    result = set()
    pending = [(rows, set()) for rows in (loot[loot_id] for loot_id in loot_ids)]
    seen_refs = set()
    while pending:
        rows, _ = pending.pop()
        for item, ref in rows:
            if ref > 0:
                result.add(item)
            elif item not in seen_refs:
                seen_refs.add(item)
                pending.append((references[item], set()))
    return result


def usable_source(item, obtainable):
    return (item["entry"] < OWN_ITEMS_FIRST and item["entry"] in obtainable and item["set"] == 0 and item["bonding"] != 4
            and item["display"] > 0 and not JUNK_NAME.search(item["name"]))


def loose_key(key):
    return (key[0], key[2]) if key[0] == 4 else key


def build_pool(items, obtainable, accept, keyed=slot_key):
    pool = defaultdict(list)
    for item in items.values():
        if usable_source(item, obtainable) and accept(item):
            pool[keyed(item["class"], item["subclass"], item["inventory"])].append(item)
    for key in pool:
        pool[key].sort(key=lambda item: (item["item_level"], item["entry"]))
    return pool


def pick(pool, key, tier, spread):
    choices = pool.get(key)
    if not choices:
        return None
    base = (tier - 1) * len(choices) // TIERS
    return choices[(base + spread) % len(choices)]


def sql_text(text):
    return text.replace("\\", "\\\\").replace("'", "''")


def main():
    items = load_items()
    obtainable = obtainable_items()
    greens = build_pool(items, obtainable, lambda i: i["quality"] == 2 and GREEN_LEVELS[0] <= i["required"] <= GREEN_LEVELS[1])
    blues = build_pool(items, obtainable, lambda i: i["quality"] == 3 and BLUE_LEVELS[0] <= i["required"] <= BLUE_LEVELS[1])
    raid_pools = {}
    for _, maps in EPIC_BANDS:
        members = raid_items(maps)
        raid_pools[tuple(maps)] = build_pool(items, obtainable, lambda i, m=members: i["quality"] == 4 and i["entry"] in m)
    big_raids = raid_items([MOLTEN_CORE, BLACKWING_LAIR, AHNQIRAJ, NAXXRAMAS])
    any_big_raid = build_pool(items, obtainable, lambda i: i["quality"] == 4 and i["entry"] in big_raids)
    raid_any_armor = build_pool(items, obtainable, lambda i: i["quality"] == 4 and i["entry"] in big_raids,
                                lambda c, sc, inv: loose_key(slot_key(c, sc, inv)))
    any_epic = build_pool(items, obtainable, lambda i: i["quality"] == 4 and i["item_level"] >= 60)
    any_green = build_pool(items, obtainable, lambda i: i["quality"] == 2)

    updates = []
    missing = defaultdict(int)

    def assign(entry, source, prefix=""):
        updates.append(f"UPDATE `item_template` SET `name` = '{sql_text(prefix + source['name'])}', `display_id` = {source['display']} WHERE `entry` = {entry};")

    shop_greens = [int(row[0]) for row in query(
        f"SELECT DISTINCT v.item FROM npc_vendor v JOIN item_template i ON i.entry = v.item WHERE v.entry = {SHOP_VENDOR} AND i.quality = 2")]
    for index, entry in enumerate(sorted(shop_greens)):
        target = items[entry]
        key = slot_key(target["class"], target["subclass"], target["inventory"])
        source = pick(greens, key, 1 + index % TIERS, index) or pick(any_green, key, 1 + index % TIERS, index)
        if not source:
            missing["green", target["inventory"], target["subclass"]] += 1
            continue
        assign(entry, source)
        if entry + SHOP_GREY_OFFSET in items:
            assign(entry + SHOP_GREY_OFFSET, source, "Tattered ")

    targets = []
    for class_index in range(CLASS_COUNT):
        for tier in range(1, TIERS + 1):
            for slot in range(SET_SLOTS):
                targets.append((SET_FIRST + (class_index * TIERS + tier - 1) * SET_SLOTS + slot, tier, class_index * 3 + slot))
    for kind in range(LOOK_KINDS):
        for tier in range(1, TIERS + 1):
            targets.append((MYTHIC_FIRST + kind * TIERS + tier - 1, tier, kind))

    for entry, tier, spread in targets:
        target = items.get(entry)
        if not target:
            continue
        key = slot_key(target["class"], target["subclass"], target["inventory"])
        blue = pick(blues, key, tier, spread)
        if blue:
            assign(entry, blue)
        else:
            missing["blue", key] += 1
        maps = next(maps for last_tier, maps in EPIC_BANDS if tier <= last_tier)
        epic = (pick(raid_pools[tuple(maps)], key, tier, spread) or pick(any_big_raid, key, tier, spread)
                or pick(raid_any_armor, loose_key(key), tier, spread)
                or pick(any_epic, key, tier, spread))
        if epic and entry + EPIC_OFFSET in items:
            assign(entry + EPIC_OFFSET, epic)
        else:
            missing["epic", key] += 1

    body = "\n".join(updates)
    with open(OUT, "w", encoding="utf-8", newline="\n") as out:
        out.write(f"""DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='{MIGRATION_ID}');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('{MIGRATION_ID}');

{body}

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
""")
    print(f"{len(updates)} updates written to {OUT}")
    for key, count in sorted(missing.items(), key=str):
        print("no source for", key, count)


if __name__ == "__main__":
    main()
