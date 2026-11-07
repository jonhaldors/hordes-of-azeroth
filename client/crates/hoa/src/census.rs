use benilla_app::{FxAnchor, Objects};
use benilla_world::particles::ParticleEmitter;
use benilla_world::rig_anim::RigPose;
use bevy::prelude::*;

use crate::telegraphs::Telegraphs;
use crate::world_fx::{AuraAnchor, Flight, KitAnchor};

const CENSUS_EVERY_SECS: f32 = 15.0;

pub fn census_wanted() -> bool {
    std::env::var_os("WOW_HOA_CENSUS").is_some()
}

#[allow(clippy::too_many_arguments)]
pub fn log_census(
    time: Res<Time<Real>>,
    mut next: Local<f32>,
    entities: Query<()>,
    meshes: Query<(), With<Mesh3d>>,
    rigs: Query<(), With<RigPose>>,
    emitters: Query<(), With<ParticleEmitter>>,
    anchors: Query<(), With<FxAnchor>>,
    kits: Query<(), With<KitAnchor>>,
    flights: Query<(), With<Flight>>,
    auras: Query<(), With<AuraAnchor>>,
    objects: Objects,
    telegraphs: Res<Telegraphs>,
    images: Res<Assets<Image>>,
    materials: Res<Assets<StandardMaterial>>,
) {
    let now = time.elapsed_secs();
    if now < *next {
        return;
    }
    *next = now + CENSUS_EVERY_SECS;
    info!(
        "HOA_CENSUS t={now:.0} entities={} meshes={} rigs={} emitters={} objects={} anchors={} kits={} flights={} auras={} marks={} images={} std_materials={}",
        entities.iter().len(),
        meshes.iter().len(),
        rigs.iter().len(),
        emitters.iter().len(),
        objects.iter().count(),
        anchors.iter().len(),
        kits.iter().len(),
        flights.iter().len(),
        auras.iter().len(),
        telegraphs.len(),
        images.len(),
        materials.len(),
    );
}
