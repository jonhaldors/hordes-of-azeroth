# Internationalization (i18n)

## 1. Goals

- Language is decided by the **account/session**, not by the client install data language.
- Every user-visible string in the server, client, addon and launcher can be localized.
- Translations are keyed by stable IDs; changing English never invalidates an existing translation.
- Missing translations have an explicit fallback and a CI alert, so there is no black box where "this part is still English".

Non-goals for this phase: right-to-left languages, voice-over localization, real-time machine translation.

First languages: **enUS, zhCN, zhTW**. zhTW prefers official 1.12.1 Traditional Chinese names; missing entries are converted from zhCN and manually reviewed, watching for character and terminology differences (e.g. 法術, 拾取, 設定). The zhTW font is Noto Sans TC.

## 2. Where language comes from

```
launcher / in-game setting → account language (server bonk_account.locale-style field)
                    ↓ world login handshake
              client loads the matching language pack
                    ↓
      server returns item/creature/spell query results and HoA text in that language
```

- The installed 1.12.1 data language (`Data/*.MPQ`, DBCs) only parses models, textures, audio and base data.
- Client UI text no longer reads English strings from DBCs/FrameXML; it reads language packs.
- The addon no longer uses `GetLocale()` to choose text; it reads the language sent by the server or the client setting.
- Switching language: update the account setting → the server refreshes visible names (extend the existing `RefreshCreatureNames` idea to items/spells) → the client reloads the UI and drops old-language caches. No full game restart is required.

## 3. Text categories

| Category | Examples | Source | Runtime |
| --- | --- | --- | --- |
| Content names/descriptions | items, spells, auras, creatures, maps, talents, cards | `shared/content` entries + `*_id` | server-localized queries; client content pack overrides |
| Server runtime text | stage unlocks, rewards, combat notices, errors | `shared/i18n/messages` | message ID + arguments, server lookup |
| Client UI | options, menus, errors, Glue, character select | `shared/i18n/ui` | client language packs |
| Addon UI | window titles, buttons, tooltips | `shared/i18n/addon` | generated Lua language tables |
| Launcher/co-op | install, launch, direct/LAN rooms | `shared/i18n/launcher` | .NET resources |

## 4. Message catalogue

Sources are split by domain, for example `shared/i18n/messages/run.yaml`:

```yaml
- id: hoa.run.stage_unlocked
  enUS: "Stage {stage} unlocked."
  zhCN: "第{stage}阶段已解锁。"
  zhTW: "第{stage}階段已解鎖。"
  placeholders:
    stage: number

- id: hoa.run.gear_found
  enUS: "You found {item}."
  zhCN: "你获得了{item}。"
  zhTW: "你獲得了{item}。"
  placeholders:
    item: text
```

Rules:

- `id` is lower-case dot-separated and grouped by feature; once released it never changes (new semantics get a new ID and the old one is retired).
- English is the source language but **not the key**; keying by English sentences makes every English edit invalidate translations (the current `source_hash` problem).
- `placeholders` declares types; the build checks that every language has the same placeholder set and the runtime formats by type.
- Plurals: `id.one` / `id.other` (or `_one` / `_other`); the formatter follows the language's rules; Chinese usually uses only `other`.
- Long text may wrap; CJK line breaking belongs to the client layout layer, not hard newlines in the string.
- Rich text such as colors/links uses explicit markers (e.g. `{c:ffd100}...{/c}`) or separate style fields; never put color codes in translations.

## 5. Generated artifacts

```
shared/i18n/
  messages/            sources (per-domain YAML/JSON)
  ui/                  client UI sources
  addon/               addon text sources
  launcher/            launcher text sources
  generated/
    messages.json      all messages + every language + placeholder metadata
    messages.hash      version hash
```

The compiler then generates:

