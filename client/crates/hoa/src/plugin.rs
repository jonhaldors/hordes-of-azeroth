use bevy::log::{info, warn};
use bevy::prelude::*;

use benilla_app::{HoaAuraRow, NetHandlerApp};
use benilla_protocol::{SessionEvent, SessionEventKind};
use benilla_ui::script::{add_in_game_event, ScriptValue};

use crate::controller_lua::deliver_pad_events;
use crate::cursor::{drive_pad_cursor, hide_cursor_for_pad, notice_keyboard_and_mouse};
use crate::interact::{update_interact, SharedInteract};
use crate::keys::{capture_typing, SharedTyping};
use crate::lua_api::{scripted_login_from_env, LuaHosts};
use crate::nameplates::{add_plate_events, track_nameplates, SharedPlates};
use crate::pad::{log_new_pads, poll_pads, SharedController};
use crate::protocol_generated::{self, HoaMessage, CONTENT_HASH, CONTENT_SECTIONS, PROTOCOL_VERSION};
use crate::server_draw::DrawCommand;
use crate::snapshot::{capture_snapshot, SharedSnapshot};
use crate::world_map::SharedMapAreas;
use crate::telegraphs::{expire_telegraphs, follow_marks, project_telegraphs, push_telegraphs, Telegraphs};
use crate::world_fx::{apply_draw_lines, expire_kit_anchors, move_flights, DisplayModels, DrawCommandMessage};

const HOA_HELLO: &str = "HOA_HELLO";
const HOA_INCOMPATIBLE: &str = "HOA_INCOMPATIBLE";
const HOA_AURA_VALUE: &str = "HOA_AURA_VALUE";
const HOA_DASH: &str = "HOA_DASH";
const HOA_AURA_PERCENT: &str = "HOA_AURA_PERCENT";
const HOA_RUN_STATE: &str = "HOA_RUN_STATE";
const HOA_RUN_START: &str = "HOA_RUN_START";
const HOA_RUN_END: &str = "HOA_RUN_END";
const HOA_RUN_PAUSED: &str = "HOA_RUN_PAUSED";
const HOA_COOP_NO_PAUSE: &str = "HOA_COOP_NO_PAUSE";
const HOA_RUN_XP: &str = "HOA_RUN_XP";
const HOA_WAVE_BEAT: &str = "HOA_WAVE_BEAT";
const HOA_MOG_BEGIN: &str = "HOA_MOG_BEGIN";
const HOA_MOG_SLOT: &str = "HOA_MOG_SLOT";
const HOA_MOG_LOOK: &str = "HOA_MOG_LOOK";
const HOA_MOG_OUTFIT: &str = "HOA_MOG_OUTFIT";
const HOA_MOG_END: &str = "HOA_MOG_END";
const HOA_HARDCORE_FELL: &str = "HOA_HARDCORE_FELL";
const HOA_HARDCORE_RESTED: &str = "HOA_HARDCORE_RESTED";
const HOA_RUN_SUPPORT: &str = "HOA_RUN_SUPPORT";
const HOA_RUN_GLYPH_METER: &str = "HOA_RUN_GLYPH_METER";
const HOA_RUN_OTHER_METER: &str = "HOA_RUN_OTHER_METER";
const HOA_RUN_PARTY_METER: &str = "HOA_RUN_PARTY_METER";
const HOA_OBJECTIVE: &str = "HOA_OBJECTIVE";
const HOA_OBJECTIVE_CLEAR: &str = "HOA_OBJECTIVE_CLEAR";
const HOA_OBJECTIVE_PING: &str = "HOA_OBJECTIVE_PING";
const HOA_MOB: &str = "HOA_MOB";
const HOA_MOB_DEAD: &str = "HOA_MOB_DEAD";
const HOA_MOB_CLEAR: &str = "HOA_MOB_CLEAR";
const HOA_ALLY: &str = "HOA_ALLY";
const HOA_ALLY_DONE: &str = "HOA_ALLY_DONE";
const HOA_AFFIX_INFO: &str = "HOA_AFFIX_INFO";
const HOA_OFFER_OPEN: &str = "HOA_OFFER_OPEN";
const HOA_OFFER_OPTION: &str = "HOA_OFFER_OPTION";
const HOA_OFFER_STAT: &str = "HOA_OFFER_STAT";
const HOA_OFFER_END: &str = "HOA_OFFER_END";
const HOA_OFFER_CLOSED: &str = "HOA_OFFER_CLOSED";
const HOA_LEY_OPEN: &str = "HOA_LEY_OPEN";
const HOA_LEY_OPTION: &str = "HOA_LEY_OPTION";
const HOA_LEY_END: &str = "HOA_LEY_END";
const HOA_LEY_CLOSED: &str = "HOA_LEY_CLOSED";
const HOA_GLYPH_OFFER: &str = "HOA_GLYPH_OFFER";
const HOA_GLYPH_OPTION: &str = "HOA_GLYPH_OPTION";
const HOA_GLYPH_OFFER_END: &str = "HOA_GLYPH_OFFER_END";
const HOA_GLYPH_CLOSE: &str = "HOA_GLYPH_CLOSE";
const HOA_GLYPH_TAKEN: &str = "HOA_GLYPH_TAKEN";
const HOA_GLYPH_INFO: &str = "HOA_GLYPH_INFO";
const HOA_GLYPH_COUNT: &str = "HOA_GLYPH_COUNT";
const HOA_QUEST_LOG_OPEN: &str = "HOA_QUEST_LOG_OPEN";
const HOA_QUEST_ENTRY: &str = "HOA_QUEST_ENTRY";
const HOA_QUEST_LOG_END: &str = "HOA_QUEST_LOG_END";
const HOA_QUEST_DONE: &str = "HOA_QUEST_DONE";
const HOA_VENDOR_OPEN: &str = "HOA_VENDOR_OPEN";
const HOA_VENDOR_SLOT: &str = "HOA_VENDOR_SLOT";
const HOA_VENDOR_END: &str = "HOA_VENDOR_END";
const HOA_VENDOR_CLOSE: &str = "HOA_VENDOR_CLOSE";
const HOA_PORTAL_HOME: &str = "HOA_PORTAL_HOME";
const HOA_PORTAL_ENDLESS: &str = "HOA_PORTAL_ENDLESS";
const HOA_FOUND_CLEAR: &str = "HOA_FOUND_CLEAR";
const HOA_FOUND_ITEM: &str = "HOA_FOUND_ITEM";
const HOA_FOUND_END: &str = "HOA_FOUND_END";
const HOA_GEAR_OFFER: &str = "HOA_GEAR_OFFER";
const HOA_GEAR_CLOSE: &str = "HOA_GEAR_CLOSE";
const HOA_VAULT_CLEAR: &str = "HOA_VAULT_CLEAR";
const HOA_VAULT_SENT: &str = "HOA_VAULT_SENT";
const HOA_VAULT_SENT_ITEM: &str = "HOA_VAULT_SENT_ITEM";
const HOA_VAULT_ITEM: &str = "HOA_VAULT_ITEM";
const HOA_VAULT_OPEN: &str = "HOA_VAULT_OPEN";
const HOA_VAULT_CLOSE: &str = "HOA_VAULT_CLOSE";
const HOA_ENCHANT_CLEAR: &str = "HOA_ENCHANT_CLEAR";
const HOA_ENCHANT_INFO: &str = "HOA_ENCHANT_INFO";
const HOA_ENCHANT_SLOT: &str = "HOA_ENCHANT_SLOT";
const HOA_ENCHANT_OFFER: &str = "HOA_ENCHANT_OFFER";
const HOA_ENCHANT_END: &str = "HOA_ENCHANT_END";
const HOA_ENCHANT_OPEN: &str = "HOA_ENCHANT_OPEN";
const HOA_ENCHANT_CLOSE: &str = "HOA_ENCHANT_CLOSE";
const HOA_CARDS: &str = "HOA_CARDS";
const HOA_CARD_TIP: &str = "HOA_CARD_TIP";
const HOA_CARD_COOLDOWN: &str = "HOA_CARD_COOLDOWN";
const HOA_CARD_NOW: &str = "HOA_CARD_NOW";
const HOA_MASTERY_STATE: &str = "HOA_MASTERY_STATE";
const HOA_WALLET: &str = "HOA_WALLET";
const HOA_NOTICE: &str = "HOA_NOTICE";
const HOA_MESSAGE: &str = "HOA_MESSAGE";
const HOA_FIND: &str = "HOA_FIND";
const HOA_NPC_NAME: &str = "HOA_NPC_NAME";
const HOA_SHARD: &str = "HOA_SHARD";
const HOA_VALOR: &str = "HOA_VALOR";
const HOA_EPIC_LUCK: &str = "HOA_EPIC_LUCK";
const HOA_COOP_WAIT: &str = "HOA_COOP_WAIT";
const HOA_COOP_WATCH: &str = "HOA_COOP_WATCH";
const HOA_COOP_REMOVED: &str = "HOA_COOP_REMOVED";
const HOA_COOP_DOWN: &str = "HOA_COOP_DOWN";
const HOA_LEASH: &str = "HOA_LEASH";
const HOA_COOP_READY: &str = "HOA_COOP_READY";
const HOA_COOP_READY_END: &str = "HOA_COOP_READY_END";
const HOA_STARTER: &str = "HOA_STARTER";
const HOA_STARTER_END: &str = "HOA_STARTER_END";
const HOA_REACH_RING: &str = "HOA_REACH_RING";
const HOA_DRUID_FORM: &str = "HOA_DRUID_FORM";
const HOA_GREED: &str = "HOA_GREED";
const HOA_HEARTH: &str = "HOA_HEARTH";
const HOA_CAPTURE: &str = "HOA_CAPTURE";
const HOA_MOONWELL: &str = "HOA_MOONWELL";
const HOA_LEY_BLESSINGS: &str = "HOA_LEY_BLESSINGS";
const HOA_LEY_BLESS: &str = "HOA_LEY_BLESS";
const HOA_LEY_BLESS_END: &str = "HOA_LEY_BLESS_END";
const HOA_EVENT_TIMER: &str = "HOA_EVENT_TIMER";
const HOA_DEATH_RECAP: &str = "HOA_DEATH_RECAP";
const HOA_DEATH_SOURCE: &str = "HOA_DEATH_SOURCE";
const HOA_DEATH_EVENTS: &str = "HOA_DEATH_EVENTS";
const HOA_RUN_SUMMARY: &str = "HOA_RUN_SUMMARY";
const HOA_SUMMARY_WEAPON: &str = "HOA_SUMMARY_WEAPON";
const HOA_SUMMARY_SPELL: &str = "HOA_SUMMARY_SPELL";
const HOA_SUMMARY_END: &str = "HOA_SUMMARY_END";
const HOA_BOARD_OPEN: &str = "HOA_BOARD_OPEN";
const HOA_BOARD_HEADER: &str = "HOA_BOARD_HEADER";
const HOA_BOARD_ROW: &str = "HOA_BOARD_ROW";
const HOA_BOARD_PAGE: &str = "HOA_BOARD_PAGE";
const HOA_BOARD_CHOICE: &str = "HOA_BOARD_CHOICE";
const HOA_BOARD_END: &str = "HOA_BOARD_END";
const HOA_SHOP_OPEN: &str = "HOA_SHOP_OPEN";
const HOA_SHOP_TREE: &str = "HOA_SHOP_TREE";
const HOA_MASTERY_TREE: &str = "HOA_MASTERY_TREE";
const HOA_SHOP_NODE: &str = "HOA_SHOP_NODE";
const HOA_MASTERY_NODE: &str = "HOA_MASTERY_NODE";
const HOA_MASTERY_PRESETS: &str = "HOA_MASTERY_PRESETS";
const HOA_MASTERY_PRESET_RANKS: &str = "HOA_MASTERY_PRESET_RANKS";
const HOA_SHOP_END: &str = "HOA_SHOP_END";
const HOA_SHOP_CLOSE: &str = "HOA_SHOP_CLOSE";
const HOA_GEAR: &str = "HOA_GEAR";
const HOA_GEAR_END: &str = "HOA_GEAR_END";
const HOA_TRINKET_TIP: &str = "HOA_TRINKET_TIP";
const HOA_ARENA: &str = "HOA_ARENA";
const HOA_TIER: &str = "HOA_TIER";
const HOA_TIER_END: &str = "HOA_TIER_END";
const HOA_TIER_INFO: &str = "HOA_TIER_INFO";
const HOA_LEVEL_PREVIEW: &str = "HOA_LEVEL_PREVIEW";
const HOA_LEVEL_BEST: &str = "HOA_LEVEL_BEST";
const HOA_MAP_INFO: &str = "HOA_MAP_INFO";
const HOA_ZONE_ART: &str = "HOA_ZONE_ART";
const HOA_CODEX: &str = "HOA_CODEX";
const HOA_WEAPON_INFO: &str = "HOA_WEAPON_INFO";
const HOA_WEAPON_EVOLUTION: &str = "HOA_WEAPON_EVOLUTION";
const HOA_WEAPON_EVOLUTION_OPTION: &str = "HOA_WEAPON_EVOLUTION_OPTION";
const HOA_COOLDOWN_PIE: &str = "HOA_COOLDOWN_PIE";
const HOA_QUARTERMASTER: &str = "HOA_QUARTERMASTER";
const HOA_QUARTERMASTER_UPGRADE_CLEAR: &str = "HOA_QUARTERMASTER_UPGRADE_CLEAR";
const HOA_QUARTERMASTER_UPGRADE: &str = "HOA_QUARTERMASTER_UPGRADE";
const HOA_QUARTERMASTER_UPGRADE_END: &str = "HOA_QUARTERMASTER_UPGRADE_END";
const HOA_MUSIC: &str = "HOA_MUSIC";
const HOA_LOADOUT: &str = "HOA_LOADOUT";
const HOA_DRUID_SLOTS: &str = "HOA_DRUID_SLOTS";
const HOA_BOSS_BAR: &str = "HOA_BOSS_BAR";
const HOA_TITLES: &str = "HOA_TITLES";
const HOA_STATS: &str = "HOA_STATS";
const HOA_KEYWORD_TIMERS: &str = "HOA_KEYWORD_TIMERS";

