# Licensing and repository layout

This page records the license audit and the monorepo layout. It is engineering documentation, not
legal advice; a final distribution should be reviewed by counsel.

## What is actually in the tree

| Path | License | Notes |
| --- | --- | --- |
| `server/` | GPL-3.0 distribution | VMaNGOS fork; `server/LICENSE` is GPL-3.0. The source headers are GPL-2.0-or-later, so the server can be distributed under GPL-3.0. The Windows database client is MariaDB Connector/C 3.4.10 (LGPL-2.1-or-later, dynamic link, Schannel) and crypto is OpenSSL 3.5.9 LTS (Apache-2.0, `libcrypto` plus the `legacy` provider). The old GPL-2.0-only MySQL client and OpenSSL 1.0.2 bundles are gone. gSOAP and libmpq are GPL-2.0-or-later; recastnavigation is zlib; cpptrace is MIT; utf8cpp is Boost; G3D is Modified BSD; zlib and bzip2 are permissive. |
| `client/` | MIT OR Apache-2.0 | benilla fork; every workspace crate declares `MIT OR Apache-2.0`. Cargo dependencies are MIT, Apache-2.0, MPL-2.0, zlib, BSD and similar (the generated `CLIENT-LICENSES.md` lists them per release). MIT/Apache-2.0 are compatible with the GPL-3.0 distribution. |
| `addon/`, `glue/`, `launcher/`, `config/`, `localization/` | GPL-3.0 | Hordes of Azeroth derivatives. The launcher's Avalonia and Mono.Nat packages are MIT. |
| `shared/`, `scripts/`, `docs/`, `tools/` | GPL-3.0 | This repository's own code and data. |
| Addon fonts | OFL-1.1 | Barlow, Noto Sans SC, Noto Sans TC; license files beside the fonts. |
| MariaDB Server | GPL-2.0 (version 2 only) | Downloaded and run by the launcher as a separate program; not linked into our binaries. |

## Compatibility

- GPL-3.0 combines fine with MIT, Apache-2.0, BSD, zlib, Boost, OFL and LGPL-2.1-or-later.
- The server is no longer constrained by a GPL-2.0-only client library or GPL-incompatible OpenSSL:
  MariaDB Connector/C is LGPL-2.1-or-later and dynamically linked, and OpenSSL 3 is Apache-2.0.
- MariaDB Server remains GPL-2.0-only, but GPLv2 and GPLv3 programs can be **aggregated** on one
  medium as separate programs. The launcher downloads and runs MariaDB Server; the game server
  links MariaDB Connector/C, not the server.
- MIT cannot be the license of our combined work: the addon, Glue, launcher and server are GPL-3.0
  derivatives. The client keeps MIT/Apache-2.0 for clarity while remaining compatible.
- The old GPL-2.0-only MySQL headers and OpenSSL 1.0.2 files were removed from the tree, not
  relicensed.

**Decision (2026-11-06):** the repository's original code, `shared/` and the server distribution
are **GPL-3.0**; the client stays **MIT OR Apache-2.0**; the addon, Glue, launcher, config and
localization are **GPL-3.0**. The Windows server ships MariaDB Connector/C under
**LGPL-2.1-or-later** and OpenSSL 3 under **Apache-2.0**. MariaDB Server is downloaded separately
under its own GPL-2.0-only license.

**The repository stays a monorepo and does not use submodules.** A license is satisfied by
keeping its text and copyright notices, naming the source and the local modifications, and
providing the corresponding source; Git structure is not a license requirement. Submodules are
only an optional upstream-tracking tool and would make contributions, atomic cross-directory
changes, CI and Gitee mirroring harder. Each imported directory keeps its `LICENSE` and
`UPSTREAM.md`; `LICENSE-NOTICE.md` and `provenance.yaml` record the rest, and a release tag is the
corresponding source.

## Layout

```
hoa-core                     GPL-3.0 (top-level LICENSE)
  LICENSES/                  GPL-3.0, GPL-2.0, LGPL-2.1, MIT, Apache-2.0, OFL-1.1 texts
  shared/                    GPL-3.0 (content, i18n, protocol)
  server/                    GPL-3.0 + LICENSE + UPSTREAM.md
  client/                    MIT OR Apache-2.0 + LICENSE-MIT/LICENSE-APACHE + UPSTREAM.md
  addon/ glue/ launcher/     GPL-3.0 + UPSTREAM.md
  config/ localization/      GPL-3.0 + UPSTREAM.md
  tools/ docs/ scripts/      GPL-3.0 original code (imported tools keep their notices)
```

If upstream tracking ever becomes painful, `server/` and `client/` can become submodules of their
own fork repositories; that is a maintenance choice, not a licensing one. In that case use relative
URLs (`../hoa-server.git`) so GitHub and Gitee clones resolve on the same host, mirror the fork
repositories, and update the release tooling first: `git archive` does not include submodule
content.

## Steps

1. Keep the top-level `LICENSE` (GPL-3.0) and the per-directory licenses; the decision above is
   recorded here and in `LICENSE-NOTICE.md`.
2. Keep a `LICENSE`/`LICENSE-MIT`/`LICENSE-APACHE` and an `UPSTREAM.md` in every imported
   directory, with the upstream URL, commit, base and local changes.
3. Keep `LICENSES/` with the full texts and `THIRD-PARTY-NOTICES.md` for dependencies. The Windows
   bundle's versions, sources and hashes are in `server/dep/windows/README.md`.
4. Keep the server's Windows dependencies GPL-3.0-compatible: MariaDB Connector/C
   (LGPL-2.1-or-later) and OpenSSL 3 (Apache-2.0). Do not reintroduce the GPL-2.0-only MySQL client
   or OpenSSL 1.0.2.
5. Do not relicense a GPL-2.0-only part as GPL-3.0 or MIT. If submodules are introduced later,
   update CI (`submodules: recursive`) and release packaging in the same change.