- `server/src/game/Hoa/i18n/generated/Messages.h/.cpp`: ID enums + English source + lookup
- `client/assets/i18n/<locale>.json`: client language packs
- `addon/HordesOfAzeroth/VanillaBonkLocaleData.lua`: one generated addon data file holding every language (fixed TOC name)
- `tools/translate` reads and writes `shared/i18n` directly instead of maintaining its own JSON

## 6. Server

- Runtime API: `Hoa::I18n::Get(locale, id, args...)`.
- Long database text (map descriptions, talent descriptions) may still live in `*_locale` tables, but the row key is a content ID, not an English sentence; the generator keeps them in sync.
- Item/creature/spell names: prefer the existing `locales_item`/`locales_creature` mechanisms; custom spell/aura names come from content tables.
- Refreshing cached names on language change:
  - Creatures: re-send `SMSG_CREATURE_QUERY_RESPONSE` for visible creatures.
  - Items: re-send templates for owned items plus currently obtainable gear/items (or have the client re-query by content version).
  - Custom spells: update with the content pack; do not depend on the client DBC.

## 7. Client

- **Language packs:** the client loads `client/crates/benilla-app/assets/i18n/<locale>.json` at startup from the launcher/last language; the account language overrides it after login. enUS, zhCN and zhTW are compiled into the client.
- **GlobalStrings:** stock UI still reads `GlobalStrings.lua` from the install's MPQ chain. When `benilla-config/locale/<language>/GlobalStrings.lua` exists, `Chain` returns that file instead, so stock FrameXML follows the account language without replacing the install.
- **`GetLocale`:** implemented through a separate UI locale: before login it returns the launcher/last language; after login it returns the account language. `GetLocale()` in the addon means the game language, not the install language. The `Wow.ini` locale is still used for parsing DBC columns and resources, and for name charsets.
- **UI text:** `OptionsFrame.xml`, `GameMenuAdapters.xml`, `ScriptLogFrame.xml`, `AccountLoginRealmlist.xml`, `KeyBindingsPage.xml` and the GlueXML files now read generated `HOA_UI_*` keys from the language pack; Lua/FrameXML read the same table.
- **DBC names:** spellbook, map, talent, class/race names read DBC columns. With `benilla-config/locale/<language>/DBFilesClient/*.dbc`, the chain reads those files and selects the pack's locale column; otherwise the install's columns remain. `tools/install-locale-pack.ps1 -Client <official-client> -Language zhCN -Config <benilla-config>` fills the folder through `benilla-extract locale-pack` (GlobalStrings plus every live `DBFilesClient` table, patch tombstones excluded); it requires a 1.12.1 client in that language, e.g. a zhCN build. zhTW has no stock pack yet and falls back to the install.
- **Fonts:** the fallback chain follows the selected UI language (zhCN: Noto Sans SC; zhTW: Noto Sans TC; enUS: stock fonts), with a fixed glyph fallback order.
- **Layout:** CJK line breaking without spaces, kinsoku rules, minimum button/label widths; long text scales or wraps. The shaper receives `zh-CN`/`zh-TW`/`en-US` from `UiLanguage::shaping_locale()`.
- **Caches:** add `(locale, contentVersion)` to WDB/template cache names or headers; old caches expire on language or content changes. This also fixes "gear names stay English after switching language". The first slice is in `client/crates/benilla-app/src/wdb.rs`: the WDB header (formats 2) folds the HOA account language into the locale tag, so a cache written under another language is discarded; the content version follows when the content pack exists.
- **Custom spells:** the client has no spell query path (`benilla-app/src/net.rs:1034-1058`), so IDs missing from `Spell.dbc` render blank (`ui_spellbook.rs:351-355`, `ui_aura.rs:256-260`). Custom aura rows are pushed by the server at addon-ready and on a language change (`aura_catalog_entry`/`aura_catalog_end`); the Rust side stores the already-localized name/icon/description and never selects a language.
- **Glue class names:** the glue code must not hardcode localized class names. It maps a character through the server-provided class id, and otherwise learns the client's localized class names at runtime from `GetClassesForRace`/`GetSelectedClass`; the old hardcoded Chinese table is gone.
- **GlueXML:** login/character-select/creation use the same language pack; language selection can live in Glue or the launcher.

