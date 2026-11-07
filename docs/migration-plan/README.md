# Migration plan

Deliver phase by phase. At the end of every phase the repository must build, run and be revertible.

## Phase 0: design and skeleton (done)

- Output: this repository, architecture/i18n/auras/content/protocol docs, component notes, license notes.
- Acceptance: the design direction and directory layout are approved.
- Not done: importing code or changing any existing implementation.

## Phase 1: import and baseline

- Import these snapshots into the monorepo, keeping their licenses and copyright:
  - `server/` ← `hordes-of-azeroth-server` (VMaNGOS, the 0.6.3 `vanilla-bonk`/Chinese branch)
  - `client/` ← `hordes-of-azeroth-client` (benilla, 0.6.3 snapshot)
  - `addon/` ← `Interface/AddOns/HordesOfAzeroth`
  - `glue/` ← `Interface/GlueXML`
  - `launcher/` ← `tools/launcher`
  - `config/`, `localization/`, `tools/` ← matching directories in the main repository
- Do not import `tools/lobby-server`: co-op is LAN and `ip/domain:port` direct only; no public directory/registration service.
- Version starts at **0.1.0** (`VERSION`).
- Add unified build scripts and CI: server CMake, client Cargo, launcher dotnet, addon Lua syntax check.
- Acceptance: one command builds every component; existing functionality runs; CI is green.
- Progress (2026-11-04): code imported and committed; `scripts/build.ps1 -Component server` passes, launcher passes, 64 addon Lua files parse, the full client `cargo build -p benilla-app` passes.
- Risks: repository size (tracked files only, no `target/`, `bin/`, `obj/`, databases); mixed licenses (kept per directory).

## Phase 2: i18n foundation

- Create the `shared/i18n` message catalogue (stable IDs, placeholders, language tables).
- Add the server `Hoa::I18n` runtime; migrate the 900+ `BonkStrings`/`BonkLocale` messages to IDs.
- Client language packs: UI text (options, menus, Glue) reads from packs; the login handshake carries the account language.
- Generate the addon language tables; delete English-key indices and reverse lookups.
- Add `(locale, contentVersion)` to cache keys; language changes refresh item/creature/spell names.
- Acceptance: any-language 1.12.1 install + Chinese account → all Chinese; switching enUS/zhCN without a game restart leaves no stale names; missing translations have a list.
- Progress (2026-11-06): 995 server strings, 1558 addon entries, 1328 client UI entries and 304 launcher entries have stable IDs (`shared/i18n/messages/server.yaml`, `addon/addon.yaml`, `ui/options.yaml`, `ui/glue.yaml`, `ui/keybindings.yaml`; enUS, zhCN and zhTW complete); `tools/i18n` extractor/validator/generators and the `i18n-check` CI job are in place; `BonkStrings.h/.cpp`, `addon/HordesOfAzeroth/VanillaBonkLocaleData.lua` (one file for every language) and `client/crates/benilla-app/assets/i18n/{enUS,zhCN,zhTW}.json` are generated from the catalogue; HoA UI/GlueXML use `HOA_UI_*` keys, `GetLocale` follows the account language, the client WDB header folds it into its cache tag (FORMAT 2), and zhTW shapes and draws with Noto Sans TC. Next: stock GlobalStrings and DBC name overlays.
- Note: this touches a lot of client text but no game values.

## Phase 3: unify auras

- Implement `Hoa::Auras` and `AuraState`; build the effect inventory.
- Support custom spell name/icon/description/stacks in the client content pack; first make the client display one test aura.
- Migrate category by category: native spell copies → custom buffs → resource/stack states → special values such as shield amounts.
- Switch the addon to `UnitBuff`/`UNIT_AURA`; delete state timers and `BONK~state`.
- Acceptance: every HoA effect appears in the buff frame; addon/server/combat-log state agrees; UI reload, reconnect and language switch preserve it.
- Progress (2026-11-04): weapon buffs, Necrotic, Determination (60001), Wounds (60003), Darkmoon Surge (60004), Shield (60005), Haste Burst (60006), Swiftness (60007), Immune (60008), Soulstone (60009), Thorns (60010), Tiger's Fury (60012), Arcane Power (60013), Shadow Dance (60014), Envenom (60015), Dark Pact (60016), Soul Harvest (60017), glyph Bloodlust (60018) Ice Block (60019), Nomad (60020), Kill Power (60021) and Unhit Power (60022); Blade Flurry, Enrage, Divine Shield and Doom Winds now read their existing auras are on real auras. Dash stays a skill: its charges and recharge live in `BonkPlayer` and only `hoa.dash` reports them, so no buff icon changes. Custom ids live in the migration `20261104120000_world.sql`; the client overlay renders them; the addon reads stacks through `C_UnitAuras` (`UI.AuraStacks`). Shield amount still travels as a server-computed value message until `AuraState` lands. Weapon buffs read the live aura instead of the removed `m_buffs` expiry map; Necrotic stacks live on spell 60056 and the server reads `GetStackAmount`, while the addon reads the stack count through `C_UnitAuras` and only takes the server-computed healing cut from the notice. The remaining timed talent procs, pet frenzy and enemy debuffs (60023-60047) now mirror real auras too, defined in `shared/content/spells/spells.yaml` and generated by `tools/content/compile.py`; the one-shot procs Clearcasting, Fingers of Frost, Arcane Potency, Aegis and Vanish (60048-60052) are auras while they wait to be spent.
- Risks: custom spell display on the client, aura packet rate, effects that no stock aura type can express.

## Phase 4: single content source

