# Building

## Dependencies

| Component | Requirements |
| --- | --- |
| `server/` | CMake 3.20+, Visual Studio 2022 Build Tools (MSVC x64) or GCC/Clang, Boost/OpenSSL 3/MariaDB Connector/C (the Windows x64 client and OpenSSL libraries are bundled) |
| `client/` | Rust stable (see `client/rust-toolchain.toml`), Cargo |
| `launcher/` | .NET SDK 10 |
| `addon/`, `glue/` | LuaJIT (syntax check) |

## Commands

Windows (PowerShell):

```powershell
pwsh scripts/build.ps1 -Component server     # configure CMake and build mangosd
pwsh scripts/build.ps1 -Component client     # cargo build --release -p hoa
pwsh scripts/build.ps1 -Component launcher   # dotnet build
pwsh scripts/build.ps1 -Component addon      # LuaJIT syntax check
pwsh scripts/build.ps1 -Component i18n       # validate and check generated i18n catalogue
pwsh scripts/build.ps1 -Component content    # compile content and check the generated SQL
pwsh scripts/build.ps1 -Component check      # client manifests + addon syntax + i18n
pwsh scripts/build.ps1 -Component all
```

Linux/macOS:

```bash
scripts/build.sh server
scripts/build.sh client
scripts/build.sh launcher
scripts/build.sh addon
scripts/build.sh i18n
scripts/build.sh content
scripts/build.sh check
scripts/build.sh all
```

## Status (0.1.0)

- `server/`: CMake configure and Release `mangosd` build pass.
- `launcher/`: `dotnet build` passes (the imported `..\telegraphs` reference was fixed to `..\tools\telegraphs`).
- `addon/` + `glue/`: 70 Lua files pass the syntax check.
- `client/`: full `cargo build -p benilla-app` passes.

## CI

`.github/workflows/ci.yml` runs `docs-check`, `i18n-check`, `content-check`, `addon-lua`, `launcher-build`, `client-check` and `server-build` on every pull request and push to `main`. These seven checks are the merge gate. Branch protection is not yet enforced: GitHub requires GitHub Pro for branch protection on a private repository, and this repository is on the free plan. Run `scripts/protect-main.sh` after upgrading or making the repository public.

## Applying content

The world database must be refreshed after a content change:

```powershell
python tools/content/compile.py
python tools/content/apply.py --maria <mariadb client> --database <world db>
```

`apply.py` also takes `--host`, `--port`, `--user` and `--password` (default `127.0.0.1:3306`, `root`/`root`). The server logs `HoA content hash ...` at startup and logs an error when the database hash does not match the build.

## Server build details

```powershell
cmake -S server -B server/build -G "Visual Studio 17 2022" -A x64 `
  -DSUPPORTED_CLIENT_BUILD=CLIENT_BUILD_1_12_1 `
  -DBUILD_EXTRACTORS=OFF -DENABLE_MAILSENDER=OFF
cmake --build server/build --config Release --target mangosd -- /m
```

Artifacts land in `server/bin/Release/`. Build directories and artifacts are ignored by `.gitignore`.
