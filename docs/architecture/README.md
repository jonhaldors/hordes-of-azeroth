# Architecture

## 1. Background

Hordes of Azeroth currently lives in three separate repositories: the main repository (addon, GlueXML, launcher, co-op networking), the VMaNGOS server, and the benilla client. That split made sense while following upstream, but our refactor direction—account-level languages, unified auras, a single content source—requires changing the server, client and addon together. Across repositories, every change becomes three pull requests and three version alignments.

The new repository therefore puts all components together, hard-forks, and evolves independently.

## 2. Problems to solve

### 2.1 Language is tied to the client install

- The client's locale has exactly one source: `Wow.ini` in the install directory (`client/crates/benilla-formats/src/wow_ini.rs:23-41`, `chain.rs:98-109`). `GetLocale`, addon `Title`/`Notes` selection, the login challenge, and the WDB cache header all use it (`benilla-app/src/ui_script/lifecycle.rs:160-161`, `ui_script/addons.rs:486-492`, `glue_session/login.rs:122`, `wdb.rs:500-504`).
- Client UI text is hardcoded English in `assets/ui/OptionsFrame.xml`, `GameMenuAdapters.xml`, `ScriptLogFrame.xml` and `AccountLoginRealmlist.xml`; `GlobalStrings.lua` also comes straight from the installed MPQs (`ui_script/lifecycle.rs:1165-1188`). The text shaper even hardcodes `"en-US"` (`ui_text/engine/mod.rs:169`).
- There is no query path for custom spells: the client only supports name/creature/pet/item queries (`benilla-app/src/net.rs:1034-1058`). IDs missing from `Spell.dbc` are dropped from the spellbook (`ui_spellbook.rs:351-355`); `GetSpellName`/`GetSpellTexture` return nothing (`benilla-ui/src/script/spellbook.rs:404-435`); the cast bar is empty (`ui_cast.rs:207-215`); aura names/icons are `None` (`ui_aura.rs:256-260`). The server cannot supply name, icon or description.
- The language setting reaches the server through an addon chat command. Server text can be localized per account, but client frames, DBC names and custom spell names remain uncontrolled.

**Goal:** language is an account/session property. The client install only supplies resources (models, textures, audio, base DBCs) and never decides the display language. Any 1.12.1 install language can run Chinese or English.

**Progress (2026-11-04):** the first client slice is in. `shared/i18n/ui` + `tools/i18n/gen_client_pack.py` generate enUS/zhCN packs; HoA-authored UI and GlueXML read `HOA_UI_*` keys; `GetLocale` uses an account/launcher locale while the install locale stays for DBC columns and name charsets. Stock FrameXML/GlobalStrings, DBC name overlays, zhTW and the hardcoded shaper locale remain.

### 2.2 Buffs/effects have three representations

- **Real auras, but only half-done:** move speed/max health use spells 17498/19255 (`BonkRun.cpp:11365-11376`); Necrotic has aura 18951 (`BonkRun.cpp:4411`) but the healing cut reads `m_necroticStacks` (`BonkRun.cpp:4439`); shield visual is 16051 (`BonkRun.cpp:4754-4758`); weapon buffs are cast as auras but their expiry is also stored in `m_buffs` (`BonkRun.cpp:8071-8072,7913-7922`).
- **Server variables plus addon rendering:** shield amount `m_spellShield` (`BonkRun.h:2263`) is sent to the addon as `shield~` (`BonkRun.cpp:4767`); dash `m_dashSpent/m_dashRechargeMs` (`BonkPlayer.h:544-545`, `BonkPlayerDash.cpp:194-221`); determination `m_determination` (`BonkPlayer.h:514`, persisted at `BonkPlayer.cpp:2322-2335`); boss wounds `m_bossWoundStacks` (`BonkRun.h:1796`, `BonkRun.cpp:4629`). None of these appear in the native buff frame.
- **Native spells plus an addon copy:** Blade Flurry, Enrage and friends reuse native spells, but the addon keeps a second set of timers.
- **Card procs span all three:** Zandalarian Hero Charm, for example, grants "25% Power for 10 sec every 30 sec" (`server/core/sql/migrations/20261027710000_world.sql:46-47`). The server uses `m_cardSurgeUntilMs` plus cooldown bookkeeping (`BonkRunCards.cpp:486-493`), and `GetCardPower` folds the bonus into damage and stats (`BonkRunCards.cpp:156-170`, `BonkRun.cpp:4867,6284`) with no Unit aura. The UI relies on the per-second `cardnow~` text (`BonkRunCards.cpp:507-533,586-596`) and a one-shot `Notify` (`:491`); the addon assembles the tooltip (`VanillaBonkCards.lua:84-86,205,313-328`).

