# CI

`.github/workflows/ci.yml` runs on every pull request and push to `main`:

| Job | What it does |
| --- | --- |
| `docs-check` | Checks English/Chinese README pairs, relative links and `provenance.yaml`/`UPSTREAM.md` records |
| `i18n-check` | Validates the shared message catalogue and its generated output |
| `content-check` | Regenerates the content SQL and typed protocol, and checks they match the sources |
| `addon-lua` | Parses every addon and GlueXML Lua file with LuaJIT |
| `launcher-build` | `dotnet build` for the Avalonia launcher |
| `client-check` | `cargo check -p hoa` for the client workspace |
| `server-build` | CMake configure + `mangosd` build on Ubuntu 24.04 |

These seven checks are the merge gate. Branch protection is **not yet enforced**: GitHub requires GitHub Pro for branch protection/rulesets on a private repository, and this repository is on the free plan. After upgrading or making the repository public, run `scripts/protect-main.sh` to require the seven contexts on `main`.

Locally, run the same checks with `scripts/build.ps1`/`build.sh` (addon, launcher, client, server, i18n, content), `python scripts/check-docs.py` and `python tools/i18n/check.py`.
