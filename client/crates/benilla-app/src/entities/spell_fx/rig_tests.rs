use std::time::Duration;

use benilla_assets::{
    AnimClip, BillboardInfo, GlobalBone, GlobalSeqChannel, ModelAnimations, ModelJoint,
    ModelSkeleton, PoseBone, PoseClip, PoseSource, PoseTrack,
};
use benilla_formats::{BillboardKind, ParentArm, ParentBasis};
use benilla_world::billboard::BillboardCard;
use benilla_world::rig_anim::{RigFrame, RigPose};
use benilla_world::rig_palette::RigPalettes;
use benilla_world::view::WorldCamera;
use bevy::animation::animation_curves::{AnimatableCurve, AnimatableKeyframeCurve};
use bevy::animation::graph::AnimationGraph;
use bevy::animation::{animated_field, AnimationClip};
use bevy::asset::AssetPlugin;
use bevy::ecs::world::CommandQueue;
use bevy::mesh::skinning::SkinnedMeshInverseBindposes;
use bevy::time::TimeUpdateStrategy;

use super::lifecycle::{FxDecay, ANIM_DECAY, ANIM_HOLD};
use super::*;

#[derive(Component)]
struct Wiggle;

#[derive(Component)]
struct Drift(Vec3);

fn wiggle_hosts(time: Res<Time>, mut rigs: Query<&mut RigPose, With<Wiggle>>) {
    let t = time.elapsed_secs();
    for mut rig in &mut rigs {
        let n = rig.locals.len();
        for i in 0..n {
            let a = t * (1.3 + 0.17 * i as f32) + i as f32;
            rig.locals[i].rotation =
                Quat::from_rotation_x(0.4 * a.sin()) * Quat::from_rotation_z(0.3 * a.cos());
        }
        rig.pose_dirty = true;
    }
}

fn drift_parents(time: Res<Time>, mut parents: Query<(&mut Transform, &Drift)>) {
    let t = time.elapsed_secs();
    for (mut tf, drift) in &mut parents {
        tf.translation = drift.0 + Vec3::new(2.0 * (0.7 * t).sin(), 0.3 * t.cos(), 1.5 * t);
        tf.rotation = Quat::from_rotation_y(0.9 * t) * Quat::from_rotation_x(0.1 * t.sin());
    }
}

fn harness(data: Option<&std::path::Path>) -> App {
    let mut app = App::new();
    app.add_plugins(MinimalPlugins);
    if let Some(d) = data {
        benilla_assets::register_mpq_source(&mut app, d).expect("mpq source");
    }
    app.add_plugins((
        AssetPlugin::default(),
        bevy::animation::AnimationPlugin,
        bevy::transform::TransformPlugin,
    ));
    app.init_asset::<Image>()
        .init_asset::<Mesh>()
        .init_asset::<SkinnedMeshInverseBindposes>();
    if data.is_some() {
        benilla_assets::register_asset_loaders(&mut app);
    }
    app.init_resource::<benilla_world::lighting::PropProbes>();
    benilla_world::rig_anim::plugin(&mut app);
    app.add_plugins(benilla_world::billboard::BillboardPlugin);
    benilla_world::rig_palette::plugin(&mut app);
    app.add_systems(
        Update,
        (lifecycle::advance_fx_anim, wiggle_hosts, drift_parents),
    );
    app.insert_resource(TimeUpdateStrategy::ManualDuration(Duration::from_millis(
        16,
    )));
    app.world_mut()
        .spawn((WorldCamera, Transform::from_xyz(-9450.0, 70.0, 60.0)));
    app
}

fn joint(parent: i16, t: Vec3) -> ModelJoint {
    ModelJoint {
        parent,
        local_translation: t,
        billboard: None,
        parent_arm: None,
    }
}

