use benilla_assets::coords::wow_to_bevy;
use bevy::prelude::Vec3;

use crate::protocol_generated::{
    VisualAura, VisualAuraRemove, VisualClear, VisualFlight, VisualKit, VisualLand, VisualMark, VisualMarkRemove,
    VisualMissile, VisualProp, VisualPropRemove, VisualTelegraphClear,
};

pub const TELEGRAPH_KEY_PREFIX: &str = "t";

#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Shape {
    Circle,
    Cone,
    Line,
    Ring,
}

#[derive(Clone, Debug, PartialEq)]
pub struct MarkSpec {
    pub key: String,
    pub shape: Shape,
    pub at: Vec3,
    pub yaw: f32,
    pub size: f32,
    pub duration: Option<f32>,
    pub outline_only: bool,
    pub additive: bool,
    pub ground_effect: bool,
    pub style: u8,
    pub follow: u64,
    pub texture: Option<String>,
    pub done: f32,
    pub opacity: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct KitSpec {
    pub kit_id: u32,
    pub at: Vec3,
    pub yaw: f32,
    pub hold: f32,
    pub raised: bool,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct FlightSpec {
    pub id: u32,
    pub from: Vec3,
    pub to: Vec3,
    pub duration: f32,
    pub display_id: u32,
    pub scale: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct MissileSpec {
    pub spell_id: u32,
    pub from: Vec3,
    pub to: Vec3,
    pub hold: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct PropSpec {
    pub key: u32,
    pub display_id: u32,
    pub at: Vec3,
    pub yaw: f32,
    pub scale: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct AuraSpec {
    pub key: u32,
    pub spell_id: u32,
    pub at: Vec3,
    pub scale: f32,
}

#[derive(Clone, Debug, PartialEq)]
pub enum DrawCommand {
    Mark(MarkSpec),
    RemoveMark(String),
    ClearTelegraphs,
    ClearAll,
    Kit(KitSpec),
    Fly(FlightSpec),
    Land(u32),
    Missile(MissileSpec),
    Prop(PropSpec),
    RemoveProp(u32),
    Aura(AuraSpec),
    RemoveAura(u32),
}

const OUTLINE_ONLY: u8 = 1;
const ADDITIVE: u8 = 2;
const GROUND_EFFECT: u8 = 4;

fn shape_of(value: u8) -> Shape {
    match value {
        1 => Shape::Cone,
        2 => Shape::Line,
        3 => Shape::Ring,
        _ => Shape::Circle,
    }
}

fn point(x: f32, y: f32, z: f32) -> Vec3 {
    wow_to_bevy([x, y, z])
}

fn secs(ms: u32) -> f32 {
    ms as f32 / 1000.0
}

impl From<VisualMark> for DrawCommand {
    fn from(mark: VisualMark) -> Self {
        Self::Mark(MarkSpec {
            key: mark.key,
            shape: shape_of(mark.shape),
            at: point(mark.x, mark.y, mark.z),
            yaw: mark.yaw,
            size: mark.size,
            duration: (mark.duration_ms > 0 || !mark.persistent).then(|| secs(mark.duration_ms)),
            outline_only: mark.flags & OUTLINE_ONLY != 0,
            additive: mark.flags & ADDITIVE != 0,
            ground_effect: mark.flags & GROUND_EFFECT != 0,
            style: mark.style,
            follow: mark.follow,
            texture: (!mark.texture.is_empty()).then_some(mark.texture),
            done: secs(mark.done_ms),
            opacity: f32::from(mark.opacity_percent.min(100)) / 100.0,
        })
    }
}

impl From<VisualMarkRemove> for DrawCommand {
    fn from(mark: VisualMarkRemove) -> Self {
        Self::RemoveMark(mark.key)
    }
}

impl From<VisualTelegraphClear> for DrawCommand {
    fn from(_: VisualTelegraphClear) -> Self {
        Self::ClearTelegraphs
    }
}

impl From<VisualClear> for DrawCommand {
    fn from(_: VisualClear) -> Self {
        Self::ClearAll
    }
}

impl From<VisualKit> for DrawCommand {
    fn from(kit: VisualKit) -> Self {
        Self::Kit(KitSpec {
            kit_id: kit.kit_id,
            at: point(kit.x, kit.y, kit.z),
            yaw: kit.yaw,
            hold: secs(kit.hold_ms),
            raised: kit.raised,
        })
    }
}

impl From<VisualFlight> for DrawCommand {
    fn from(flight: VisualFlight) -> Self {
        Self::Fly(FlightSpec {
            id: flight.id,
            from: point(flight.from_x, flight.from_y, flight.from_z),
            to: point(flight.to_x, flight.to_y, flight.to_z),
            duration: secs(flight.duration_ms),
            display_id: flight.display_id,
            scale: flight.scale,
        })
    }
}

impl From<VisualLand> for DrawCommand {
    fn from(land: VisualLand) -> Self {
        Self::Land(land.id)
    }
}

impl From<VisualMissile> for DrawCommand {
    fn from(missile: VisualMissile) -> Self {
        Self::Missile(MissileSpec {
            spell_id: missile.spell_id,
            from: point(missile.from_x, missile.from_y, missile.from_z),
            to: point(missile.to_x, missile.to_y, missile.to_z),
            hold: secs(missile.hold_ms),
        })
    }
}

impl From<VisualProp> for DrawCommand {
    fn from(prop: VisualProp) -> Self {
        Self::Prop(PropSpec {
            key: prop.key,
            display_id: prop.display_id,
            at: point(prop.x, prop.y, prop.z),
            yaw: prop.yaw,
            scale: prop.scale,
        })
    }
}

impl From<VisualPropRemove> for DrawCommand {
    fn from(prop: VisualPropRemove) -> Self {
        Self::RemoveProp(prop.key)
    }
}

impl From<VisualAura> for DrawCommand {
    fn from(aura: VisualAura) -> Self {
        Self::Aura(AuraSpec {
            key: aura.key,
            spell_id: aura.spell_id,
            at: point(aura.x, aura.y, aura.z),
            scale: aura.scale,
        })
    }
}

impl From<VisualAuraRemove> for DrawCommand {
    fn from(aura: VisualAuraRemove) -> Self {
        Self::RemoveAura(aura.key)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_typed_mark_keeps_every_field() {
        let command = DrawCommand::from(VisualMark {
            key: "t7".into(),
            shape: 1,
            x: -8949.5,
            y: -132.25,
            z: 83.5,
            yaw: 1.5,
            size: 10.0,
            duration_ms: 2000,
            flags: OUTLINE_ONLY,
            style: 2,
            follow: 0,
            texture: String::new(),
            done_ms: 0,
            opacity_percent: 100,
            persistent: false,
        });
        let DrawCommand::Mark(spec) = command else {
            panic!("a mark message is a mark");
        };
        assert_eq!(spec.key, "t7");
        assert_eq!(spec.shape, Shape::Cone);
        assert_eq!(spec.at, wow_to_bevy([-8949.5, -132.25, 83.5]));
        assert_eq!((spec.yaw, spec.size, spec.duration), (1.5, 10.0, Some(2.0)));
        assert!(spec.outline_only);
        assert!(!spec.additive);
        assert_eq!(spec.style, 2);
        assert_eq!(spec.texture, None);
    }

    #[test]
    fn a_persistent_mark_without_time_has_no_duration() {
        let command = DrawCommand::from(VisualMark {
            key: "mreach".into(),
            shape: 0,
            x: 1.0,
            y: 2.0,
            z: 3.0,
            yaw: 0.0,
            size: 5.0,
            duration_ms: 0,
            flags: ADDITIVE | GROUND_EFFECT,
            style: 2,
            follow: 4_294_967_297,
            texture: "World\\Goober\\RuneGroundBlue01.blp".into(),
            done_ms: 4500,
            opacity_percent: 40,
            persistent: true,
        });
        let DrawCommand::Mark(spec) = command else {
            panic!("a mark message is a mark");
        };
        assert_eq!(spec.duration, None);
        assert!(spec.additive);
        assert!(spec.ground_effect);
        assert_eq!(spec.follow, 4_294_967_297);
        assert_eq!(spec.texture.as_deref(), Some("World\\Goober\\RuneGroundBlue01.blp"));
        assert_eq!(spec.done, 4.5);
        assert_eq!(spec.opacity, 0.4);
    }

    #[test]
    fn no_field_visuals_clear_and_remove() {
        assert_eq!(DrawCommand::from(VisualTelegraphClear {}), DrawCommand::ClearTelegraphs);
        assert_eq!(DrawCommand::from(VisualClear {}), DrawCommand::ClearAll);
        assert_eq!(DrawCommand::from(VisualLand { id: 3 }), DrawCommand::Land(3));
        assert_eq!(
            DrawCommand::from(VisualMarkRemove { key: "t12".into() }),
            DrawCommand::RemoveMark("t12".into())
        );
    }
}
