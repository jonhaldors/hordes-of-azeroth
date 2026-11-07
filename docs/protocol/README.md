# Protocol

## 0. Current state

- HoA UI data now travels over the typed channel; neither the server nor the addon uses the `BONK~` chat channel anymore.
- The Rust client receives presentation data over the typed channel; the old `HOA~` drawing parser has been removed.
- The client has no spell query path (`benilla-app/src/net.rs:1034-1058`), so custom spell metadata has nowhere to come from.
- State data (shield amount, dash, determination, card procs) used to depend on this string channel; field order was by convention and every change touched both sides. The state messages now use the typed channel below, and the server no longer sends `BONK~` lines.
- First typed slice (2026-11-04): opcode `SMSG_HOA_MESSAGE` (826) carries `hoa.hello` — protocol version, content hash and account language — after the addon's `.bonk hello`. `shared/protocol/messages.yaml` is the source; `tools/protocol/gen.py` generates `HoaProtocol.h` and `protocol_generated.rs`; the client compares version/hash; a mismatch fires `HOA_INCOMPATIBLE`, stops applying typed packets, and the addon shows an explicit error, while a match fires `HOA_HELLO` into Lua. `hoa.aura_value` (`spell_id`, `value`, `max_value`) replaces the shield chat text and fires `HOA_AURA_VALUE`. `hoa.dash` carries the max charges, recharge, cooldown, blink flag and available charges and fires `HOA_DASH`. `hoa.aura_percent` (`spell_id`, `percent`) covers determination, necrotic and wounds and fires `HOA_AURA_PERCENT`. `hoa.aura_text` and `hoa.aura_catalog_entry`/`aura_catalog_end` carry the localized aura display data. `hoa.run_state` carries the run timer, kills, gold, stage, boss/portal flags and meter strings, and fires `HOA_RUN_STATE` with a Lua table; the addon no longer parses the old `state~` line. `hoa.run_start` and `hoa.run_end` replace `start~`/`end~` and fire `HOA_RUN_START`/`HOA_RUN_END` tables. `hoa.run_paused`, `hoa.coop_no_pause`, `hoa.run_xp` and `hoa.wave_beat` cover pause state, co-op pause policy, experience and wave callouts. `hoa.run_support`, `hoa.run_glyph_meter`, `hoa.run_other_meter` and `hoa.run_party_meter` carry the high-frequency meter payloads as typed text fields. `hoa.objective`, `hoa.objective_clear` and `hoa.objective_ping` cover the tracked objective pins. `hoa.mob`, `hoa.mob_dead`, `hoa.mob_clear`, `hoa.ally`, `hoa.ally_done` and `hoa.affix_info` cover enemy/ally plates and the affix glossary; `mob_clear` has no fields. `hoa.offer_*` and `hoa.ley_*` cover the level/chest and ley choice panels, including no-field close events. `hoa.glyph_*` covers the glyph offer, taken list, info cards and Shadowmourne count. `hoa.quest_*`, `hoa.vendor_*` and `hoa.portal_*` cover quest logs/rewards, the vendor shelf and the home/endless confirmations. `hoa.found_*` and `hoa.gear_*` cover found-gear cards and the gear replacement offer. `hoa.vault_*` covers the vault shelf and sent-home list. `hoa.enchant_*` covers the enchanter slots, offers and open/close events. `hoa.cards` and `hoa.card_*` cover the held-card list, tips, cooldowns and live values. `hoa.mastery_state`, `hoa.wallet`, `hoa.notice`, `hoa.message`, `hoa.find`, `hoa.npc_name`, `hoa.shard`, `hoa.valor` and `hoa.epic_luck` cover the remaining player-status signals. `hoa.coop_*` and `hoa.leash` cover co-op wait/watch/down/ready and leash warnings. `hoa.starter*`, `hoa.reach_ring`, `hoa.druid_form`, `hoa.greed` and `hoa.hearth` cover the remaining small run signals. `hoa.capture`, `hoa.moonwell`, `hoa.ley_bless*` and `hoa.event_timer` cover shrine and event timers. `hoa.death_*`, `hoa.run_summary`, `hoa.summary_*` and `hoa.summary_end` cover the death recap and end-of-run breakdown. `hoa.board_*` covers the leaderboard open/header/row/page/choice flow; row text stays a formatted `line` for now. `hoa.shop_*` and `hoa.mastery_*` cover the shop, mastery trees, nodes, presets and close events. `hoa.gear`, `hoa.gear_end`, `hoa.trinket_tip` and `hoa.arena` cover gear stats, trinket tooltips and the arena panel. `hoa.tier`, `hoa.tier_info`, `hoa.level_*`, `hoa.map_info` and `hoa.zone_art` cover the difficulty/map selector. `hoa.codex` carries the remaining codex/glossary rows as a typed kind plus packed line. `hoa.weapon_info`, `hoa.weapon_evolution*`, `hoa.cooldown_pie`, `hoa.quartermaster*`, `hoa.music`, `hoa.loadout`, `hoa.druid_slots`, `hoa.boss_bar`, `hoa.titles`, `hoa.stats` and `hoa.keyword_timers` cover the last dynamic signals. `hoa.visual_*` carries telegraph marks, kits, flights, missiles, props and aura anchors as typed coordinates, replacing the old `HOA~` chat lines. Neither the server nor the addon uses the `BONK~` channel anymore.

