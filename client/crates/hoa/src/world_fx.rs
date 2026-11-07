use std::collections::HashMap;

use benilla_app::{AnchorFx, FxAnchor};
use benilla_formats::{load_creature_catalog, wow_data, Chain};
use benilla_world::decal::WorldDecal;
use bevy::prelude::*;

use crate::server_draw::{DrawCommand, FlightSpec, KitSpec, MissileSpec, PropSpec};
use crate::telegraphs::Telegraphs;

const GROUND_SNAP_YARDS: f32 = 2.0;

fn on_ground_near(decals: &WorldDecal, at: Vec3) -> Vec3 {
    decals
        .surface_height_near(at, GROUND_SNAP_YARDS)
        .map_or(at, |ground| at.with_y(ground))
}

#[derive(Resource, Default)]
pub struct DisplayModels(HashMap<u32, (String, f32)>);

impl DisplayModels {
    pub fn from_install() -> Self {
        match load_display_models() {
            Ok(models) => models,
            Err(error) => {
                warn!("Hordes of Azeroth: creature displays not loaded: {error:#}");
                Self::default()
            }
        }
    }
}

fn load_display_models() -> anyhow::Result<DisplayModels> {
    let data = wow_data().ok_or_else(|| anyhow::anyhow!("no WoW Data folder found"))?;
    let mut chain = Chain::open(&data)?;
    let catalog = load_creature_catalog(&mut chain)?;
    let models = catalog
        .display_models()
        .filter_map(|(display, _)| {
            let model = catalog.model(display)?;
            Some((display, (model.model_path, model.scale)))
        })
        .collect();
    Ok(DisplayModels(models))
}

#[derive(Component)]
pub struct KitAnchor {
    until: f32,
}

#[derive(Component)]
pub struct Flight {
    id: u32,
    from: Vec3,
    to: Vec3,
    started: f32,
    duration: f32,
}

#[derive(Message, Clone, Debug)]
pub struct DrawCommandMessage(pub DrawCommand);

#[derive(Component)]
pub struct AuraAnchor {
    key: u32,
}

#[derive(Component)]
pub struct PropAnchor {
    key: u32,
}

#[allow(clippy::too_many_arguments)]
pub fn apply_draw_lines(
    mut commands: Commands,
    mut lines: MessageReader<DrawCommandMessage>,
    mut telegraphs: ResMut<Telegraphs>,
    mut fx: MessageWriter<AnchorFx>,
    displays: Res<DisplayModels>,
    flights: Query<(Entity, &Flight)>,
    auras: Query<(Entity, &AuraAnchor)>,
    props: Query<(Entity, &PropAnchor)>,
    decals: WorldDecal,
    time: Res<Time>,
) {
    let now = time.elapsed_secs();
    let mut fresh_auras: Vec<(u32, Entity)> = Vec::new();
    for line in lines.read() {
        let command = line.0.clone();
        match command {
            DrawCommand::Mark(spec) => telegraphs.add(spec, now),
            DrawCommand::RemoveMark(key) => telegraphs.remove(&key),
            DrawCommand::ClearTelegraphs => telegraphs.clear_telegraphs(),
            DrawCommand::ClearAll => {
                telegraphs.clear_all();
                for (entity, _) in &auras {
                    commands.entity(entity).despawn();
                }
                for (entity, _) in &props {
                    commands.entity(entity).despawn();
                }
                for (_, entity) in fresh_auras.drain(..) {
                    commands.entity(entity).despawn();
                }
            }
            DrawCommand::Prop(prop) => {
                let prop = PropSpec {
                    at: on_ground_near(&decals, prop.at),
                    ..prop
                };
                place_prop(&mut commands, &mut fx, &displays, prop)
            }
            DrawCommand::RemoveProp(key) => {
                for (entity, anchor) in &props {
                    if anchor.key == key {
                        commands.entity(entity).despawn();
                    }
                }
            }
            DrawCommand::Kit(kit) => {
                let at = if kit.raised { kit.at } else { on_ground_near(&decals, kit.at) };
                play_kit(&mut commands, &mut fx, KitSpec { at, ..kit }, now)
            }
            DrawCommand::Missile(missile) => launch_missile(&mut commands, &mut fx, missile, now),
            DrawCommand::Fly(flight) => fly(&mut commands, &mut fx, &displays, flight, now),
            DrawCommand::Land(id) => {
                for (entity, flight) in &flights {
                    if flight.id == id {
                        commands.entity(entity).despawn();
                    }
                }
            }
            DrawCommand::Aura(aura) => {
                let at = on_ground_near(&decals, aura.at);
                let transform = Transform::from_translation(at).with_scale(Vec3::splat(aura.scale));
                let anchor = commands
                    .spawn((
                        FxAnchor,
                        transform,
                        GlobalTransform::from(transform),
                        AuraAnchor { key: aura.key },
                    ))
                    .id();
                fx.write(AnchorFx::Aura {
                    anchor,
                    spell_id: aura.spell_id,
                });
                fresh_auras.push((aura.key, anchor));
            }
            DrawCommand::RemoveAura(key) => {
                for (entity, anchor) in &auras {
                    if anchor.key == key {
                        commands.entity(entity).despawn();
                    }
                }
                fresh_auras.retain(|&(fresh_key, entity)| {
                    if fresh_key != key {
                        return true;
                    }
                    commands.entity(entity).despawn();
                    false
                });
            }
        }
    }
}

