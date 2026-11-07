# Content and data

## 1. Goals

- Items, spells, auras, creatures, maps, talents, cards, quests and loot have their **only definition** in `shared/content`.
- The server, client and addon get their formats from the compiler; no component keeps a copy.
- The server remains authoritative at runtime; the client content pack is a read-only projection of the same data.
- Changing content = edit the source + regenerate + commit the artifacts; never edit the database directly.

## 2. Where data lives

| Data | Location | Notes |
| --- | --- | --- |
| Vanilla 1.12.1 resources (models, textures, audio, base DBCs) | user install | not distributed with the repo; language-independent |
| Vanilla item/spell/creature base values | server DB (from the VMaNGOS base) | not redefined |
| HoA-added or changed content | `shared/content` | single source |
| HoA text | `shared/i18n` + `*_id` references | never hardcoded in component code |
| Client UI data (layout, icon paths) | `client/assets` | presentation resources, not game values |
| Addon UI layout | `addon/` | presentation logic |

Rule of thumb: **values and names that affect game results live in `shared/content`; pure presentation resources stay in the component.**

## 3. Source layout

```
shared/content/
  manifest.yaml          content version, package list
  items/
  spells/
  auras/
  creatures/
  zones/
  talents/
  cards/
  gear/
  loot/
  quests/
  i18n/                  content text (by ID, by language)
  schemas/               JSON Schema (or Rust types)
```

Entry example:

```yaml
id: hoa.item.darkmoon.ogre_slayer
kind: item
entry: 930359                 # runtime uint32 ID assigned by the registry
name_id: hoa.text.item.ogre_slayer.name
description_id: hoa.text.item.ogre_slayer.desc
icon: Interface/Icons/INV_Misc_Ticket_Darkmoon_01
quality: 3
item_level: 60
slot: trinket
stats: { strength: 12, stamina: 8 }
source: { kind: darkmoon_card }
```

```yaml
id: hoa.text.item.ogre_slayer.name
enUS: "Ogre Slayer"
zhCN: "食人魔杀手"
```

## 4. ID rules

- Stable string IDs: `hoa.<domain>.<group>.<name>`; never rename after release.
- Runtime uint32: assigned by the registry and written back to generated files; avoid vanilla ID ranges.
  - Custom items: >= 900000 (existing convention)
  - Custom spells/auras: their own range, connected to the existing `BONK_SPELL_*`
  - Custom creatures/maps: existing conventions
- The string-ID → uint32 map is a generated artifact committed to the repo; CI checks conflicts and accidental changes.

## 5. Compiler

`tools/content-compiler`:

```
sources → schema validation → intermediate model → generators
                                  ├─ server/sql/content/*.sql
                                  ├─ server/src/game/Hoa/content/generated/*.h/.cpp
                                  ├─ client/assets/content/<hash>/content.bin
                                  ├─ addon/HordesOfAzeroth/generated/content.lua
                                  └─ shared/i18n/generated/*
```

Requirements:

- **Deterministic output:** stable ordering, no timestamps, no random IDs; identical sources produce identical bytes so CI can check the diff.
- **Idempotent SQL:** repeated runs produce the same result; content updates use a version or delete-then-insert.
- **Cross-artifact consistency:** the same ID has the same name/icon/values in every artifact; the compiler cross-checks.
- **Incremental:** regenerate only changed packages and emit a content hash.

## 6. Versioning and validation

- `manifest.yaml` declares the content version; the compiler computes `content.hash` (sources + artifacts).
- The server verifies at startup that the DB content version matches the artifacts; a mismatch refuses startup or logs an error.
- The client login handshake carries the content hash; a mismatch prompts an update, and a LAN/direct host refuses different versions.
- Content packs live in hash-named directories, naturally supporting multiple versions and rollback.

## 7. Migrating from the current state

Content is currently scattered across:

- `server/core/sql/`'s `bonk_*` tables (about 50) and many migrations;
- 900000+ custom items in `item_template`;
- text in `locales_item`, `locales_creature`, `bonk_*_locale`, etc.;
- class/difficulty/keyword/mastery/gear tooltip tables in the addon;
- vanilla names in client DBCs.

Migration steps:

1. Write `tools/content-dump`: export current `bonk_*`, custom `item_template` and `*_locale` rows into `shared/content` sources.
2. Write the compiler's SQL generator to produce a result **row-for-row equivalent** to the current tables first.
3. Run export → generate → compare on a test database until the diff is zero.
4. Switch to the generated flow: migrations keep only structural changes; content is no longer handwritten SQL.
5. Replace the duplicated addon/client tables with generated artifacts or protocol data.

## 8. Client content pack

> Current implementation: custom and reskinned auras use the server-pushed catalog
> (`aura_catalog_entry`/`aura_catalog_end`) at addon-ready and language changes. The broader
> content pack below remains the target for items, creatures and the spellbook.

- Format: compact binary + string pool + ID index, containing:
  - names, icons, descriptions, quality and type for custom items/spells/auras/creatures/maps;
  - buff/debuff flags and stack-display rules for spells;
  - display fields needed by gear/card UI.
- The client loads it by content hash at startup; the login handshake verifies it.
- Vanilla entries are not overridden by default; only HoA-added or explicitly rewritten entries are.
- Language: generate per-language packs or embed a multilingual string pool; the client selects by account language.

## 9. Validation

CI checks:

- schema validation, unique IDs, complete references (`*_id` points to existing text, icons exist or are allowlisted);
- uint32 mappings without conflicts or accidental changes;
- artifacts match the sources (regenerating leaves an empty diff);
- server SQL runs repeatedly on both an empty and an existing database;
- generated client/addon artifacts load in their runtimes (smoke test).
