# shared/content / content sources

The single source of game content. Suggested layout by domain:

```
content/
  items/          gear, consumables, materials
  spells/         spells (including custom HoA spells)
  auras/          HoA effect/aura definitions (see docs/auras)
  creatures/      creatures, NPCs, bosses
  zones/          maps, areas, scenarios
  talents/        talents, mastery trees
  cards/          Darkmoon cards, card effects
  gear/           gear pools, qualities, level curves, loot tables
  quests/         quests
  loot/           loot tables
  strings/        long text referenced by content (or inline in entries)
```

## Entry format (draft)

Every entry has a stable ID, English source, localized fields, values and relations. Example:

```yaml
id: hoa.item.darkmoon.ogre_slayer
kind: item
name_id: hoa.text.item.darkmoon.ogre_slayer.name
description_id: hoa.text.item.darkmoon.ogre_slayer.desc
icon: Interface/Icons/INV_Misc_Ticket_Darkmoon_01
quality: 3
stats: { strength: 12, stamina: 8 }
```

Text lives beside the entry or in separate `i18n` files and is referenced by `*_id`; never use English sentences as keys.

## Compiler output

`tools/content-compiler` reads this directory and generates:

- `server/sql/content/*.sql`: repeatable schema/data SQL
- `server/src/game/Hoa/content/generated/`: ID constants and static tables
- `client/assets/content/<version>/content.bin`: client content pack
- `addon/HordesOfAzeroth/generated/content.lua`: addon data tables
- `shared/i18n/generated/*.json`: text catalogue shared by C++, Rust and Lua
- `content.hash`: the whole-content version hash
- `content.manifest.json`: the same hash plus one hash and file list per section (`cards`, `spells`, `tables`)

## Current state

The design-content tables are now sourced here:

- `cards/cards.yaml` is the hand-shaped source for the 46 cards (English + zhCN).
- `spells/spells.yaml` defines every custom HoA aura. Each entry names its owning card, mastery, weapon, glyph or keyword under `source`; the compiler inherits that row's name, icon and description (or applies an explained `display` override), then validates the result. It emits the `spell_template` SQL, `hoa_aura`/`hoa_aura_locale` SQL, the server's C++ ids and the addon's `VanillaBonkAuraIds.lua` constants. The client receives the localized display rows from the server at login, not from a generated copy.
- `tables/<table>.yaml` holds the 49 design-content `bonk_*` tables (weapons, upgrades, glyphs, talents, mastery, maps, quests, titles, tiers, mobs, item stats and their locale rows).
- `tools/content/dump_cards.py` / `dump_tables.py` imported them once from the database.
- `tools/content/compile.py` emits `server/sql/content/*.sql`; `--check` keeps every generated file in sync in CI, and `tools/content/test_auras.py` checks the source bindings and the usage audit.
- `tools/content/apply.py --maria <client> --database <world db>` applies those files in order; this is how the test database picks up source changes.
- The compiler also emits `hoa_content.sql`, `BonkContentHash.h` and `content.manifest.json`. The SQL fills `hoa_content` (the whole hash) and `hoa_content_section` (one row per section); the server compares both with the build at startup and logs which section is stale. The login hello carries the section hashes, so a mismatched client names the changed sections in its warning.

Every generated table was applied to the test database and compared row for row with the old data; all 49 matched. The large generated spawn tables (`bonk_hidden_creature`, `bonk_hidden_gameobject`) deliberately stay in the database, per the project decision, so the source tree stays reviewable.

## Migration

First write a dump tool that exports the current `bonk_*` tables, custom `item_template` rows and `locales_*` text into these sources. Once the generated result matches the existing database, switch to the generated flow. See [the migration plan](../../docs/migration-plan/README.md).