fn play_kit(commands: &mut Commands, fx: &mut MessageWriter<AnchorFx>, kit: KitSpec, now: f32) {
    let transform = Transform::from_translation(kit.at).with_rotation(Quat::from_rotation_y(kit.yaw));
    let anchor = commands
        .spawn((
            FxAnchor,
            transform,
            GlobalTransform::from(transform),
            KitAnchor {
                until: now + kit.hold,
            },
        ))
        .id();
    fx.write(AnchorFx::Kit {
        anchor,
        kit_id: kit.kit_id,
    });
}

fn place_prop(commands: &mut Commands, fx: &mut MessageWriter<AnchorFx>, displays: &DisplayModels, prop: PropSpec) {
    let Some((path, model_scale)) = displays.0.get(&prop.display_id).cloned() else {
        warn!("Hordes of Azeroth: no model for prop display {}", prop.display_id);
        return;
    };
    let transform = Transform::from_translation(prop.at)
        .with_rotation(Quat::from_rotation_y(prop.yaw))
        .with_scale(Vec3::splat(model_scale * prop.scale));
    let anchor = commands
        .spawn((
            FxAnchor,
            transform,
            GlobalTransform::from(transform),
            PropAnchor { key: prop.key },
        ))
        .id();
    fx.write(AnchorFx::Model { anchor, path });
}

fn launch_missile(commands: &mut Commands, fx: &mut MessageWriter<AnchorFx>, missile: MissileSpec, now: f32) {
    let transform = Transform::from_translation(missile.from);
    let anchor = commands
        .spawn((
            FxAnchor,
            transform,
            GlobalTransform::from(transform),
            KitAnchor {
                until: now + missile.hold,
            },
        ))
        .id();
    fx.write(AnchorFx::Missile {
        anchor,
        spell_id: missile.spell_id,
        to: missile.to,
    });
}

fn flight_transform(from: Vec3, to: Vec3, at: Vec3, scale: f32) -> Transform {
    let travel = to - from;
    let transform = Transform::from_translation(at).with_scale(Vec3::splat(scale));
    if travel.length_squared() > 1e-6 {
        transform.looking_to(travel, Vec3::Y)
    } else {
        transform
    }
}

fn fly(
    commands: &mut Commands,
    fx: &mut MessageWriter<AnchorFx>,
    displays: &DisplayModels,
    flight: FlightSpec,
    now: f32,
) {
    let Some((path, model_scale)) = displays.0.get(&flight.display_id).cloned() else {
        warn!("Hordes of Azeroth: no model for bolt display {}", flight.display_id);
        return;
    };
    let transform = flight_transform(flight.from, flight.to, flight.from, model_scale * flight.scale);
    let anchor = commands
        .spawn((
            FxAnchor,
            transform,
            GlobalTransform::from(transform),
            Flight {
                id: flight.id,
                from: flight.from,
                to: flight.to,
                started: now,
                duration: flight.duration.max(0.01),
            },
        ))
        .id();
    fx.write(AnchorFx::Model { anchor, path });
}

pub fn move_flights(
    mut commands: Commands,
    mut flights: Query<(Entity, &Flight, &mut Transform)>,
    time: Res<Time>,
) {
    let now = time.elapsed_secs();
    for (entity, flight, mut transform) in &mut flights {
        let progress = (now - flight.started) / flight.duration;
        if progress >= 1.0 {
            commands.entity(entity).despawn();
            continue;
        }
        transform.translation = flight.from.lerp(flight.to, progress.max(0.0));
    }
}

pub fn expire_kit_anchors(mut commands: Commands, anchors: Query<(Entity, &KitAnchor)>, time: Res<Time>) {
    let now = time.elapsed_secs();
    for (entity, anchor) in &anchors {
        if now >= anchor.until {
            commands.entity(entity).despawn();
        }
    }
}


