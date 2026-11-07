# Imported code and provenance

Version 0.1.0 of this repository was not written from scratch. Its first code is a set of upstream snapshots, imported with their licenses and copyright notices. Later changes happen in the new history and are not merged from upstream automatically.

The machine-readable record is [`provenance.yaml`](../../provenance.yaml) at the repository root; every imported directory also contains an `UPSTREAM.md`.

| Path | Open-source repository | Imported branch/commit | License |
| --- | --- | --- | --- |
| `server/` | https://github.com/jonhaldors/hordes-of-azeroth-server | `zhcn-063` / `930628c2c05f44af067a138b93e8726955f3b8a6` (upstream `vanilla-bonk` base `b41bf911790061dc539bc62140b256a69d44edc7`) | GPL-3.0 distribution (source GPL-2.0-or-later) |
| `client/` | https://github.com/jonhaldors/hordes-of-azeroth-client | `zhcn-063` / `74a4e4eb8ef5030fcde1657531217d3f3f4b384f` (upstream `main` base `1f23d0eaf02afe8831e9229bff027a93d387f5eb`) | MIT or Apache-2.0 |
| `addon/HordesOfAzeroth/` | https://github.com/jonhaldors/hordes-of-azeroth | `zhcn-063` / `3ca658b525bd67bf0302fa30c80829305295f3c5` (`Interface/AddOns/HordesOfAzeroth`) | GPL-3.0 |
| `glue/` | https://github.com/jonhaldors/hordes-of-azeroth | same commit (`Interface/GlueXML`) | GPL-3.0 |
| `launcher/` | https://github.com/jonhaldors/hordes-of-azeroth | same commit (`tools/launcher`) | GPL-3.0 |
| `tools/` (except launcher) | https://github.com/jonhaldors/hordes-of-azeroth | same commit (`tools/`, excluding `tools/launcher` and `tools/lobby-server`) | GPL-3.0 |
| `config/` | https://github.com/jonhaldors/hordes-of-azeroth | same commit (`config/`) | GPL-3.0 |
| `localization/` | https://github.com/jonhaldors/hordes-of-azeroth | same commit (`localization/`) | GPL-3.0 |

Imported on 2026-11-04. The actual code came from our forks:
[`xenoglossy-asyncio/hordes-of-azeroth-server`](https://github.com/xenoglossy-asyncio/hordes-of-azeroth-server),
[`xenoglossy-asyncio/hordes-of-azeroth-client`](https://github.com/xenoglossy-asyncio/hordes-of-azeroth-client),
[`xenoglossy-asyncio/hordes-of-azeroth`](https://github.com/xenoglossy-asyncio/hordes-of-azeroth).

## Not imported

- `tools/lobby-server/`: the new co-op model is LAN and `ip/domain:port` direct only; no public lobby/registration service.
- `Interface/AddOns/BonkAuras/`: a separate WA-style addon, not part of the HoA core; it stays in its own repository.
- Build artifacts (`target/`, `build/`, `bin/`, `obj/`), databases, server run directories, logs, screenshots and test configuration.
- Submodule git history: the new repository starts a fresh history at 0.1.0; use the source repositories above to trace old changes.

## Version

- Upstream 0.6.3 → this repository **0.1.0**, marking the start of the architecture rewrite, not a feature reduction.
- `VERSION` lives at the repository root; components no longer keep separate versions and packaging derives from it.

## Licenses

Each imported directory keeps its original license files:

- `server/LICENSE` (GPL-3.0)
- `client/LICENSE-MIT`, `client/LICENSE-APACHE`
- Root `LICENSE` and `THIRD-PARTY-NOTICES.md` cover the addon/glue/launcher/tools parts from the main repository
- New `shared/`, `scripts/`, `docs/` and new parts of `tools/` use GPL-3.0

See [LICENSE-NOTICE.md](../../LICENSE-NOTICE.md).
