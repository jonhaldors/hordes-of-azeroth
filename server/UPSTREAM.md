# Upstream

Tracked-file snapshot imported by hoa-core 0.1.0 on 2026-11-04.

- Upstream: https://github.com/jonhaldors/hordes-of-azeroth-server
- Upstream branch/base: `vanilla-bonk`, `b41bf911790061dc539bc62140b256a69d44edc7`
- Imported from: https://github.com/xenoglossy-asyncio/hordes-of-azeroth-server, branch `zhcn-063`
- Commit: `930628c2c05f44af067a138b93e8726955f3b8a6`
- License: GPL-3.0 (see `LICENSE`). The VMaNGOS source headers are GPL-2.0-or-later, so the server
  can be distributed under GPL-3.0. The Windows dependencies are MariaDB Connector/C 3.4.10
  (LGPL-2.1-or-later) and OpenSSL 3.5.9 LTS (Apache-2.0); the old GPL-2.0-only MySQL client and
  OpenSSL 1.0.2 are gone. See [`docs/licensing`](../docs/licensing/README.md).
- Git history was not imported; see `../provenance.yaml`.
- Local changes: the HoA/Bonk run, Hardcore, leaderboard and transmog systems, the typed protocol,
  content tables and migrations, and the build/runtime configuration in this monorepo.
