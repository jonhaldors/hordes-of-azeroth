import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

MARIADB = r"G:\WoW Vanilla\server\mariadb\bin\mariadb.exe"
MIGRATIONS = Path(__file__).resolve().parent.parent / "server" / "core" / "sql" / "migrations"
WORLD_ID = "20261031400000"
CHARACTERS_ID = "20261031400001"

GEAR_FIRST = 930000
LEGENDARY_FIRST = 932000
TIERS = 10
QUALITIES = (1, 2, 3, 4)
TIER_STEP = 0.25
QUALITY_SCALE = {1: (1.0, 1.0), 2: (1.0, 1.0), 3: (1.1, 1.0), 4: (1.45, 1.2), 5: (1.0, 1.0)}
QUALITY_PRICE = {1: 0.5, 2: 0.75, 3: 1.0, 4: 1.5}
PRICE_FIRST = 60000
PRICE_POWER = 1.3
PRICE_SLOT_BASE = 58296

GROWING = ("power", "max_health", "armor")
FLAT = ("dodge", "crit", "crit_damage", "shield", "haste", "area", "pickup_range", "luck")

ARMOR_SLOTS = (1, 3, 5, 6, 7, 8, 9, 10)
ARMOR_TYPES = ((1, 400, 4), (2, 1100, 2), (3, 3, 0))
OLD_SET_FIRST, OLD_SET_TIERS, OLD_SET_SLOTS, OLD_SET_CLASSES = 903000, 20, 8, 9
OLD_SET_ARMOR = {0: 2, 1: 2, 2: 1, 3: 1, 4: 0, 5: 1, 6: 0, 7: 0, 8: 1}
OLD_MYTHIC_FIRST, OLD_MYTHIC_KINDS = 904500, 20
OLD_LEGENDARY_FIRST, OLD_LEGACY_LEGENDARY, LEGENDARY_KINDS = 905000, 901420, 8
OLD_EPIC_OFFSET = 7000
FIRST_WEAPON_KIND = len(ARMOR_SLOTS) * len(ARMOR_TYPES)
FIRST_TRINKET_KIND = FIRST_WEAPON_KIND + 12
GEAR_KINDS = FIRST_WEAPON_KIND + OLD_MYTHIC_KINDS
OLD_UNLOCK_TIER = {0: 1, 1: 4, 3: 8}
SHOP_VENDOR = 900004
OLD_TIER_VENDOR, OLD_TIER_VENDOR_GUID, OLD_TIER_VENDOR_TEXT = 900150, 900013, 900015

WHITE_LEVELS = (10, 24)
GREEN_LEVELS = (25, 40)
BLUE_LEVELS = (45, 60)
MOLTEN_CORE, BLACKWING_LAIR, AHNQIRAJ, NAXXRAMAS = 409, 469, 531, 533
EPIC_BANDS = [(4, [MOLTEN_CORE]), (7, [BLACKWING_LAIR]), (9, [AHNQIRAJ]), (10, [NAXXRAMAS])]
RAID_BOSSES = {
    MOLTEN_CORE: [12118, 11982, 12259, 12057, 12264, 12056, 12098, 11988, 12018, 11502],
    BLACKWING_LAIR: [12435, 13020, 12017, 11983, 14601, 11981, 14020, 11583],
    AHNQIRAJ: [15263, 15544, 15511, 15543, 15516, 15510, 15299, 15509, 15275, 15276, 15517, 15727, 15589],
    NAXXRAMAS: [15956, 15953, 15952, 15954, 15936, 16011, 16061, 16060, 16028, 15931, 15932, 15928, 15989, 15990],
}
RAID_CHESTS = {MOLTEN_CORE: [179703], NAXXRAMAS: [181366]}
JUNK_NAME = re.compile(r"(^Monster|Deprecated|^Test|TEST|^QA|\bOLD\b|\[PH\]|Unused|DEBUG)", re.IGNORECASE)
OWN_ITEMS_FIRST = 900000
ONE_HANDED = {13, 21, 22}
CHEST = {5, 20}
GEAR_INVENTORY_TYPES = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 20, 21, 22, 23, 26}
WEAPON_KIND_BY_SUBCLASS = {7: 0, 0: 0, 4: 1, 15: 2, 13: 2, 8: 3, 1: 3, 5: 4, 10: 5, 6: 5, 2: 6, 3: 6, 18: 6, 16: 6, 19: 6}