The addon used to parse only `BONK~` chat lines and never used `UNIT_AURA`/`GetPlayerBuff`; it now consumes typed `HOA_*` events decoded by the Rust client, while `C_UnitAuras` serves enemy nameplate and boss debuffs. No chat parser remains.

**Progress (2026-11-05):** phase 3 moved the effect set onto real auras, and phase 5 replaced every server presentation/state string with the typed protocol. The bullets above describe the pre-refactor baseline kept for context.

Examples of duplication and polling:

- Keyword timers exist in four places: aura, `m_dotStacks`, a 200 ms server `kwdt` refresh (`BonkKeywords.cpp:29,342-361,497-555`), and an addon countdown (`VanillaBonkDebuffs.lua:328-350,385-399`).
- Card cooldowns: server `m_cardCooldowns`, addon rebuilds the countdown every frame (`VanillaBonkCards.lua:255-271,298-310`).
- Shield value: server `m_spellShield`, addon stores another copy (`VanillaBonk.lua:3611,3623`).
- Per-frame `OnUpdate`: `VanillaBonkDebuffs.lua:385` (plus a ring per icon at `:219`), `VanillaBonkCards.lua:255`, `VanillaBonkPlates.lua:652` (per nameplate at `:464`), `VanillaBonkHurt.lua:59`, `VanillaBonkDash.lua:89`, `VanillaBonkController.lua:1900`.

Result: what the player sees, what the addon shows and what the server actually applies can be three different states; other addons and combat logs cannot identify HoA effects through standard APIs.

**Goal:** one effect = one real aura. The server is the only state source; the native buff frame/`UnitBuff` can read it; the addon only displays it.

### 2.3 The same data exists in multiple places

Survey results (server = `server/core/src/game/Bonk/`, addon = `Interface/AddOns/HordesOfAzeroth/`):

