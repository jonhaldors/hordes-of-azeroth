use std::sync::Arc;

use benilla_assets::{ModelSkeleton, PoseSource};
use bevy::mesh::skinning::SkinnedMeshInverseBindposes;
use bevy::prelude::*;

use super::RigPose;
use crate::rig_palette::{RigPalettes, RigSkin};
use crate::view::WorldCamera;
use crate::vis_chain::VisChainOnly;

#[derive(Component)]
pub struct FxRig {
    pub(super) pose: RigPose,
    pub(super) source: Option<Arc<PoseSource>>,
    last_root: Option<GlobalTransform>,
    last_special: bool,
}

impl FxRig {
    pub fn new(
        root: Entity,
        skeleton: &ModelSkeleton,
        source: Option<Arc<PoseSource>>,
    ) -> Option<Self> {
        if skeleton.joints.is_empty() || !parents_precede_children(skeleton) {
            return None;
        }
        Some(Self {
            pose: RigPose::new(root, skeleton),
            source,
            last_root: None,
            last_special: false,
        })
    }

    pub fn bones(&self) -> usize {
        self.pose.locals.len()
    }

    pub fn anchor_for(&mut self, commands: &mut Commands, bone: u16) -> Option<Entity> {
        if let Some(&(_, anchor)) = self.pose.anchors.iter().find(|&&(b, _)| b == bone) {
            return Some(anchor);
        }
        if bone as usize >= self.bones() {
            return None;
        }
        let anchor = commands
            .spawn((GlobalTransform::IDENTITY, Visibility::default()))
            .vis_chain_only()
            .id();
        commands.entity(self.pose.joints_root).add_child(anchor);
        self.pose.anchors.push((bone, anchor));
        Some(anchor)
    }

    pub fn locals(&self) -> &[Transform] {
        &self.pose.locals
    }

    pub fn anchors(&self) -> &[(u16, Entity)] {
        &self.pose.anchors
    }

    pub(crate) fn walled_root(&self) -> Option<Entity> {
        self.pose.has_special.then_some(self.pose.joints_root)
    }

    pub fn worlds(
        &self,
        root_g: GlobalTransform,
        cam: Option<(Vec3, Vec3, Vec3)>,
    ) -> Vec<GlobalTransform> {
        match cam.filter(|_| self.pose.has_special) {
            Some(_) => super::compose::rig_worlds(&self.pose, root_g, cam).0,
            None => propagated_chain(&self.pose, root_g),
        }
    }
}

fn parents_precede_children(skeleton: &ModelSkeleton) -> bool {
    let n = skeleton.joints.len();
    skeleton.joints.iter().enumerate().all(|(i, j)| {
        usize::try_from(j.parent)
            .ok()
            .is_none_or(|p| p < i || p >= n)
    })
}

fn propagated_chain(rig: &RigPose, root_g: GlobalTransform) -> Vec<GlobalTransform> {
    let mut worlds: Vec<GlobalTransform> = Vec::with_capacity(rig.locals.len());
    for (i, local) in rig.locals.iter().enumerate() {
        let parent = usize::try_from(rig.parents[i])
            .ok()
            .filter(|&p| p < i)
            .map_or(root_g, |p| worlds[p]);
        worlds.push(parent.mul_transform(*local));
    }
    worlds
}

pub(super) type FxRoots<'w, 's> =
    Query<'w, 's, (&'static Transform, &'static mut GlobalTransform), Without<WorldCamera>>;

pub(super) fn finalize_fx_rigs(
    cam_basis: Option<(Vec3, Vec3, Vec3)>,
    rigs: &mut Query<(&mut FxRig, Option<&RigSkin>)>,
    roots: &FxRoots,
    ibps: &Assets<SkinnedMeshInverseBindposes>,
    palettes: &mut RigPalettes,
    seats: &mut Vec<(Entity, GlobalTransform)>,
) {
    for (rig, skin) in rigs.iter_mut() {
        let Ok((_, root_g)) = roots.get(rig.pose.joints_root) else {
            continue;
        };
        let root_g = *root_g;
        let special = rig.pose.has_special && cam_basis.is_some();
        let refresh = rig.pose.pose_dirty
            || rig.last_root != Some(root_g)
            || rig.last_special != special
            || (special && rig.pose.has_billboard);
        if !refresh {
            continue;
        }
        let rig = rig.into_inner();
        let worlds = rig.worlds(root_g, cam_basis);
        if let Some(ibp) = skin.and_then(|s| ibps.get(&s.ibp).map(|i| (s, i))) {
            let origin = crate::rig_palette::rebase_origin(root_g.translation());
            let rebased: Vec<GlobalTransform> = worlds
                .iter()
                .map(|&w| crate::rig_palette::rebase_global(w, origin))
                .collect();
            palettes.write_rig_worlds(ibp.0, &rebased, ibp.1, origin);
        }
        seats.extend(
            rig.pose
                .anchors
                .iter()
                .filter_map(|&(bone, anchor)| worlds.get(bone as usize).map(|&w| (anchor, w))),
        );
        rig.pose.pose_dirty = false;
        rig.last_root = Some(root_g);
        rig.last_special = special;
    }
}
