import argparse
import collections
import csv
import datetime
import glob
import gzip
import json
import os
import re
import statistics
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_LOG = os.path.join(ROOT, "server", "logs", "LevelUp.log")
DEFAULT_ARCHIVE = os.path.join(ROOT, "data", "runs", "runs.jsonl")
PLAYER_ARCHIVE = os.path.join(ROOT, "data", "runs", "players.jsonl")
PLAYER_INBOX = os.path.join(ROOT, "data", "runs", "inbox")
RECORD_FORMAT = 1
MYSQL = os.path.join(ROOT, "server", "mariadb", "bin", "mysql.exe")
CLASSES = {1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest", 7: "Shaman", 8: "Mage", 9: "Warlock", 11: "Druid"}

HEAD = re.compile(r"^(\S+ \S+) \[LevelUp\] \(acc (\d+),.*?name ([^,]+),.*?\) Bonk (\w+): (.*)$")
WHERE = r"\(stage (\d+), (\w+), (\w+), class (\d+)\)"
LOADOUT = re.compile(r"starts a run at run minute 0 " + WHERE + r": mastery level (\d+), talent points (\d+) of (\d+), best floor (\d+), "
                     r"determination (\d+); talents \[([^\]]*)\]; upgrades \[([^\]]*)\]; fortunes \[([^\]]*)\]; gear \[([^\]]*)\]"
                     r"(?:; found \[([^\]]*)\]; gold (\d+), scrap (\d+), tickets (\d+))?")
FOUND = re.compile(r"; found \[([^\]]*)\]; enchants \[([^\]]*)\]")
DROP = re.compile(r"gets item (\d+) from a ([\w-]+) at run minute ([\d.]+) " + WHERE + r": quality (\d+), tier (\d+), (\d+) bonus stats")
FLOOR = re.compile(r"starts stage (\d+) at run minute ([\d.]+) " + WHERE + r": level (\d+), (\d+) kills, took (\d+) damage so far")
BUILD = re.compile(r"at run minute ([\d.]+) " + WHERE + r": level (\d+); (spells .*)$")
END = re.compile(r"at run minute ([\d.]+) " + WHERE + r": (\w+), level (\d+), (\d+) kills, gold earned (\d+)(?:, tickets earned (\d+), scrap earned (\d+))?; (spells .*)$")
TOTALS = re.compile(r"spells \[([^\]]*)\]; passives \[([^\]]*)\]; cards \[([^\]]*)\](?:; glyphs \[([^\]]*)\])?(?:; gear \[([^\]]*)\])?(?:; stats \[([^\]]*)\])?")
PICK = re.compile(r"takes (.+?) rank (\d+) \(([^,]+), (\w+)\) at run minute ([\d.]+), level (\d+)")
BOSS = re.compile(r"kills (.+?) \(([\w -]+)\) at run minute ([\d.]+) " + WHERE + r", level (\d+): ([\d.]+) s after it arrived")
DEATH = re.compile(r"at run minute ([\d.]+) " + WHERE + r", level (\d+), (\d+) kills: last hit by (.+?) for (\d+)"
                   r"(?:; (\d+) damage in the last 10 s from (\d+) hits \(([\d.]+)% of max health\))?")
MINUTE = re.compile(r"took (\d+) damage \(([\d.]+)% of max health\), healed (\d+) \(([\d.]+)%\), lowest health (\d+)%, (\d+) enemies alive")
DEFENSE = re.compile(r"defense: max health (\d+), armor (\d+) \(([\d.]+)% reduction, \+([\d.]+)% health\), "
                     r"enemy damage x([\d.]+), grunt hit ([\d.]+)% of max health")


def parse_pairs(text):
    return {int(key): int(value) for key, value in (pair.split(":") for pair in text.split(",") if pair)}


def parse_found(text):
    found = {}
    for entry in filter(None, text.split(",")):
        slot, tier, bonus = (int(part) for part in entry.split(":"))
        found[slot] = {"tier": tier, "bonus_stats": bonus}
    return found


def parse_enchants(text):
    enchants = {}
    for entry in filter(None, text.split(",")):
        slot, effect, grade, value = entry.split(":")
        enchants[int(slot)] = {"effect": int(effect), "grade": int(grade), "value": float(value)}
    return enchants


def parse_stats(text):
    return {int(key): float(value) for key, value in (pair.split(":") for pair in text.split(",") if pair)}


def parse_totals(text):
    found = TOTALS.search(text)
    spells = []
    for entry in filter(None, found[1].split(",")):
        weapon, rank, damage, kills = (int(part) for part in entry.split(":"))
        spells.append({"weapon": weapon, "rank": rank, "damage": damage, "kills": kills})
    glyphs = [int(glyph.split(":")[0]) for glyph in (found[4] or "").split(",") if glyph]
    totals = {"spells": spells, "passives": parse_pairs(found[2]), "cards": parse_pairs(found[3]), "glyphs": glyphs,
              "gear": parse_pairs(found[5] or ""), "stats": parse_stats(found[6] or "")}
    extra = FOUND.search(text)
    if extra:
        totals.update({"found": parse_found(extra[1]), "enchants": parse_enchants(extra[2])})
    return totals


def parse_minute(text):
    found = MINUTE.search(text)
    if not found:
        return {}
    minute = {"taken": int(found[1]), "taken_share": float(found[2]), "healed": int(found[3]), "healed_share": float(found[4]),
              "lowest_health": int(found[5]), "alive": int(found[6])}
    minute.update(parse_defense(text))
    return minute


def parse_defense(text):
    found = DEFENSE.search(text)
    if not found:
        return {}
    return {"max_health": int(found[1]), "armor": int(found[2]), "armor_reduction": float(found[3]), "armor_health": float(found[4]),
            "enemy_damage": float(found[5]), "grunt_hit_share": float(found[6])}


def log_entries(path):
    with open(path, encoding="utf-8", errors="ignore") as handle:
        for line in handle:
            head = HEAD.match(line.rstrip("\n"))
            if head:
                yield head[1], int(head[2]), head[3], head[4], head[5], {}


def record_entries(path):
    with gzip.open(path, "rt", encoding="utf-8") as handle:
        record = json.load(handle)
    if record.get("format") != RECORD_FORMAT:
        return
    started = datetime.datetime.strptime(record["started"], "%Y-%m-%d %H:%M")
    name = f"{record['install'][:12]}/{record['character']}"
    extra = {"install": record["install"], "game": record["game"], "os": record["os"]}
    for line in record["lines"]:
        seconds, rest = line.split(" ", 1)
        kind, body = rest.split(": ", 1)
        when = (started + datetime.timedelta(seconds=int(seconds))).strftime("%Y-%m-%d %H:%M:%S")
        yield when, 0, name, kind, body, extra


def read_runs(entries):
    runs = []
    open_runs = {}
    pending_minutes = {}
    for when, account, name, kind, body, extra in entries:
        if kind == "loadout":
            found = LOADOUT.search(body)
            if not found:
                continue
            run = {
                "id": f"{name}@{when}", "name": name, "account": account, "started": when,
                "class": int(found[4]), "tier": found[3], "first_map": found[2],
                "mastery_level": int(found[5]), "talent_points_spent": int(found[6]), "talent_points": int(found[7]),
                "best_floor": int(found[8]), "determination": int(found[9]),
                "talents": parse_pairs(found[10]), "upgrades": parse_pairs(found[11]), "fortunes": parse_pairs(found[12]),
                "gear": parse_pairs(found[13]), "minutes": [], "picks": [], "bosses": [], "drops": [], "floors": [],
                "death": None, "end": None,
            }
            if found[14] is not None:
                run.update({"found": parse_found(found[14]), "gold_balance": int(found[15]), "scrap_balance": int(found[16]),
                            "ticket_balance": int(found[17])})
            run.update(extra)
            open_runs[name] = run
            runs.append(run)
            continue
        run = open_runs.get(name)
        if run is None:
            continue
        if kind == "minute":
            pending_minutes[name] = parse_minute(body)
        elif kind == "build":
            found = BUILD.search(body)
            if found:
                snapshot = {"minute": float(found[1]), "floor": int(found[2]), "map": found[3], "level": int(found[6])}
                snapshot.update(parse_totals(found[7]))
                snapshot.update(pending_minutes.pop(name, {}))
                run["minutes"].append(snapshot)
        elif kind == "pick":
            found = PICK.search(body)
            if found:
                run["picks"].append({"name": found[1], "rank": int(found[2]), "rarity": found[3], "source": found[4],
                                     "minute": float(found[5]), "level": int(found[6])})
        elif kind == "boss":
            found = BOSS.search(body)
            if found:
                run["bosses"].append({"name": found[1], "kind": found[2], "minute": float(found[3]), "floor": int(found[4]),
                                      "map": found[5], "level": int(found[8]), "seconds": float(found[9])})
        elif kind == "drop":
            found = DROP.search(body)
            if found:
                run["drops"].append({"item": int(found[1]), "source": found[2], "minute": float(found[3]), "floor": int(found[4]),
                                     "quality": int(found[8]), "tier": int(found[9]), "bonus_stats": int(found[10])})
        elif kind == "floor":
            found = FLOOR.search(body)
            if found:
                run["floors"].append({"floor": int(found[1]), "minute": float(found[2]), "level": int(found[7]), "kills": int(found[8]),
                                      "taken": int(found[9])})
        elif kind == "death":
            found = DEATH.search(body)
            if found:
                run["death"] = {"minute": float(found[1]), "floor": int(found[2]), "level": int(found[6]), "striker": found[8],
                                "hit": int(found[9])}
                if found[10]:
                    run["death"].update({"recent_damage": int(found[10]), "recent_hits": int(found[11]), "recent_share": float(found[12])})
                run["death"].update(parse_defense(body))
        elif kind == "end":
            found = END.search(body)
            if found:
                run["end"] = {"minute": float(found[1]), "floor": int(found[2]), "map": found[3], "outcome": found[6],
                              "level": int(found[7]), "kills": int(found[8]), "gold": int(found[9])}
                if found[10] is not None:
                    run["end"]["tickets"] = int(found[10])
                    run["end"]["scrap"] = int(found[11])
                run["end"].update(parse_totals(found[12]))
                del open_runs[name]
    return [run for run in runs if run["end"]]


def load_archive(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as handle:
        return {run["id"]: run for run in map(json.loads, filter(str.strip, handle))}


def save_runs(path, entries, rebuild=False):
    archive = load_archive(path)
    if rebuild:
        parsed = read_runs(entries)
        archive.update((run["id"], run) for run in parsed)
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            for run in archive.values():
                handle.write(json.dumps(run, separators=(",", ":")) + "\n")
        print(f"{len(parsed)} runs re-read, {len(archive)} in {path}")
        return
    added = [run for run in read_runs(entries) if run["id"] not in archive]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8", newline="\n") as handle:
        for run in added:
            handle.write(json.dumps(run, separators=(",", ":")) + "\n")
    print(f"{len(added)} new runs saved, {len(archive) + len(added)} in {path}")


def player_entries(inbox):
    for path in sorted(glob.glob(os.path.join(inbox, "**", "*.json.gz"), recursive=True)):
        try:
            yield from record_entries(path)
        except (OSError, ValueError, KeyError) as problem:
            print(f"skipped {path}: {problem}")


def export_csv(path, target):
    names = weapon_names()
    columns = ["id", "install", "game", "class", "tier", "first_map", "outcome", "minutes", "floor", "level", "kills", "gold",
               "mastery_level", "talent_points_spent", "best_floor", "bosses", "death_striker", "top_spell", "top_share", "spells", "cards",
               "glyphs", "start_gear", "end_gear"]
    with open(target, "w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(columns)
        for run in load_archive(path).values():
            end = run["end"]
            spells = sorted(end["spells"], key=lambda spell: -spell["damage"])
            total = sum(spell["damage"] for spell in spells) or 1
            writer.writerow([
                run["id"], run.get("install", ""), run.get("game", ""), CLASSES.get(run["class"], run["class"]), run["tier"], run["first_map"],
                end["outcome"], end["minute"], end["floor"], end["level"], end["kills"], end["gold"], run["mastery_level"],
                run["talent_points_spent"], run["best_floor"], len(run["bosses"]), (run["death"] or {}).get("striker", ""),
                names.get(spells[0]["weapon"], spells[0]["weapon"]) if spells else "", f"{spells[0]['damage'] / total:.2f}" if spells else "",
                " ".join(f"{spell['weapon']}:{spell['rank']}:{spell['damage']}" for spell in spells),
                " ".join(f"{card}:{count}" for card, count in sorted(end["cards"].items())),
                " ".join(str(glyph) for glyph in end.get("glyphs", [])),
                " ".join(f"{slot}:{item}" for slot, item in sorted(run["gear"].items())),
                " ".join(f"{slot}:{item}" for slot, item in sorted(end.get("gear", {}).items())),
            ])
    print(f"wrote {target}")


def weapon_names():
    try:
        output = subprocess.run([MYSQL, "-h", "127.0.0.1", "-P", "3306", "-uroot", "-proot", "-N", "-B", "mangos", "-e",
                                 "SELECT id, name, damage_fraction FROM bonk_weapon"], capture_output=True, text=True, timeout=10).stdout
    except OSError:
        return {}
    names = {}
    for row in output.splitlines():
        weapon, name, fraction = row.split("\t")
        names[int(weapon)] = f"{name} ({weapon}, damage_fraction {float(fraction):g})"
    return names


def first_seen_minutes(run):
    seen = {}
    for snapshot in run["minutes"]:
        for spell in snapshot["spells"]:
            seen.setdefault(spell["weapon"], max(0.0, snapshot["minute"] - 1.0))
    return seen


def spell_rows(runs):
    rows = collections.defaultdict(list)
    for run in runs:
        end = run["end"]
        total = sum(spell["damage"] for spell in end["spells"]) or 1
        seen = first_seen_minutes(run)
        for spell in end["spells"]:
            minutes = max(0.5, end["minute"] - seen.get(spell["weapon"], 0.0))
            rows[(run["class"], run["tier"], spell["weapon"])].append({
                "share": spell["damage"] / total, "per_minute": spell["damage"] / minutes, "rank": spell["rank"],
                "kills_per_minute": spell["kills"] / minutes, "floor": end["floor"]})
    return rows


def report(path, class_filter, tier_filter, flag_ratio, min_minutes, min_kills):
    runs = [run for run in load_archive(path).values()
            if run["end"]["minute"] >= min_minutes and run["end"]["kills"] >= min_kills
            and (not class_filter or CLASSES.get(run["class"], "").lower() == class_filter.lower())
            and (not tier_filter or run["tier"] == tier_filter)]
    if not runs:
        print("No archived runs match.")
        return
    names = weapon_names()
    rows = spell_rows(runs)
    groups = collections.defaultdict(dict)
    for (class_id, tier, weapon), entries in rows.items():
        groups[(class_id, tier)][weapon] = entries
    for (class_id, tier), spells in sorted(groups.items()):
        medians = {weapon: statistics.median(entry["per_minute"] for entry in entries) for weapon, entries in spells.items()}
        middle = statistics.median(medians.values())
        print(f"\n== {CLASSES.get(class_id, class_id)}, {tier}: {sum(1 for run in runs if run['class'] == class_id and run['tier'] == tier)} runs")
        print(f"   {'runs':>4} {'rank':>5} {'share':>6} {'dmg/min':>12} {'kills/min':>9}  spell")
        for weapon, entries in sorted(spells.items(), key=lambda item: -medians[item[0]]):
            flag = "  << strong" if middle and medians[weapon] > middle * flag_ratio else "  << weak" if middle and medians[weapon] * flag_ratio < middle else ""
            print(f"   {len(entries):>4} {statistics.mean(entry['rank'] for entry in entries):>5.1f} "
                  f"{statistics.median(entry['share'] for entry in entries):>6.0%} {medians[weapon]:>12,.0f} "
                  f"{statistics.median(entry['kills_per_minute'] for entry in entries):>9.1f}  {names.get(weapon, weapon)}{flag}")


def defense_report(path, class_filter, tier_filter):
    floors = {}
    deaths = {}
    for run in load_archive(path).values():
        if tier_filter and run["tier"] != tier_filter:
            continue
        if class_filter and CLASSES.get(run["class"], "").lower() != class_filter.lower():
            continue
        for snapshot in run["minutes"]:
            if "taken_share" in snapshot:
                floors.setdefault(snapshot["floor"], []).append(snapshot)
        if run["death"]:
            deaths.setdefault(run["death"]["floor"], []).append(run["death"])

    def pick(key, source, share):
        values = sorted(row[key] for row in source if key in row)
        return values[min(len(values) - 1, int(share * len(values)))] if values else float("nan")

    print("floor  minutes  deaths  taken/min p90  lowest p10  max health  armor  reduction  armor health  enemy dmg  grunt hit")
    for floor in sorted(set(floors) | set(deaths)):
        rows = floors.get(floor, [])
        print(f"{floor:>5}  {len(rows):>7}  {len(deaths.get(floor, [])):>6}  {pick('taken_share', rows, 0.9):>12.0f}%"
              f"  {pick('lowest_health', rows, 0.1):>9.0f}%  {pick('max_health', rows, 0.5):>10.0f}  {pick('armor', rows, 0.5):>5.0f}"
              f"  {pick('armor_reduction', rows, 0.5):>8.1f}%  {pick('armor_health', rows, 0.5):>11.1f}%  {pick('enemy_damage', rows, 0.5):>8.2f}x"
              f"  {pick('grunt_hit_share', rows, 0.5):>8.1f}%")


def main():
    parser = argparse.ArgumentParser(description="Save finished runs from LevelUp.log into data/runs and report damage per spell.")
    parser.add_argument("command", choices=["save", "ingest", "spells", "defense", "csv"])
    parser.add_argument("--rebuild", action="store_true", help="re-read every run and replace the stored copies")
    parser.add_argument("--log", default=DEFAULT_LOG)
    parser.add_argument("--archive", help="default data/runs/runs.jsonl, or players.jsonl for ingest")
    parser.add_argument("--inbox", default=PLAYER_INBOX, help="folder of uploaded .json.gz run records")
    parser.add_argument("--out", help="csv file to write")
    parser.add_argument("--class", dest="class_name")
    parser.add_argument("--tier")
    parser.add_argument("--flag", type=float, default=2.0, help="flag spells this many times above or below the class median")
    parser.add_argument("--min-minutes", type=float, default=3.0, help="skip runs shorter than this")
    parser.add_argument("--min-kills", type=int, default=50, help="skip runs with fewer kills")
    args = parser.parse_args()
    archive = args.archive or (PLAYER_ARCHIVE if args.command == "ingest" else DEFAULT_ARCHIVE)
    if args.command == "save":
        save_runs(archive, log_entries(args.log), args.rebuild)
    elif args.command == "ingest":
        save_runs(archive, player_entries(args.inbox), args.rebuild)
    elif args.command == "defense":
        defense_report(archive, args.class_name, args.tier)
    elif args.command == "csv":
        export_csv(archive, args.out or os.path.splitext(archive)[0] + ".csv")
    else:
        report(archive, args.class_name, args.tier, args.flag, args.min_minutes, args.min_kills)


if __name__ == "__main__":
    main()
