# AGENTS.md

Guidance for AI assistants (and humans in a hurry) working in this repository.

Hordes of Azeroth is a survivors-style game mode for World of Warcraft 1.12.1:
an endless horde, spells that fire on their own, co-op for up to 4 players, on
a server that runs on the player's own PC. This repository is a monorepo: the
VMaNGOS server, the benilla Rust client, the addon, the GlueXML, the launcher
and the shared content all live here.

## Layout

```
server/    VMaNGOS 1.12.1 C++ world+login server - the game rules live here
client/    benilla: the Rust 1.12.1 client (engine + UI scripting + net)
addon/     the HordesOfAzeroth addon (Lua 1.12) loaded by the client
glue/      GlueXML: login / character-select screens (Lua 1.12)
launcher/  the downloader/installer (C#, Avalonia)
shared/    the single content source (yaml), i18n, and the protocol definition
tools/     build, release, content, i18n, protocol and e2e scripts
scripts/   development and build scripts
config/    release/manifest/launcher configuration
docs/      architecture and component notes (README.md + README_zh.md pairs)
```

For "I need to change X, where is it" see `.claude/skills/module-map/SKILL.md`.

## Build

`scripts/build.sh [all|server|client|launcher|check]`. The underlying commands:

- Server: `cmake -S server -B server/build -DSUPPORTED_CLIENT_BUILD=CLIENT_BUILD_1_12_1 -DBUILD_EXTRACTORS=OFF -DENABLE_MAILSENDER=OFF` once, then `cmake --build server/build --config Release --target mangosd`.
- Client: `cargo build -p hoa` in `client/` (a debug build includes the probe features used by the e2e tools).
- Launcher: `dotnet build launcher/HordesOfAzerothLauncher.csproj -c Release`.

## The content pipeline (mandatory after editing shared/content/**)

The yaml under `shared/content/` is the single source for game data (spells,
auras, talents, weapons, cards, maps, text). Generated files are never edited
by hand:

1. `python tools/content/compile.py` - yaml to `server/sql/content/*.sql` and a
   content hash (`shared/content/content.hash`).
2. `python tools/protocol/gen.py` - regenerates `HoaProtocol.h` and
   `protocol_generated.rs`. The hash is part of the client/server handshake:
   mismatched ends block every message after hello.
3. `python tools/content/apply.py --maria <mariadb.exe> --user <u> --password <p> --database mangos`
4. Rebuild **both** the server and the client - each embeds the hash.

Skipping a step leaves the client refusing all game messages after hello.

## Testing

- CI runs on push/PR to `main` and `monorepo` (`.github/workflows/ci.yml`):
  client checks, server build, launcher build, addon Lua syntax, i18n checks,
  content check, protocol consistency.
- End-to-end: `tools/e2e/bonk-probe.ps1` launches the real client against the
  local server, types `.bonk` commands and reads both logs. See
  `.claude/skills/local-test/SKILL.md` for the full local environment (server
  start, accounts, log locations, the client launch environment variables).

## Rules of the road

- **Never edit generated files** (`server/sql/content/*.sql`, `HoaProtocol.h`,
  `protocol_generated.rs`, `content.hash`): edit the yaml and regenerate.
- **Lua is 1.12**: `string.gfind` not `string.gmatch`, globals `this`/`event`/
  `arg1..argN`, no `print` in the shipped addon.
- **Every client event the plugin fires must be registered** with
  `add_in_game_event` in `client/crates/hoa/src/plugin.rs`; an unregistered
  event is a silent no-op on both ends, and the `every_fired_event_is_registered`
  test fails the build if one appears.
- **Cast-on-condition masteries require their weapon in the bag** (Shadow
  Weaving needs the Mind Blast weapon, i.e. a Shadow-spec run). Their
  descriptions start with "If you have learned X, ..."; keep new ones in that
  shape.
- **Text is enUS + zhCN**: every locale table has a `_locale.yaml` twin; both
  languages are updated together (zhTW is not maintained).
- Class balance tuning is data work - see `.claude/skills/class-balance/SKILL.md`
  for which yaml file holds which numbers and the full edit/apply/rebuild cycle.

## Repository skills

`.claude/skills/` holds three task guides: `local-test` (run the local server +
client + e2e probe), `module-map` (where everything lives), and `class-balance`
(how to tune classes). Read the one matching the task before diving in.