- `tools/content-dump` exports current `bonk_*`, custom items and text.
- `tools/content-compiler` generates equivalent SQL; compare row by row on a test database.
- Switch to the generated flow; replace duplicated addon/client tables with generated artifacts or protocol data.
- Acceptance: one source generates all three artifacts; content changes only touch sources; CI checks artifact diffs.
- Progress (2026-11-04): `shared/content/cards/cards.yaml`, `shared/content/spells/spells.yaml` and 49 design tables under `shared/content/tables/` are the sources. `tools/content/compile.py` emits the world SQL, the server spell-id header, `hoa_aura`/`hoa_aura_locale` rows, `content.hash`, `hoa_content.sql` and `BonkContentHash.h`; `--check` guards them in CI. The server pushes the localized aura catalog to the client at login, so the client keeps no generated copy. `tools/content/apply.py` applies the SQL to a database, the generated tables matched the old data row for row, and the server compares the database hash with the build hash at startup. Spawn tables `bonk_hidden_creature` and `bonk_hidden_gameobject` deliberately stay in the database.
- Risks: large content volume, conflicts with old SQL during migration; guarantee equivalence with export → generate → compare.

## Phase 5: protocol cleanup

- Define the HoA message schema and generate C++/Rust.
- Expose the client Lua API; migrate presentation data in the addon.
- Delete the `BONK~` parser and string assembly.
- Acceptance: all state uses native auras; presentation data uses the typed protocol; version mismatches are explicit.
- Progress (2026-11-05): `shared/protocol/messages.yaml` and `tools/protocol/gen.py` generate the C++ writer and Rust decoder; `SMSG_HOA_MESSAGE` (826) carries `hoa.hello`, `hoa.aura_value`, `hoa.aura_text`, `hoa.aura_catalog_entry`/`aura_catalog_end`, `hoa.dash` and `hoa.aura_percent`. The client fires the matching `HOA_*` events into Lua. Shield, determination, necrotic, wounds and dash now use only the typed messages; `hoa.run_state`, `hoa.run_start` and `hoa.run_end` replace the old `state~`/`start~`/`end~` lines and fire table events. Pause, co-op pause policy, run XP, wave beats, the support/glyph/party meters, objective pins, enemy/ally plates, the offer/ley/glyph choice panels, quests, the vendor, the home/endless portal, found gear, gear replacement, the vault, the enchanter, the card panel, player-status signals, co-op prompts, small run signals and shrine/event timers, the death recap, the run summary, the leaderboard flow, the shop/mastery trees, gear stats, trinket tips, the arena panel, the tier/level/map selector and the codex rows are typed too. The server no longer sends any `BONK~` line and the addon parser is gone. A hello whose protocol version or content hash differs now fires `HOA_INCOMPATIBLE`, the client stops applying typed packets, and the addon raises a visible error instead of running against a mismatched server. Telegraph marks, kits, flights, missiles, props and aura anchors also use `hoa.visual_*` now, so the client no longer parses `HOA~` chat lines.

## Phase 6: performance and kernel cleanup

- Inventory and fix hot spots: Lua polling, aura refreshes, grid searches, per-frame scans, duplicated calculations.
- Establish benchmarks (server tick, login time, memory, client frame time).
- Remove migration switches and dead code.
- Acceptance: benchmarks are no worse than before; no regressions; docs updated.
- Progress (2026-11-06): mob pathing is Detour A* (`dtNavMeshQuery::findPath`), wrapped by `PathInfo`; Bonk crowd, spawn-point and run checks use it. A Barrens sandbox stress run with a 150-mob pack measured a 27–28 ms server tick, 0.1 ms HoA run code, a 0.04–0.24 ms crowd step and 0.00 ms of path time, so A* is not a hot spot in open ground; the map update interval dominates the tick. The remaining phase 6 work is the per-frame addon loops and the client-side benchmarks. A warm client launch reaches character select in 2.1 s, the in-game UI is up 0.45 s after entry and the loading screen clears after 2.0 s (about 6 s from process start); the release client held a 2.36 GB working set (4.47 GB private) and `mangosd` 504 MB while idle in the sandbox, with a 1 s warm server start. `BonkRun.cpp` is split into lifecycle, update, spawn, combat, loot, stage and weapon translation units (14.8k lines down to about 6.4k), and the content compiler now emits `content.manifest.json` plus `hoa_content_section`; hello v30 carries per-section hashes so the client names the changed content. The upstream 0.6.3 hotfix 1 is ported: launcher shutdown/restart fixes, leaderboard miss reasons and the server code-integrity check.

- Progress (2026-11-06): the upstream 0.6.4 update is ported: Hardcore mode with fallen/rest records, several characters per class with per-character progress, transmogrification and outfits, regular and Hardcore leaderboards, class balance, and the launcher download-resume/database-start fixes. The new messages use protocol 31; all new text is in the shared catalogue with enUS, zhCN and zhTW.

## Why this order

1. **i18n first:** it is the most direct user pain, and it requires server/client/addon changes together, best done while the monorepo is new and coupling is still clear.
2. **Auras second:** they depend on custom spell display in the client content pack, but can share the language-pack infrastructure.
3. **Content compiler third:** aura and text definitions can start handwritten and be compiled once the shape stabilizes; avoid blocking on a huge migration.
4. **Protocol last:** define messages after state and presentation data settle, minimizing churn.

## Rollback strategy

- Isolate each phase behind branches/switches; keep the old path until the new one passes regression.
- Do not switch the content compiler until "generated result == existing DB" is verified.
- Version client caches so a rollback invalidates old caches automatically.