def query(sql):
    out = subprocess.run([MARIADB, "--skip-ssl", "-h", "127.0.0.1", "-u", "mangos", "-pmangos", "-N", "-B", "mangos", "-e", sql],
                         capture_output=True, text=True, encoding="utf-8", check=True).stdout
    return [line.split("\t") for line in out.splitlines() if line]


def gear_entry(kind, quality, tier):
    return GEAR_FIRST + (kind * len(QUALITIES) + quality - 1) * TIERS + tier - 1


def legendary_entry(kind, tier):
    return LEGENDARY_FIRST + kind * TIERS + tier - 1


def slot_key(item_class, subclass, inventory_type):
    if item_class == 2:
        return (2, subclass, "one") if inventory_type in ONE_HANDED else (2, subclass, inventory_type)
    if inventory_type in CHEST:
        return (4, subclass, "chest")
    return (4, subclass, inventory_type)


def load_items():
    items = {}
    for row in query("SELECT entry, class, subclass, name, display_id, quality, inventory_type, item_level, required_level, set_id, bonding, buy_price "
                     "FROM item_template ORDER BY entry, patch"):
        items[int(row[0])] = {
            "entry": int(row[0]), "class": int(row[1]), "subclass": int(row[2]), "name": row[3], "display": int(row[4]),
            "quality": int(row[5]), "inventory": int(row[6]), "item_level": int(row[7]), "required": int(row[8]),
            "set": int(row[9]), "bonding": int(row[10]), "buy": int(row[11]),
        }
    return items


def load_stats():
    columns = ", ".join(f"`{c}`" for c in GROWING + FLAT)
    return {int(row[0]): {"stats": dict(zip(GROWING + FLAT, (float(v) for v in row[1:-1]))), "unlock": int(row[-1])}
            for row in query(f"SELECT entry, {columns}, unlock_tier FROM bonk_item_stat")}


def obtainable_items():
    found = set()
    for table in ("creature_loot_template", "reference_loot_template", "gameobject_loot_template", "item_loot_template"):
        found.update(int(row[0]) for row in query(f"SELECT DISTINCT item FROM {table} WHERE mincountOrRef > 0"))
    found.update(int(row[0]) for row in query("SELECT DISTINCT item FROM npc_vendor"))
    return found


def raid_items(maps):
    creatures = {boss for raid in maps for boss in RAID_BOSSES.get(raid, [])}
    loot_ids = {int(row[1]) for row in query("SELECT entry, loot_id FROM creature_template WHERE loot_id <> 0") if int(row[0]) in creatures}
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
    pending = [loot[loot_id] for loot_id in loot_ids]
    seen_refs = set()
    while pending:
        for item, ref in pending.pop():
            if ref > 0:
                result.add(item)
            elif item not in seen_refs:
                seen_refs.add(item)
                pending.append(references[item])
    return result


def build_pool(items, obtainable, accept, keyed=slot_key):
    pool = defaultdict(list)
    for item in items.values():
        if (item["entry"] < OWN_ITEMS_FIRST and item["entry"] in obtainable and item["set"] == 0 and item["bonding"] != 4
                and item["display"] > 0 and not JUNK_NAME.search(item["name"]) and accept(item)):
            pool[keyed(item["class"], item["subclass"], item["inventory"])].append(item)
    for key in pool:
        pool[key].sort(key=lambda item: (item["item_level"], item["entry"]))
    return pool


def loose_key(key):
    return (key[0], key[2]) if key[0] == 4 else key


