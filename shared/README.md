# shared / shared layer

Data and protocol shared by the server, client, addon and launcher. This is the **single source**: no component keeps another copy.

```
shared/
  content/    game content definitions (items, spells, auras, maps, talents, cards, quests, ...)
  i18n/       message catalogue, language packs, placeholder rules
  protocol/   server↔client message definitions and codegen inputs
```

## Rules

1. Content is written only in `shared/content`; `tools/content-compiler` generates server SQL, the client binary pack and addon Lua tables.
2. User-visible text is written only in `shared/i18n` (text inside content entries is defined with the entry and referenced by message ID); never hardcode English or Chinese in C++/Rust/Lua.
3. Protocol messages are defined only in `shared/protocol`; generate C++ and Rust code from them. Never hand-write a parser on each side.
4. Every generated artifact carries a content version hash; the client, addon, co-op host and server verify it during the handshake.
5. Never hand-edit generated artifacts; CI regenerates and checks the diff.