## 1. Goals

- HoA data between server and client has an explicit schema and version; no more string assembly.
- State data (buffs, stacks, values) uses vanilla game state wherever possible; custom messages cover only display data vanilla cannot express.
- One schema generates both C++ and Rust code, avoiding parser drift.
- Content version, protocol version and language are negotiated during the handshake.

## 2. Layers

```
Vanilla 1.12.1 protocol (kept)
  ├─ login/character/movement/combat/items/auras/chat/...
  └─ native buffs, levels, casting, cooldowns are used directly

HoA protocol (new, versioned)
  ├─ handshake: account language, content hash, protocol version, capabilities
  ├─ content: manifest/incremental (client content-pack validation)
  ├─ run: start, waves, bosses, rewards, results
  └─ presentation: cards, codex, leaderboard, notices, telegraphs/flights/props (UI and client visuals)
```

## 3. Handshake

On world login the server sends:

```yaml
handshake:
  protocol_version: 1
  content_hash: "sha256:..."
  locale: "zhCN"          # account language
  capabilities: [auras, content_pack, i18n]
```

- The client loads the matching language/content pack. On a hash or protocol mismatch it fires `HOA_INCOMPATIBLE`, stops applying typed packets, and the addon shows an explicit error; direct hosts are expected to refuse different versions before the world is entered.
- Language change: the client sends `set_locale` (or reuses a vanilla command); the server updates the account language and refreshes cached names; the client reloads language packs and UI.

## 4. Message definitions

`shared/protocol/*.yaml`:

```yaml
- name: hoa.run.stage_started
  id: 0xA001
  direction: server_to_client
  fields:
    - { name: stage, type: u8 }
    - { name: difficulty, type: u8 }
    - { name: boss_entry, type: u32 }
```

```yaml
- name: hoa.aura.value
  id: 0xA010
  direction: server_to_client
  fields:
    - { name: unit_guid, type: u64 }
    - { name: spell_id, type: u32 }
    - { name: value, type: u32 }     # shield remaining and other values that do not fit aura fields
    - { name: max_value, type: u32 }
```

- IDs use a dedicated HoA range; they do not take vanilla opcodes.
- Field types are fixed (u8/u16/u32/u64/i32/f32/string/array); strings are UTF-8 with a length prefix.
- Every message is versioned; incompatible changes bump `protocol_version`.

## 5. Generation

`tools/protocol-gen` reads the schema and generates:

- C++: `server/src/game/Hoa/protocol/generated/` (serialization/deserialization and message ID constants)
- Rust: `client/crates/hoa-protocol/src/generated/`
- Lua: only message constants the addon needs (the client forwards data; the addon never parses binary)

Generated files are committed; CI checks the diff.

## 6. How the addon receives data

Current: the server sends presentation data as `BONK~type~...` chat lines and the addon parses strings; state uses the typed channel.

New design:

1. The Rust client handles HoA messages.
2. The client exposes a stable Lua API to the addon, for example:

```lua
Hoa.GetRunState()          -- run state
Hoa.GetAuraValue(spellID)  -- shield amount, etc.
Hoa.GetCards()             -- card data
Hoa.RegisterEvent("RUN_STAGE", fn)
```

3. The addon no longer subscribes to chat lines or parses `~`-separated strings.

During the transition the `BONK~` channel may remain for UI data not yet migrated, but **state data must move to native auras first**, and no new chat-line state may be added.

## 7. Compatibility

- Protocol version, content hash and client version are independent; any mismatch has an explicit message.
- LAN discovery/direct-connect handshakes verify the version; different versions cannot play together.
- An old client connecting to a new server is rejected at the handshake with a clear update message.
- A new client connecting to an old server downgrades by capability bits or refuses.

## 8. Migration

1. Inventory existing `BONK~` messages and classify them as state/presentation/command.
2. Move state to auras (see [Auras and effects](../auras/README.md)).
3. Define presentation messages and the client Lua API.
4. Commands (`.bonk ...`) keep their chat entry point, but handlers call server APIs instead of assembling strings.
5. Finally delete the addon's `BONK~` parser and hand-written field indices.