- **Class names/IDs:** server `BonkStrings.cpp:666-674`, `SharedDefines.h:87-99`; addon `VanillaBonkUI.lua:71-72`, `VanillaBonkCodex.lua:25-33`, `VanillaBonkCoop.lua:71`, `VanillaBonkMeter.lua:22`.
- **Stat names, descriptions and caps:** server `BonkStrings.cpp:412-429`, `BonkMgr.h:888-899`, pickup cap at `BonkRun.cpp:228-229`; the addon writes them again at `VanillaBonk.lua:3030-3052` (5/50/60/75/20, pickup 400).
- **Item level formula:** server `BonkFoundGear.cpp:19-21,39-41`, `BonkFoundGear.h:19`; addon `VanillaBonkFound.lua:84-98`.
- **Numeric constants:** dungeon +30% health/+20% damage (`BonkRun.cpp:252-253` vs `VanillaBonkRunMaster.lua:34`), carry window 10 (`BonkMgr.h:1091` vs `VanillaBonkRunMaster.lua:677`), free climb 49 (`BonkLeaderboard.cpp:26` vs `VanillaBonkRunMaster.lua:1352`), vendor restock +50% (`BonkRunVendor.cpp:30` vs `VanillaBonkVendor.lua:97`), vendor name Zixil (`BonkRunVendor.cpp:33` vs `VanillaBonkVendor.lua:17`).
- **Vocabularies:** quality (`BonkStrings.cpp:950-954` vs `VanillaBonkUI.lua:42-47`, `VanillaBonk.lua:101-105`), damage types (`BonkRunStats.cpp:90,104-110` vs `VanillaBonkUI.lua:50-68`), objective kinds (`BonkObjectives.cpp:31` vs `VanillaBonkObjectives.lua:4-11`), quest categories (`BonkQuests.cpp:26` vs `VanillaBonkQuests.lua:46-53`).
- **IDs:** game objects 900001-900062 (`BonkMgr.h:40-46` vs `VanillaBonkSettings.lua:9-11`, `VanillaBonkController.lua:1699`, `VanillaBonkTutorial.lua:4-8`), Hearthstone 900230 (`BonkMgr.h:1054` vs `VanillaBonkHearth.lua:5`).
- **Key counts:** spell/passive slots (`BonkRun.cpp:248-251` vs `VanillaBonkHeroBar.lua:4-5`), glyph offers (`BonkRunGlyphs.cpp:20` vs `VanillaBonkGlyphs.lua:9`), level-up offers (`BonkMgr.h:1028` vs `VanillaBonk.lua:353`), evolve rank (`BonkMgr.h:464` vs `VanillaBonkCodex.lua:21`).
- **Duplicated computation:** leaderboard eligibility (`BonkPlayer.cpp:3388-3401` vs `VanillaBonkRunMaster.lua:1354-1378`).
- **Text:** resolved. Server text, addon text and client UI text now come from `shared/i18n`; the addon's single generated `VanillaBonkLocaleData.lua` replaces the old hand-kept ZH table.
- **Custom spell IDs:** resolved. `shared/content/spells/spells.yaml` generates `BonkSpellIds.h` and the addon's `VanillaBonkAuraIds.lua`; the client receives the localized custom aura rows from the server instead of keeping its own ID table.
- Spell/item names: custom HoA spells display through the server-sent aura catalog. Stock spell/item/creature names still come from the installed DBC columns or the server's query response, so they follow the install locale rather than the account language until a DBC name overlay exists.
- **Text:** resolved. Text is keyed by stable message IDs in `shared/i18n` and every artifact is generated from it.

**Goal:** content is written only in `shared/content`, text only in `shared/i18n`, and tools generate each artifact. The server is authoritative at runtime; the client/addon keep no business copies.

## 3. Core principles

1. **Server authority:** game state, effects, progression and numbers live on the server; client and addon only present them.
2. **Language decoupled from the install:** account language decides text; client data language only affects resource parsing.
3. **Aura first:** if a native aura can express it, never use a custom timer; if not, use a dummy aura plus server logic, but the state still lives on an aura.
4. **Single source:** content, text and protocol each have one source file; generated artifacts are never hand-edited.
5. **Keep the kernels:** VMaNGOS and benilla keep their network, movement, combat, rendering and Lua engines; only the HoA layer and proven hot spots are refactored.
6. **Verifiable:** every phase has a runnable build, headless integration tests and explicit acceptance criteria.

## 4. Layers

```
┌──────────────────────────────────────────────────────────────┐
│  shared/content + shared/i18n + shared/protocol (sources)     │
└───────────────┬──────────────────────────────┬───────────────┘
                │ tools/content-compiler       │ tools/protocol-gen
                ▼                              ▼
   server SQL / C++ constants      client content pack / Rust code
   addon Lua tables / text catalogues      addon Lua constants
                │                              │
┌───────────────▼──────────────┐  ┌────────────▼───────────────┐
│ server (VMaNGOS kernel)      │  │ client (benilla kernel)     │
│  Hoa game layer              │  │  HoA UI / content overlay   │
│  ├ aura lifecycle            │  │  ├ native buff/level/cast   │
│  ├ run/combat/proc           │  │  ├ language packs + fonts   │
│  ├ content access (generated)│  │  └ cache (locale, content)  │
│  └ i18n runtime              │  │                             │
└───────────────┬──────────────┘  └────────────┬───────────────┘
                │      vanilla opcodes + HoA protocol  │
                └──────────────┬───────────────┘
                               ▼
                      addon (presentation)
                      launcher (LAN / direct connect)
```

