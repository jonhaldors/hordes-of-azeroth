# launcher

Imported from the main repository's `tools/launcher` (`3ca658b`, 2026-11-04); license GPL-3.0. The source currently lives in `launcher/`. See [`UPSTREAM.md`](../../../launcher/UPSTREAM.md).

Avalonia C# launcher.

## Refactor points

- Language selection is part of the launcher/client settings and is decoupled from the client install language; the value reaches the game through the account/config, not by changing client data.
- No longer requires an English 1.12.1 install: accept any language's 1.12.1 build 5875 (file version), with the English MD5 as a fast path only. The upstream PR #25 experiment validated this.
- Clear/expire client caches by `(locale, content version)` before launch (keep and upgrade the current `*.bin` cleanup).
- Keep the server, database and realmlist start/stop logic.
- Co-op is direct only: the host shows its LAN/VPN address as `ip:port`, and a guest joins by entering that address (plus the host's optional password). There is no public lobby, room registration or central notification service; NAT traversal is the player's responsibility (port forwarding, ZeroTier/Tailscale, etc.).
- Launcher text uses i18n resources and follows the language setting.

## Build

See [BUILDING.md](../../../BUILDING.md). `dotnet build` passes; publishing and packaging are still to be documented.

## To change

- Make language selection account-level; expire caches by `(locale, contentVersion)` before launch.
- Keep `config/release.json` in sync with the fork's GitHub and Gitee repositories.

## Update sources

`config/release.json` names the GitHub repository, its Gitee mirror (`giteeRepository`) and the
third-party downloads. The launcher reads `manifest.json` / `manifest-linux.json` from
`https://github.com/<repository>/releases/latest/download/`; in China (or after GitHub fails) it
uses `https://gitee.com/<giteeRepository>/releases/download/<tag>/<asset>` instead, resolving the
latest tag through Gitee's API (`/releases/latest`). Package zips keep the same tag and file name
on both hosts, so `tools/publish-gitee.ps1 -Version x.y.z` mirrors a published release: it creates
or reuses the `packages-vX` and `vX` releases and uploads `release/<version>/assets` (set
`HOA_GITEE_TOKEN` to a token with repo write access; it also points the Gitee default branch at
`main`). MariaDB lists Tsinghua, Aliyun and USTC
mirrors under `thirdParty[].mirrors`; the launcher tries them first in China and after failures
elsewhere. A private R2 mirror (`HOA_MIRROR_URL`) remains optional.

## Direct co-op

`CoopAgent` no longer contacts a lobby service. The host listens on the gate port (3725 by
default) and answers `HOA1 ASK`, `HOA1 POLL` and `HOA1 CANCEL` on that port; the guest enters the
host's `ip:port` in the Glue co-op screen. The host checks version and protocol before showing the
request, and the existing token gate still carries `LOGIN`, `WORLD`, `UPLOAD`, `LEDGER`, `ANSWERS`
and `LEAVE`. The host advertises every usable LAN address, with VPN/proxy addresses after the LAN
ones, and can show a manually entered public address instead.