fn lua_table(fields: Vec<(&str, ScriptValue)>) -> ScriptValue {
    ScriptValue::Table(fields.into_iter().map(|(key, value)| (key.to_string(), value)).collect())
}

/// Typed HoA packets, drained on the main thread because firing a Lua event needs the VM.
#[derive(Resource, Default)]
struct HoaInbox(Vec<(u16, Vec<u8>)>);

/// Set once hello disagrees with this build, so no later packet is decoded as if it agreed.
#[derive(Resource, Default)]
struct HoaHandshake {
    blocked: bool,
}

#[derive(Clone, PartialEq, Eq, Debug)]
struct HelloCheck {
    protocol_mismatch: bool,
    content_mismatch: bool,
    changed_sections: Vec<String>,
}

impl HelloCheck {
    fn of(protocol_version: u16, content_hash: &str, content_sections: &str) -> Self {
        let content_mismatch = content_hash != CONTENT_HASH;
        Self {
            protocol_mismatch: protocol_version != PROTOCOL_VERSION,
            content_mismatch,
            changed_sections: if content_mismatch {
                changed_sections(content_sections)
            } else {
                Vec::new()
            },
        }
    }

    fn compatible(&self) -> bool {
        !self.protocol_mismatch && !self.content_mismatch
    }
}

/// The manifest sections whose hash differs from this build's, plus any the server omitted.
fn changed_sections(server: &str) -> Vec<String> {
    use std::collections::{BTreeMap, BTreeSet};
    let expected: BTreeMap<&str, &str> = CONTENT_SECTIONS.iter().copied().collect();
    let mut changed = Vec::new();
    let mut seen = BTreeSet::new();
    for part in server.split(';').filter(|part| !part.is_empty()) {
        let Some((name, hash)) = part.split_once('=') else {
            changed.push(part.to_string());
            continue;
        };
        seen.insert(name);
        if expected.get(name).copied() != Some(hash) {
            changed.push(name.to_string());
        }
    }
    changed.extend(
        expected
            .keys()
            .filter(|name| !seen.contains(**name))
            .map(|name| (*name).to_string()),
    );
    changed
}

/// A catalog that arrived before the spell catalog existed, retried each frame.
#[derive(Resource, Default)]
struct AuraCatalogBuffer {
    rows: Vec<HoaAuraRow>,
    total: u16,
    active: bool,
    pending: bool,
}

fn apply_pending_catalog(world: &mut World) {
    if !world.resource::<AuraCatalogBuffer>().pending {
        return;
    }
    let rows = {
        let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
        buffer.pending = false;
        std::mem::take(&mut buffer.rows)
    };
    if !benilla_app::set_hoa_aura_catalog(world, &rows) {
        let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
        buffer.rows = rows;
        buffer.pending = true;
    }
}

fn on_hoa_message(In(event): In<SessionEvent>, mut inbox: ResMut<HoaInbox>) {
    if let SessionEvent::HoaMessage { id, body } = event {
        inbox.0.push((id, body));
    }
}