def pick(pool, key, tier, spread):
    choices = pool.get(key)
    if not choices:
        return None
    return choices[((tier - 1) * len(choices) // TIERS + spread) % len(choices)]


class Looks:
    def __init__(self, items):
        obtainable = obtainable_items()
        self.white = build_pool(items, obtainable, lambda i: i["quality"] == 2 and WHITE_LEVELS[0] <= i["required"] <= WHITE_LEVELS[1])
        self.green = build_pool(items, obtainable, lambda i: i["quality"] == 2 and GREEN_LEVELS[0] <= i["required"] <= GREEN_LEVELS[1])
        self.any_green = build_pool(items, obtainable, lambda i: i["quality"] == 2)
        self.blue = build_pool(items, obtainable, lambda i: i["quality"] == 3 and BLUE_LEVELS[0] <= i["required"] <= BLUE_LEVELS[1])
        self.any_blue = build_pool(items, obtainable, lambda i: i["quality"] == 3)
        self.raids = {}
        for _, maps in EPIC_BANDS:
            members = raid_items(maps)
            self.raids[tuple(maps)] = build_pool(items, obtainable, lambda i, m=members: i["quality"] == 4 and i["entry"] in m)
        big_raids = raid_items([MOLTEN_CORE, BLACKWING_LAIR, AHNQIRAJ, NAXXRAMAS])
        self.any_raid = build_pool(items, obtainable, lambda i: i["quality"] == 4 and i["entry"] in big_raids)
        self.raid_any_armor = build_pool(items, obtainable, lambda i: i["quality"] == 4 and i["entry"] in big_raids,
                                         lambda c, sc, inv: loose_key(slot_key(c, sc, inv)))
        self.any_epic = build_pool(items, obtainable, lambda i: i["quality"] == 4 and i["item_level"] >= 60)
        self.missing = defaultdict(int)

    def find(self, key, quality, tier, spread):
        if quality == 1:
            found = pick(self.white, key, tier, spread) or pick(self.any_green, key, tier, spread)
        elif quality == 2:
            found = pick(self.green, key, tier, spread) or pick(self.any_green, key, tier, spread)
        elif quality == 3:
            found = pick(self.blue, key, tier, spread) or pick(self.any_blue, key, tier, spread)
        else:
            maps = next(maps for last_tier, maps in EPIC_BANDS if tier <= last_tier)
            found = (pick(self.raids[tuple(maps)], key, tier, spread) or pick(self.any_raid, key, tier, spread)
                     or pick(self.raid_any_armor, loose_key(key), tier, spread) or pick(self.any_epic, key, tier, spread))
        if not found:
            self.missing[quality, key] += 1
        return found


def tier_scale(tier):
    return 1.0 + TIER_STEP * (tier - 1)


def scaled_stats(base, quality, tier):
    growing, flat = QUALITY_SCALE[quality]
    return [round(base[c] * tier_scale(tier) * growing, 1) for c in GROWING] + [round(base[c] * flat, 2) for c in FLAT]


def gear_kinds(items, stats):
    kinds = []
    for armor_index, (subclass, allowable, class_index) in enumerate(ARMOR_TYPES):
        for slot_index, inventory in enumerate(ARMOR_SLOTS):
            template = OLD_SET_FIRST + class_index * OLD_SET_TIERS * OLD_SET_SLOTS + slot_index
            kinds.append({"template": template, "allowable": allowable, "fixed_look": False,
                          "key": slot_key(4, subclass, inventory), "stats": stats[template]["stats"]})
    for kind in range(OLD_MYTHIC_KINDS):
        template = OLD_MYTHIC_FIRST + kind * OLD_SET_TIERS
        item = items[template]
        kinds.append({"template": template, "allowable": None, "fixed_look": kind >= FIRST_TRINKET_KIND - FIRST_WEAPON_KIND,
                      "key": slot_key(item["class"], item["subclass"], item["inventory"]), "stats": stats[template]["stats"]})
    return kinds


def build_gear(items, stats, looks):
    rows = []
    for kind_index, kind in enumerate(gear_kinds(items, stats)):
        template = items[kind["template"]]
        slot_price = PRICE_FIRST * template["buy"] / PRICE_SLOT_BASE
        for quality in QUALITIES:
            for tier in range(1, TIERS + 1):
                look = None if kind["fixed_look"] else looks.find(kind["key"], quality, tier, kind_index)
                price = round(slot_price * tier ** PRICE_POWER * QUALITY_PRICE[quality])
                rows.append({"entry": gear_entry(kind_index, quality, tier), "source": kind["template"], "tier": tier, "quality": quality,
                             "name": look["name"] if look else None, "display": look["display"] if look else None,
                             "allowable": kind["allowable"], "price": price if quality < 4 else 0, "sell": round(price / 10),
                             "stats": scaled_stats(kind["stats"], quality, tier)})
    return rows


def build_legendaries(stats):
    rows = []
    cards = {int(row[0]): int(row[1]) for row in query("SELECT entry, card_id FROM bonk_item_card")}
    for kind in range(LEGENDARY_KINDS):
        first = OLD_LEGENDARY_FIRST + kind * OLD_SET_TIERS
        for tier in range(1, TIERS + 1):
            rows.append({"entry": legendary_entry(kind, tier), "source": first + tier - 1, "tier": tier, "quality": 5, "name": None,
                         "display": None, "allowable": None, "price": 0, "sell": 5000 * tier, "card": cards[first],
                         "stats": scaled_stats(stats[first]["stats"], 5, tier)})
    return rows


def old_entry_target(entry, item, stat, run_entries):
    if entry in run_entries:
        return None
    blue = entry - OLD_EPIC_OFFSET if OLD_SET_FIRST + OLD_EPIC_OFFSET <= entry < OLD_MYTHIC_FIRST + OLD_MYTHIC_KINDS * OLD_SET_TIERS + OLD_EPIC_OFFSET else entry
    quality = 4 if blue != entry else 3
    if OLD_SET_FIRST <= blue < OLD_SET_FIRST + OLD_SET_CLASSES * OLD_SET_TIERS * OLD_SET_SLOTS:
        index = blue - OLD_SET_FIRST
        class_index, tier, slot = index // (OLD_SET_TIERS * OLD_SET_SLOTS), (index // OLD_SET_SLOTS) % OLD_SET_TIERS + 1, index % OLD_SET_SLOTS
        return gear_entry(OLD_SET_ARMOR[class_index] * len(ARMOR_SLOTS) + slot, quality, min(tier, TIERS)), tier
    if OLD_MYTHIC_FIRST <= blue < OLD_MYTHIC_FIRST + OLD_MYTHIC_KINDS * OLD_SET_TIERS:
        kind, tier = (blue - OLD_MYTHIC_FIRST) // OLD_SET_TIERS, (blue - OLD_MYTHIC_FIRST) % OLD_SET_TIERS + 1
        return gear_entry(FIRST_WEAPON_KIND + kind, quality, min(tier, TIERS)), tier
    if OLD_LEGENDARY_FIRST <= entry < OLD_LEGENDARY_FIRST + LEGENDARY_KINDS * OLD_SET_TIERS:
        kind, tier = (entry - OLD_LEGENDARY_FIRST) // OLD_SET_TIERS, (entry - OLD_LEGENDARY_FIRST) % OLD_SET_TIERS + 1
        return legendary_entry(kind, min(tier, TIERS)), tier
    if OLD_LEGACY_LEGENDARY <= entry < OLD_LEGACY_LEGENDARY + LEGENDARY_KINDS:
        return legendary_entry(entry - OLD_LEGACY_LEGENDARY, 1), 1
    tier = OLD_UNLOCK_TIER.get(stat["unlock"], 1)
    quality = min(4, max(1, item["quality"]))
    if item["quality"] == 5:
        return legendary_entry(entry % LEGENDARY_KINDS, tier), tier
    return gear_entry(plain_kind(entry, item), quality, tier), tier


def plain_kind(entry, item):
    inventory, subclass = item["inventory"], item["subclass"]
    if item["class"] == 4 and inventory in ARMOR_SLOTS + (20,) and subclass in (1, 2, 3, 4):
        armor = min(subclass, 3) - 1
        return armor * len(ARMOR_SLOTS) + ARMOR_SLOTS.index(5 if inventory == 20 else inventory)
    accessory = {16: 9, 2: 10, 11: 11, 14: 7, 23: 8}
    if inventory in accessory:
        return FIRST_WEAPON_KIND + accessory[inventory]
    if inventory == 12:
        return FIRST_TRINKET_KIND + entry % (GEAR_KINDS - FIRST_TRINKET_KIND)
    if item["class"] == 2:
        kind = WEAPON_KIND_BY_SUBCLASS.get(subclass, 0)
        if inventory in (17,) and kind in (0, 1, 2):
            kind += 3
        if inventory in ONE_HANDED and kind in (3, 4, 5):
            kind -= 3
        return FIRST_WEAPON_KIND + kind
    sys.exit(f"no new kind for old item {entry} {item['name']}")


def old_gear(items, stats):
    run_entries = {int(row[0]) for row in query("SELECT entry FROM bonk_gear")}
    keep_entries = {int(row[0]) for row in query("SELECT keep_entry FROM bonk_gear")}
    mapping, removed = [], []
    for entry, stat in sorted(stats.items()):
        item = items.get(entry)
        if not item or item["inventory"] not in GEAR_INVENTORY_TYPES:
            continue
        removed.append(entry)
        target = old_entry_target(entry, item, stat, run_entries - keep_entries)
        if target:
            mapping.append((entry,) + target)
    return mapping, removed


def sql_text(text):
    return "'" + text.replace("\\", "\\\\").replace("'", "''") + "'"


def chunked(values, size=150):
    for start in range(0, len(values), size):
        yield values[start:start + size]


def wrap(migration_id, body):
    return "\n".join([
        "DROP PROCEDURE IF EXISTS add_migration;",
        "DELIMITER ??",
        "CREATE PROCEDURE `add_migration`()",
        "BEGIN",
        "DECLARE v INT DEFAULT 1;",
        f"SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='{migration_id}');",
        "IF v = 0 THEN",
        f"INSERT INTO `migrations` VALUES ('{migration_id}');",
        "",
    ] + body + [
        "",
        "END IF;",
        "END??",
        "DELIMITER ;",
        "CALL add_migration();",
        "DROP PROCEDURE IF EXISTS add_migration;",
        "",
    ])


def world_body(rows, removed):
    columns = GROWING + FLAT
    body = [
        "DROP TEMPORARY TABLE IF EXISTS `gear_map`;",
        "CREATE TEMPORARY TABLE `gear_map` (`new_entry` INT UNSIGNED NOT NULL PRIMARY KEY, `src_entry` INT UNSIGNED NOT NULL, "
        "`tier` TINYINT UNSIGNED NOT NULL, `new_quality` TINYINT UNSIGNED NOT NULL, `new_name` VARCHAR(255) NULL, `new_display` INT UNSIGNED NULL, "
        "`new_allowable` INT NULL, `price` INT UNSIGNED NOT NULL, `sell` INT UNSIGNED NOT NULL, "
        + ", ".join(f"`{c}` FLOAT NOT NULL" for c in columns) + ");",
    ]
    for part in chunked(rows):
        values = []
        for row in part:
            name = "NULL" if row["name"] is None else sql_text(row["name"])
            display = "NULL" if row["display"] is None else str(row["display"])
            allowable = "NULL" if row["allowable"] is None else str(row["allowable"])
            values.append(f"({row['entry']}, {row['source']}, {row['tier']}, {row['quality']}, {name}, {display}, {allowable}, {row['price']}, "
                          f"{row['sell']}, " + ", ".join(f"{v:g}" for v in row["stats"]) + ")")
        body.append("INSERT INTO `gear_map` VALUES " + ", ".join(values) + ";")
    removed_list = ", ".join(str(entry) for entry in removed)
    body += [
        "",
        "DROP TEMPORARY TABLE IF EXISTS `gear_items`;",
        "CREATE TEMPORARY TABLE `gear_items` AS SELECT m.`new_entry`, m.`tier`, m.`new_quality`, m.`new_name`, m.`new_display`, m.`new_allowable`, "
        "m.`price`, m.`sell`, t.* FROM `gear_map` m JOIN `item_template` t ON t.`entry` = m.`src_entry` AND t.`patch` = 0;",
        "UPDATE `gear_items` SET `entry` = `new_entry`, `name` = COALESCE(`new_name`, `name`), `display_id` = COALESCE(`new_display`, `display_id`),",
        "    `allowable_class` = COALESCE(`new_allowable`, `allowable_class`), `quality` = `new_quality`, `description` = '',",
        "    `flags` = IF(`new_display` IS NULL, `flags`, 0), `buy_count` = 1, `buy_price` = `price`, `sell_price` = `sell`, `item_level` = 60 + `tier`,",
        "    `required_level` = 0, `max_count` = 0, `bonding` = 1, `random_property` = 0, `set_id` = 0, `disenchant_id` = 0, `max_durability` = 0;",
        "ALTER TABLE `gear_items` DROP COLUMN `new_entry`, DROP COLUMN `tier`, DROP COLUMN `new_quality`, DROP COLUMN `new_name`, DROP COLUMN `new_display`,",
        "    DROP COLUMN `new_allowable`, DROP COLUMN `price`, DROP COLUMN `sell`;",
        "INSERT INTO `item_template` SELECT * FROM `gear_items`;",
        "",
        "INSERT INTO `bonk_item_stat` (`entry`, " + ", ".join(f"`{c}`" for c in columns) + ")",
        "SELECT `new_entry`, " + ", ".join(f"`{c}`" for c in columns) + " FROM `gear_map`;",
        "",
        "INSERT INTO `bonk_item_card` (`entry`, `card_id`) VALUES " + ", ".join(f"({row['entry']}, {row['card']})" for row in rows if "card" in row) + ";",
        "",
        f"DELETE FROM `item_template` WHERE `entry` IN ({removed_list});",
        f"DELETE FROM `bonk_item_stat` WHERE `entry` IN ({removed_list});",
        f"DELETE FROM `bonk_item_card` WHERE `entry` IN ({removed_list});",
        f"DELETE FROM `locales_item` WHERE `entry` IN ({removed_list});",
        f"DELETE FROM `npc_vendor` WHERE `entry` = {SHOP_VENDOR};",
        f"DELETE FROM `creature` WHERE `guid` = {OLD_TIER_VENDOR_GUID};",
        f"DELETE FROM `creature_template` WHERE `entry` = {OLD_TIER_VENDOR};",
        f"DELETE FROM `npc_text` WHERE `ID` = {OLD_TIER_VENDOR_TEXT};",
        "DROP TABLE IF EXISTS `bonk_gear`;",
        "DROP TABLE IF EXISTS `bonk_item_set_bonus`;",
        "DROP TABLE IF EXISTS `bonk_item_set`;",
        "DROP TABLE IF EXISTS `bonk_item_set_bonus_locale`;",
        "DROP TABLE IF EXISTS `bonk_item_set_locale`;",
        "ALTER TABLE `bonk_item_stat` DROP COLUMN `set_id`, DROP COLUMN `unlock_tier`;",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `gear_map`;",
        "DROP TEMPORARY TABLE IF EXISTS `gear_items`;",
    ]
    return body


def characters_body(mapping, removed):
    body = [
        "DROP TEMPORARY TABLE IF EXISTS `gear_convert`;",
        "CREATE TEMPORARY TABLE `gear_convert` (`old_entry` INT UNSIGNED NOT NULL PRIMARY KEY, `new_entry` INT UNSIGNED NOT NULL, "
        "`tier` SMALLINT UNSIGNED NOT NULL);",
    ]
    for part in chunked(mapping, 300):
        body.append("INSERT INTO `gear_convert` VALUES " + ", ".join(f"({old}, {new}, {tier})" for old, new, tier in part) + ";")
    mapped = {old for old, _, _ in mapping}
    dropped = ", ".join(str(entry) for entry in removed if entry not in mapped)
    body += [
        "",
        "INSERT INTO `bonk_item_found` (`item_guid`, `tier`) SELECT i.`guid`, c.`tier` FROM `item_instance` i JOIN `gear_convert` c ON c.`old_entry` = i.`item_id`",
        "    ON DUPLICATE KEY UPDATE `tier` = IF(`bonk_item_found`.`tier` > 0, `bonk_item_found`.`tier`, VALUES(`tier`));",
        "UPDATE `item_instance` i JOIN `gear_convert` c ON c.`old_entry` = i.`item_id` SET i.`item_id` = c.`new_entry`;",
        "UPDATE `character_inventory` i JOIN `gear_convert` c ON c.`old_entry` = i.`item_id` SET i.`item_id` = c.`new_entry`;",
        "UPDATE `bonk_account_bank` i JOIN `gear_convert` c ON c.`old_entry` = i.`item_id` SET i.`item_id` = c.`new_entry`;",
        "UPDATE `mail_items` i JOIN `gear_convert` c ON c.`old_entry` = i.`item_id` SET i.`item_id` = c.`new_entry`;",
        "",
        f"DELETE f FROM `bonk_item_found` f JOIN `item_instance` i ON i.`guid` = f.`item_guid` WHERE i.`item_id` IN ({dropped});",
        f"DELETE FROM `character_inventory` WHERE `item_id` IN ({dropped});",
        f"DELETE FROM `bonk_account_bank` WHERE `item_id` IN ({dropped});",
        f"DELETE FROM `mail_items` WHERE `item_id` IN ({dropped});",
        f"DELETE FROM `item_instance` WHERE `item_id` IN ({dropped});",
        "DROP TABLE IF EXISTS `bonk_account_found`;",
        "DROP TABLE IF EXISTS `bonk_character_notice`;",
        "UPDATE `bonk_account` SET `gear_notice` = 1;",
        "",
        "DROP TEMPORARY TABLE IF EXISTS `gear_convert`;",
    ]
    return body


def write(migration_id, kind, body):
    path = MIGRATIONS / f"{migration_id}_{kind}.sql"
    with open(path, "x", encoding="utf-8", newline="\n") as handle:
        handle.write(wrap(migration_id, body))
    return path


def main():
    items = load_items()
    stats = load_stats()
    looks = Looks(items)
    rows = build_gear(items, stats, looks) + build_legendaries(stats)
    mapping, removed = old_gear(items, stats)
    print(write(WORLD_ID, "world", world_body(rows, removed)), len(rows), "new items,", len(removed), "old items removed")
    print(write(CHARACTERS_ID, "characters", characters_body(mapping, removed)), len(mapping), "old items converted")
    for key, count in sorted(looks.missing.items(), key=str):
        print("no look for", key, count)


if __name__ == "__main__":
    main()