**Progress (2026-11-06):** `shared/i18n/ui` + `tools/i18n/gen_client_pack.py` generate enUS/zhCN/zhTW packs; `HOA_UI_*` globals cover HoA's Options, GameMenu, ScriptLog, Realmlist, KeyBindings and GlueXML, and `GetLocale` follows the account language. zhTW has its own font and shaping locale. The client also reads stock GlobalStrings and DBCs from `benilla-config/locale/<language>/` when installed; `tools/install-locale-pack.ps1` fills that folder from an official 1.12.1 client, and a zhCN pack generated this way was verified against the official zhCN client.

- **Caches:** add `(locale, contentVersion)` to WDB/template cache names or headers; old caches expire on language or content changes. The first slice is in `client/crates/benilla-app/src/wdb.rs`: the WDB header (formats 2) folds the HOA account language into the locale tag, so a cache written under another language is discarded.
- **Custom spells:** the client has no spell query path (`benilla-app/src/net.rs:1034-1058`), so IDs missing from `Spell.dbc` render blank (`ui_spellbook.rs:351-355`, `ui_aura.rs:256-260`). Custom aura rows are pushed by the server at addon-ready and on a language change (`aura_catalog_entry`/`aura_catalog_end`); the Rust side stores the already-localized name/icon/description and never selects a language.
- **Glue class names:** the glue code must not hardcode localized class names. It maps a character through the server-provided class id, and otherwise learns the client's localized class names at runtime from `GetClassesForRace`/`GetSelectedClass`; the old hardcoded Chinese table is gone.
- **GlueXML:** login/character-select/creation use the same language pack; language selection can live in Glue or the launcher.

## 8. Addon

- All languages live in one generated `VanillaBonkLocaleData.lua`, keyed by stable message ID; there is no per-language Lua file.
- The addon registers the tables through `VanillaBonkLocale.RegisterLanguages`. `L()` call sites still pass their English lookup text; a generated English→ID map keeps them working during the migration.
- Delete the `VanillaBonkLocale.English` reverse lookup (currently used to match NPC names across languages); NPC windows match by NPC entry/ID, not by name.
- Option text (`VanillaBonkOptionsText.lua`) becomes language-pack driven; no more English→Chinese map in Lua.
- Text arguments use `L(id, args)`; never concatenate sentences with variable word order in Lua.

## 9. Translation workflow

1. Developers change the English source (only `shared/i18n`).
2. `tools/translate` lists missing, changed, unused and placeholder-error entries.
3. Translators fill in the target language; the tool checks length, formatting and glossary terms.
4. CI generates artifacts and checks the diff; missing translations warn on development branches and block release branches.
5. The glossary lives in `shared/i18n/glossary.yaml`, keyed by content ID, not by English sentence.

## 10. Migrating from the current system

| Current state | Migration |
| --- | --- |
| Server `BonkLocale`: English sentences + `source_hash` | Extract 900+ messages, assign stable IDs, generate enums; import old translations by English match |
| `bonk_*_locale` tables | Row key becomes the content ID; the generator maintains them |
| Addon `VanillaBonkLocaleData.lua` (~1000+ entries) | Generated from the catalogue; one data file for every language |
| `VanillaBonkOptionsText.lua` client-option patch | Replace with native client language packs; keep the patch during the transition |
| GlueXML `BonkGlueLocaleZhCN.lua` | Merge into the Glue section of `shared/i18n/ui` |
| Hardcoded English in client `OptionsFrame.xml` and kin | Replace with language-pack keys in a client PR |
| Client DBC names | Content pack overrides; language no longer depends on the install |
| Caches that do not expire on language change | Add `(locale, contentVersion)` to the cache key |