fn host_skeleton() -> ModelSkeleton {
    ModelSkeleton {
        joints: vec![
            joint(-1, Vec3::ZERO),
            ModelJoint {
                billboard: Some(BillboardKind::Spherical),
                ..joint(0, Vec3::new(0.0, 1.5, 0.0))
            },
            ModelJoint {
                parent_arm: Some(ParentArm {
                    ignore_translate: false,
                    basis: ParentBasis::RootDirection,
                }),
                ..joint(1, Vec3::new(0.2, 0.3, 0.0))
            },
            joint(0, Vec3::new(-0.4, 0.9, 0.1)),
        ],
        spine_bone: None,
        head_bone: None,
    }
}

struct Parents {
    slots: Vec<Entity>,
}

fn spawn_parents(app: &mut App) -> Parents {
    let mut queue = CommandQueue::default();
    let mut commands = Commands::new(&mut queue, app.world());
    let world_root = commands
        .spawn((
            Transform::from_xyz(-9464.31, 62.17, 56.91),
            Visibility::default(),
            Drift(Vec3::new(-9464.31, 62.17, 56.91)),
        ))
        .id();
    let unit = commands
        .spawn((
            Transform::from_xyz(-9460.5, 63.0, 50.25).with_scale(Vec3::splat(1.3)),
            Visibility::default(),
            Drift(Vec3::new(-9460.5, 63.0, 50.25)),
            Wiggle,
        ))
        .id();
    let mut unit_rig = RigPose::new(unit, &host_skeleton());
    let unit_bb = unit_rig.anchor_for(&mut commands, unit, 1).unwrap();
    let unit_arm = unit_rig.anchor_for(&mut commands, unit, 2).unwrap();
    let unit_plain = unit_rig.anchor_for(&mut commands, unit, 3).unwrap();
    commands.entity(unit).insert(unit_rig);
    let mount = commands
        .spawn((
            Transform::from_xyz(-9470.0, 61.0, 58.0),
            Visibility::default(),
            Drift(Vec3::new(-9470.0, 61.0, 58.0)),
            Wiggle,
        ))
        .id();
    let mut mount_rig = RigPose::new(mount, &host_skeleton());
    let mount_seat = mount_rig.anchor_for(&mut commands, mount, 1).unwrap();
    commands.entity(mount).insert(mount_rig);
    let rider = commands.spawn(Wiggle).id();
    let seat = commands
        .spawn((
            Transform::from_xyz(0.1, 0.2, -0.3),
            Visibility::default(),
            RigFrame(rider),
        ))
        .id();
    commands.entity(mount_seat).add_child(seat);
    let mut rider_rig = RigPose::new(seat, &host_skeleton());
    let rider_chest = rider_rig.anchor_for(&mut commands, rider, 3).unwrap();
    let rider_head = rider_rig.anchor_for(&mut commands, rider, 1).unwrap();
    commands.entity(rider).insert(rider_rig);
    let item = commands
        .spawn((
            Transform::from_xyz(-9455.0, 62.5, 53.0),
            Visibility::default(),
            Drift(Vec3::new(-9455.0, 62.5, 53.0)),
        ))
        .id();
    let item_sk = host_skeleton();
    let item_joints = benilla_world::rig_palette::spawn_joints(&mut commands, item, item, &item_sk);
    commands.entity(item).insert(
        benilla_world::billboard::BillboardJointRig::new(&item_sk, &item_joints, item).unwrap(),
    );
    queue.apply(app.world_mut());
    Parents {
        slots: vec![
            world_root,
            unit_bb,
            unit_arm,
            unit_plain,
            rider_chest,
            rider_head,
            item_joints[1],
            item_joints[3],
        ],
    }
}

struct Lane {
    root: Entity,
    owners: Vec<Entity>,
    slot: u16,
    cards: Vec<Entity>,
    collapsed: bool,
}

struct Pair {
    name: String,
    old: Lane,
    new: Lane,
    decays: bool,
}

