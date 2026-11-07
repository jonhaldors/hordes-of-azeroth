# Class and skill balance: where to change what

Use this when tuning classes, weapons, talents, passives, cards or auras. Almost all balance numbers are **data**, not code — one wrong yaml edit beats a C++ patch.

## The data files (all under `shared/content/`)

| File | What it tunes |
|---|---|
| `tables/bonk_weapon.yaml` | Every class weapon: `spell_id`, cooldown, range, radius, `damage_fraction`, heal, chains, `behavior` + `behavior_value`, evolution (`evolves_from`). The numbers of a skill. |
| `tables/bonk_weapon_upgrade.yaml` | The rune/upgrade slots a weapon offers. |
| `tables/bonk_mastery*.yaml`, `tables/bonk_mastery_tree*.yaml` | Talents: what a rank grants (`BONK_MASTERY_*` kinds map to `bonkDuration`, `enrageHaste`, ... in `BonkMastery.cpp`) and the tree layout. |
| `tables/bonk_passive*.yaml` | Run passives (Power, Haste, movement speed, max health...). `effect` indexes the stat array; `value_per_rank` is the per-rank number. |
| `cards/cards.yaml` | Darkmoon cards / trinkets: `values` (effect numbers), `cooldown_ms`, max copies. |
| `spells/spells.yaml` | The aura a mechanic shows: name, icon, base description and the dynamic template (`enUS`/`zhCN` with `{1}` placeholders) for live values. |
| `tables/bonk_level.yaml`, `tables/bonk_map*.yaml`, `tables/bonk_mob*.yaml` | XP curve, run maps, enemy stats. |

Locale text (names/descriptions, enUS + zhCN) sits in the `*_locale.yaml` twins and in the `display:` blocks. Placeholders like `{10}` in a description are the value per rank; the game substitutes them.

## The code that interprets the numbers

- `server/src/game/Bonk/BonkRun<Class>.cpp` — per-class behaviour (how Enrage/Bladestorm/Bloodthirst actually behave). `BonkRunWarrior.cpp` holds the Enrage haste/duration math (`GetEnrageHaste`, `BONK_ENRAGE_HASTE` + masteries).
- `server/src/game/Bonk/BonkMastery.cpp` — maps mastery kinds to the `bonkDuration`/`enrageHaste`/`enrageDamage` bonuses.
- `server/src/game/Bonk/BonkRunCards.cpp` — card effect logic (`GetCardTotal` applies copy counts).
- Constants like `BONK_ENRAGE_HASTE = 25.0f` are the *base* values the data scales.

## The mandatory cycle after any data edit

```bash
python tools/content/compile.py      # yaml -> server/sql/content/*.sql + content.hash
python tools/protocol/gen.py         # the hash is part of the client/server handshake
python tools/content/apply.py --maria <mariadb.exe> --user <u> --password <p> --database mangos
```

then rebuild the server and the client (both embed the hash) and restart the server. Skipping `gen.py` leaves the client refusing every message after hello.

## Verify it, do not eyeball it

The end-to-end probe types real commands and reads both sides' logs (see the `local-test` skill):

```powershell
tools\e2e\bonk-probe.ps1 -Commands '.bonk hello enUS','.bonk start 1','.bonk god','.bonk card 21' -LuaFile tools\e2e\suite-listen.lua
```

- Buff/aura values: the server sends the formatted text (e.g. `Haste increased by 60%.`) as an `HOA` aura text — for a quick check, watch `snapshot` lines in the probe output or the aura tooltip in game.
- Run outcomes: `C:\World of Warcraft\server\logs\LevelUp.log` records every run's build, kills, gear, cards and stats — compare before/after tuning there.
- A damage number that surprises you: `stats [...]` in the LevelUp line plus the weapon's `damage_fraction` and the class file's math.

If a mechanic's *behaviour* (not its number) is wrong, that is code: find the `BONK_BEHAVIOR_*` case in the class's `BonkRun<Class>.cpp`.