fn deliver_hoa_messages(world: &mut World) {
    let pending = std::mem::take(&mut world.resource_mut::<HoaInbox>().0);
    if pending.is_empty() {
        return;
    }
    let mut value_texts: Vec<(u32, String)> = Vec::new();
    let (mut catalog_rows, mut catalog_total, mut catalog_active) = {
        let buffer = world.resource::<AuraCatalogBuffer>();
        (
            if buffer.active { buffer.rows.clone() } else { Vec::new() },
            buffer.total,
            buffer.active,
        )
    };
    let mut catalog_done = false;
    // The account language arrives with hello. Seat it before the closure fires HOA_HELLO, so the
    // addon's handler and GetLocale already read the new language.
    let hello = pending.iter().rev().find_map(|(id, body)| {
        match protocol_generated::decode(*id, body) {
            Some(HoaMessage::Hello(hello)) => Some(hello),
            _ => None,
        }
    });
    let mut blocked = world.resource::<HoaHandshake>().blocked;
    if let Some(hello) = &hello {
        blocked = !HelloCheck::of(
            hello.protocol_version,
            &hello.content_hash,
            &hello.content_sections,
        )
        .compatible();
    }
    if !blocked {
        if let Some(hello) = &hello {
            benilla_app::set_hoa_account_language(world, &hello.language);
        }
    }
    let mut draws: Vec<DrawCommand> = Vec::new();
    benilla_app::run_hosted(world, |script| {
        let Some(script) = script else {
            return;
        };
        for (id, body) in pending {
            let Some(message) = protocol_generated::decode(id, &body) else {
                warn!("hoa protocol: unknown message id {id}");
                continue;
            };
            if blocked && !matches!(&message, HoaMessage::Hello(_)) {
                continue;
            }
            match message {
                HoaMessage::Music(music) => {
                    script.fire_event(
                        HOA_MUSIC,
                        vec![lua_table(vec![("track", ScriptValue::Str(music.track))])],
                    );
                }
                HoaMessage::Loadout(loadout) => {
                    script.fire_event(
                        HOA_LOADOUT,
                        vec![lua_table(vec![
                            ("entries", ScriptValue::Str(loadout.entries)),
                            ("spell_slots", ScriptValue::Int(i64::from(loadout.spell_slots))),
                            ("passive_slots", ScriptValue::Int(i64::from(loadout.passive_slots))),
                        ])],
                    );
                }
                HoaMessage::DruidSlots(slots) => {
                    script.fire_event(
                        HOA_DRUID_SLOTS,
                        vec![lua_table(vec![("slots", ScriptValue::Str(slots.slots))])],
                    );
                }
                HoaMessage::BossBar(bar) => {
                    script.fire_event(
                        HOA_BOSS_BAR,
                        vec![lua_table(vec![("data", ScriptValue::Str(bar.data))])],
                    );
                }
                HoaMessage::Titles(titles) => {
                    script.fire_event(
                        HOA_TITLES,
                        vec![lua_table(vec![
                            ("active", ScriptValue::Int(i64::from(titles.active))),
                            ("list", ScriptValue::Str(titles.list)),
                        ])],
                    );
                }
                HoaMessage::Stats(stats) => {
                    script.fire_event(
                        HOA_STATS,
                        vec![lua_table(vec![
                            ("in_run", ScriptValue::Bool(stats.in_run)),
                            ("caps", ScriptValue::Str(stats.caps)),
                            ("after_caps", ScriptValue::Str(stats.after_caps)),
                        ])],
                    );
                }
                HoaMessage::KeywordTimers(timers) => {
                    script.fire_event(
                        HOA_KEYWORD_TIMERS,
                        vec![lua_table(vec![("entries", ScriptValue::Str(timers.entries))])],
                    );
                }
                HoaMessage::WeaponInfo(weapon) => {
                    script.fire_event(
                        HOA_WEAPON_INFO,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(weapon.index))),
                            ("name", ScriptValue::Str(weapon.name)),
                            ("ranks", ScriptValue::Str(weapon.ranks)),
                            ("interval", ScriptValue::Int(i64::from(weapon.interval))),
                            ("next_cast", ScriptValue::Int(i64::from(weapon.next_cast))),
                            ("line", ScriptValue::Str(weapon.line)),
                            ("description", ScriptValue::Str(weapon.description)),
                            ("damage", ScriptValue::Str(weapon.damage)),
                            ("header", ScriptValue::Str(weapon.header)),
                            ("faster", ScriptValue::Bool(weapon.faster)),
                            ("tags", ScriptValue::Str(weapon.tags)),
                            ("radius", ScriptValue::Str(weapon.radius)),
                        ])],
                    );
                }
                HoaMessage::WeaponEvolution(evolution) => {
                    script.fire_event(
                        HOA_WEAPON_EVOLUTION,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(evolution.index))),
                            ("evolution", ScriptValue::Str(evolution.evolution)),
                            ("evolution_text", ScriptValue::Str(evolution.evolution_text)),
                            ("evolved_from", ScriptValue::Str(evolution.evolved_from)),
                            ("chance_text", ScriptValue::Str(evolution.chance_text)),
                            ("chance", ScriptValue::Int(i64::from(evolution.chance))),
                        ])],
                    );
                }
                HoaMessage::WeaponEvolutionOption(option) => {
                    script.fire_event(
                        HOA_WEAPON_EVOLUTION_OPTION,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(option.index))),
                            ("name", ScriptValue::Str(option.name)),
                            ("text", ScriptValue::Str(option.text)),
                        ])],
                    );
                }
                HoaMessage::CooldownPie(pie) => {
                    script.fire_event(
                        HOA_COOLDOWN_PIE,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(pie.index))),
                            ("pie_ms", ScriptValue::Int(i64::from(pie.pie_ms))),
                            ("timer", ScriptValue::Int(i64::from(pie.timer))),
                            ("held", ScriptValue::Bool(pie.held)),
                        ])],
                    );
                }
                HoaMessage::Quartermaster(qm) => {
                    script.fire_event(
                        HOA_QUARTERMASTER,
                        vec![lua_table(vec![
                            ("tier", ScriptValue::Int(i64::from(qm.tier))),
                            ("scrap", ScriptValue::Int(i64::from(qm.scrap))),
                        ])],
                    );
                }
                HoaMessage::QuartermasterUpgradeClear(_) => {
                    script.fire_event(HOA_QUARTERMASTER_UPGRADE_CLEAR, Vec::new());
                }
                HoaMessage::QuartermasterUpgrade(upgrade) => {
                    script.fire_event(
                        HOA_QUARTERMASTER_UPGRADE,
                        vec![lua_table(vec![
                            ("guid", ScriptValue::Int(i64::from(upgrade.guid))),
                            ("entry", ScriptValue::Int(i64::from(upgrade.entry))),
                            ("tier", ScriptValue::Int(i64::from(upgrade.tier))),
                            ("cost", ScriptValue::Int(i64::from(upgrade.cost))),
                            ("can", ScriptValue::Bool(upgrade.can)),
                            ("worn", ScriptValue::Bool(upgrade.worn)),
                            ("lines", ScriptValue::Str(upgrade.lines)),
                            ("extra", ScriptValue::Str(upgrade.extra)),
                            ("reroll_cost", ScriptValue::Int(i64::from(upgrade.reroll_cost))),
                            ("reroll_line", ScriptValue::Int(i64::from(upgrade.reroll_line))),
                            ("offer_line", ScriptValue::Int(i64::from(upgrade.offer_line))),
                            ("offers", ScriptValue::Str(upgrade.offers)),
                            ("ranges", ScriptValue::Str(upgrade.ranges)),
                            ("left", ScriptValue::Int(i64::from(upgrade.left))),
                        ])],
                    );
                }
                HoaMessage::QuartermasterUpgradeEnd(end) => {
                    script.fire_event(
                        HOA_QUARTERMASTER_UPGRADE_END,
                        vec![lua_table(vec![("scrap", ScriptValue::Int(i64::from(end.scrap)))])],
                    );
                }
                HoaMessage::Codex(codex) => {
                    script.fire_event(
                        HOA_CODEX,
                        vec![lua_table(vec![
                            ("kind", ScriptValue::Str(codex.kind)),
                            ("line", ScriptValue::Str(codex.line)),
                        ])],
                    );
                }
                HoaMessage::Tier(tier) => {
                    script.fire_event(
                        HOA_TIER,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(tier.id))),
                            ("key", ScriptValue::Str(tier.key)),
                            ("name", ScriptValue::Str(tier.name)),
                            ("unlocked", ScriptValue::Bool(tier.unlocked)),
                            ("hint", ScriptValue::Str(tier.hint)),
                            ("best", ScriptValue::Int(i64::from(tier.best))),
                            ("description", ScriptValue::Str(tier.description)),
                            ("art", ScriptValue::Str(tier.art)),
                            ("maps", ScriptValue::Str(tier.maps)),
                            ("levels", ScriptValue::Int(i64::from(tier.levels))),
                            ("open_level", ScriptValue::Int(i64::from(tier.open_level))),
                            ("dungeons", ScriptValue::Str(tier.dungeons)),
                            ("details", ScriptValue::Str(tier.details)),
                            ("first_level", ScriptValue::Int(i64::from(tier.first_level))),
                        ])],
                    );
                }
                HoaMessage::TierEnd(_) => {
                    script.fire_event(HOA_TIER_END, Vec::new());
                }
                HoaMessage::TierInfo(info) => {
                    script.fire_event(
                        HOA_TIER_INFO,
                        vec![lua_table(vec![
                            ("tier_id", ScriptValue::Int(i64::from(info.tier_id))),
                            ("aim", ScriptValue::Str(info.aim)),
                            ("boss", ScriptValue::Str(info.boss)),
                            ("charge_seconds", ScriptValue::Int(i64::from(info.charge_seconds))),
                            ("crowd", ScriptValue::Int(i64::from(info.crowd))),
                            ("carried_from", ScriptValue::Str(info.carried_from)),
                        ])],
                    );
                }
                HoaMessage::LevelPreview(level) => {
                    script.fire_event(
                        HOA_LEVEL_PREVIEW,
                        vec![lua_table(vec![
                            ("tier_id", ScriptValue::Int(i64::from(level.tier_id))),
                            ("band", ScriptValue::Int(i64::from(level.band))),
                            ("health", ScriptValue::Str(level.health)),
                            ("damage", ScriptValue::Str(level.damage)),
                            ("veterans", ScriptValue::Str(level.veterans)),
                            ("affixes", ScriptValue::Int(i64::from(level.affixes))),
                            ("gold", ScriptValue::Str(level.gold)),
                            ("legendary", ScriptValue::Str(level.legendary)),
                            ("epic", ScriptValue::Str(level.epic)),
                            ("blue", ScriptValue::Str(level.blue)),
                            ("green", ScriptValue::Str(level.green)),
                            ("white", ScriptValue::Str(level.white)),
                            ("cleared", ScriptValue::Str(level.cleared)),
                            ("drop_tier", ScriptValue::Int(i64::from(level.drop_tier))),
                            ("stone", ScriptValue::Bool(level.stone)),
                        ])],
                    );
                }
                HoaMessage::LevelBest(best) => {
                    script.fire_event(
                        HOA_LEVEL_BEST,
                        vec![lua_table(vec![
                            ("tier_id", ScriptValue::Int(i64::from(best.tier_id))),
                            ("band", ScriptValue::Int(i64::from(best.band))),
                            ("clears", ScriptValue::Int(i64::from(best.clears))),
                            ("first_clear", ScriptValue::Int(i64::from(best.first_clear))),
                            ("best_ms", ScriptValue::Int(i64::from(best.best_ms))),
                            ("best_ms_by", ScriptValue::Str(best.best_ms_by)),
                            ("damage", ScriptValue::Int(i64::from(best.damage))),
                            ("damage_by", ScriptValue::Str(best.damage_by)),
                            ("kills", ScriptValue::Int(i64::from(best.kills))),
                            ("kills_by", ScriptValue::Str(best.kills_by)),
                            ("gold", ScriptValue::Int(i64::from(best.gold))),
                            ("gold_by", ScriptValue::Str(best.gold_by)),
                            ("valor", ScriptValue::Int(i64::from(best.valor))),
                            ("valor_by", ScriptValue::Str(best.valor_by)),
                            ("finale", ScriptValue::Int(i64::from(best.finale))),
                            ("finale_seconds", ScriptValue::Int(i64::from(best.finale_seconds))),
                        ])],
                    );
                }
                HoaMessage::MapInfo(map) => {
                    script.fire_event(
                        HOA_MAP_INFO,
                        vec![lua_table(vec![
                            ("key", ScriptValue::Str(map.key)),
                            ("map_id", ScriptValue::Int(i64::from(map.map_id))),
                            ("summary", ScriptValue::Str(map.summary)),
                            ("description", ScriptValue::Str(map.description)),
                            ("zone_file", ScriptValue::Str(map.zone_file)),
                            ("u", ScriptValue::Str(map.u)),
                            ("v", ScriptValue::Str(map.v)),
                        ])],
                    );
                }
                HoaMessage::ZoneArt(art) => {
                    script.fire_event(
                        HOA_ZONE_ART,
                        vec![lua_table(vec![
                            ("file", ScriptValue::Str(art.file)),
                            ("texture", ScriptValue::Str(art.texture)),
                            ("width", ScriptValue::Int(i64::from(art.width))),
                            ("height", ScriptValue::Int(i64::from(art.height))),
                            ("x", ScriptValue::Str(art.x)),
                            ("y", ScriptValue::Str(art.y)),
                        ])],
                    );
                }
                HoaMessage::Gear(gear) => {
                    script.fire_event(
                        HOA_GEAR,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(gear.id))),
                            ("stats", ScriptValue::Str(gear.stats)),
                        ])],
                    );
                }
                HoaMessage::GearEnd(_) => {
                    script.fire_event(HOA_GEAR_END, Vec::new());
                }
                HoaMessage::TrinketTip(tip) => {
                    script.fire_event(
                        HOA_TRINKET_TIP,
                        vec![lua_table(vec![
                            ("entry", ScriptValue::Int(i64::from(tip.entry))),
                            ("count", ScriptValue::Int(i64::from(tip.count))),
                            ("text", ScriptValue::Str(tip.text)),
                        ])],
                    );
                }
                HoaMessage::Arena(arena) => {
                    script.fire_event(
                        HOA_ARENA,
                        vec![lua_table(vec![
                            ("npc_present", ScriptValue::Bool(arena.npc_present)),
                            ("npc", ScriptValue::Str(arena.npc)),
                            ("gold_bonus", ScriptValue::Int(i64::from(arena.gold_bonus))),
                            ("challenges", ScriptValue::Str(arena.challenges)),
                            ("perks", ScriptValue::Str(arena.perks)),
                        ])],
                    );
                }
                HoaMessage::ShopOpen(shop) => {
                    script.fire_event(
                        HOA_SHOP_OPEN,
                        vec![lua_table(vec![
                            ("kind", ScriptValue::Int(i64::from(shop.kind))),
                            ("open", ScriptValue::Bool(shop.open)),
                            ("npc", ScriptValue::Str(shop.npc)),
                            ("currency", ScriptValue::Str(shop.currency)),
                            ("balance", ScriptValue::Int(i64::from(shop.balance))),
                            ("level", ScriptValue::Int(i64::from(shop.level))),
                            ("xp", ScriptValue::Int(i64::from(shop.xp))),
                            ("xp_next", ScriptValue::Int(i64::from(shop.xp_next))),
                            ("max_level", ScriptValue::Int(i64::from(shop.max_level))),
                            ("earned", ScriptValue::Int(i64::from(shop.earned))),
                            ("from_quests", ScriptValue::Int(i64::from(shop.from_quests))),
                            ("class_name", ScriptValue::Str(shop.class_name)),
                            ("points_per_row", ScriptValue::Int(i64::from(shop.points_per_row))),
                            ("inspect", ScriptValue::Bool(shop.inspect)),
                            ("gates", ScriptValue::Str(shop.gates)),
                            ("coop_guest", ScriptValue::Bool(shop.coop_guest)),
                        ])],
                    );
                }
                HoaMessage::ShopTree(tree) => {
                    script.fire_event(
                        HOA_SHOP_TREE,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(tree.id))),
                            ("name", ScriptValue::Str(tree.name)),
                            ("background", ScriptValue::Str(tree.background)),
                            ("spent", ScriptValue::Int(i64::from(tree.spent))),
                        ])],
                    );
                }
                HoaMessage::MasteryTree(tree) => {
                    script.fire_event(
                        HOA_MASTERY_TREE,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(tree.id))),
                            ("name", ScriptValue::Str(tree.name)),
                            ("background", ScriptValue::Str(tree.background)),
                            ("layout", ScriptValue::Int(i64::from(tree.layout))),
                            ("gates", ScriptValue::Str(tree.gates)),
                            ("spent", ScriptValue::Int(i64::from(tree.spent))),
                        ])],
                    );
                }
                HoaMessage::ShopNode(node) => {
                    script.fire_event(
                        HOA_SHOP_NODE,
                        vec![lua_table(vec![
                            ("tree", ScriptValue::Int(i64::from(node.tree))),
                            ("id", ScriptValue::Int(i64::from(node.id))),
                            ("row", ScriptValue::Int(i64::from(node.row))),
                            ("column", ScriptValue::Int(i64::from(node.column))),
                            ("icon", ScriptValue::Str(node.icon)),
                            ("rank", ScriptValue::Int(i64::from(node.rank))),
                            ("max_rank", ScriptValue::Int(i64::from(node.max_rank))),
                            ("cost", ScriptValue::Int(i64::from(node.cost))),
                            ("required_id", ScriptValue::Int(i64::from(node.required_id))),
                            ("required_rank", ScriptValue::Int(i64::from(node.required_rank))),
                            ("toggle", ScriptValue::Bool(node.toggle)),
                            ("enabled", ScriptValue::Bool(node.enabled)),
                            ("name", ScriptValue::Str(node.name)),
                            ("description", ScriptValue::Str(node.description)),
                            ("locked", ScriptValue::Bool(node.locked)),
                            ("quest", ScriptValue::Str(node.quest)),
                            ("value_per_rank", ScriptValue::Str(node.value_per_rank)),
                            ("refund", ScriptValue::Int(i64::from(node.refund))),
                            ("quest_description", ScriptValue::Str(node.quest_description)),
                            ("rank_lock", ScriptValue::Str(node.rank_lock)),
                        ])],
                    );
                }
                HoaMessage::MasteryNode(node) => {
                    script.fire_event(
                        HOA_MASTERY_NODE,
                        vec![lua_table(vec![
                            ("tree", ScriptValue::Int(i64::from(node.tree))),
                            ("id", ScriptValue::Int(i64::from(node.id))),
                            ("row", ScriptValue::Int(i64::from(node.row))),
                            ("column", ScriptValue::Int(i64::from(node.column))),
                            ("icon", ScriptValue::Str(node.icon)),
                            ("rank", ScriptValue::Int(i64::from(node.rank))),
                            ("max_rank", ScriptValue::Int(i64::from(node.max_rank))),
                            ("cost", ScriptValue::Int(i64::from(node.cost))),
                            ("required_id", ScriptValue::Int(i64::from(node.required_id))),
                            ("required_rank", ScriptValue::Int(i64::from(node.required_rank))),
                            ("name", ScriptValue::Str(node.name)),
                            ("description", ScriptValue::Str(node.description)),
                            ("value_per_rank", ScriptValue::Str(node.value_per_rank)),
                            ("refund", ScriptValue::Int(i64::from(node.refund))),
                            ("shape", ScriptValue::Int(i64::from(node.shape))),
                            ("position", ScriptValue::Str(node.position)),
                            ("parents", ScriptValue::Str(node.parents)),
                            ("excludes", ScriptValue::Str(node.excludes)),
                        ])],
                    );
                }
                HoaMessage::MasteryPresets(presets) => {
                    script.fire_event(
                        HOA_MASTERY_PRESETS,
                        vec![lua_table(vec![
                            ("active", ScriptValue::Int(i64::from(presets.active))),
                            ("points_1", ScriptValue::Int(i64::from(presets.points_1))),
                            ("points_2", ScriptValue::Int(i64::from(presets.points_2))),
                            ("points_3", ScriptValue::Int(i64::from(presets.points_3))),
                        ])],
                    );
                }
                HoaMessage::MasteryPresetRanks(ranks) => {
                    script.fire_event(
                        HOA_MASTERY_PRESET_RANKS,
                        vec![lua_table(vec![
                            ("preset", ScriptValue::Int(i64::from(ranks.preset))),
                            ("ranks", ScriptValue::Str(ranks.ranks)),
                        ])],
                    );
                }
                HoaMessage::ShopEnd(_) => {
                    script.fire_event(HOA_SHOP_END, Vec::new());
                }
                HoaMessage::ShopClose(_) => {
                    script.fire_event(HOA_SHOP_CLOSE, Vec::new());
                }
                HoaMessage::BoardOpen(_) => {
                    script.fire_event(HOA_BOARD_OPEN, Vec::new());
                }
                HoaMessage::BoardHeader(header) => {
                    script.fire_event(
                        HOA_BOARD_HEADER,
                        vec![lua_table(vec![("line", ScriptValue::Str(header.line))])],
                    );
                }
                HoaMessage::BoardRow(row) => {
                    script.fire_event(
                        HOA_BOARD_ROW,
                        vec![lua_table(vec![
                            ("view", ScriptValue::Int(i64::from(row.view))),
                            ("class_id", ScriptValue::Int(i64::from(row.class_id))),
                            ("position", ScriptValue::Int(i64::from(row.position))),
                            ("line", ScriptValue::Str(row.line)),
                        ])],
                    );
                }
                HoaMessage::BoardPage(page) => {
                    script.fire_event(
                        HOA_BOARD_PAGE,
                        vec![lua_table(vec![
                            ("view", ScriptValue::Int(i64::from(page.view))),
                            ("class_id", ScriptValue::Int(i64::from(page.class_id))),
                            ("offset", ScriptValue::Int(i64::from(page.offset))),
                            ("total", ScriptValue::Int(i64::from(page.total))),
                        ])],
                    );
                }
                HoaMessage::BoardChoice(choice) => {
                    script.fire_event(
                        HOA_BOARD_CHOICE,
                        vec![lua_table(vec![
                            ("choice", ScriptValue::Int(i64::from(choice.choice))),
                            ("climb", ScriptValue::Int(i64::from(choice.climb))),
                            ("game_master", ScriptValue::Bool(choice.game_master)),
                            ("server_modified", ScriptValue::Bool(choice.server_modified)),
                        ])],
                    );
                }
                HoaMessage::BoardEnd(_) => {
                    script.fire_event(HOA_BOARD_END, Vec::new());
                }
                HoaMessage::HardcoreRested(_) => {
                    script.fire_event(HOA_HARDCORE_RESTED, Vec::new());
                }
                HoaMessage::HardcoreFell(fell) => {
                    script.fire_event(
                        HOA_HARDCORE_FELL,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(fell.name)),
                            ("class_id", ScriptValue::Int(i64::from(fell.class_id))),
                            ("level", ScriptValue::Int(i64::from(fell.level))),
                            ("best_level", ScriptValue::Int(i64::from(fell.best_level))),
                            ("mastery", ScriptValue::Int(i64::from(fell.mastery))),
                            ("played", ScriptValue::Int(i64::from(fell.played))),
                            ("runs", ScriptValue::Int(i64::from(fell.runs))),
                            ("kills", ScriptValue::Int(i64::from(fell.kills))),
                            ("killer", ScriptValue::Str(fell.killer)),
                            ("map", ScriptValue::Str(fell.map)),
                            ("ironman", ScriptValue::Bool(fell.ironman)),
                        ])],
                    );
                }
                HoaMessage::MogBegin(_) => {
                    script.fire_event(HOA_MOG_BEGIN, Vec::new());
                }
                HoaMessage::MogSlot(slot) => {
                    script.fire_event(
                        HOA_MOG_SLOT,
                        vec![lua_table(vec![
                            ("slot", ScriptValue::Int(i64::from(slot.slot))),
                            ("worn_entry", ScriptValue::Int(i64::from(slot.worn_entry))),
                            ("look", ScriptValue::Int(i64::from(slot.look))),
                            ("group", ScriptValue::Int(i64::from(slot.group))),
                            ("catalog_entry", ScriptValue::Int(i64::from(slot.catalog_entry))),
                            ("can_hide", ScriptValue::Bool(slot.can_hide)),
                        ])],
                    );
                }
                HoaMessage::MogLook(look) => {
                    script.fire_event(
                        HOA_MOG_LOOK,
                        vec![lua_table(vec![
                            ("group", ScriptValue::Int(i64::from(look.group))),
                            ("entry", ScriptValue::Int(i64::from(look.entry))),
                            ("quality", ScriptValue::Int(i64::from(look.quality))),
                            ("owned", ScriptValue::Bool(look.owned)),
                            ("source", ScriptValue::Str(look.source)),
                        ])],
                    );
                }
                HoaMessage::MogOutfit(outfit) => {
                    script.fire_event(
                        HOA_MOG_OUTFIT,
                        vec![lua_table(vec![
                            ("slot", ScriptValue::Int(i64::from(outfit.slot))),
                            ("name", ScriptValue::Str(outfit.name)),
                        ])],
                    );
                }
                HoaMessage::MogEnd(_) => {
                    script.fire_event(HOA_MOG_END, Vec::new());
                }
                HoaMessage::DeathRecap(recap) => {
                    script.fire_event(
                        HOA_DEATH_RECAP,
                        vec![lua_table(vec![
                            ("max_health", ScriptValue::Int(i64::from(recap.max_health))),
                            ("start_health", ScriptValue::Int(i64::from(recap.start_health))),
                            ("killer", ScriptValue::Int(i64::from(recap.killer))),
                            ("kill_amount", ScriptValue::Int(i64::from(recap.kill_amount))),
                            ("overkill", ScriptValue::Int(i64::from(recap.overkill))),
                            ("taken", ScriptValue::Int(i64::from(recap.taken))),
                            ("healed", ScriptValue::Int(i64::from(recap.healed))),
                        ])],
                    );
                }
                HoaMessage::DeathSource(source) => {
                    script.fire_event(
                        HOA_DEATH_SOURCE,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(source.index))),
                            ("icon", ScriptValue::Str(source.icon)),
                            ("name", ScriptValue::Str(source.name)),
                            ("spell", ScriptValue::Str(source.spell)),
                            ("kind", ScriptValue::Str(source.kind)),
                            ("damage", ScriptValue::Number(source.damage as f64)),
                        ])],
                    );
                }
                HoaMessage::DeathEvents(events) => {
                    script.fire_event(
                        HOA_DEATH_EVENTS,
                        vec![lua_table(vec![("text", ScriptValue::Str(events.text))])],
                    );
                }
                HoaMessage::RunSummary(summary) => {
                    script.fire_event(
                        HOA_RUN_SUMMARY,
                        vec![lua_table(vec![
                            ("damage_taken", ScriptValue::Number(summary.damage_taken as f64)),
                            ("elites", ScriptValue::Int(i64::from(summary.elites))),
                            ("minis", ScriptValue::Int(i64::from(summary.minis))),
                            ("bosses", ScriptValue::Int(i64::from(summary.bosses))),
                        ])],
                    );
                }
                HoaMessage::SummaryWeapon(weapon) => {
                    script.fire_event(
                        HOA_SUMMARY_WEAPON,
                        vec![lua_table(vec![
                            ("icon", ScriptValue::Str(weapon.icon)),
                            ("name", ScriptValue::Str(weapon.name)),
                            ("level", ScriptValue::Int(i64::from(weapon.level))),
                            ("max_level", ScriptValue::Int(i64::from(weapon.max_level))),
                            ("evolved", ScriptValue::Bool(weapon.evolved)),
                            ("damage", ScriptValue::Number(weapon.damage as f64)),
                            ("kills", ScriptValue::Int(i64::from(weapon.kills))),
                            ("school", ScriptValue::Str(weapon.school)),
                        ])],
                    );
                }
                HoaMessage::SummarySpell(spell) => {
                    script.fire_event(
                        HOA_SUMMARY_SPELL,
                        vec![lua_table(vec![
                            ("icon", ScriptValue::Str(spell.icon)),
                            ("name", ScriptValue::Str(spell.name)),
                            ("damage", ScriptValue::Number(spell.damage as f64)),
                            ("kills", ScriptValue::Int(i64::from(spell.kills))),
                        ])],
                    );
                }
                HoaMessage::SummaryEnd(_) => {
                    script.fire_event(HOA_SUMMARY_END, Vec::new());
                }
                HoaMessage::Capture(capture) => {
                    script.fire_event(
                        HOA_CAPTURE,
                        vec![lua_table(vec![
                            ("label", ScriptValue::Str(capture.label)),
                            ("percent", ScriptValue::Int(i64::from(capture.percent))),
                        ])],
                    );
                }
                HoaMessage::Moonwell(moonwell) => {
                    script.fire_event(
                        HOA_MOONWELL,
                        vec![lua_table(vec![
                            ("seconds", ScriptValue::Int(i64::from(moonwell.seconds))),
                            ("inside", ScriptValue::Bool(moonwell.inside)),
                            ("total", ScriptValue::Int(i64::from(moonwell.total))),
                        ])],
                    );
                }
                HoaMessage::LeyBlessings(_) => {
                    script.fire_event(HOA_LEY_BLESSINGS, Vec::new());
                }
                HoaMessage::LeyBless(bless) => {
                    script.fire_event(
                        HOA_LEY_BLESS,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(bless.name)),
                            ("icon", ScriptValue::Str(bless.icon)),
                            ("text", ScriptValue::Str(bless.text)),
                        ])],
                    );
                }
                HoaMessage::LeyBlessEnd(_) => {
                    script.fire_event(HOA_LEY_BLESS_END, Vec::new());
                }
                HoaMessage::EventTimer(timer) => {
                    script.fire_event(
                        HOA_EVENT_TIMER,
                        vec![lua_table(vec![
                            ("label", ScriptValue::Str(timer.label)),
                            ("seconds", ScriptValue::Int(i64::from(timer.seconds))),
                            ("total", ScriptValue::Int(i64::from(timer.total))),
                        ])],
                    );
                }
                HoaMessage::Starter(starter) => {
                    script.fire_event(
                        HOA_STARTER,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(starter.id))),
                            ("icon", ScriptValue::Str(starter.icon)),
                            ("name", ScriptValue::Str(starter.name)),
                            ("unlocked", ScriptValue::Bool(starter.unlocked)),
                            ("chosen", ScriptValue::Bool(starter.chosen)),
                            ("hint", ScriptValue::Str(starter.hint)),
                            ("description", ScriptValue::Str(starter.description)),
                        ])],
                    );
                }
                HoaMessage::StarterEnd(_) => {
                    script.fire_event(HOA_STARTER_END, Vec::new());
                }
                HoaMessage::ReachRing(ring) => {
                    script.fire_event(
                        HOA_REACH_RING,
                        vec![lua_table(vec![
                            ("spell_id", ScriptValue::Int(i64::from(ring.spell_id))),
                            ("slot", ScriptValue::Int(i64::from(ring.slot))),
                        ])],
                    );
                }
                HoaMessage::DruidForm(form) => {
                    script.fire_event(
                        HOA_DRUID_FORM,
                        vec![lua_table(vec![("form", ScriptValue::Str(form.form))])],
                    );
                }
                HoaMessage::Greed(greed) => {
                    script.fire_event(
                        HOA_GREED,
                        vec![lua_table(vec![
                            ("stacks", ScriptValue::Int(i64::from(greed.stacks))),
                            ("reward_percent", ScriptValue::Int(i64::from(greed.reward_percent))),
                            ("mob_percent", ScriptValue::Int(i64::from(greed.mob_percent))),
                        ])],
                    );
                }
                HoaMessage::Hearth(hearth) => {
                    script.fire_event(
                        HOA_HEARTH,
                        vec![lua_table(vec![
                            ("percent", ScriptValue::Int(i64::from(hearth.percent))),
                            ("inside", ScriptValue::Bool(hearth.inside)),
                            ("seconds", ScriptValue::Int(i64::from(hearth.seconds))),
                        ])],
                    );
                }
                HoaMessage::CoopWait(wait) => {
                    script.fire_event(
                        HOA_COOP_WAIT,
                        vec![lua_table(vec![
                            ("names", ScriptValue::Str(wait.names)),
                            ("seconds", ScriptValue::Int(i64::from(wait.seconds))),
                        ])],
                    );
                }
                HoaMessage::CoopWatch(watch) => {
                    script.fire_event(
                        HOA_COOP_WATCH,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(watch.name)),
                            ("choices", ScriptValue::Int(i64::from(watch.choices))),
                        ])],
                    );
                }
                HoaMessage::CoopRemoved(_) => {
                    script.fire_event(HOA_COOP_REMOVED, Vec::new());
                }
                HoaMessage::CoopDown(down) => {
                    script.fire_event(
                        HOA_COOP_DOWN,
                        vec![lua_table(vec![
                            ("pool", ScriptValue::Int(i64::from(down.pool))),
                            ("cap", ScriptValue::Int(i64::from(down.cap))),
                            ("list", ScriptValue::Str(down.list)),
                        ])],
                    );
                }
                HoaMessage::Leash(leash) => {
                    script.fire_event(
                        HOA_LEASH,
                        vec![lua_table(vec![
                            ("distance", ScriptValue::Int(i64::from(leash.distance))),
                            ("radius", ScriptValue::Int(i64::from(leash.radius))),
                            ("slow_percent", ScriptValue::Int(i64::from(leash.slow_percent))),
                        ])],
                    );
                }
                HoaMessage::CoopReady(ready) => {
                    script.fire_event(
                        HOA_COOP_READY,
                        vec![lua_table(vec![
                            ("text", ScriptValue::Str(ready.text)),
                            ("seconds", ScriptValue::Int(i64::from(ready.seconds))),
                        ])],
                    );
                }
                HoaMessage::CoopReadyEnd(_) => {
                    script.fire_event(HOA_COOP_READY_END, Vec::new());
                }
                HoaMessage::MasteryState(mastery) => {
                    script.fire_event(
                        HOA_MASTERY_STATE,
                        vec![lua_table(vec![
                            ("class_name", ScriptValue::Str(mastery.class_name)),
                            ("level", ScriptValue::Int(i64::from(mastery.level))),
                            ("xp", ScriptValue::Int(i64::from(mastery.xp))),
                            ("next", ScriptValue::Int(i64::from(mastery.next))),
                            ("max_level", ScriptValue::Int(i64::from(mastery.max_level))),
                            ("unspent", ScriptValue::Int(i64::from(mastery.unspent))),
                            ("trees", ScriptValue::Bool(mastery.trees)),
                        ])],
                    );
                }
                HoaMessage::Wallet(wallet) => {
                    script.fire_event(
                        HOA_WALLET,
                        vec![lua_table(vec![("shards", ScriptValue::Int(i64::from(wallet.shards)))])],
                    );
                }
                HoaMessage::Notice(notice) => {
                    script.fire_event(
                        HOA_NOTICE,
                        vec![lua_table(vec![("kind", ScriptValue::Str(notice.kind))])],
                    );
                }
                HoaMessage::Message(message) => {
                    script.fire_event(
                        HOA_MESSAGE,
                        vec![lua_table(vec![("text", ScriptValue::Str(message.text))])],
                    );
                }
                HoaMessage::Find(find) => {
                    script.fire_event(
                        HOA_FIND,
                        vec![lua_table(vec![("text", ScriptValue::Str(find.text))])],
                    );
                }
                HoaMessage::NpcName(name) => {
                    script.fire_event(
                        HOA_NPC_NAME,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(name.name)),
                            ("npc_name", ScriptValue::Str(name.npc_name)),
                        ])],
                    );
                }
                HoaMessage::Shard(shard) => {
                    script.fire_event(
                        HOA_SHARD,
                        vec![lua_table(vec![
                            ("count", ScriptValue::Int(i64::from(shard.count))),
                            ("total", ScriptValue::Int(i64::from(shard.total))),
                        ])],
                    );
                }
                HoaMessage::Valor(_) => {
                    script.fire_event(HOA_VALOR, Vec::new());
                }
                HoaMessage::EpicLuck(luck) => {
                    script.fire_event(
                        HOA_EPIC_LUCK,
                        vec![lua_table(vec![("bonus", ScriptValue::Int(i64::from(luck.bonus)))])],
                    );
                }
                HoaMessage::Cards(cards) => {
                    script.fire_event(
                        HOA_CARDS,
                        vec![lua_table(vec![("entries", ScriptValue::Str(cards.entries))])],
                    );
                }
                HoaMessage::CardTip(tip) => {
                    script.fire_event(
                        HOA_CARD_TIP,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(tip.id))),
                            ("name", ScriptValue::Str(tip.name)),
                            ("description", ScriptValue::Str(tip.description)),
                        ])],
                    );
                }
                HoaMessage::CardCooldown(cooldown) => {
                    script.fire_event(
                        HOA_CARD_COOLDOWN,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(cooldown.id))),
                            ("left_ms", ScriptValue::Int(i64::from(cooldown.left_ms))),
                            ("total_ms", ScriptValue::Int(i64::from(cooldown.total_ms))),
                        ])],
                    );
                }
                HoaMessage::CardNow(now) => {
                    script.fire_event(
                        HOA_CARD_NOW,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(now.id))),
                            ("text", ScriptValue::Str(now.text)),
                        ])],
                    );
                }
                HoaMessage::EnchantClear(_) => {
                    script.fire_event(HOA_ENCHANT_CLEAR, Vec::new());
                }
                HoaMessage::EnchantInfo(info) => {
                    script.fire_event(
                        HOA_ENCHANT_INFO,
                        vec![lua_table(vec![
                            ("cost", ScriptValue::Int(i64::from(info.cost))),
                            ("valor", ScriptValue::Int(i64::from(info.valor))),
                        ])],
                    );
                }
                HoaMessage::EnchantSlot(slot) => {
                    script.fire_event(
                        HOA_ENCHANT_SLOT,
                        vec![lua_table(vec![
                            ("slot", ScriptValue::Int(i64::from(slot.slot))),
                            ("effect", ScriptValue::Int(i64::from(slot.effect))),
                            ("grade", ScriptValue::Int(i64::from(slot.grade))),
                            ("value", ScriptValue::Number(f64::from(slot.value))),
                            ("percent", ScriptValue::Number(f64::from(slot.percent))),
                        ])],
                    );
                }
                HoaMessage::EnchantOffer(offer) => {
                    script.fire_event(
                        HOA_ENCHANT_OFFER,
                        vec![lua_table(vec![
                            ("slot", ScriptValue::Int(i64::from(offer.slot))),
                            ("index", ScriptValue::Int(i64::from(offer.index))),
                            ("effect", ScriptValue::Int(i64::from(offer.effect))),
                            ("grade", ScriptValue::Int(i64::from(offer.grade))),
                            ("value", ScriptValue::Number(f64::from(offer.value))),
                            ("percent", ScriptValue::Number(f64::from(offer.percent))),
                        ])],
                    );
                }
                HoaMessage::EnchantEnd(_) => {
                    script.fire_event(HOA_ENCHANT_END, Vec::new());
                }
                HoaMessage::EnchantOpen(_) => {
                    script.fire_event(HOA_ENCHANT_OPEN, Vec::new());
                }
                HoaMessage::EnchantClose(_) => {
                    script.fire_event(HOA_ENCHANT_CLOSE, Vec::new());
                }
                HoaMessage::VaultClear(_) => {
                    script.fire_event(HOA_VAULT_CLEAR, Vec::new());
                }
                HoaMessage::VaultSent(_) => {
                    script.fire_event(HOA_VAULT_SENT, Vec::new());
                }
                HoaMessage::VaultSentItem(item) => {
                    script.fire_event(
                        HOA_VAULT_SENT_ITEM,
                        vec![lua_table(vec![
                            ("entry", ScriptValue::Int(i64::from(item.entry))),
                            ("stage", ScriptValue::Int(i64::from(item.stage))),
                            ("tier", ScriptValue::Int(i64::from(item.tier))),
                            ("lines", ScriptValue::Str(item.lines)),
                            ("extra", ScriptValue::Str(item.extra)),
                        ])],
                    );
                }
                HoaMessage::VaultItem(item) => {
                    script.fire_event(
                        HOA_VAULT_ITEM,
                        vec![lua_table(vec![
                            ("guid", ScriptValue::Int(i64::from(item.guid))),
                            ("entry", ScriptValue::Int(i64::from(item.entry))),
                            ("quality", ScriptValue::Int(i64::from(item.quality))),
                            ("worn", ScriptValue::Bool(item.worn)),
                            ("sell_copper", ScriptValue::Int(i64::from(item.sell_copper))),
                            ("saved", ScriptValue::Str(item.saved)),
                            ("tier", ScriptValue::Int(i64::from(item.tier))),
                            ("best", ScriptValue::Int(i64::from(item.best))),
                            ("owned", ScriptValue::Bool(item.owned)),
                            ("scrap", ScriptValue::Int(i64::from(item.scrap))),
                            ("lines", ScriptValue::Str(item.lines)),
                            ("extra", ScriptValue::Str(item.extra)),
                        ])],
                    );
                }
                HoaMessage::VaultOpen(open) => {
                    script.fire_event(
                        HOA_VAULT_OPEN,
                        vec![lua_table(vec![
                            ("slots", ScriptValue::Int(i64::from(open.slots))),
                            ("chosen", ScriptValue::Str(open.chosen)),
                            ("mode", ScriptValue::Str(open.mode)),
                            ("scrap_bonus", ScriptValue::Int(i64::from(open.scrap_bonus))),
                        ])],
                    );
                }
                HoaMessage::VaultClose(_) => {
                    script.fire_event(HOA_VAULT_CLOSE, Vec::new());
                }
                HoaMessage::FoundClear(_) => {
                    script.fire_event(HOA_FOUND_CLEAR, Vec::new());
                }
                HoaMessage::FoundItem(item) => {
                    script.fire_event(
                        HOA_FOUND_ITEM,
                        vec![lua_table(vec![
                            ("place", ScriptValue::Str(item.place)),
                            ("entry", ScriptValue::Int(i64::from(item.entry))),
                            ("tier", ScriptValue::Int(i64::from(item.tier))),
                            ("lines", ScriptValue::Str(item.lines)),
                            ("extra", ScriptValue::Str(item.extra)),
                            ("legacy", ScriptValue::Bool(item.legacy)),
                        ])],
                    );
                }
                HoaMessage::FoundEnd(_) => {
                    script.fire_event(HOA_FOUND_END, Vec::new());
                }
                HoaMessage::GearOffer(offer) => {
                    script.fire_event(
                        HOA_GEAR_OFFER,
                        vec![lua_table(vec![
                            ("entry", ScriptValue::Int(i64::from(offer.entry))),
                            ("replaced", ScriptValue::Int(i64::from(offer.replaced))),
                            ("valor", ScriptValue::Int(i64::from(offer.valor))),
                            ("quality", ScriptValue::Int(i64::from(offer.quality))),
                            ("tier", ScriptValue::Int(i64::from(offer.tier))),
                            ("lines", ScriptValue::Str(offer.lines)),
                            ("slot", ScriptValue::Int(i64::from(offer.slot))),
                            ("other_slot", ScriptValue::Int(i64::from(offer.other_slot))),
                            ("other_replaced", ScriptValue::Int(i64::from(offer.other_replaced))),
                            ("extra", ScriptValue::Str(offer.extra)),
                        ])],
                    );
                }
                HoaMessage::GearClose(_) => {
                    script.fire_event(HOA_GEAR_CLOSE, Vec::new());
                }
                HoaMessage::QuestLogOpen(open) => {
                    script.fire_event(
                        HOA_QUEST_LOG_OPEN,
                        vec![lua_table(vec![("npc", ScriptValue::Str(open.npc))])],
                    );
                }
                HoaMessage::QuestEntry(quest) => {
                    script.fire_event(
                        HOA_QUEST_ENTRY,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(quest.id))),
                            ("name", ScriptValue::Str(quest.name)),
                            ("description", ScriptValue::Str(quest.description)),
                            ("icon", ScriptValue::Str(quest.icon)),
                            ("progress", ScriptValue::Int(i64::from(quest.progress))),
                            ("amount", ScriptValue::Int(i64::from(quest.amount))),
                            ("completed", ScriptValue::Bool(quest.completed)),
                            ("reward", ScriptValue::Str(quest.reward)),
                            ("reward_icon", ScriptValue::Str(quest.reward_icon)),
                            ("class_only", ScriptValue::Bool(quest.class_only)),
                            ("category", ScriptValue::Str(quest.category)),
                        ])],
                    );
                }
                HoaMessage::QuestLogEnd(_) => {
                    script.fire_event(HOA_QUEST_LOG_END, Vec::new());
                }
                HoaMessage::QuestDone(done) => {
                    script.fire_event(
                        HOA_QUEST_DONE,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(done.id))),
                            ("name", ScriptValue::Str(done.name)),
                            ("reward", ScriptValue::Str(done.reward)),
                            ("icon", ScriptValue::Str(done.icon)),
                        ])],
                    );
                }
                HoaMessage::VendorOpen(open) => {
                    script.fire_event(
                        HOA_VENDOR_OPEN,
                        vec![lua_table(vec![
                            ("coins", ScriptValue::Int(i64::from(open.coins))),
                            ("reroll_cost", ScriptValue::Int(i64::from(open.reroll_cost))),
                            ("seconds", ScriptValue::Int(i64::from(open.seconds))),
                            ("name", ScriptValue::Str(open.name)),
                            ("restocks", ScriptValue::Int(i64::from(open.restocks))),
                        ])],
                    );
                }
                HoaMessage::VendorSlot(slot) => {
                    script.fire_event(
                        HOA_VENDOR_SLOT,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(slot.index))),
                            ("kind", ScriptValue::Str(slot.kind)),
                            ("rank", ScriptValue::Int(i64::from(slot.rank))),
                            ("max_rank", ScriptValue::Int(i64::from(slot.max_rank))),
                            ("name", ScriptValue::Str(slot.name)),
                            ("icon", ScriptValue::Str(slot.icon)),
                            ("description", ScriptValue::Str(slot.description)),
                            ("rarity", ScriptValue::Str(slot.rarity)),
                            ("locked", ScriptValue::Bool(slot.locked)),
                            ("price", ScriptValue::Int(i64::from(slot.price))),
                            ("state", ScriptValue::Int(i64::from(slot.state))),
                        ])],
                    );
                }
                HoaMessage::VendorEnd(_) => {
                    script.fire_event(HOA_VENDOR_END, Vec::new());
                }
                HoaMessage::VendorClose(_) => {
                    script.fire_event(HOA_VENDOR_CLOSE, Vec::new());
                }
                HoaMessage::PortalHome(home) => {
                    script.fire_event(
                        HOA_PORTAL_HOME,
                        vec![lua_table(vec![
                            ("vault_empty", ScriptValue::Bool(home.vault_empty)),
                            ("finale", ScriptValue::Bool(home.finale)),
                        ])],
                    );
                }
                HoaMessage::PortalEndless(_) => {
                    script.fire_event(HOA_PORTAL_ENDLESS, Vec::new());
                }
                HoaMessage::GlyphOffer(offer) => {
                    script.fire_event(
                        HOA_GLYPH_OFFER,
                        vec![lua_table(vec![
                            ("picks_given", ScriptValue::Int(i64::from(offer.picks_given))),
                            ("count", ScriptValue::Int(i64::from(offer.count))),
                            ("rerolls", ScriptValue::Int(i64::from(offer.rerolls))),
                        ])],
                    );
                }
                HoaMessage::GlyphOption(option) => {
                    script.fire_event(
                        HOA_GLYPH_OPTION,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(option.index))),
                            ("id", ScriptValue::Int(i64::from(option.id))),
                        ])],
                    );
                }
                HoaMessage::GlyphOfferEnd(_) => {
                    script.fire_event(HOA_GLYPH_OFFER_END, Vec::new());
                }
                HoaMessage::GlyphClose(_) => {
                    script.fire_event(HOA_GLYPH_CLOSE, Vec::new());
                }
                HoaMessage::GlyphTaken(taken) => {
                    script.fire_event(
                        HOA_GLYPH_TAKEN,
                        vec![lua_table(vec![("ids", ScriptValue::Str(taken.ids))])],
                    );
                }
                HoaMessage::GlyphInfo(info) => {
                    script.fire_event(
                        HOA_GLYPH_INFO,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(info.id))),
                            ("name", ScriptValue::Str(info.name)),
                            ("icon", ScriptValue::Str(info.icon)),
                            ("rarity", ScriptValue::Int(i64::from(info.rarity))),
                            ("description", ScriptValue::Str(info.description)),
                            ("drawback", ScriptValue::Str(info.drawback)),
                        ])],
                    );
                }
                HoaMessage::GlyphCount(count) => {
                    script.fire_event(
                        HOA_GLYPH_COUNT,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(count.id))),
                            ("count", ScriptValue::Int(i64::from(count.count))),
                        ])],
                    );
                }
                HoaMessage::OfferOpen(offer) => {
                    script.fire_event(
                        HOA_OFFER_OPEN,
                        vec![lua_table(vec![
                            ("level", ScriptValue::Int(i64::from(offer.level))),
                            ("count", ScriptValue::Int(i64::from(offer.count))),
                            ("source", ScriptValue::Str(offer.source)),
                            ("rerolls", ScriptValue::Int(i64::from(offer.rerolls))),
                            ("banishes", ScriptValue::Int(i64::from(offer.banishes))),
                            ("skips", ScriptValue::Int(i64::from(offer.skips))),
                        ])],
                    );
                }
                HoaMessage::OfferOption(option) => {
                    script.fire_event(
                        HOA_OFFER_OPTION,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(option.index))),
                            ("kind", ScriptValue::Str(option.kind)),
                            ("new_level", ScriptValue::Int(i64::from(option.new_level))),
                            ("max_level", ScriptValue::Int(i64::from(option.max_level))),
                            ("name", ScriptValue::Str(option.name)),
                            ("icon", ScriptValue::Str(option.icon)),
                            ("description", ScriptValue::Str(option.description)),
                            ("rarity", ScriptValue::Str(option.rarity)),
                            ("locked", ScriptValue::Bool(option.locked)),
                            ("damage_before", ScriptValue::Str(option.damage_before)),
                            ("damage_after", ScriptValue::Str(option.damage_after)),
                            ("damage_label", ScriptValue::Str(option.damage_label)),
                            ("banishable", ScriptValue::Bool(option.banishable)),
                        ])],
                    );
                }
                HoaMessage::OfferStat(stat) => {
                    script.fire_event(
                        HOA_OFFER_STAT,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(stat.index))),
                            ("label", ScriptValue::Str(stat.label)),
                            ("before", ScriptValue::Str(stat.before)),
                            ("after", ScriptValue::Str(stat.after)),
                        ])],
                    );
                }
                HoaMessage::OfferEnd(_) => {
                    script.fire_event(HOA_OFFER_END, Vec::new());
                }
                HoaMessage::OfferClosed(_) => {
                    script.fire_event(HOA_OFFER_CLOSED, Vec::new());
                }
                HoaMessage::LeyOpen(open) => {
                    script.fire_event(
                        HOA_LEY_OPEN,
                        vec![lua_table(vec![("count", ScriptValue::Int(i64::from(open.count)))])],
                    );
                }
                HoaMessage::LeyOption(option) => {
                    script.fire_event(
                        HOA_LEY_OPTION,
                        vec![lua_table(vec![
                            ("index", ScriptValue::Int(i64::from(option.index))),
                            ("name", ScriptValue::Str(option.name)),
                            ("icon", ScriptValue::Str(option.icon)),
                            ("description", ScriptValue::Str(option.description)),
                            ("rarity", ScriptValue::Int(i64::from(option.rarity))),
                            ("kind", ScriptValue::Str(option.kind)),
                            ("new_level", ScriptValue::Int(i64::from(option.new_level))),
                            ("max_level", ScriptValue::Int(i64::from(option.max_level))),
                        ])],
                    );
                }
                HoaMessage::LeyEnd(_) => {
                    script.fire_event(HOA_LEY_END, Vec::new());
                }
                HoaMessage::LeyClosed(_) => {
                    script.fire_event(HOA_LEY_CLOSED, Vec::new());
                }
                HoaMessage::Mob(mob) => {
                    script.fire_event(
                        HOA_MOB,
                        vec![lua_table(vec![
                            ("kind", ScriptValue::Int(i64::from(mob.kind))),
                            ("name", ScriptValue::Str(mob.name)),
                            ("icons", ScriptValue::Str(mob.icons)),
                            ("plate_id", ScriptValue::Int(i64::from(mob.plate_id))),
                            ("guid", ScriptValue::Str(mob.guid)),
                        ])],
                    );
                }
                HoaMessage::MobDead(dead) => {
                    script.fire_event(
                        HOA_MOB_DEAD,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(dead.name)),
                            ("plate_id", ScriptValue::Int(i64::from(dead.plate_id))),
                            ("guid", ScriptValue::Str(dead.guid)),
                        ])],
                    );
                }
                HoaMessage::MobClear(_) => {
                    script.fire_event(HOA_MOB_CLEAR, Vec::new());
                }
                HoaMessage::Ally(ally) => {
                    script.fire_event(
                        HOA_ALLY,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(ally.name)),
                            ("plate_id", ScriptValue::Int(i64::from(ally.plate_id))),
                            ("guid", ScriptValue::Str(ally.guid)),
                        ])],
                    );
                }
                HoaMessage::AllyDone(done) => {
                    script.fire_event(
                        HOA_ALLY_DONE,
                        vec![lua_table(vec![
                            ("plate_id", ScriptValue::Int(i64::from(done.plate_id))),
                            ("guid", ScriptValue::Str(done.guid)),
                        ])],
                    );
                }
                HoaMessage::AffixInfo(info) => {
                    script.fire_event(
                        HOA_AFFIX_INFO,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(info.name)),
                            ("icon", ScriptValue::Str(info.icon)),
                            ("description", ScriptValue::Str(info.description)),
                        ])],
                    );
                }
                HoaMessage::Objective(objective) => {
                    script.fire_event(
                        HOA_OBJECTIVE,
                        vec![lua_table(vec![
                            ("id", ScriptValue::Int(i64::from(objective.id))),
                            ("kind", ScriptValue::Str(objective.kind)),
                            ("x", ScriptValue::Number(f64::from(objective.x))),
                            ("y", ScriptValue::Number(f64::from(objective.y))),
                            ("map_id", ScriptValue::Int(i64::from(objective.map_id))),
                            ("label", ScriptValue::Str(objective.label)),
                            ("seconds", ScriptValue::Int(i64::from(objective.seconds))),
                            ("icon", ScriptValue::Str(objective.icon)),
                            ("description", ScriptValue::Str(objective.description)),
                        ])],
                    );
                }
                HoaMessage::ObjectiveClear(clear) => {
                    script.fire_event(
                        HOA_OBJECTIVE_CLEAR,
                        vec![lua_table(vec![("id", ScriptValue::Int(i64::from(clear.id)))])],
                    );
                }
                HoaMessage::ObjectivePing(ping) => {
                    script.fire_event(
                        HOA_OBJECTIVE_PING,
                        vec![lua_table(vec![("id", ScriptValue::Int(i64::from(ping.id)))])],
                    );
                }
                HoaMessage::RunSupport(support) => {
                    script.fire_event(HOA_RUN_SUPPORT, vec![lua_table(vec![("text", ScriptValue::Str(support.text))])]);
                }
                HoaMessage::RunGlyphMeter(meter) => {
                    script.fire_event(HOA_RUN_GLYPH_METER, vec![lua_table(vec![("text", ScriptValue::Str(meter.text))])]);
                }
                HoaMessage::RunOtherMeter(meter) => {
                    script.fire_event(HOA_RUN_OTHER_METER, vec![lua_table(vec![("text", ScriptValue::Str(meter.text))])]);
                }
                HoaMessage::RunPartyMeter(meter) => {
                    script.fire_event(HOA_RUN_PARTY_METER, vec![lua_table(vec![("text", ScriptValue::Str(meter.text))])]);
                }
                HoaMessage::RunPaused(paused) => {
                    script.fire_event(
                        HOA_RUN_PAUSED,
                        vec![lua_table(vec![("paused", ScriptValue::Bool(paused.paused))])],
                    );
                }
                HoaMessage::CoopNoPause(no_pause) => {
                    script.fire_event(
                        HOA_COOP_NO_PAUSE,
                        vec![lua_table(vec![("no_pause", ScriptValue::Bool(no_pause.no_pause))])],
                    );
                }
                HoaMessage::RunXp(xp) => {
                    script.fire_event(
                        HOA_RUN_XP,
                        vec![lua_table(vec![
                            ("level", ScriptValue::Int(i64::from(xp.level))),
                            ("xp", ScriptValue::Int(i64::from(xp.xp))),
                            ("next", ScriptValue::Int(i64::from(xp.next))),
                            ("orbs", ScriptValue::Int(i64::from(xp.orbs))),
                        ])],
                    );
                }
                HoaMessage::WaveBeat(beat) => {
                    script.fire_event(
                        HOA_WAVE_BEAT,
                        vec![lua_table(vec![
                            ("name", ScriptValue::Str(beat.name)),
                            ("beat", ScriptValue::Int(i64::from(beat.beat))),
                            ("seconds", ScriptValue::Int(i64::from(beat.seconds))),
                        ])],
                    );
                }
                HoaMessage::RunStart(start) => {
                    script.fire_event(
                        HOA_RUN_START,
                        vec![lua_table(vec![
                            ("map_name", ScriptValue::Str(start.map_name)),
                            ("difficulty", ScriptValue::Str(start.difficulty)),
                            ("duration_s", ScriptValue::Int(i64::from(start.duration_s))),
                            ("stage", ScriptValue::Int(i64::from(start.stage))),
                            ("first_miniboss_s", ScriptValue::Int(i64::from(start.first_miniboss_s))),
                            ("timeline_marks", ScriptValue::Str(start.timeline_marks)),
                            ("mythic", ScriptValue::Bool(start.mythic)),
                            ("stages", ScriptValue::Int(i64::from(start.stages))),
                            ("level_name", ScriptValue::Str(start.level_name)),
                            ("finale", ScriptValue::Bool(start.finale)),
                            ("sandbox", ScriptValue::Bool(start.sandbox)),
                        ])],
                    );
                }
                HoaMessage::RunEnd(end) => {
                    script.fire_event(
                        HOA_RUN_END,
                        vec![lua_table(vec![
                            ("went_home", ScriptValue::Bool(end.went_home)),
                            ("seconds", ScriptValue::Int(i64::from(end.seconds))),
                            ("kills", ScriptValue::Int(i64::from(end.kills))),
                            ("gold", ScriptValue::Int(i64::from(end.gold))),
                            ("player_level", ScriptValue::Int(i64::from(end.player_level))),
                            ("stage", ScriptValue::Int(i64::from(end.stage))),
                            ("shards", ScriptValue::Int(i64::from(end.shards))),
                            ("victory", ScriptValue::Bool(end.victory)),
                            ("mythic", ScriptValue::Bool(end.mythic)),
                            ("best_level", ScriptValue::Int(i64::from(end.best_level))),
                            ("best_before", ScriptValue::Int(i64::from(end.best_before))),
                            ("level_name", ScriptValue::Str(end.level_name)),
                            ("finale_seconds", ScriptValue::Int(i64::from(end.finale_seconds))),
                        ])],
                    );
                }
                HoaMessage::RunState(state) => {
                    script.fire_event(
                        HOA_RUN_STATE,
                        vec![ScriptValue::Table(vec![
                            ("elapsed_s".into(), ScriptValue::Int(i64::from(state.elapsed_s))),
                            ("duration_s".into(), ScriptValue::Int(i64::from(state.duration_s))),
                            ("kills".into(), ScriptValue::Int(i64::from(state.kills))),
                            ("gold_earned".into(), ScriptValue::Int(i64::from(state.gold_earned))),
                            ("player_level".into(), ScriptValue::Int(i64::from(state.player_level))),
                            ("boss_spawned".into(), ScriptValue::Bool(state.boss_spawned)),
                            ("coins".into(), ScriptValue::Int(i64::from(state.coins))),
                            ("chest_price".into(), ScriptValue::Int(i64::from(state.chest_price))),
                            ("stage".into(), ScriptValue::Int(i64::from(state.stage))),
                            ("portal".into(), ScriptValue::Bool(state.portal)),
                            ("shards_earned".into(), ScriptValue::Int(i64::from(state.shards_earned))),
                            ("weapon_stats".into(), ScriptValue::Str(state.weapon_stats)),
                            ("total_s".into(), ScriptValue::Int(i64::from(state.total_s))),
                            ("damage_types".into(), ScriptValue::Str(state.damage_types)),
                        ])],
                    );
                }
                HoaMessage::AuraValue(aura) => {
                    script.fire_event(
                        HOA_AURA_VALUE,
                        vec![
                            ScriptValue::Int(i64::from(aura.spell_id)),
                            ScriptValue::Int(i64::from(aura.value)),
                            ScriptValue::Int(i64::from(aura.max_value)),
                        ],
                    );
                }
                HoaMessage::AuraText(text) => {
                    value_texts.push((text.spell_id, text.text));
                }
                HoaMessage::AuraPercent(percent) => {
                    script.fire_event(
                        HOA_AURA_PERCENT,
                        vec![
                            ScriptValue::Int(i64::from(percent.spell_id)),
                            ScriptValue::Number(f64::from(percent.percent)),
                        ],
                    );
                }
                HoaMessage::Dash(dash) => {
                    script.fire_event(
                        HOA_DASH,
                        vec![
                            ScriptValue::Int(i64::from(dash.max_charges)),
                            ScriptValue::Int(i64::from(dash.recharge_ms)),
                            ScriptValue::Int(i64::from(dash.cooldown_ms)),
                            ScriptValue::Bool(dash.blink),
                            ScriptValue::Int(i64::from(dash.charges)),
                        ],
                    );
                }
                HoaMessage::AuraCatalogEntry(entry) => {
                    if entry.index == 0 || !catalog_active {
                        catalog_rows.clear();
                        catalog_active = true;
                    }
                    catalog_total = entry.total;
                    catalog_rows.push(HoaAuraRow {
                        id: entry.spell_id,
                        name: entry.name,
                        icon: entry.icon,
                        description: entry.description,
                        stack_amount: entry.stack,
                        duration_index: entry.duration,
                    });
                }
                HoaMessage::AuraCatalogEnd(end) => {
                    catalog_total = end.total;
                    catalog_done = true;
                }
                HoaMessage::VisualMark(mark) => draws.push(DrawCommand::from(mark)),
                HoaMessage::VisualMarkRemove(mark) => draws.push(DrawCommand::from(mark)),
                HoaMessage::VisualTelegraphClear(clear) => draws.push(DrawCommand::from(clear)),
                HoaMessage::VisualClear(clear) => draws.push(DrawCommand::from(clear)),
                HoaMessage::VisualKit(kit) => draws.push(DrawCommand::from(kit)),
                HoaMessage::VisualFlight(flight) => draws.push(DrawCommand::from(flight)),
                HoaMessage::VisualLand(land) => draws.push(DrawCommand::from(land)),
                HoaMessage::VisualMissile(missile) => draws.push(DrawCommand::from(missile)),
                HoaMessage::VisualProp(prop) => draws.push(DrawCommand::from(prop)),
                HoaMessage::VisualPropRemove(prop) => draws.push(DrawCommand::from(prop)),
                HoaMessage::VisualAura(aura) => draws.push(DrawCommand::from(aura)),
                HoaMessage::VisualAuraRemove(aura) => draws.push(DrawCommand::from(aura)),
                HoaMessage::Hello(hello) => {
                    let check = HelloCheck::of(
                        hello.protocol_version,
                        &hello.content_hash,
                        &hello.content_sections,
                    );
                    if check.protocol_mismatch {
                        warn!(
                            "hoa protocol: server speaks {}, this build speaks {PROTOCOL_VERSION}",
                            hello.protocol_version
                        );
                    }
                    if check.content_mismatch {
                        warn!(
                            "hoa protocol: server content {} does not match this build's {CONTENT_HASH} (changed: {})",
                            hello.content_hash,
                            check.changed_sections.join(", ")
                        );
                    }
                    if check.compatible() {
                        script.fire_event(
                            HOA_HELLO,
                            vec![
                                ScriptValue::Int(i64::from(hello.protocol_version)),
                                ScriptValue::Str(hello.content_hash),
                                ScriptValue::Str(hello.language),
                            ],
                        );
                    } else {
                        let changed = check.changed_sections.join(", ");
                        script.fire_event(
                            HOA_INCOMPATIBLE,
                            vec![lua_table(vec![
                                ("protocol_version", ScriptValue::Int(i64::from(hello.protocol_version))),
                                ("expected_protocol", ScriptValue::Int(i64::from(PROTOCOL_VERSION))),
                                ("content_hash", ScriptValue::Str(hello.content_hash)),
                                ("expected_content", ScriptValue::Str(CONTENT_HASH.to_string())),
                                ("protocol_mismatch", ScriptValue::Bool(check.protocol_mismatch)),
                                ("content_mismatch", ScriptValue::Bool(check.content_mismatch)),
                                ("changed_sections", ScriptValue::Str(changed.clone())),
                            ])],
                        );
                        // The addon's event frame is not always live when hello lands; call its
                        // warning directly so a mismatch can never pass silently.
                        let changed = changed.replace('\\', "\\\\").replace('\'', "\\'");
                        let warning = format!(
                            "if VanillaBonkUI and VanillaBonkUI.ShowProtocolWarning then \
                             VanillaBonkUI.ShowProtocolWarning({}, {}, {}, {}, '{}') \
                             else DEFAULT_CHAT_FRAME:AddMessage('Hordes of Azeroth: the server and this client use different versions. Update the game.') end",
                            hello.protocol_version,
                            PROTOCOL_VERSION,
                            check.protocol_mismatch,
                            check.content_mismatch,
                            changed,
                        );
                        if let Err(error) = script.run(&warning) {
                            warn!("hoa protocol: could not show the mismatch warning: {error}");
                        }
                    }
                }
            }
        }
    });
    for (spell_id, description) in value_texts {
        benilla_app::set_hoa_spell_description(world, spell_id, description);
    }
    if catalog_done {
        if catalog_rows.len() != usize::from(catalog_total) {
            warn!(
                "hoa protocol: aura catalog has {} rows, expected {catalog_total}",
                catalog_rows.len()
            );
        }
        if benilla_app::set_hoa_aura_catalog(world, &catalog_rows) {
            let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
            buffer.active = false;
            buffer.pending = false;
            buffer.rows.clear();
        } else {
            let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
            buffer.rows = catalog_rows;
            buffer.total = catalog_total;
            buffer.active = false;
            buffer.pending = true;
        }
    } else if catalog_active {
        let mut buffer = world.resource_mut::<AuraCatalogBuffer>();
        buffer.rows = catalog_rows;
        buffer.total = catalog_total;
        buffer.active = true;
    }
    for draw in draws {
        world.write_message(DrawCommandMessage(draw));
    }
    world.resource_mut::<HoaHandshake>().blocked = blocked;
    apply_pending_catalog(world);
}