## 5. Key flows

### 5.1 Login and negotiation

1. The launcher reads the account language and content version, then starts the client.
2. The client starts with 1.12.1 data in any language; the login challenge carries only the client data locale (for resource parsing).
3. On world login the server sends the account language, content hash and protocol version.
4. The client loads the matching language pack and content pack; a version mismatch prompts an update or refuses entry.
5. The server localizes item/creature/spell query responses and all HoA text for the account language.

### 5.2 Text

- Content text: localized by the server and sent with query responses; the client does not use DBC names for display.
- Custom spells/auras: the content pack maps ID → name/icon/description and overrides DBC lookups.
- Server runtime text: message ID plus arguments; the server looks up the table and sends the result.
- Client/addon UI: local language packs.

### 5.3 Auras

- Effects are defined in `shared/content/auras`.
- The server's `Hoa::Auras` applies, refreshes, removes, stacks and times them.
- The client receives them through native `SMSG_AURA_UPDATE`; the buff frame shows them directly; the addon reads them with `UnitBuff`.
- Server logic reads `Unit::HasAura/GetAuraCount` and keeps no parallel booleans or timers.

### 5.4 Content publishing

- Content source changes → compiler generates SQL/client pack/addon tables/text catalogues → version hash changes.
- The server verifies at startup that the generated hash matches the database.
- Client/host handshake verifies the version so old-content clients cannot join.

### 5.5 Co-op

- No public lobby or registration server.
- After starting a local server, the host can be discovered by LAN broadcast or give teammates `ip/domain:port` directly.
- Clients connect directly to the host; the handshake checks protocol version, content hash and language capabilities.
- NAT traversal, dynamic DNS and port forwarding are the player's responsibility (or use existing tools such as ZeroTier/Tailscale); the project maintains no notification service.

## 6. Component responsibilities

| Component | Keep | Refactor |
| --- | --- | --- |
| server | VMaNGOS networking, movement, combat, maps, DB layer | HoA game layer, effect state, text, content access |
| client | benilla rendering, input, networking, Lua/FrameXML, stock UI | language packs, content overlay, custom spells, cache keys, HoA UI hooks |
| addon | window layout, card/reward/codex UI | remove state timers, data copies, hardcoded text |
| launcher | install, launch, server management | language selection, any-language client check, cache invalidation, LAN/direct co-op |
| tools | ideas from the existing translation tool | content compiler, protocol generator, CI checks |

## 7. Non-goals (this phase)

- Do not rewrite VMaNGOS or benilla internals.
- Do not keep merging with upstream; upstream is only a reference for content and bug fixes.
- Do not change the 1.12.1 protocol itself; define HoA messages on top of it.
- Do not promise a one-shot migration; deliver phase by phase, each runnable.

## 8. Risks and trade-offs

| Risk | Trade-off |
| --- | --- |
| More auras create network/performance pressure | Coalesce refreshes, limit high-frequency procs, use aura events instead of polling; set benchmark gates |
| Custom spells are absent from DBCs and render blank | Land the client content overlay before migrating effects |
| The content compiler is a wide change | Do an equivalent export→generate→compare migration first, then switch the runtime |
| A hard fork loses upstream fixes | Periodically cherry-pick upstream fixes by hand; no automatic merges |
| More languages mean more text | Stable IDs + CI completeness checks + incremental translation tooling |

## 9. Phases

See the [migration plan](../migration-plan/README.md).
