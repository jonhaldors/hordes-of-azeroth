# Documentation index

## Decisions

| Decision | Choice |
| --- | --- |
| Repository shape | One monorepo with server, client, addon, launcher, GlueXML and shared content |
| Hosting | Private GitHub repository `hoa-core`, hard fork |
| Version line | Starts at **0.1.0**; does not continue upstream 0.6.x |
| Upstream relationship | Independent evolution; upstream is only a starting point and reference |
| Kernels | Keep VMaNGOS and benilla; refactor only the HoA layer and proven hot spots |
| Language | Account/session property; first release **enUS + zhCN + zhTW** |
| Effects | One effect = one real server aura; the addon only reads it |
| Content | Single source in `shared/content`; tools generate each artifact |
| Co-op | LAN and `ip/domain:port` direct connections only; no public lobby or registration server |
| First step | Phase 0 docs/skeleton and phase 1 code import are complete; phase 2 i18n is in progress |
| Merge gate | CI runs six checks; branch protection is deferred (private repo without GitHub Pro), enable it with `scripts/protect-main.sh` once the repository is public |

## Documentation convention

Every document directory provides both an English `README.md` and a Chinese `README_zh.md`. Keep the two in sync; a change to one must change the other.

## Reading order

1. [Imported code and provenance](imported-code/README.md)
2. [Architecture](architecture/README.md)
3. [i18n](i18n/README.md)
4. [Auras and effects](auras/README.md)
5. [Client-native capabilities](native-capabilities/README.md)
6. [Content and data](content-data/README.md)
7. [Protocol](protocol/README.md)
8. [Migration plan](migration-plan/README.md)

## Components

- [server](components/server/README.md)
- [client](components/client/README.md)
- [addon](components/addon/README.md)
- [launcher](components/launcher/README.md)

## Open questions

- zhTW terminology source: prefer official 1.12.1 Traditional Chinese names; fall back to zhCN converted and manually reviewed.
- Whether to keep the upstream update/packaging scripts or start a new release pipeline.