pub struct HordesOfAzerothPlugin;

impl Plugin for HordesOfAzerothPlugin {
    fn build(&self, app: &mut App) {
        add_plate_events();
        add_in_game_event(HOA_HELLO);
        add_in_game_event(HOA_INCOMPATIBLE);
        add_in_game_event(HOA_AURA_VALUE);
        add_in_game_event(HOA_DASH);
        add_in_game_event(HOA_AURA_PERCENT);
        add_in_game_event(HOA_RUN_STATE);
        add_in_game_event(HOA_RUN_START);
        add_in_game_event(HOA_RUN_END);
        add_in_game_event(HOA_RUN_PAUSED);
        add_in_game_event(HOA_COOP_NO_PAUSE);
        add_in_game_event(HOA_RUN_XP);
        add_in_game_event(HOA_WAVE_BEAT);
        add_in_game_event(HOA_RUN_SUPPORT);
        add_in_game_event(HOA_RUN_GLYPH_METER);
        add_in_game_event(HOA_RUN_OTHER_METER);
        add_in_game_event(HOA_RUN_PARTY_METER);
        add_in_game_event(HOA_OBJECTIVE);
        add_in_game_event(HOA_OBJECTIVE_CLEAR);
        add_in_game_event(HOA_OBJECTIVE_PING);
        add_in_game_event(HOA_MOB);
        add_in_game_event(HOA_MOB_DEAD);
        add_in_game_event(HOA_MOB_CLEAR);
        add_in_game_event(HOA_ALLY);
        add_in_game_event(HOA_ALLY_DONE);
        add_in_game_event(HOA_AFFIX_INFO);
        add_in_game_event(HOA_OFFER_OPEN);
        add_in_game_event(HOA_OFFER_OPTION);
        add_in_game_event(HOA_OFFER_STAT);
        add_in_game_event(HOA_OFFER_END);
        add_in_game_event(HOA_OFFER_CLOSED);
        add_in_game_event(HOA_LEY_OPEN);
        add_in_game_event(HOA_LEY_OPTION);
        add_in_game_event(HOA_LEY_END);
        add_in_game_event(HOA_LEY_CLOSED);
        add_in_game_event(HOA_GLYPH_OFFER);
        add_in_game_event(HOA_GLYPH_OPTION);
        add_in_game_event(HOA_GLYPH_OFFER_END);
        add_in_game_event(HOA_GLYPH_CLOSE);
        add_in_game_event(HOA_GLYPH_TAKEN);
        add_in_game_event(HOA_GLYPH_INFO);
        add_in_game_event(HOA_GLYPH_COUNT);
        add_in_game_event(HOA_QUEST_LOG_OPEN);
        add_in_game_event(HOA_QUEST_ENTRY);
        add_in_game_event(HOA_QUEST_LOG_END);
        add_in_game_event(HOA_QUEST_DONE);
        add_in_game_event(HOA_VENDOR_OPEN);
        add_in_game_event(HOA_VENDOR_SLOT);
        add_in_game_event(HOA_VENDOR_END);
        add_in_game_event(HOA_VENDOR_CLOSE);
        add_in_game_event(HOA_PORTAL_HOME);
        add_in_game_event(HOA_PORTAL_ENDLESS);
        add_in_game_event(HOA_FOUND_CLEAR);
        add_in_game_event(HOA_FOUND_ITEM);
        add_in_game_event(HOA_FOUND_END);
        add_in_game_event(HOA_GEAR_OFFER);
        add_in_game_event(HOA_GEAR_CLOSE);
        add_in_game_event(HOA_VAULT_CLEAR);
        add_in_game_event(HOA_VAULT_SENT);
        add_in_game_event(HOA_VAULT_SENT_ITEM);
        add_in_game_event(HOA_VAULT_ITEM);
        add_in_game_event(HOA_VAULT_OPEN);
        add_in_game_event(HOA_VAULT_CLOSE);
        add_in_game_event(HOA_ENCHANT_CLEAR);
        add_in_game_event(HOA_ENCHANT_INFO);
        add_in_game_event(HOA_ENCHANT_SLOT);
        add_in_game_event(HOA_ENCHANT_OFFER);
        add_in_game_event(HOA_ENCHANT_END);
        add_in_game_event(HOA_ENCHANT_OPEN);
        add_in_game_event(HOA_ENCHANT_CLOSE);
        add_in_game_event(HOA_CARDS);
        add_in_game_event(HOA_CARD_TIP);
        add_in_game_event(HOA_CARD_COOLDOWN);
        add_in_game_event(HOA_CARD_NOW);
        add_in_game_event(HOA_MASTERY_STATE);
        add_in_game_event(HOA_WALLET);
        add_in_game_event(HOA_MOG_BEGIN);
        add_in_game_event(HOA_MOG_SLOT);
        add_in_game_event(HOA_MOG_LOOK);
        add_in_game_event(HOA_MOG_OUTFIT);
        add_in_game_event(HOA_MOG_END);
        add_in_game_event(HOA_HARDCORE_FELL);
        add_in_game_event(HOA_HARDCORE_RESTED);
        add_in_game_event(HOA_NOTICE);
        add_in_game_event(HOA_MESSAGE);
        add_in_game_event(HOA_FIND);
        add_in_game_event(HOA_NPC_NAME);
        add_in_game_event(HOA_SHARD);
        add_in_game_event(HOA_VALOR);
        add_in_game_event(HOA_EPIC_LUCK);
        add_in_game_event(HOA_COOP_WAIT);
        add_in_game_event(HOA_COOP_WATCH);
        add_in_game_event(HOA_COOP_REMOVED);
        add_in_game_event(HOA_COOP_DOWN);
        add_in_game_event(HOA_LEASH);
        add_in_game_event(HOA_COOP_READY);
        add_in_game_event(HOA_COOP_READY_END);
        add_in_game_event(HOA_STARTER);
        add_in_game_event(HOA_STARTER_END);
        add_in_game_event(HOA_REACH_RING);
        add_in_game_event(HOA_DRUID_FORM);
        add_in_game_event(HOA_GREED);
        add_in_game_event(HOA_HEARTH);
        add_in_game_event(HOA_CAPTURE);
        add_in_game_event(HOA_MOONWELL);
        add_in_game_event(HOA_LEY_BLESSINGS);
        add_in_game_event(HOA_LEY_BLESS);
        add_in_game_event(HOA_LEY_BLESS_END);
        add_in_game_event(HOA_EVENT_TIMER);
        add_in_game_event(HOA_DEATH_RECAP);
        add_in_game_event(HOA_DEATH_SOURCE);
        add_in_game_event(HOA_DEATH_EVENTS);
        add_in_game_event(HOA_RUN_SUMMARY);
        add_in_game_event(HOA_SUMMARY_WEAPON);
        add_in_game_event(HOA_SUMMARY_SPELL);
        add_in_game_event(HOA_SUMMARY_END);
        add_in_game_event(HOA_BOARD_OPEN);
        add_in_game_event(HOA_BOARD_HEADER);
        add_in_game_event(HOA_BOARD_ROW);
        add_in_game_event(HOA_BOARD_PAGE);
        add_in_game_event(HOA_BOARD_CHOICE);
        add_in_game_event(HOA_BOARD_END);
        add_in_game_event(HOA_SHOP_OPEN);
        add_in_game_event(HOA_SHOP_TREE);
        add_in_game_event(HOA_MASTERY_TREE);
        add_in_game_event(HOA_SHOP_NODE);
        add_in_game_event(HOA_MASTERY_NODE);
        add_in_game_event(HOA_MASTERY_PRESETS);
        add_in_game_event(HOA_MASTERY_PRESET_RANKS);
        add_in_game_event(HOA_SHOP_END);
        add_in_game_event(HOA_SHOP_CLOSE);
        add_in_game_event(HOA_GEAR);
        add_in_game_event(HOA_GEAR_END);
        add_in_game_event(HOA_TRINKET_TIP);
        add_in_game_event(HOA_ARENA);
        add_in_game_event(HOA_TIER);
        add_in_game_event(HOA_TIER_END);
        add_in_game_event(HOA_TIER_INFO);
        add_in_game_event(HOA_LEVEL_PREVIEW);
        add_in_game_event(HOA_LEVEL_BEST);
        add_in_game_event(HOA_MAP_INFO);
        add_in_game_event(HOA_ZONE_ART);
        add_in_game_event(HOA_CODEX);
        add_in_game_event(HOA_WEAPON_INFO);
        add_in_game_event(HOA_WEAPON_EVOLUTION);
        add_in_game_event(HOA_WEAPON_EVOLUTION_OPTION);
        add_in_game_event(HOA_COOLDOWN_PIE);
        add_in_game_event(HOA_QUARTERMASTER);
        add_in_game_event(HOA_QUARTERMASTER_UPGRADE_CLEAR);
        add_in_game_event(HOA_QUARTERMASTER_UPGRADE);
        add_in_game_event(HOA_QUARTERMASTER_UPGRADE_END);
        add_in_game_event(HOA_MUSIC);
        add_in_game_event(HOA_LOADOUT);
        add_in_game_event(HOA_DRUID_SLOTS);
        add_in_game_event(HOA_BOSS_BAR);
        add_in_game_event(HOA_TITLES);
        add_in_game_event(HOA_STATS);
        add_in_game_event(HOA_KEYWORD_TIMERS);
        let hosts = LuaHosts {
            snapshot: SharedSnapshot::default(),
            areas: SharedMapAreas::from_install(),
            interact: SharedInteract::default(),
            plates: SharedPlates::default(),
            typing: SharedTyping::default(),
            controller: SharedController::default(),
            scripted_login: scripted_login_from_env(),
        };
        app.add_plugins(bevy::gilrs::GilrsPlugin)
            .insert_non_send_resource(hosts.snapshot.clone())
            .insert_non_send_resource(hosts.interact.clone())
            .insert_non_send_resource(hosts.plates.clone())
            .insert_non_send_resource(hosts.typing.clone())
            .insert_non_send_resource(hosts.controller.clone())
            .init_resource::<Telegraphs>()
            .init_resource::<HoaInbox>()
            .init_resource::<HoaHandshake>()
            .add_message::<DrawCommandMessage>()
            .init_resource::<AuraCatalogBuffer>()
            .net_handler(SessionEventKind::HoaMessage, on_hoa_message)
            .insert_resource(DisplayModels::from_install())
            .add_systems(Startup, (name_window, announce_addon_folder))
            .add_systems(
                PreUpdate,
                (log_new_pads, notice_keyboard_and_mouse, poll_pads, drive_pad_cursor)
                    .chain()
                    .after(bevy::input::InputSystems),
            )
            .add_systems(
                Update,
                (
                    hide_cursor_for_pad,
                    (
                        apply_draw_lines,
                        move_flights,
                        expire_kit_anchors,
                        expire_telegraphs,
                        follow_marks,
                        project_telegraphs,
                    )
                        .chain(),
                ),
            )
            .add_systems(Last, crate::census::log_census.run_if(crate::census::census_wanted))
            .add_systems(Last, deliver_hoa_messages)
            .add_systems(Last, apply_pending_catalog.after(deliver_hoa_messages))
            .add_systems(
                PostUpdate,
                push_telegraphs.after(benilla_world::particles::buffer::begin_effect_frame),
            )
            .add_systems(
                Last,
                (
                    capture_snapshot,
                    update_interact,
                    track_nameplates,
                    capture_typing,
                    deliver_pad_events,
                )
                    .chain(),
            );
        benilla_app::seed_every_vm(app, move |script| hosts.seed(script));
    }
}

