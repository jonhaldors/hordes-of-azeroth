//! The addon profiler: Lua time per frame and heap per addon, live, in an egui window toggled by
//! the dev chord + `L`. Time comes from the VM's chunk profile (`benilla_lua::vm::Profile`), heap
//! from its census; both are grouped by addon (`owners`).

use std::collections::{HashMap, VecDeque};

use benilla_ui::script::UiScript;
use benilla_world::modkeys::dev_chord;
use bevy::prelude::*;
use bevy_egui::{egui, EguiContexts};

use super::hot_reload::HotReload;
use super::owners::owners_of;
use crate::debug_panel::{overlay_text, EguiDemand, OVERLAY_FILL, OVERLAY_TEXT_DIM};

/// How often time is sampled, and how often the heap is counted.
const SAMPLE_SECS: f32 = 0.5;
const CENSUS_SECS: f32 = 2.0;
/// Samples each sparkline keeps: a minute.
const HISTORY: usize = 120;
/// The frame the bars are drawn against: 60 fps.
const FRAME_US: f32 = 16_667.0;

#[derive(Default)]
struct Row {
    us: f32,
    history: VecDeque<f32>,
    kb: f32,
    tables: usize,
    functions: usize,
}

#[derive(Resource, Default)]
pub(crate) struct AddonProfiler {
    open: bool,
    /// The VM session profiling was turned on in: a new VM (a world entry, a `/reload`) starts
    /// without it.
    session: u64,
    next: f32,
    next_census: f32,
    frames: u32,
    /// Each source id's charged time at the last sample.
    last_ns: Vec<u64>,
    rows: HashMap<String, Row>,
    /// Each source id's owning addon, as of source epoch `owners_epoch`.
    owners: Vec<String>,
    owners_epoch: Option<u64>,
    total_us: f32,
    total_history: VecDeque<f32>,
}

pub(super) fn toggle(
    keys: Res<ButtonInput<KeyCode>>,
    script: Option<NonSend<UiScript>>,
    mut prof: ResMut<AddonProfiler>,
    mut demand: ResMut<EguiDemand>,
) {
    if !dev_chord(&keys, KeyCode::KeyL) {
        return;
    }
    let Some(script) = script else { return };
    prof.open = !prof.open;
    demand.profiler = prof.open;
    let open = prof.open;
    let last_ns = script.lua().with_vm(|vm| {
        vm.set_profiling(open);
        vm.profile
            .as_ref()
            .map(|p| p.ns.clone())
            .unwrap_or_default()
    });
    info!(
        "devtools: addon profiler {}",
        if open { "on" } else { "off" }
    );
    if open {
        *prof = AddonProfiler {
            open: true,
            session: script.session(),
            last_ns,
            ..default()
        };
    }
}

pub(super) fn sample(
    time: Res<Time>,
    script: Option<NonSend<UiScript>>,
    mut prof: ResMut<AddonProfiler>,
) {
    if !prof.open {
        return;
    }
    let Some(script) = script else { return };
    if prof.session != script.session() {
        script.lua().with_vm(|vm| vm.set_profiling(true));
        *prof = AddonProfiler {
            open: true,
            session: script.session(),
            ..default()
        };
        return;
    }
    prof.frames += 1;
    let now = time.elapsed_secs();
    if now < prof.next {
        return;
    }
    prof.next = now + SAMPLE_SECS;
    let census = now >= prof.next_census;
    let prof = &mut *prof;
    let (ns, census) = script.lua().with_vm(|vm| {
        let ns = vm
            .profile
            .as_ref()
            .map(|p| p.ns.clone())
            .unwrap_or_default();
        if prof.owners_epoch != Some(vm.heap.sources_epoch()) {
            prof.owners = owners_of(&vm.heap);
            prof.owners_epoch = Some(vm.heap.sources_epoch());
        }
        (ns, census.then(|| vm.heap.census()))
    });
    let owners = &prof.owners;

    let frames = prof.frames.max(1) as f32;
    let mut per: HashMap<&str, f32> = HashMap::new();
    for (id, &n) in ns.iter().enumerate() {
        let d = n.saturating_sub(prof.last_ns.get(id).copied().unwrap_or(0));
        if let Some(owner) = owners.get(id) {
            *per.entry(owner).or_default() += d as f32 / 1000.0 / frames;
        }
    }
    prof.last_ns = ns;
    prof.frames = 0;
    prof.total_us = per.values().sum();
    push(&mut prof.total_history, prof.total_us);
    // A free source slot has no owner.
    for owner in owners.iter().filter(|o| !o.is_empty()) {
        prof.rows.entry(owner.clone()).or_default();
    }
    for (name, row) in prof.rows.iter_mut() {
        row.us = per.get(name.as_str()).copied().unwrap_or(0.0);
        push(&mut row.history, row.us);
    }

    if let Some(census) = census {
        prof.next_census = now + CENSUS_SECS;
        for row in prof.rows.values_mut() {
            (row.kb, row.tables, row.functions) = (0.0, 0, 0);
        }
        for (id, c) in census.into_iter().enumerate() {
            if let Some(row) = owners.get(id).and_then(|o| prof.rows.get_mut(o)) {
                row.kb += c.bytes as f32 / 1024.0;
                row.tables += c.tables;
                row.functions += c.functions;
            }
        }
    }
}

