use bevy::prelude::*;

use super::spell_visual::{state_kit_effects, FxClass, FxSlot, FxStage, SpellKitFx, SpellVisuals};
use super::{KitPush, PlaySeq};
use crate::entities::VisualAttached;

#[derive(Component, Default)]
#[require(Transform, Visibility, VisualAttached)]
pub struct FxAnchor;

#[derive(Message, Clone, Debug)]
pub enum AnchorFx {
    Kit { anchor: Entity, kit_id: u32 },
    Model { anchor: Entity, path: String },
    Aura { anchor: Entity, spell_id: u32 },
    Missile { anchor: Entity, spell_id: u32, to: Vec3 },
}

impl AnchorFx {
    fn anchor(&self) -> Entity {
        match self {
            AnchorFx::Kit { anchor, .. }
            | AnchorFx::Model { anchor, .. }
            | AnchorFx::Aura { anchor, .. }
            | AnchorFx::Missile { anchor, .. } => *anchor,
        }
    }
}

const ANCHOR_MODEL_EFFECT: u32 = u32::MAX;
const FRAMES_TO_WAIT_FOR_ANCHOR: u8 = 3;
const DEST_TARGET_MASK: u16 = 0x40;

pub(crate) fn play_anchor_fx(
    mut requests: MessageReader<AnchorFx>,
    mut waiting: Local<Vec<(AnchorFx, u8)>>,
    anchors: Query<(), With<FxAnchor>>,
    mut play_seq: ResMut<PlaySeq>,
    mut kits: MessageWriter<KitPush>,
    mut models: MessageWriter<SpellKitFx>,
    mut gos: MessageWriter<super::SpellGoTargets>,
    visuals: Option<Res<SpellVisuals>>,
    spells: Option<Res<crate::ui_action::Spells>>,
) {
    let mut pending = std::mem::take(&mut *waiting);
    pending.extend(requests.read().cloned().map(|r| (r, 0)));
    for (request, frames) in pending {
        let anchor = request.anchor();
        if anchors.get(anchor).is_err() {
            if frames < FRAMES_TO_WAIT_FOR_ANCHOR {
                waiting.push((request, frames + 1));
            }
            continue;
        }
        match request {
            AnchorFx::Kit { kit_id, .. } => {
                kits.write(KitPush {
                    entity: anchor,
                    kit_id,
                    seq: play_seq.next(),
                });
            }
            AnchorFx::Model { path, .. } => {
                models.write(SpellKitFx::Begin {
                    entity: anchor,
                    spell_id: 0,
                    persistent: true,
                    class: FxClass::Hold,
                    stage: FxStage::Relive,
                    effects: vec![FxSlot {
                        tag: 0,
                        effect: ANCHOR_MODEL_EFFECT,
                        path,
                    }],
                });
            }
            AnchorFx::Aura { spell_id, .. } => {
                let (Some(visuals), Some(spells)) = (visuals.as_deref(), spells.as_deref()) else {
                    continue;
                };
                let effects = state_kit_effects(spells, &visuals.0, spell_id);
                if !effects.is_empty() {
                    models.write(SpellKitFx::Begin {
                        entity: anchor,
                        spell_id,
                        persistent: true,
                        class: FxClass::AuraState,
                        stage: FxStage::State,
                        effects,
                    });
                }
            }
            AnchorFx::Missile { spell_id, to, .. } => {
                gos.write(super::SpellGoTargets {
                    caster: Some(anchor),
                    spell_id,
                    hits: Vec::new(),
                    misses: Vec::new(),
                    source: None,
                    dest: Some(to),
                    target_mask: DEST_TARGET_MASK,
                    ammo_display_id: None,
                    seq: play_seq.next(),
                });
            }
        }
    }
}
