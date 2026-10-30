import argparse
import collections
import json
import os
import re
import statistics
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_LOG = os.path.join(ROOT, "server", "logs", "LevelUp.log")
DEFAULT_ARCHIVE = os.path.join(ROOT, "data", "runs", "runs.jsonl")
MYSQL = os.path.join(ROOT, "server", "mariadb", "bin", "mysql.exe")
CLASSES = {1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest", 7: "Shaman", 8: "Mage", 9: "Warlock", 11: "Druid"}

HEAD = re.compile(r"^(\S+ \S+) \[LevelUp\] \(acc (\d+),.*?name ([^,]+),.*?\) Bonk (\w+): (.*)$")
WHERE = r"\(stage (\d+), (\w+), (\w+), class (\d+)\)"
LOADOUT = re.compile(r"starts a run at run minute 0 " + WHERE + r": mastery level (\d+), talent points (\d+) of (\d+), best floor (\d+), "
                     r"determination (\d+); talents \[([^\]]*)\]; upgrades \[([^\]]*)\]; fortunes \[([^\]]*)\]; gear \[([^\]]*)\]")
BUILD = re.compile(r"at run minute ([\d.]+) " + WHERE + r": level (\d+); (spells .*)$")
END = re.compile(r"at run minute ([\d.]+) " + WHERE + r": (\w+), level (\d+), (\d+) kills, gold earned (\d+)(?:, tickets earned (\d+), scrap earned (\d+))?; (spells .*)$")
TOTALS = re.compile(r"spells \[([^\]]*)\]; passives \[([^\]]*)\]; cards \[([^\]]*)\]")
PICK = re.compile(r"takes (.+?) rank (\d+) \(([^,]+), (\w+)\) at run minute ([\d.]+), level (\d+)")
BOSS = re.compile(r"kills (.+?) \(([\w -]+)\) at run minute ([\d.]+) " + WHERE + r", level (\d+): ([\d.]+) s after it arrived")
DEATH = re.compile(r"at run minute ([\d.]+) " + WHERE + r", level (\d+), (\d+) kills: last hit by (.+?) for (\d+)")


def parse_pairs(text):
    return {int(key): int(value) for key, value in (pair.split(":") for pair in text.split(",") if pair)}


def parse_totals(text):
    found = TOTALS.search(text)
    spells = []
    for entry in filter(None, found[1].split(",")):
        weapon, rank, damage, kills = (int(part) for part in entry.split(":"))
        spells.append({"weapon": weapon, "rank": rank, "damage": damage, "kills": kills})
    return {"spells": spells, "passives": parse_pairs(found[2]), "cards": parse_pairs(found[3])}


def read_runs(path):
    runs = []
    open_runs = {}
    with open(path, encoding="utf-8", errors="ignore") as handle:
        for line in handle:
            head = HEAD.match(line.rstrip("\n"))
            if not head:
                continue
            when, account, name, kind, body = head[1], int(head[2]), head[3], head[4], head[5]
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
                    "gear": parse_pairs(found[13]), "minutes": [], "picks": [], "bosses": [], "death": None, "end": None,
                }
                open_runs[name] = run
                runs.append(run)
                continue
            run = open_runs.get(name)
            if run is None:
                continue
            if kind == "build":
                found = BUILD.search(body)
                if found:
                    snapshot = {"minute": float(found[1]), "floor": int(found[2]), "map": found[3], "level": int(found[6])}
                    snapshot.update(parse_totals(found[7]))
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
            elif kind == "death":
                found = DEATH.search(body)
                if found:
                    run["death"] = {"minute": float(found[1]), "floor": int(found[2]), "level": int(found[6]), "striker": found[8],
                                    "hit": int(found[9])}
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


def save_runs(path, log):
    archive = load_archive(path)
    added = [run for run in read_runs(log) if run["id"] not in archive]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8", newline="\n") as handle:
        for run in added:
            handle.write(json.dumps(run, separators=(",", ":")) + "\n")
    print(f"{len(added)} new runs saved, {len(archive) + len(added)} in {path}")


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


def main():
    parser = argparse.ArgumentParser(description="Save finished runs from LevelUp.log into data/runs and report damage per spell.")
    parser.add_argument("command", choices=["save", "spells"])
    parser.add_argument("--log", default=DEFAULT_LOG)
    parser.add_argument("--archive", default=DEFAULT_ARCHIVE)
    parser.add_argument("--class", dest="class_name")
    parser.add_argument("--tier")
    parser.add_argument("--flag", type=float, default=2.0, help="flag spells this many times above or below the class median")
    parser.add_argument("--min-minutes", type=float, default=3.0, help="skip runs shorter than this")
    parser.add_argument("--min-kills", type=int, default=50, help="skip runs with fewer kills")
    args = parser.parse_args()
    if args.command == "save":
        save_runs(args.archive, args.log)
    else:
        report(args.archive, args.class_name, args.tier, args.flag, args.min_minutes, args.min_kills)


if __name__ == "__main__":
    main()