const WINDOW_TITLE: &str = "Hordes of Azeroth";

fn name_window(mut windows: Query<&mut Window>) {
    for mut window in &mut windows {
        window.title = WINDOW_TITLE.to_string();
    }
}

fn announce_addon_folder() {
    let addons = benilla_app::config_dir().map(|dir| dir.join("AddOns"));
    info!("Hordes of Azeroth plugin running; addons load from {addons:?}");
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A fired event name nobody registered is a silent no-op: `fire_event` dispatches nothing
    /// and an addon's `RegisterEvent` registers nothing, so a whole window can die without one
    /// error anywhere — the transmogrifier's `HOA_MOG_*` sat unfired exactly this way from the
    /// first hoa-core build until the live probe caught it. This reads the plugin's own source,
    /// as `every_handler_names_the_kind_it_registered_for` does for the net handlers, so a new
    /// message's event cannot land without its registration.
    #[test]
    fn every_fired_event_is_registered() {
        let source = std::fs::read_to_string(std::path::Path::new(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/src/plugin.rs"
        )))
        .expect("the plugin's own source");
        let constants: std::collections::HashMap<&str, &str> = source
            .lines()
            .filter_map(|line| {
                let line = line.trim();
                let rest = line.strip_prefix("const ")?;
                let name = rest.split(':').next()?.trim();
                let value = line.rsplit('"').nth(1)?;
                Some((name, value))
            })
            .collect();
        let registered: std::collections::HashSet<&str> = source
            .lines()
            .filter_map(|line| {
                let rest = line.trim().strip_prefix("add_in_game_event(")?;
                let name = rest.strip_suffix(");")?.trim();
                Some(constants.get(name).copied().unwrap_or(name))
            })
            .collect();
        assert!(
            registered.len() > 100,
            "the registration table vanished: {} events registered",
            registered.len()
        );
        let mut fired: Vec<&str> = Vec::new();
        for line in source.lines() {
            for call in line.match_indices("fire_event").map(|(at, _)| at) {
                let rest = &line[call + "fire_event".len()..];
                let rest = rest.trim_start().strip_prefix('(').unwrap_or(rest);
                let name = rest.split(',').next().unwrap_or("").trim();
                let name = name.trim_start_matches('&');
                let literal = name.strip_prefix('"').map(|rest| rest.split('"').next().unwrap_or(""));
                let resolved = literal
                    .map(|text| text)
                    .or_else(|| constants.get(name).copied());
                if let Some(event) = resolved {
                    if !event.starts_with("HOA_") {
                        continue; // a frame event of the wider client, not ours to register
                    }
                    fired.push(event);
                }
            }
        }
        let unregistered: Vec<&str> = {
            let mut seen = fired.clone();
            seen.sort_unstable();
            seen.dedup();
            seen.into_iter().filter(|event| !registered.contains(event)).collect()
        };
        assert!(
            unregistered.is_empty(),
            "events fired but never add_in_game_event'd (nobody hears them): {}",
            unregistered.join(", ")
        );
    }

    #[test]
    fn the_generated_hello_decoder_reads_the_wire_layout() {
        let sections = CONTENT_SECTIONS
            .iter()
            .map(|(name, hash)| format!("{name}={hash}"))
            .collect::<Vec<_>>()
            .join(";");
        let mut body = Vec::new();
        body.extend_from_slice(&PROTOCOL_VERSION.to_le_bytes());
        for text in [CONTENT_HASH, sections.as_str(), "zhCN"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        let Some(HoaMessage::Hello(hello)) = protocol_generated::decode(protocol_generated::MSG_HELLO, &body) else {
            panic!("hello did not decode");
        };
        assert_eq!(hello.protocol_version, PROTOCOL_VERSION);
        assert_eq!(hello.content_hash, CONTENT_HASH);
        assert_eq!(hello.content_sections, sections);
        assert_eq!(hello.language, "zhCN");
    }

    #[test]
    fn the_hello_check_rejects_protocol_and_content_mismatches() {
        let sections = CONTENT_SECTIONS
            .iter()
            .map(|(name, hash)| format!("{name}={hash}"))
            .collect::<Vec<_>>()
            .join(";");
        assert!(HelloCheck::of(PROTOCOL_VERSION, CONTENT_HASH, &sections).compatible());

        let protocol = HelloCheck::of(PROTOCOL_VERSION + 1, CONTENT_HASH, &sections);
        assert!(protocol.protocol_mismatch);
        assert!(!protocol.content_mismatch);
        assert!(!protocol.compatible());

        let content = HelloCheck::of(PROTOCOL_VERSION, "sha256:other", &sections);
        assert!(!content.protocol_mismatch);
        assert!(content.content_mismatch);
        assert!(!content.compatible());
        assert!(content.changed_sections.is_empty());
    }

    #[test]
    fn a_content_mismatch_names_the_changed_and_missing_sections() {
        let changed = changed_sections("cards=sha256:old;spells=sha256:old;tables=sha256:old");
        assert_eq!(changed, ["cards", "spells", "tables"]);

        let missing = changed_sections("");
        assert_eq!(missing.len(), CONTENT_SECTIONS.len());
        assert!(changed_sections("cards=sha256:old").contains(&"cards".to_string()));
    }

    #[test]
    fn the_catalog_entry_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&0u16.to_le_bytes());
        body.extend_from_slice(&1u16.to_le_bytes());
        body.extend_from_slice(&60024u32.to_le_bytes());
        for text in ["切割", "Interface\\Icons\\Spell_Shadow_CurseOfTounges", "每层提高急速"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.extend_from_slice(&0u32.to_le_bytes());
        body.extend_from_slice(&28u32.to_le_bytes());

        let Some(HoaMessage::AuraCatalogEntry(entry)) = protocol_generated::decode(protocol_generated::MSG_AURA_CATALOG_ENTRY, &body) else {
            panic!("catalog entry did not decode");
        };
        assert_eq!(entry.spell_id, 60024);
        assert_eq!(entry.name, "切割");
        assert_eq!(entry.stack, 0);
        assert_eq!(entry.duration, 28);
    }

    #[test]
    fn the_run_state_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&7u32.to_le_bytes());
        body.extend_from_slice(&60u32.to_le_bytes());
        body.extend_from_slice(&12u32.to_le_bytes());
        body.extend_from_slice(&340u32.to_le_bytes());
        body.push(60);
        body.push(1);
        body.extend_from_slice(&5u32.to_le_bytes());
        body.extend_from_slice(&25u32.to_le_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());
        body.push(0);
        body.extend_from_slice(&2u32.to_le_bytes());
        let weapon_stats = "1:2,3:4";
        body.extend_from_slice(&(weapon_stats.len() as u16).to_le_bytes());
        body.extend_from_slice(weapon_stats.as_bytes());
        body.extend_from_slice(&90u32.to_le_bytes());
        let damage_types = "fire,ice";
        body.extend_from_slice(&(damage_types.len() as u16).to_le_bytes());
        body.extend_from_slice(damage_types.as_bytes());

        let Some(HoaMessage::RunState(state)) = protocol_generated::decode(protocol_generated::MSG_RUN_STATE, &body) else {
            panic!("run state did not decode");
        };
        assert_eq!(state.elapsed_s, 7);
        assert_eq!(state.duration_s, 60);
        assert_eq!(state.player_level, 60);
        assert!(state.boss_spawned);
        assert_eq!(state.weapon_stats, "1:2,3:4");
        assert_eq!(state.total_s, 90);
        assert_eq!(state.damage_types, "fire,ice");
    }

    #[test]
    fn the_run_start_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        for text in ["Deadmines", "Normal"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.extend_from_slice(&600u32.to_le_bytes());
        body.extend_from_slice(&2u32.to_le_bytes());
        body.extend_from_slice(&45u32.to_le_bytes());
        let timeline_marks = "first pull";
        body.extend_from_slice(&(timeline_marks.len() as u16).to_le_bytes());
        body.extend_from_slice(timeline_marks.as_bytes());
        body.push(0);
        body.extend_from_slice(&5u32.to_le_bytes());
        let level_name = "Hero";
        body.extend_from_slice(&(level_name.len() as u16).to_le_bytes());
        body.extend_from_slice(level_name.as_bytes());
        body.push(1);
        body.push(0);

        let Some(HoaMessage::RunStart(start)) = protocol_generated::decode(protocol_generated::MSG_RUN_START, &body) else {
            panic!("run start did not decode");
        };
        assert_eq!(start.map_name, "Deadmines");
        assert_eq!(start.difficulty, "Normal");
        assert_eq!(start.duration_s, 600);
        assert_eq!(start.timeline_marks, "first pull");
        assert_eq!(start.stages, 5);
        assert!(start.finale);
        assert!(!start.sandbox);
    }

    #[test]
    fn the_run_end_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.push(1);
        body.extend_from_slice(&120u32.to_le_bytes());
        body.extend_from_slice(&9u32.to_le_bytes());
        body.extend_from_slice(&300u32.to_le_bytes());
        body.push(60);
        body.extend_from_slice(&4u32.to_le_bytes());
        body.extend_from_slice(&2u32.to_le_bytes());
        body.push(1);
        body.push(0);
        body.extend_from_slice(&7u32.to_le_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());
        body.extend_from_slice(&(4u16).to_le_bytes());
        body.extend_from_slice(b"Hero");
        body.extend_from_slice(&30u32.to_le_bytes());

        let Some(HoaMessage::RunEnd(end)) = protocol_generated::decode(protocol_generated::MSG_RUN_END, &body) else {
            panic!("run end did not decode");
        };
        assert!(end.went_home);
        assert_eq!(end.seconds, 120);
        assert_eq!(end.gold, 300);
        assert_eq!(end.player_level, 60);
        assert!(end.victory);
        assert_eq!(end.level_name, "Hero");
        assert_eq!(end.finale_seconds, 30);
    }

    #[test]
    fn the_run_xp_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&61u32.to_le_bytes());
        body.extend_from_slice(&1000u32.to_le_bytes());
        body.extend_from_slice(&2000u32.to_le_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());

        let Some(HoaMessage::RunXp(xp)) = protocol_generated::decode(protocol_generated::MSG_RUN_XP, &body) else {
            panic!("run xp did not decode");
        };
        assert_eq!(xp.level, 61);
        assert_eq!(xp.xp, 1000);
        assert_eq!(xp.next, 2000);
        assert_eq!(xp.orbs, 3);
    }

    #[test]
    fn the_wave_beat_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        let name = "Boss";
        body.extend_from_slice(&(name.len() as u16).to_le_bytes());
        body.extend_from_slice(name.as_bytes());
        body.extend_from_slice(&2u32.to_le_bytes());
        body.extend_from_slice(&15u32.to_le_bytes());

        let Some(HoaMessage::WaveBeat(beat)) = protocol_generated::decode(protocol_generated::MSG_WAVE_BEAT, &body) else {
            panic!("wave beat did not decode");
        };
        assert_eq!(beat.name, "Boss");
        assert_eq!(beat.beat, 2);
        assert_eq!(beat.seconds, 15);
    }

    #[test]
    fn the_objective_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&7u32.to_le_bytes());
        let kind = "shrine";
        body.extend_from_slice(&(kind.len() as u16).to_le_bytes());
        body.extend_from_slice(kind.as_bytes());
        body.extend_from_slice(&1.5f32.to_le_bytes());
        body.extend_from_slice(&2.5f32.to_le_bytes());
        body.extend_from_slice(&1u32.to_le_bytes());
        let label = "Shrine";
        body.extend_from_slice(&(label.len() as u16).to_le_bytes());
        body.extend_from_slice(label.as_bytes());
        body.extend_from_slice(&30u32.to_le_bytes());
        for text in ["icon", "desc"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }

        let Some(HoaMessage::Objective(objective)) = protocol_generated::decode(protocol_generated::MSG_OBJECTIVE, &body) else {
            panic!("objective did not decode");
        };
        assert_eq!(objective.id, 7);
        assert_eq!(objective.kind, "shrine");
        assert_eq!(objective.x, 1.5);
        assert_eq!(objective.y, 2.5);
        assert_eq!(objective.label, "Shrine");
        assert_eq!(objective.seconds, 30);
        assert_eq!(objective.icon, "icon");
        assert_eq!(objective.description, "desc");
    }

    #[test]
    fn an_empty_message_decodes_without_fields() {
        let Some(HoaMessage::MobClear(_)) = protocol_generated::decode(protocol_generated::MSG_MOB_CLEAR, &[]) else {
            panic!("empty mob clear did not decode");
        };
        assert!(protocol_generated::decode(protocol_generated::MSG_MOB_CLEAR, &[1]).is_none());
    }

    #[test]
    fn the_offer_option_decoder_reads_the_wire_layout() {
        let mut body = Vec::new();
        body.extend_from_slice(&2u32.to_le_bytes());
        let kind = "w";
        body.extend_from_slice(&(kind.len() as u16).to_le_bytes());
        body.extend_from_slice(kind.as_bytes());
        body.extend_from_slice(&3u32.to_le_bytes());
        body.extend_from_slice(&5u32.to_le_bytes());
        for text in ["Arcane Orb", "icon", "desc", "2"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.push(1);
        for text in ["10", "20", "damage"] {
            body.extend_from_slice(&(text.len() as u16).to_le_bytes());
            body.extend_from_slice(text.as_bytes());
        }
        body.push(0);

        let Some(HoaMessage::OfferOption(option)) = protocol_generated::decode(protocol_generated::MSG_OFFER_OPTION, &body) else {
            panic!("offer option did not decode");
        };
        assert_eq!(option.index, 2);
        assert_eq!(option.kind, "w");
        assert_eq!(option.new_level, 3);
        assert_eq!(option.max_level, 5);
        assert_eq!(option.name, "Arcane Orb");
        assert_eq!(option.rarity, "2");
        assert!(option.locked);
        assert!(!option.banishable);
    }
}
