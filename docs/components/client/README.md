# client

Imported from the `hordes-of-azeroth-client` `zhcn-063` snapshot (`74a4e4e`, 2026-11-04); license MIT / Apache-2.0. This is the refactor starting point, not the final structure. See [`UPSTREAM.md`](../../../client/UPSTREAM.md) and [`provenance.yaml`](../../../provenance.yaml).

benilla: a from-scratch 1.12.1 client written in Rust + Bevy.

**Status: imported.** `LICENSE-MIT`, `LICENSE-APACHE` and the `third_party/` copyright notices are kept.

## Planned changes

- **Content overlay:** custom spells/auras/items are absent from the installed DBCs. The server pushes the localized aura catalog over the typed protocol at addon-ready and language changes; the client installs it through `SpellCatalog::set_overlay` (`hoa_aura.rs`) and overrides DBC lookups at runtime. The wider generated content pack remains future work.
- **Language packs:** HoA's own UI text (Options, GameMenu, ScriptLog, Realmlist, KeyBindings, GlueXML) comes from `client/crates/benilla-app/assets/i18n/<locale>.json`, generated from `shared/i18n/ui`. Before login the launcher/last `hoaLanguage` selects the pack; after login the server's account language overrides it and one `ReloadUI` applies it. `GetLocale` follows the pack while the install locale still selects DBC columns and name charsets. Stock FrameXML/GlobalStrings text remains install-language for now.
- **Cache keys:** WDB/template caches are keyed by `(locale, content version)` and expire when either changes, so switching language no longer leaves old names behind. The account language is folded into the WDB header tag now; the content version comes with the content pack.
- **Native capabilities:** buffs, levels, casting and cooldowns use the client's existing systems; HoA state no longer travels through custom chat lines.
- **Kernel kept:** networking, movement, combat, rendering and the Lua/FrameXML engine stay benilla's; only HoA integration points and hot spots change.

## Data sources

The client still needs the user's own 1.12.1 install for models, textures, audio and base DBC data. HoA-authored UI text no longer depends on the install language; stock UI text and DBC names still do, until the later GlobalStrings/content-name slices. Missing resources or custom entries come from the content pack (see [Content and data](../../content-data/README.md)).

## Build

See [BUILDING.md](../../../BUILDING.md). The workspace manifests pass; a full `cargo build` is still pending.