fn spawn_lane(
    commands: &mut Commands,
    palettes: &mut RigPalettes,
    dm: &DisplayModel,
    parent: Entity,
    offset: Transform,
    stage: Option<FxStage>,
    collapse: bool,
) -> Lane {
    let root = commands.spawn((offset, Visibility::default())).id();
    commands.entity(parent).add_child(root);
    let (mut bones, _) = arm_effect_rig(commands, root, dm, None, stage, collapse);
    let slot = bones.allocate_skin(commands, root, dm, palettes);
    let owners: Vec<Entity> = (0..dm.skeleton.joints.len())
        .filter_map(|b| bones.owner(commands, b as u16))
        .collect();
    let cards = dm
        .skeleton
        .joints
        .iter()
        .enumerate()
        .filter_map(|(b, j)| j.billboard.map(|kind| (b, kind)))
        .map(|(b, kind)| {
            let info = BillboardInfo {
                bone: b as u16,
                pivot: Vec3::ZERO,
                kind,
                scale_anim: None,
                seq_translations: vec![],
            };
            commands
                .spawn(BillboardCard::following_joint(&info, owners[b]))
                .id()
        })
        .collect();
    let collapsed = matches!(bones, EffectBones::Rig(_));
    bones.finish(commands, root);
    Lane {
        root,
        owners,
        slot,
        cards,
        collapsed,
    }
}

fn spawn_pairs(app: &mut App, models: &[(String, DisplayModel)], parents: &Parents) -> Vec<Pair> {
    let mut palettes = app.world_mut().remove_resource::<RigPalettes>().unwrap();
    let mut queue = CommandQueue::default();
    let mut commands = Commands::new(&mut queue, app.world());
    let mut pairs = Vec::new();
    for (i, (name, dm)) in models.iter().enumerate() {
        let parent = parents.slots[i % parents.slots.len()];
        let offset = Transform::from_xyz(0.05 * (i % 7) as f32, 0.1, -0.02 * (i % 5) as f32)
            .with_rotation(Quat::from_rotation_y(0.3 * i as f32));
        let decays = dm
            .animations
            .as_ref()
            .is_some_and(|a| a.find(ANIM_DECAY).is_some());
        let stage = match i % 3 {
            0 => Some(FxStage::State),
            1 => Some(FxStage::Relive),
            _ => None,
        };
        let old = spawn_lane(
            &mut commands,
            &mut palettes,
            dm,
            parent,
            offset,
            stage,
            false,
        );
        let new = spawn_lane(
            &mut commands,
            &mut palettes,
            dm,
            parent,
            offset,
            stage,
            true,
        );
        pairs.push(Pair {
            name: name.clone(),
            old,
            new,
            decays: decays && stage.is_some(),
        });
    }
    queue.apply(app.world_mut());
    app.world_mut().insert_resource(palettes);
    pairs
}

fn bits(g: &GlobalTransform) -> [u32; 12] {
    g.affine().to_cols_array().map(f32::to_bits)
}

fn mat_bits(m: &Mat4) -> [u32; 16] {
    m.to_cols_array().map(f32::to_bits)
}

#[derive(Default)]
struct Tally {
    bones: u64,
    rows: u64,
    cards: u64,
    players: u64,
    mismatches: Vec<String>,
}

