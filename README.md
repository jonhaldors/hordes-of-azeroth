# Hordes of Azeroth Core

A monorepo refactor of Hordes of Azeroth: server, client, addon, launcher and shared content in one repository.

- Upstream projects: [jonhaldors/hordes-of-azeroth](https://github.com/jonhaldors/hordes-of-azeroth) (GPL-3.0),
  [hordes-of-azeroth-server](https://github.com/jonhaldors/hordes-of-azeroth-server) (VMaNGOS, GPL-2.0-or-later),
  [hordes-of-azeroth-client](https://github.com/jonhaldors/hordes-of-azeroth-client) (benilla, MIT / Apache-2.0).
- This repository is a **hard fork**. It evolves on its own architecture and no longer tracks upstream; upstream code is only a starting point and content source.
- Version line starts at **0.1.0**.
- Languages: **enUS + zhCN + zhTW**.
- Co-op supports only **LAN** and direct `ip/domain:port` connections. There is no public lobby or registration server.
- Status: **phase 1 complete, phase 2 in progress**. 0.1.0 starts from the 0.6.3 code snapshots and will be refactored according to `docs/`.

## Goals

1. **Language is an account setting, not a property of the client install.** Any 1.12.1 client data language can run; the server and language packs decide the displayed text.
2. **Every HoA effect is a real server aura.** The native buff frame, `UnitBuff`, the addon and combat logs see the same state; the addon no longer keeps its own buff timers.
3. **Content has a single source.** Items, spells, auras, talents, cards, maps and text are defined in `shared/content`; tools generate server SQL, client data and addon Lua.
4. **Keep the kernels that work; refactor the layers that do not.** Keep the VMaNGOS server and benilla client cores (network, movement, combat, rendering) and rewrite the HoA game layer, i18n, auras and data model. Handle proven performance hot spots separately.

## Layout

```
hoa-core/
  VERSION             0.1.3
  docs/               Architecture and design (every document exists as README.md / README_zh.md)
  server/             VMaNGOS C++ server (GPL-3.0 distribution; source GPL-2.0-or-later)
  client/             benilla Rust client (MIT / Apache-2.0)
  addon/              Lua addon (GPL-3.0)
  glue/               Login/character-select GlueXML (GPL-3.0)
  launcher/           Avalonia C# launcher; LAN/direct co-op (GPL-3.0)
  config/             Server and launcher default configuration (GPL-3.0)
  localization/       Existing translation data and tooling (transitional reference, GPL-3.0)
  shared/
    content/          Content source: items, spells, auras, maps, text, ...
    i18n/             Message catalogue and language packs
    protocol/         Server/client message schema and code generation
  tools/              Content compiler, protocol generator, translation and test tools
  scripts/            Development and build scripts
  .github/workflows/  CI
```

## Documentation

- [Build instructions](BUILDING.md)
- [Documentation index and decisions](docs/README.md)
- [Imported code and provenance](docs/imported-code/README.md)
- [Architecture](docs/architecture/README.md)
- [i18n](docs/i18n/README.md)
- [Auras and effects](docs/auras/README.md)
- [Client-native capabilities](docs/native-capabilities/README.md)
- [Content and data](docs/content-data/README.md)
- [Protocol](docs/protocol/README.md)
- [Migration plan](docs/migration-plan/README.md)

## License

The repository aggregates code from several projects; the repository's own code and the server distribution are GPL-3.0, and imported parts keep their compatible licenses:

| Path | License | Source |
| --- | --- | --- |
| `server/` | GPL-3.0; source headers are GPL-2.0-or-later; Windows deps are MariaDB Connector/C (LGPL-2.1-or-later) and OpenSSL 3 (Apache-2.0) | VMaNGOS / hordes-of-azeroth-server |
| `client/` | MIT or Apache-2.0 | benilla / hordes-of-azeroth-client |
| `addon/`, `glue/`, `launcher/`, `config/`, `localization/` | GPL-3.0 | hordes-of-azeroth |
| `shared/`, `scripts/`, `docs/`, `tools/` | GPL-3.0 | this repository |

The repository stays a monorepo: per-directory `LICENSE` and `UPSTREAM.md` files plus
`LICENSE-NOTICE.md` are authoritative, and a release tag is the corresponding source. Submodules
are not required by the licenses and are not used.

See [LICENSE-NOTICE.md](LICENSE-NOTICE.md) and the license audit plus monorepo/submodule plan in [docs/licensing](docs/licensing/README.md). World of Warcraft is a trademark of Blizzard Entertainment, Inc.; this project does not ship any game assets.
