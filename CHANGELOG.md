## 0.7.0

- The repository is now a monorepo: the server (VMaNGOS), the client (benilla), the addon, the Glue screens, the launcher, shared content and the build tooling all live here, replacing the `server/core` and `client` submodules.
- Single content source: every tuning number — weapons, masteries, passives, cards, auras, maps — lives in `shared/content/**/*.yaml`, compiled into SQL and embedded in both the server and the client with a content hash that keeps the two sides in sync.
- Typed protocol: the server and the client speak 171 versioned messages (`SMSG_HOA_MESSAGE`) generated from `shared/protocol/messages.yaml`, replacing the `BONK~` chat lines. A handshake blocks every message when the protocol or content hash disagrees.
- Localization: an i18n catalogue with stable message IDs covers the server, client, addon, Glue and launcher in English and Simplified Chinese; the account language drives `GetLocale` and loads stock GlobalStrings/DBC names from an installed language pack.
- Native auras: buff names, icons and descriptions come from a server-pushed catalog with live-value text (`Haste increased by 60%.`), not string parsing.
- Tooling: `.claude/skills/` for local testing, the module map and class-balance tuning; `tools/e2e/bonk-probe.ps1` drives a live client against the local server with `.bonk` commands and reads both sides' logs.

## 0.1.3

#### Hotfix 4

- Transmog: the transmogrifier window now opens — from the NPC, the interact key and `.bonk mog open`. The client fired the window's `HOA_MOG_*` events without ever registering them, and an unregistered event is a silent no-op for both `fire_event` and the addon's `RegisterEvent`, so the window could not open from any path since the first hoa-core build. The hardcore fallen/remembered events had the same defect and are fixed with it.
- Addon: the mail tooltip no longer errors on open (`InboxItemLink` became a method in the module split but two call sites still passed the old global); the offer window's skip/reroll/banish buttons work again (nil handlers after the actions moved onto the Offer module); fortune shops send their own payload instead of the class shop's.
- Tooling: `tools/e2e/bonk-probe.ps1` drives a live client against the local server with `.bonk` commands and reads both sides' logs — the probe that found the transmog defect — and a client test now fails when an event is fired without being registered.

- Licensing: the server is now distributed under GPL-3.0. The GPL-2.0-only Windows MySQL client was replaced by MariaDB Connector/C 3.4.10 (LGPL-2.1-or-later), and OpenSSL 1.0.2 by OpenSSL 3.5.9 LTS (Apache-2.0, including the legacy provider). The old `libmySQL`/`libeay32` files were removed; MariaDB Server remains a separate GPL-2.0 download.
- Addon: phase D object refactor completed. The scoreboard, codex, meter, quartermaster, vault, transmog and controller panel/HUD now use `UI.Module` controllers; offer cards own their layout and keyword methods through `OfferCard`; the core combat-log, shield and gossip state moved into controllers.
- Full release now includes generated navmesh/mmap pathfinding tiles for every run map, so players no longer build them on their CPU at first launch.

## 0.1.2

- Package and navmesh entries in the manifest now list a Gitee mirror next to their GitHub URL; the launcher prefers the mirror in China and falls back to the other host on failure.
- Linux builds run in Docker (`ubuntu:22.04`) when WSL 22.04 is not installed, so this release ships the Linux client, server and extractors again.
- `tools/release.ps1` builds from the monorepo layout and tolerates a regenerated `config/navtiles.json` whose content did not change.

## 0.1.1

- Simplified Chinese and Traditional Chinese across the client, addon, launcher and server text; the account language drives `GetLocale`, and stock GlobalStrings and DBC names load from an installed language pack.
- Protocol v31 with Hardcore mode (fallen and remembered runs), several characters per class, transmogrification and outfits, and Regular and Hardcore leaderboards.
- Direct co-op: hosts share an `ip:port`; the public lobby and punch-through are gone.
- Content manifest with per-section hashes and server-side integrity checks for leaderboard runs.
- Addon: shared `UI.Hover`, `UI.IconRow`, `UI.IconButton` and `UI.Listen` helpers, named event modules in `UI.modules`, and far less duplicated tooltip and event wiring.
- Launcher: Gitee release mirror for China, domestic MariaDB mirrors (TUNA, Aliyun, USTC), download resume and database start retries.
- CI: client tests link with lld so private-repo runners stop dying mid-link.