fn compare(app: &App, pairs: &[Pair], frame: usize, tally: &mut Tally) {
    let world = app.world();
    let palettes = world.resource::<RigPalettes>();
    for p in pairs {
        for (b, (&o, &n)) in p.old.owners.iter().zip(&p.new.owners).enumerate() {
            let (go, gn) = (
                world.get::<GlobalTransform>(o).unwrap(),
                world.get::<GlobalTransform>(n).unwrap(),
            );
            tally.bones += 1;
            if tally.mismatches.len() < 4 && bits(go) != bits(gn) {
                let local_old = world.get::<Transform>(o).copied();
                let local_new = world
                    .get::<benilla_world::rig_anim::FxRig>(p.new.root)
                    .and_then(|r| r.locals().get(b).copied());
                let root_old = world.get::<GlobalTransform>(p.old.root).map(bits);
                let root_new = world.get::<GlobalTransform>(p.new.root).map(bits);
                tally.mismatches.push(format!(
                    "{} frame {frame} bone {b} locals {local_old:?} vs {local_new:?} roots equal {}",
                    p.name,
                    root_old == root_new
                ));
            }
            if bits(go) != bits(gn) {
                tally.mismatches.push(format!(
                    "{} frame {frame} bone {b}: {:?} vs {:?}",
                    p.name,
                    go.affine(),
                    gn.affine()
                ));
            }
        }
        let n = p.old.owners.len();
        if p.old.slot != 0 || p.new.slot != 0 {
            let ro = palettes.rig_rows(p.old.slot, n).unwrap_or_default();
            let rn = palettes.rig_rows(p.new.slot, n).unwrap_or_default();
            tally.rows += ro.len() as u64;
            let same = ro.len() == rn.len()
                && ro.iter().zip(&rn).all(|(a, b)| mat_bits(a) == mat_bits(b))
                && palettes.slot_origin(p.old.slot) == palettes.slot_origin(p.new.slot);
            if !same {
                tally
                    .mismatches
                    .push(format!("{} frame {frame}: palette rows differ", p.name));
            }
        }
        for (&co, &cn) in p.old.cards.iter().zip(&p.new.cards) {
            tally.cards += 1;
            let (a, b) = (
                world.get::<GlobalTransform>(co).unwrap(),
                world.get::<GlobalTransform>(cn).unwrap(),
            );
            if bits(a) != bits(b) {
                tally
                    .mismatches
                    .push(format!("{} frame {frame}: card differs", p.name));
            }
        }
        let seeks = |root: Entity| -> Vec<(usize, u32)> {
            world
                .get::<AnimationPlayer>(root)
                .map(|pl| {
                    let mut v: Vec<(usize, u32)> = pl
                        .playing_animations()
                        .map(|(n, a)| (n.index(), a.seek_time().to_bits()))
                        .collect();
                    v.sort_unstable();
                    v
                })
                .unwrap_or_default()
        };
        tally.players += 1;
        if seeks(p.old.root) != seeks(p.new.root) {
            tally
                .mismatches
                .push(format!("{} frame {frame}: players differ", p.name));
        }
    }
}

fn orbit_camera(app: &mut App, frame: usize) {
    let a = frame as f32 * 0.11;
    let eye = Vec3::new(
        -9462.0 + 12.0 * a.cos(),
        66.0 + 3.0 * (0.5 * a).sin(),
        55.0 + 12.0 * a.sin(),
    );
    let mut q = app
        .world_mut()
        .query_filtered::<&mut Transform, With<WorldCamera>>();
    for mut tf in q.iter_mut(app.world_mut()) {
        *tf = Transform::from_translation(eye).looking_at(Vec3::new(-9463.0, 63.0, 55.0), Vec3::Y);
    }
}

fn run_and_compare(app: &mut App, pairs: &[Pair], frames: usize) -> Tally {
    let mut tally = Tally::default();
    for frame in 0..frames {
        orbit_camera(app, frame);
        if frame == frames / 2 {
            for p in pairs.iter().filter(|p| p.decays) {
                app.world_mut().entity_mut(p.old.root).insert(FxDecay);
                app.world_mut().entity_mut(p.new.root).insert(FxDecay);
            }
        }
        app.update();
        compare(app, pairs, frame, &mut tally);
    }
    tally
}

fn report(what: &str, pairs: &[Pair], tally: &Tally) {
    let collapsed = pairs.iter().filter(|p| p.new.collapsed).count();
    eprintln!(
        "{what}: {} pairs ({collapsed} collapsed), compared {} bone frames, {} palette rows, {} \
         card frames, {} player frames, {} mismatches",
        pairs.len(),
        tally.bones,
        tally.rows,
        tally.cards,
        tally.players,
        tally.mismatches.len()
    );
    for m in tally.mismatches.iter().take(12) {
        eprintln!("  {m}");
    }
    assert!(
        tally.mismatches.is_empty(),
        "{what}: the collapsed effect rig diverged from the joint path"
    );
}

