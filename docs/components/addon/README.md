# addon

Imported from the main repository's `Interface/AddOns/HordesOfAzeroth` (`3ca658b`, 2026-11-04); license GPL-3.0. The source currently lives in `addon/HordesOfAzeroth/`. See [`UPSTREAM.md`](../../../addon/HordesOfAzeroth/UPSTREAM.md).

## Responsibilities after the refactor

The addon is a **presentation layer only**:

- Reads native client APIs (`UnitBuff`, `UnitLevel`, `GetTime`, combat events) to render the HoA UI.
- No longer maintains buff/effect timers, stacks or state machines; those live in server auras (see [Auras and effects](../../auras/README.md)).
- No longer computes item level, gear stats or other values the server already knows; those come from the content pack or protocol.
- All text comes from Lua tables generated from `shared/i18n`; the language is the server/client setting, never the installed client language. `VanillaBonkLocaleData.lua` is generated from `shared/i18n/addon/addon.yaml` and holds every language in one file.

## Module system

Each feature is a named module: `UI.Module("bags")` returns the same table for the same name.
`Module:Listen(handlers, frame)` owns one event frame (or reuses an existing one), and
`Module:OnEnterWorld`, `:OnLeaveWorld`, `:OnRunStart`, `:OnRunEnd` register lifecycle hooks. One
dispatcher in `VanillaBonkUI.lua` owns `PLAYER_ENTERING_WORLD`, `PLAYER_LEAVING_WORLD` and the
typed `HOA_RUN_START`/`HOA_RUN_END` events and calls the hooks in load order, passing the run
start/end fields. `UI.modules` / `UI.moduleOrder` list the modules for diagnostics, and
`UI.RunLifecycle(field, ...)` dispatches a lifecycle manually. The core run state in
`VanillaBonk.lua` still handles the two run messages directly.

## UI objects

`UI.Class(parent)` / `UI.New` / `UI.Mixin` are plain-table classes (frames are userdata and keep
using the factory functions). `UI.PanelObject(name, frames)` wraps one or more frames, registers
in `UI.panels`, and exposes `Show/Hide/Toggle/IsShown/Refresh` with optional `OnShow`, `OnHide` and
`OnRefresh`; `UI.RefreshPanels()` refreshes them all. `UI.List(parent, opts)` owns named `UI.Row`
objects with `SetValue`, `SetLabel`, `Show`, `Hide` and `Layout`, so list placement is computed in
one place. The tracker is the first panel/list pilot.

`VanillaBonk.lua` is split by domain: `VanillaBonkOffer.lua` (rarities, banishing, keywords, offer
cards, results), `VanillaBonkStarters.lua` (run-master loadout starters), `VanillaBonkShop.lua`
(shop window, trees, presets), `VanillaBonkGearStats.lua` (gear, stat sheet, tooltips) and
`VanillaBonkChatFilter.lua`. The shared run table is `VanillaBonkRun`; split files read state and
helpers from it.

## Planned layout

```
addon/
  HordesOfAzeroth/
    core/            core state, UI kit, locale, options text, chat filter
    run/             run mechanics and their panels (offer, shop, gear, hero bar, ...)
    panels/          menus, codex, map, quests, settings, controller, co-op, ...
    Fonts/           language font fallbacks (Noto Sans SC / Noto Sans TC)
    VanillaBonkAuraIds.lua       generated content ids (root)
    VanillaBonkLocaleData.lua    generated language data (root)
    HordesOfAzeroth.toc
```

## Kept

The usable parts of the current addon (window layout, card/reward UI, tooltips, bindings, GlueXML language mechanism) stay and migrate to the new data sources step by step.