fn push(h: &mut VecDeque<f32>, v: f32) {
    h.push_back(v);
    if h.len() > HISTORY {
        h.pop_front();
    }
}

/// A steady colour per addon, from its name.
fn colour(name: &str) -> egui::Color32 {
    let h = name
        .bytes()
        .fold(2166136261u32, |h, b| (h ^ b as u32).wrapping_mul(16777619));
    egui::ecolor::Hsva::new((h % 360) as f32 / 360.0, 0.55, 0.95, 1.0).into()
}

fn sparkline(ui: &mut egui::Ui, h: &VecDeque<f32>, size: egui::Vec2, c: egui::Color32) {
    let (rect, _) = ui.allocate_exact_size(size, egui::Sense::hover());
    let top = h.iter().copied().fold(1.0f32, f32::max);
    let n = HISTORY.max(2) - 1;
    let pts: Vec<egui::Pos2> = h
        .iter()
        .enumerate()
        .map(|(i, v)| {
            let x = rect.right() - (h.len() - 1 - i) as f32 / n as f32 * rect.width();
            egui::pos2(x, rect.bottom() - v / top * rect.height())
        })
        .collect();
    ui.painter()
        .rect_filled(rect, 2.0, egui::Color32::from_white_alpha(10));
    ui.painter()
        .add(egui::Shape::line(pts, egui::Stroke::new(1.5f32, c)));
}

pub(super) fn panel_ui(
    mut contexts: EguiContexts,
    prof: Res<AddonProfiler>,
    reloads: Res<HotReload>,
    time: Res<Time>,
) -> Result {
    if !prof.open {
        return Ok(());
    }
    let ctx = contexts.ctx_mut()?;
    let mut rows: Vec<(&String, &Row)> = prof.rows.iter().collect();
    rows.sort_by(|a, b| b.1.us.total_cmp(&a.1.us).then(a.0.cmp(b.0)));
    let top = rows.first().map_or(1.0, |r| r.1.us.max(1.0));
    let kb: f32 = rows.iter().map(|r| r.1.kb).sum();

    egui::Window::new("Addon profiler")
        .default_pos(egui::pos2(12.0, 120.0))
        .resizable(false)
        .frame(
            egui::Frame::window(&ctx.style())
                .fill(OVERLAY_FILL)
                .inner_margin(10),
        )
        .show(ctx, |ui| {
            overlay_text(ui);
            ui.horizontal(|ui| {
                ui.label(
                    egui::RichText::new(format!("{:.0} µs", prof.total_us))
                        .size(22.0)
                        .strong(),
                );
                ui.vertical(|ui| {
                    ui.label(format!(
                        "Lua per frame · {:.1}% of a 60 fps frame",
                        prof.total_us / FRAME_US * 100.0
                    ));
                    ui.label(
                        egui::RichText::new(format!("heap {:.0} KB, {} owners", kb, rows.len()))
                            .color(OVERLAY_TEXT_DIM),
                    );
                });
            });
            sparkline(
                ui,
                &prof.total_history,
                egui::vec2(460.0, 36.0),
                egui::Color32::from_rgb(255, 209, 0),
            );
            ui.add_space(6.0);
            egui::Grid::new("addon_rows")
                .num_columns(5)
                .spacing([10.0, 4.0])
                .show(ui, |ui| {
                    for h in ["addon", "µs / frame", "last minute", "heap", "tables · fns"] {
                        ui.label(egui::RichText::new(h).small().color(OVERLAY_TEXT_DIM));
                    }
                    ui.end_row();
                    for (name, row) in &rows {
                        let c = colour(name);
                        ui.label(egui::RichText::new(name.as_str()).color(c));
                        ui.horizontal(|ui| {
                            let (rect, _) = ui
                                .allocate_exact_size(egui::vec2(90.0, 12.0), egui::Sense::hover());
                            let w = rect.width() * (row.us / top).clamp(0.0, 1.0);
                            ui.painter().rect_filled(
                                rect,
                                2.0,
                                egui::Color32::from_white_alpha(12),
                            );
                            ui.painter().rect_filled(
                                egui::Rect::from_min_size(rect.min, egui::vec2(w, rect.height())),
                                2.0,
                                c,
                            );
                            ui.label(format!("{:7.1}", row.us));
                        });
                        sparkline(ui, &row.history, egui::vec2(120.0, 16.0), c);
                        ui.label(format!("{:.0} KB", row.kb));
                        ui.label(
                            egui::RichText::new(format!("{} · {}", row.tables, row.functions))
                                .color(OVERLAY_TEXT_DIM),
                        );
                        ui.end_row();
                    }
                });
            if !reloads.log.is_empty() {
                ui.separator();
                ui.label(
                    egui::RichText::new("hot reload")
                        .small()
                        .color(OVERLAY_TEXT_DIM),
                );
                let now = time.elapsed_secs();
                for (at, line, ok) in reloads.log.iter().rev() {
                    let c = if *ok {
                        egui::Color32::from_rgb(102, 255, 153)
                    } else {
                        egui::Color32::from_rgb(255, 102, 102)
                    };
                    ui.label(
                        egui::RichText::new(format!("{:>4.0}s ago  {line}", now - at))
                            .small()
                            .color(c),
                    );
                }
            }
        });
    Ok(())
}
