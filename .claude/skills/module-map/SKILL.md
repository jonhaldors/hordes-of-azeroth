# Where everything lives (module map)

Use this to find the right file before changing anything. The repository is a monorepo: one build per component, one shared content source, one typed protocol between server and client.

```
server/   VMaNGOS 1.12.1 C++ world+login server (the game rules live here)
client/   benilla: the Rust 1.12.1 client (engine + UI scripting + net)
addon/    the HordesOfAzeroth addon (Lua 1.12) loaded by the client
glue/     GlueXML: login/character-select screens (Lua 1.12)
launcher/ the downloader/installer (C#, Avalonia)
shared/   the single content source + i18n + the protocol definition
tools/    build, release, content and e2e scripts
config/   release/manifest/launcher configuration
docs/     architecture and component notes
```

## Who owns what

| You are changing... | Go to |
|---|---|
| a class's weapons, damage, cooldowns | `shared/content/tables/bonk_weapon.yaml` (+ `bonk_weapon_locale.yaml` for text) |
| a mastery / talent tree, class balance talents | `shared/content/tables/bonk_mastery*.yaml`, `bonk_mastery_tree*.yaml` |
| run passives (Blessing of Might etc.) | `shared/content/tables/bonk_passive*.yaml` |
| Darkmoon cards / trinket effects | `shared/content/cards/cards.yaml` |
| an aura's name/icon/description or dynamic text | `shared/content/spells/spells.yaml` |
| enemy types, maps, spawns | `shared/content/tables/bonk_mob*.yaml`, `bonk_map*.yaml` |
| class behaviour *code* (how a weapon behaves, not its numbers) | `server/src/game/Bonk/BonkRun<Class>.cpp` (e.g. `BonkRunWarrior.cpp`) |
| the run loop, scoring, waves | `server/src/game/Bonk/BonkRun*.cpp` |
| the typed protocol between server and client | `shared/protocol/messages.yaml` → generated into both sides (never edit the generated files) |
| what the addon shows for a message | `addon/HordesOfAzeroth/**` (Lua; `core/` framework, `panels/` HUD, `run/` run windows) |
| login screen / character select | `glue/GlueXML/*.lua/.xml` |
| the client's Lua API and injected globals | `client/crates/hoa/src/plugin.rs`, `lua_api.rs`, `*_lua.rs` |
| 1.12 UI scripting itself (frames, events, tooltips) | `client/crates/benilla-ui/src/script/**`, `client/crates/benilla-app/src/ui_*` |

## The flows that cross module lines

1. **Content**: `shared/content/**/*.yaml` —`tools/content/compile.py`→ `server/sql/content/*.sql` + a content hash —`tools/protocol/gen.py`→ embedded in both the server (`BonkContentHash.h`) and the client (`protocol_generated.rs`). Both sides must agree or the client blocks every message after hello.
2. **Protocol**: `shared/protocol/messages.yaml` —`tools/protocol/gen.py`→ `server/src/game/Bonk/HoaProtocol.h` + `client/crates/hoa/src/protocol_generated.rs` (171 messages, ids identical on both sides).
3. **Server → addon**: the server sends typed `SMSG_HOA_MESSAGE` packets; the client's `plugin.rs` decodes them and fires Lua events (`HOA_MOG_BEGIN`, `HOA_TIER`, ...). **Every fired event name must be `add_in_game_event`-registered in `plugin.rs`** — an unregistered event is a silent no-op on both ends, and the `every_fired_event_is_registered` test fails the build if one appears.
4. **Addon → server**: the addon sends chat (`.bonk hello <lang>` is the addon-ready handshake; other commands go through `SendChatMessage(".bonk ...", "SAY")`), handled in `server/src/game/Chat/Chat.cpp`'s `bonkCommandTable` → `server/src/game/Bonk/BonkCommands.cpp`.

## Rules of the road

- Never edit generated files (`server/sql/content/*.sql`, `HoaProtocol.h`, `protocol_generated.rs`, `shared/content/content.hash`): edit the yaml/`messages.yaml` and regenerate.
- Lua is 1.12: `string.gfind` not `string.gmatch`, globals `this`/`event`/`arg1..argN`, no `print` in the ship client. The addon harness (`cargo run -p benilla-app --example addon_harness -- addon --probe HordesOfAzeroth`) loads it into a real VM and reports load errors.
- `tools/e2e/bonk-probe.ps1` is the end-to-end check (see the `local-test` skill) — use it before claiming a UI fix works.
