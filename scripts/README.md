# scripts / development scripts

Provided:

- `build.ps1` / `build.sh`: build by component (server/client/launcher/addon/i18n/check/all). See [BUILDING.md](../BUILDING.md).
- `protect-main.sh`: configure the six required checks on `main`; GitHub requires Pro or a public repository for this.

Planned:

- `dev.ps1` / `dev.sh`: start local MariaDB, realmd, the world server and the client in an isolated profile.
- `content.ps1` / `content.sh`: regenerate content, text and protocol, then run checks.
- `test.ps1` / `test.sh`: unit tests + headless integration tests (login, language switch, aura display).
- `release.ps1` / `release.sh`: package the server, client, addon and launcher.

Scripts only orchestrate; they do not hide business logic. CI calls the same scripts.