fn synthetic_model(app: &mut App, bones: usize, seed: f32) -> DisplayModel {
    let joints: Vec<ModelJoint> = (0..bones)
        .map(|i| {
            let parent = if i == 0 { -1 } else { ((i - 1) / 2) as i16 };
            ModelJoint {
                parent,
                local_translation: Vec3::new(0.11 * i as f32, 0.37, -0.05 * seed),
                billboard: match i % 9 {
                    3 => Some(BillboardKind::Spherical),
                    5 => Some(BillboardKind::LockZ),
                    7 => Some(BillboardKind::LockX),
                    8 => Some(BillboardKind::LockY),
                    _ => None,
                },
                parent_arm: match i % 11 {
                    4 => Some(ParentArm {
                        ignore_translate: false,
                        basis: ParentBasis::RootBasis,
                    }),
                    6 => Some(ParentArm {
                        ignore_translate: true,
                        basis: ParentBasis::UnitNormalize,
                    }),
                    9 => Some(ParentArm {
                        ignore_translate: false,
                        basis: ParentBasis::RootDirection,
                    }),
                    _ => None,
                },
            }
        })
        .collect();
    let skeleton = ModelSkeleton {
        joints,
        spine_bone: None,
        head_bone: None,
    };
    let mut graph = AnimationGraph::new();
    let root = graph.root;
    let mut pose = PoseSource::default();
    let mut clips = Vec::new();
    for (seq, (anim_id, looping, span)) in [
        (0u16, false, 0.4f32),
        (ANIM_HOLD, true, 0.7),
        (ANIM_DECAY, false, 0.5),
    ]
    .into_iter()
    .enumerate()
    {
        let mut clip = AnimationClip::default();
        let mut pclip = PoseClip::default();
        for b in 0..bones as u16 {
            let f = b as f32 + seed + seq as f32;
            let r: Vec<(f32, Quat)> = (0..4)
                .map(|k| {
                    let t = span * k as f32 / 3.0;
                    (
                        t,
                        Quat::from_rotation_x(0.3 * (f + k as f32).sin())
                            * Quat::from_rotation_y(0.2 * k as f32),
                    )
                })
                .collect();
            let t: Vec<(f32, Vec3)> = vec![
                (0.0, Vec3::new(0.11 * b as f32, 0.37, 0.0)),
                (span, Vec3::new(0.11 * b as f32, 0.37 + 0.1 * f.cos(), 0.05)),
            ];
            let s: Vec<(f32, Vec3)> = vec![
                (0.0, Vec3::ONE),
                (span * 0.5, Vec3::new(1.0 + 0.3 * f.sin().abs(), 0.6, 1.4)),
                (span, Vec3::splat(0.8)),
            ];
            clip.add_curve_to_target(
                benilla_assets::bone_target_id(b),
                AnimatableCurve::new(
                    animated_field!(Transform::rotation),
                    AnimatableKeyframeCurve::new(r.iter().copied()).unwrap(),
                ),
            );
            clip.add_curve_to_target(
                benilla_assets::bone_target_id(b),
                AnimatableCurve::new(
                    animated_field!(Transform::translation),
                    AnimatableKeyframeCurve::new(t.iter().copied()).unwrap(),
                ),
            );
            if b % 3 == 1 {
                clip.add_curve_to_target(
                    benilla_assets::bone_target_id(b),
                    AnimatableCurve::new(
                        animated_field!(Transform::scale),
                        AnimatableKeyframeCurve::new(s.iter().copied()).unwrap(),
                    ),
                );
            }
            pclip.push(PoseBone {
                bone: b,
                translation: PoseTrack::new(&t),
                rotation: PoseTrack::new(&r),
                scale: if b % 3 == 1 {
                    PoseTrack::new(&s)
                } else {
                    PoseTrack::default()
                },
            });
        }
        let handle = app
            .world_mut()
            .resource_mut::<Assets<AnimationClip>>()
            .add(clip);
        let node = graph.add_clip(handle, 1.0, root);
        pose.set_node(node, pose.clips.len() as u32, 0);
        pose.clips.push(pclip);
        clips.push(AnimClip {
            anim_id,
            seq_index: seq,
            node,
            blend_node: None,
            looping,
            duration: span,
            move_speed: 0.0,
            blend_time: 0.0,
            bounds_center: Vec3::ZERO,
            bounds_radius: 0.0,
            bounds_min: Vec3::ZERO,
            bounds_max: Vec3::ZERO,
            events: Vec::new().into(),
            arm_nodes: None,
            upper_node: None,
            frequency: 0,
            replay: (0, 0),
            poses_bones: true,
        });
    }
    let graph = app
        .world_mut()
        .resource_mut::<Assets<AnimationGraph>>()
        .add(graph);
    let global_bones = vec![
        GlobalBone {
            bone: 3,
            translation: None,
            rotation: None,
            scale: Some(GlobalSeqChannel {
                period: 0.9,
                keys: vec![
                    (0.0, Vec3::ONE),
                    (0.45, Vec3::new(2.0, 1.5, 0.5)),
                    (0.9, Vec3::ONE),
                ],
            }),
        },
        GlobalBone {
            bone: (bones - 1) as u16,
            translation: Some(GlobalSeqChannel {
                period: 1.3,
                keys: vec![(0.0, Vec3::ZERO), (1.3, Vec3::new(0.2, 0.4, -0.1))],
            }),
            rotation: Some(GlobalSeqChannel {
                period: 0.6,
                keys: vec![(0.0, Quat::IDENTITY), (0.6, Quat::from_rotation_z(1.1))],
            }),
            scale: None,
        },
    ];
    let ibp: Vec<Mat4> = (0..bones)
        .map(|i| Mat4::from_translation(-Vec3::new(0.11 * i as f32, 0.37 * i as f32, 0.0)))
        .collect();
    let ibp = app
        .world_mut()
        .resource_mut::<Assets<SkinnedMeshInverseBindposes>>()
        .add(SkinnedMeshInverseBindposes::from(ibp));
    DisplayModel {
        skeleton,
        inverse_bindposes: Some(ibp),
        animations: Some(ModelAnimations {
            graph,
            clips,
            hand_close: [None, None],
            playable_animation_lookup: Vec::new(),
            animation_lookup: Vec::new(),
            global_bones,
            first_seq: None,
            pose: std::sync::Arc::new(pose),
        }),
        ..crate::entities::display::empty_shell()
    }
}

