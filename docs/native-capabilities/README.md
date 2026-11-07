# Client-native capabilities

Principle: **if the client already exposes a state or event, use it; only add a HoA message for something vanilla has no equivalent for.**

Benefits: the native buff frame, unit frames, cast bar, combat log and other addons work directly; the HoA addon stays thin; no state exists twice.

## Mapping

| HoA concept | Native capability | Notes |
| --- | --- | --- |
| Character/run level | `PLAYER_LEVEL`, `UnitLevel`, `PLAYER_LEVEL_UP`, `UNIT_LEVEL` | The server already uses `m_player->GetLevel()` for the run level; the addon must not store another copy |
| Buff / Debuff | server aura → `SMSG_AURA_UPDATE`; addon `UnitBuff`/`UnitDebuff`/`UNIT_AURA` | See [Auras and effects](../auras/README.md) |
| Stacks | aura stack | `GetPlayerBuffApplications` or the aura stack field |
| Health/mana | native unit fields; `UNIT_HEALTH`, `UNIT_MANA`, `UNIT_MAXHEALTH` | The addon already uses some of these |
| Combat state | `UnitAffectingCombat`, `PLAYER_REGEN_ENABLED/DISABLED`, `UNIT_COMBAT` | Do not synchronize a server boolean |
| Cast/channel | `UnitCastingInfo`, `UnitChannelInfo`, `UNIT_SPELLCAST_*` | Use directly for cast bars and interrupt prompts |
| Cooldowns | `GetSpellCooldown`, `SPELL_UPDATE_COOLDOWN` | Card/spell cooldowns are driven by server spells |
| Equipment | `GetInventoryItemLink`, `UNIT_INVENTORY_CHANGED`, `GetContainerItemLink` | Item names come from server-localized queries |
| Target/party | native target/party APIs | HoA party UI reads native members |
| Death/revive | `UnitIsDeadOrGhost`, `PLAYER_DEAD`, `PLAYER_ALIVE` | Do not use custom messages |
| Money/XP | `GetMoney`, `GetXP` | Native |
| Move speed | server aura (speed type) | The client does not compute it |

## What stays on HoA messages

Data that vanilla does not have:

- run stage/wave/difficulty, boss progress;
- card choices, rewards, codex, leaderboard;
- custom shop/quartermaster stock;
- values the server computes that do not fit native unit fields (for example shield remaining or special stack caps).

These use the typed protocol plus a client Lua API (see [Protocol](../protocol/README.md)), not `BONK~` strings.

## Client Lua API audit

benilla's Lua/FrameXML coverage is incomplete. Before migrating, inventory and fill in the standard APIs, at least:

- `UnitBuff`/`UnitDebuff`/`GetPlayerBuff`/`GetPlayerBuffApplications`/`GetPlayerBuffTimeLeft`
- `UnitCastingInfo`/`UnitChannelInfo`, `UNIT_SPELLCAST_*` events
- `GetSpellCooldown`/`SPELL_UPDATE_COOLDOWN`
- `UnitLevel`/`PLAYER_LEVEL_UP`
- `UnitAffectingCombat`/`PLAYER_REGEN_*`
- party-member and target APIs

`C_UnitAuras` now serves enemy nameplates, boss debuffs, keyword stacks and player auras; the remaining gaps are the stock spell/cooldown and party APIs listed above.

## Addon migration

Done in phase 5:

- the `BONK~state` parser and local state timers are gone; typed `HOA_*` events carry server state, and native auras carry the effects.

Remaining:

- per-frame `OnUpdate` countdown/cooldown rebuilds;
- addon-computed item level/stats/gear tooltips (read server data instead).

Keep:

- window layout and the visual presentation of cards/rewards/codex;
- custom styling driven by native API data.
