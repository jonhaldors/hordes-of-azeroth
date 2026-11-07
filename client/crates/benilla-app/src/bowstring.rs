//! The engine-drawn bowstring: bow M2s have no string geometry. The reference's per-frame callback
//! (`0x611ff0`) draws a two-segment line between the `$WTT`/`$WTB` limb-tip markers, its middle
//! vertex at the HandArrow attach while the nock latch (`[+0xd58] & 0x4000`) holds, else the tip
//! midpoint. Drawn here as gizmo lines; the color and width are inferred, since the reference's
//! packed vertex color is not decoded.
//!
//! The tips are posed: `$BWP` plays BowPull (160) on the prop and `$BWR` returns it to Stand (0),
//! so the markers ride limb bones that bend through the draw.

use bevy::prelude::*;

use crate::creature_anim::NockLatch;
use crate::entities::BoneAttach;

/// The HandArrow attach id (35, `0x6121b8`): the string's middle point while nocked.
const HAND_ARROW: u16 = 0x23;

/// Marks a bow prop root whose model authors the `$WTT`/`$WTB` anchors; despawned with the prop.
#[derive(Component)]
pub(crate) struct Bowstring {
    /// The unit wearing the bow, which carries the HandArrow attach and the nock latch.
    pub(crate) owner: Entity,
    /// The `$WTT` top and `$WTB` bottom anchors as `(bone, model-local offset)`.
    pub(crate) top: StringTip,
    pub(crate) bottom: StringTip,
}

#[derive(Clone, Copy)]
pub(crate) struct StringTip {
    pub(crate) bone: u16,
    pub(crate) model: Vec3,
    pub(crate) from_bone: Vec3,
}

impl StringTip {
    pub(crate) fn new(skeleton: &benilla_assets::ModelSkeleton, (bone, model): (u16, Vec3)) -> Self {
        Self {
            bone,
            model,
            from_bone: model - bone_pivot(skeleton, bone),
        }
    }
}

fn bone_pivot(skeleton: &benilla_assets::ModelSkeleton, bone: u16) -> Vec3 {
    let mut pivot = Vec3::ZERO;
    let mut at = Some(bone as usize);
    while let Some(joint) = at.and_then(|i| skeleton.joints.get(i)) {
        pivot += joint.local_translation;
        at = usize::try_from(joint.parent).ok();
    }
    pivot
}

/// Draws every visible bow's string, tip to middle to tip, from this frame's joint frames.
fn draw_bowstrings(
    bows: Query<(
        &Bowstring,
        &GlobalTransform,
        &InheritedVisibility,
        Option<&benilla_world::rig_anim::RigPose>,
    )>,
    owners: Query<(
        &BoneAttach,
        &benilla_world::rig_anim::RigPose,
        Has<NockLatch>,
    )>,
    joints: Query<&GlobalTransform>,
    mut gizmos: Gizmos,
) {
    // Inferred: the reference's packed vertex color is not decoded.
    const STRING_COLOR: Color = Color::srgb(0.12, 0.10, 0.08);
    for (bs, prop, vis, flex) in &bows {
        if !vis.get() {
            continue;
        }
        // The prop's own pose when it flexes (`joints_root` is this entity); its rigid frame
        // otherwise.
        let tip = |t: StringTip| {
            flex.and_then(|p| p.posed_point(prop, t.bone, t.from_bone))
                .unwrap_or_else(|| prop.transform_point(t.model))
        };
        let top = tip(bs.top);
        let bottom = tip(bs.bottom);
        let middle = owners
            .get(bs.owner)
            .ok()
            .filter(|(_, _, latched)| *latched)
            .and_then(|(bones, pose, _)| {
                let &(bone, offset) = bones.points.get(&HAND_ARROW)?;
                pose.posed_point(joints.get(pose.joints_root).ok()?, bone, offset)
            })
            .unwrap_or_else(|| (top + bottom) / 2.0);
        gizmos.line(top, middle, STRING_COLOR);
        gizmos.line(middle, bottom, STRING_COLOR);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use benilla_assets::{ModelJoint, ModelSkeleton};

    fn joint(parent: i16, local: Vec3) -> ModelJoint {
        ModelJoint {
            parent,
            local_translation: local,
            billboard: None,
            parent_arm: None,
        }
    }

    #[test]
    fn a_tip_on_its_bone_pivot_poses_from_the_bone_itself() {
        let skeleton = ModelSkeleton {
            joints: vec![
                joint(-1, Vec3::ZERO),
                joint(0, Vec3::new(0.4, 0.0, 0.0)),
                joint(1, Vec3::new(0.465, 0.0, 0.219)),
            ],
            ..Default::default()
        };
        let tip = StringTip::new(&skeleton, (2, Vec3::new(0.865, 0.0, 0.219)));
        assert_eq!(tip.model, Vec3::new(0.865, 0.0, 0.219));
        assert!(tip.from_bone.length() < 1e-6, "{:?}", tip.from_bone);
    }
}

/// Registers the string drawer after the palette pass, beside the other joint-frame readers.
pub(crate) struct BowstringPlugin;

impl Plugin for BowstringPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(
            PostUpdate,
            draw_bowstrings.in_set(benilla_world::billboard::BillboardPlace),
        );
    }
}