#[test]
fn synthetic_effect_rigs_match_the_joint_path_bit_for_bit() {
    let mut app = harness(None);
    let models: Vec<(String, DisplayModel)> = (0..24)
        .map(|i| {
            let bones = [27, 6, 13, 40][i % 4];
            (
                format!("synthetic#{i}"),
                synthetic_model(&mut app, bones, i as f32),
            )
        })
        .collect();
    app.update();
    app.update();
    let parents = spawn_parents(&mut app);
    let pairs = spawn_pairs(&mut app, &models, &parents);
    let tally = run_and_compare(&mut app, &pairs, 120);
    assert!(pairs.iter().all(|p| p.new.collapsed && !p.old.collapsed));
    assert!(tally.cards > 0 && tally.rows > 0);
    report("synthetic", &pairs, &tally);
}

#[test]
fn a_malformed_skeleton_stays_on_the_joint_path() {
    let sk = ModelSkeleton {
        joints: vec![joint(1, Vec3::X), joint(-1, Vec3::Y)],
        spine_bone: None,
        head_bone: None,
    };
    assert!(benilla_world::rig_anim::FxRig::new(Entity::PLACEHOLDER, &sk, None).is_none());
    let sk = ModelSkeleton {
        joints: vec![joint(-1, Vec3::X), joint(0, Vec3::Y), joint(7, Vec3::Z)],
        spine_bone: None,
        head_bone: None,
    };
    assert!(benilla_world::rig_anim::FxRig::new(Entity::PLACEHOLDER, &sk, None).is_some());
}

