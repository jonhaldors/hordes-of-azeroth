# Run the game locally and test it end to end

Use this when asked to run the game, reproduce a bug, verify a fix, or drive `.bonk` commands against a real server. Everything here runs on one Windows machine; the 1.12 install and the test server live under `C:\World of Warcraft`.

## 1. Start the servers (once per machine session)

MariaDB must be running (it usually is; check the service). Then realmd and mangosd — **mangosd reads stdin, so EOF quits it**: keep a pipe open.

```powershell
cd 'C:\World of Warcraft\server\run'
$env:WOW_DATA = 'C:\World of Warcraft\Data'   # only the client needs this
```

```bash
# from Git Bash, one line each, in the background:
cd "/c/World of Warcraft/server/run" && tail -f /dev/null | ./realmd.exe &
cd "/c/World of Warcraft/server/run" && tail -f /dev/null | ./mangosd.exe &
```

Wait for `World initialized.` in the mangosd output, then check ports 3724 (realmd) and 8085 (world). Server logs land in `C:\World of Warcraft\server\logs\`: `Server.log`, `LevelUp.log` (the run ledger — every run's build, kills, gear, cards), `Chat.log`, `DBErrors.log`.

## 2. Run the client

Repo build: `cargo build --manifest-path client/Cargo.toml -p hoa` (debug is fine; it has the probe features). The player build is `--profile ship --no-default-features` and has **no probes**.

First run needs two gitignored files (never commit or echo them):

- `client/.probe-identity` — `WOW_USER=` / `WOW_PASS=` / `WOW_CHAR=` of the test account (from `C:\World of Warcraft\HordesOfAzeroth\accounts.ini`; the account is PLAYER4, character Xenossy).
- `client/benilla-config/AddOns/HordesOfAzeroth` — a copy of `addon/HordesOfAzeroth`, refreshed after every addon edit.

The account's GM level comes from the **realmd `account_access` table** (`id, gmLevel, RealmID`), not `account.gmlevel` — set `gmLevel=3, RealmID=1` for the GM-only `.bonk` subcommands.

## 3. The end-to-end probe: type .bonk commands, read both logs

```powershell
tools\e2e\bonk-probe.ps1 -Commands '.bonk hello enUS','.bonk start 1','.bonk god','.bonk card 21' `
    -LuaFile tools\e2e\suite-listen.lua
```

It logs the test account in, types each line into the chat box in world, runs a Lua listener in the live UI VM, exits, then prints the client's `probe-log:`/error lines plus the server's Chat/Server/DBErrors **deltas for just this run**. `-CommandsFile tools\e2e\bonk-commands.txt` runs the whole suite.

**`.bonk hello enUS` must come first**: it is the addon-ready handshake, and without it the server silently skips every window it could send. The addon's own enter-world hello races the login and often arrives too early, so always say it yourself.

Listeners in `tools/e2e/`:
- `mog-listen.lua` — counts `HOA_MOG_*` events and reports whether the transmog window is shown.
- `suite-listen.lua` — counts a broad set of `HOA_*` events, logs every chat reply the server sends, and snapshots every 20 s.

Debugging a "the window never opens" report: count the `HOA_*` events. Zero events with the server having sent the packets means the event name was fired without `add_in_game_event`-ing it (the client's `plugin.rs` regression test `every_fired_event_is_registered` guards this class). Zero events with no packets sent means the server skipped it — check `IsAddonReady` and the command's guard.

## 4. Cheats that matter for testing

- `.bonk god` — damage stops at 1 health (survive any run while probing).
- `.bonk card <id>` / `.bonk gear testfound <tier> <lines>` — grant content during a run.
- `.bonk mastery <xp>` — mastery XP → talent points (then `.bonk learn <node>`).
- `.bonk stop` — end the run.

## 5. Rebuilding after a change

- Server: `cmake --build server/build --config Release --parallel 8`, then copy `server/bin/Release/mangosd.exe` over the running one (stop it first — the exe is locked) and restart with the pipe trick.
- Client: `cargo build -p hoa` in `client/`.
- Content tables (`shared/content/**/*.yaml`): `python tools/content/compile.py` regenerates `server/sql/content/*.sql` and `shared/content/content.hash`; the hash is part of the client/server handshake, so also run `python tools/protocol/gen.py` and rebuild both sides. Apply the SQL with `python tools/content/apply.py --maria <mariadb.exe> --user <u> --password <p> --database mangos` (the connection is in `server/run/mangosd.conf`, `WorldDatabase.Info`).
