# Building and working on Hordes of Azeroth

This file is for people who want to build Hordes of Azeroth from source or work on it. To play, see the [README](README.md).

**Contents**

- [Layout](#layout)
- [Building from scratch](#building-from-scratch)
- [Running the development tree](#running-the-development-tree)
- [The game mode on the server](#the-game-mode-on-the-server)
- [Scripts](#scripts)
- [Releases](#releases)
- [Code style](#code-style)

<br>

---

## Layout

The repository root is a World of Warcraft 1.12.1 (build 5875) client folder. `.gitignore` is a whitelist, so the game files are never tracked. Only these are:

| Path | Contents |
| --- | --- |
| `Interface/AddOns/` | Client addons (the game mode's UI) |
| `Interface/GlueXML/` | Login and hero screens |
| `tools/` | Scripts for the local server, the launcher (`tools/launcher`), and TelegraphKit (`tools/telegraphs`) |
| `config/` | MariaDB settings, server config overrides, release packages |
| `play.bat`, `stop.bat` | Double-click wrappers around the scripts |
| `client/` | Submodule: the game client, [hordes-of-azeroth-client](https://github.com/jonhaldors/hordes-of-azeroth-client), a modified version of [benilla](https://github.com/samwhosung/benilla), branch `main`. Our code is in `client/crates/hoa` |
| `server/core/` | Submodule: our VMaNGOS fork, [hordes-of-azeroth-server](https://github.com/jonhaldors/hordes-of-azeroth-server), branch `vanilla-bonk` |

Everything else under `server/` is third-party or generated and stays untracked:

| Path | Contents |
| --- | --- |
| `server/build/` | CMake build tree |
| `server/run/` | Installed `mangosd.exe`, `realmd.exe`, extractors, generated configs |
| `server/data/` | dbc, maps, vmaps and mmaps extracted from the client |
| `server/mariadb/`, `server/mariadb-data/` | Portable MariaDB and its data directory |
| `server/logs/` | Server logs |

Internal names still use the project's working title, Vanilla Bonk: `bonk_*` tables, `.bonk` commands, `BONK~` addon messages and `VanillaBonk*.lua` files.

<br>

---

## Building from scratch

You need Git, Visual Studio 2022 Build Tools with the C++ workload (CMake ships with it), [Rust](https://rustup.rs), the .NET 10 SDK, and the 1.12.1 client in the repository root. Run everything from the root in PowerShell.

### 1. Get the client and server source

The benilla and VMaNGOS forks are pinned by submodules:

```powershell
git submodule update --init
```

### 2. Build the server and install it into `server\run`

```powershell
cmake -S server\core -B server\build -G "Visual Studio 17 2022" -A x64 `
    -DBUILD_EXTRACTORS=1 "-DCMAKE_INSTALL_PREFIX=$PWD\server\run"
cmake --build server\build --config Release -- /m
cmake --install server\build --config Release
```

If several Visual Studio 2022 installations exist, point CMake at the one with the C++ tools: `"-DCMAKE_GENERATOR_INSTANCE=<install path>"`.

### 3. Set up the database

Extract the MariaDB 11.4 Windows zip to `server\mariadb`, and the `db-*.zip` from [vmangos db_latest](https://github.com/vmangos/core/releases/tag/db_latest) to `server\downloads\db`. Then create the databases, import the dump, and apply the game mode's own tables and world data:

```powershell
server\mariadb\bin\mariadb-install-db.exe "--datadir=$PWD\server\mariadb-data" --password=root
tools\start-server.ps1 -DatabaseOnly
$sql = "server\mariadb\bin\mariadb.exe", "-h", "127.0.0.1", "-u", "root", "-proot"
$dump = "$PWD\server\downloads\db\mysql-dump" -replace '\\', '/'
& $sql[0] $sql[1..5] -e "source config/create-databases.sql"
& $sql[0] $sql[1..5] realmd     -e "source $dump/logon.sql"
& $sql[0] $sql[1..5] logs       -e "source $dump/logs.sql"
& $sql[0] $sql[1..5] characters -e "source $dump/characters.sql"
& $sql[0] $sql[1..5] mangos     -e "source $dump/mangos.sql"
& $sql[0] $sql[1..5] -e "INSERT INTO realmd.realmlist (id, name, address, port) VALUES (1, 'Hordes of Azeroth', '127.0.0.1', 8085)"
tools\apply-migrations.ps1
```

The dump must match the upstream revision the fork is based on; the world server lists any missing migrations at startup. `db_latest` is rebuilt whenever SQL changes upstream, so after merging `upstream/development` into the fork, run `tools\apply-migrations.ps1` or re-import.

### 4. Client data, configs and account

Close the client first. The map extraction and nav tiles take a while. `build-telegraphs.ps1` writes `Data\patch-3.MPQ` (attack warnings, XP orb wisps, run bolt visuals) and copies its tables into `server\data`, so it runs after the extraction.

```powershell
tools\extract-client-data.ps1
tools\build-telegraphs.ps1
tools\apply-config.ps1
tools\create-account.ps1 -Name player -Password player -GmLevel 6
```

### 5. The game client

```powershell
cd client
cargo build --release -p hoa
```

The output is `client\target\release\HordesOfAzeroth.exe`. It reads the game data from `client\WoW` (a junction to the root: `New-Item -ItemType Junction -Path client\WoW -Target $PWD`) or from `WOW_DATA`.

### 6. The launcher

The launcher is an Avalonia app for .NET 10 in `tools/launcher`, built for Windows and Linux: `dotnet publish tools\launcher\HordesOfAzerothLauncher.csproj -c Release -r win-x64` (or `linux-x64`). `HoALauncher.exe --source <folder>` installs and updates from a local folder of release assets instead of GitHub.

### macOS development (Apple Silicon)

Install the Xcode command line tools, Homebrew, Rust and the .NET 10 SDK. From the repository root:

```bash
brew install cmake ninja openssl@3 mariadb@11.4
git submodule update --init
bash tools/macos/build-server.sh
bash tools/macos/build-client.sh
```

The native server and all four data tools install into `server/run`. The CMake cache is in `server/build-macos`, with an intermediate installation in `server/install-macos`. Set `BUILD_JOBS` to control parallel compilation (default: 6). `MARIADB_ROOT` and `OPENSSL_ROOT_DIR` can point at alternative Homebrew installations. Stack traces use macOS's `atos`, avoiding extra dependency downloads during configuration. These development binaries link against the local Homebrew libraries; keep those dependencies installed.

Use your own Windows 1.12.1 build 5875 English (enUS) client as the asset source. Its Windows executable is never run:

```bash
client_source="/path/to/World of Warcraft"
bash tools/macos/extract-client-data.sh "$client_source"
bash tools/macos/build-telegraphs.sh "$client_source"
python3 tools/macos/build-navtiles.py --threads 6
```

The source client stays read-only. Extraction writes DBC tables to `server/data/5875/dbc`, terrain to `server/data/maps` and collision data to `server/data/vmaps`. The intermediate collision files remain in `server/data/Buildings`; the extractor refuses to overwrite an existing extraction there. The navigation script builds the configured camp, dungeon, Heroic and Mythic tiles, skipping existing nonempty tile files on a rerun.

The spell-effect script creates a local `Data` folder containing links to the source archives and the generated `patch-z.MPQ`. Generated addon textures and server DBC changes also stay in the project. Both asset scripts accept the source game's `Data` folder as well as its parent. The .NET scripts use `DOTNET`, `.devtools/dotnet/dotnet`, or `dotnet` on the PATH, in that order.

Download the release's database packages and initialize a separate local database:

```bash
python3 tools/macos/fetch-database.py
python3 tools/macos/server.py setup
python3 tools/macos/server.py start
python3 tools/macos/server.py console "account create player player"
python3 tools/macos/server.py console "account set gmlevel player 6"
bash tools/macos/play.sh
```

The downloader verifies package and SQL-file checksums against the release manifest cached in `server/manifest-linux.json`. Setup imports the base schemas and the project's world dump, applies missing migrations, merges the server config overrides, and configures the local realm. It preserves populated databases when rerun; stop the world server before applying migrations. MariaDB runs from Homebrew with its data in `server/mariadb-data`, a project-local socket, and TCP port 13306. It does not use a Homebrew service or the global database directory. All three services bind to `127.0.0.1`.

After setup, `bash tools/macos/play.sh` starts the local services if needed and launches the client. The run script selects Metal, loads the generated local data and addon, and logs in as `player` / `player`. Set `WOW_USER` and `WOW_PASS` for another account. Client settings and caches live under `client/benilla-config`; `BENILLA_HOME` can select another state folder. An explicit client path or `WOW_DATA` overrides the generated local `Data` folder, so use the default after building spell effects. Unattended runs require explicit test credentials and follow the client repository's probe-identity rules.

```bash
python3 tools/macos/server.py status
python3 tools/macos/server.py console "server info"
python3 tools/macos/server.py stop
```

Console output and server logs are under `server/logs`. `start` reuses the project services if they are already running; `stop` shuts down the world, login server and database cleanly. The launcher can be compiled with `bash tools/macos/build-launcher.sh`, but macOS updater packages and installation through the launcher are not yet verified; use the development scripts locally. Packaging for another Mac remains separate work.

Verified on November 2, 2026: the Apple Silicon server build (`ae62abb2c`), asset and spell-effect generation, database imports and migrations, launcher compilation, clean service shutdown/restart, and native-client authentication, hero creation and world entry on GM Island. This was a local login smoke test; combat and multiplayer were not exercised.

<br>

---

## Running the development tree

- `play.bat` starts MariaDB, realmd and mangosd (if not already running), then the client from `client\target\release`, which logs in as `player` / `player` (administrator, GM level 6) and opens the hero screen.
- Use `play.bat` for development, not `HoALauncher.exe`. The launcher is built for players: an install it makes gets a normal player account without GM commands, and it updates the folder from GitHub. In the repository it leaves your GM level alone, but `play.bat` is the way to run your own build.
- The GM level comes from the account, not from `play.bat`: step 4 creates `player` with `-GmLevel 6`. Without it (the script's default is 0) the GM commands (`.bonk skip`, `.bonk god`, `.bonk card`, `.gm` and the rest) won't work. To fix an existing account, stop the world server and run `tools\create-account.ps1 -Name player -Password player -GmLevel 6` again, or type `account set gmlevel player 6` in the `mangosd` console.
- `stop.bat` shuts everything down cleanly.
- The minimized `mangosd` window is the server console; type commands there.
- All three services listen on `127.0.0.1` only, and `realmlist.wtf` must contain `set realmlist 127.0.0.1`.

<br>

---

## The game mode on the server

The game mode lives in `server/core/src/game/Bonk/`. Maps, spawn pools, spells, upgrades and the rest are the `bonk_*` tables in the world database (`mangos`); edit them and run `.bonk reload` between runs.

- Heroes live at the camp on GM Island between runs. Gold is shared by every hero on the account.
- `/bonk` in game picks a map, or use `.bonk start westfall` / `.bonk start moltencore`. `.bonk stop` ends a run.

Game-mode changes to the core go on the `vanilla-bonk` branch of the fork: commit and push inside `server/core`, then commit the updated submodule pointer here. `upstream` in that checkout is `vmangos/core`. Rebuild with step 2 above, then restart the server.

<br>

---

## Scripts

| Script | Purpose |
| --- | --- |
| `tools/start-server.ps1 [-Play] [-DatabaseOnly]` | Start the services; safe to rerun |
| `tools/launch-client.ps1 [-Account] [-Password]` | Start the client with that login (what `-Play` runs) |
| `tools/stop-server.ps1` | Stop the services |
| `tools/apply-config.ps1` | Regenerate `server/run/*.conf` from `*.conf.dist` and `config/*.overrides.conf` |
| `tools/apply-migrations.ps1` | Apply new SQL migrations from `server/core/sql/migrations` (MariaDB must be running) |
| `tools/create-account.ps1 -Name -Password [-GmLevel]` | Create a game account (world server must be stopped) |
| `tools/extract-client-data.ps1` | Extract dbc, maps and vmaps into `server/data` and build the nav tiles in `config/navtiles.json`, camp and Normal zones first (`-AllTiles` builds every tile, `-MmapsOnly` skips the extraction) |
| `tools/build-navtiles.ps1` | Rewrite `config/navtiles.json` from the run zones, start spots and tiers in the world database (after zone changes, before a release) |
| `tools/build-telegraphs.ps1` | Build `Data/patch-z.MPQ` and copy its tables into `server/data`; rerun after extracting client data, client closed |
| `tools/release.ps1 [-Publish]` | Stage a release into `release/<version>`; `-Publish` creates the GitHub release |

To change a server setting, add it to `config/mangosd.overrides.conf` (or `realmd.overrides.conf`), run `tools/apply-config.ps1`, and restart the server.

<br>

---

## Releases

`tools/release.ps1` builds the server from the committed fork, dumps the world database, packs everything into `release/<version>/assets` and writes the `manifest.json` the launcher reads. `config/release.json` lists the packages and the third-party downloads. A package is only uploaded again when its contents change; otherwise the manifest points at the previous release's file.

The monster paths ship the same way: each group in `config/navtiles.json` becomes a `navmesh-<group>.zip` of the matching files in `server/data/mmaps`, and the launcher downloads those instead of building them. A group whose map header is missing, or with any file older than the last map generator change in `server/core`, is left out with a warning, and the launcher builds that group on the player's CPU instead. Build every tile (`tools\extract-client-data.ps1 -MmapsOnly -AllTiles`) after a generator change, and in a fork before its first release, to ship them as downloads. Each repository hosts its own navmesh files on its own releases. The launcher also builds tiles on the CPU when a download fails.

1. Raise `VERSION`.
2. Add a section for it at the top of `CHANGELOG.md`.
3. Run `tools\release.ps1 -Publish`.

The newest changelog section becomes the GitHub release text, and the launcher shows every section as patch notes. In a section, `### Heading` lines become subheadings, lines starting with `- ` become bullets, and other lines are paragraphs:

```markdown
## 0.2.0

The second content patch.

### Mage
- Frost Nova now affects 1 additional target.

### Fixes
- The mailbox no longer sparkles after the mail is read.
```

`-Version 0.x.y -Repository <owner>/<test-repo>` builds a test release for a test repository without touching `VERSION`.

A published release (not a test release) also posts its patch notes to the Discord's `#announcements` through a webhook. The webhook URL is read from the `HOA_DISCORD_WEBHOOK` environment variable or from `%LOCALAPPDATA%\HordesOfAzeroth\discord-webhook.txt`. It is a secret and never goes in the repository; without it, the release skips the post.

Nothing from the game may go into a release or into this repository: no client files, extracted data, renders of game art or patched executables. Anything derived from the client is built on the player's PC by the launcher.

<br>

---

## Code style

- No comments in code, in any language. Clear names and small functions instead; design notes go in commit messages.
- Upstream VMaNGOS comments in `server/core` stay as they are, so merges stay clean.
- Server code follows the surrounding VMaNGOS style; Lua follows the existing addon files.