#[test]
fn client_spell_effect_models_match_the_joint_path_bit_for_bit() {
    let data = benilla_formats::wow_data_or_skip!();
    let chain = benilla_formats::open_chain(&data).expect("open chain");
    let limit: usize = std::env::var("WOW_FX_RIG_PARITY_LIMIT")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(usize::MAX);
    let mut names: Vec<String> = chain
        .list()
        .expect("listfile")
        .into_iter()
        .map(|e| e.name)
        .filter(|n| {
            let l = n.to_ascii_lowercase();
            (l.starts_with("spells\\") || l.starts_with("particles\\")) && l.ends_with(".m2")
        })
        .collect();
    names.sort();
    names.truncate(limit);
    let mut app = harness(Some(&data));
    let server = app.world().resource::<AssetServer>().clone();
    let handles: Vec<(String, Handle<benilla_assets::M2Model>)> = names
        .iter()
        .map(|n| (n.clone(), server.load(benilla_assets::m2_url(n))))
        .collect();
    for _ in 0..30_000 {
        app.update();
        let pending = handles.iter().any(|(_, h)| {
            !matches!(
                server.load_state(h),
                bevy::asset::LoadState::Loaded | bevy::asset::LoadState::Failed(_)
            )
        });
        if !pending {
            break;
        }
        std::thread::sleep(Duration::from_millis(1));
    }
    let models: Vec<(String, DisplayModel)> = {
        let assets = app.world().resource::<Assets<benilla_assets::M2Model>>();
        handles
            .iter()
            .filter_map(|(n, h)| assets.get(h).map(|m| (n, m)))
            .filter(|(_, m)| !m.skeleton.joints.is_empty())
            .map(|(n, m)| {
                (
                    n.clone(),
                    DisplayModel {
                        skeleton: m.skeleton.clone(),
                        inverse_bindposes: Some(m.inverse_bindposes.clone()),
                        animations: m.animations.clone(),
                        ..crate::entities::display::empty_shell()
                    },
                )
            })
            .collect()
    };
    assert!(
        models.len() > 100,
        "only {} effect models loaded",
        models.len()
    );
    let billboards = models
        .iter()
        .filter(|(_, m)| m.skeleton.joints.iter().any(|j| j.billboard.is_some()))
        .count();
    let arms = models
        .iter()
        .filter(|(_, m)| m.skeleton.joints.iter().any(|j| j.parent_arm.is_some()))
        .count();
    let gseq = models
        .iter()
        .filter(|(_, m)| {
            m.animations
                .as_ref()
                .is_some_and(|a| !a.global_bones.is_empty())
        })
        .count();
    let decay = models
        .iter()
        .filter(|(_, m)| {
            m.animations
                .as_ref()
                .is_some_and(|a| a.find(ANIM_DECAY).is_some())
        })
        .count();
    eprintln!(
        "client effects: {} rigged models of {} listed; billboard {billboards}, arm {arms}, \
         global-seq {gseq}, decay {decay}",
        models.len(),
        names.len()
    );
    let parents = spawn_parents(&mut app);
    let pairs = spawn_pairs(&mut app, &models, &parents);
    let kept: Vec<&str> = pairs
        .iter()
        .filter(|p| !p.new.collapsed)
        .map(|p| p.name.as_str())
        .collect();
    eprintln!("kept on the joint path: {kept:?}");
    let tally = run_and_compare(&mut app, &pairs, 90);
    report("client effects", &pairs, &tally);
}
