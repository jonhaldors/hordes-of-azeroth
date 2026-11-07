use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

use benilla_app::{Interact, ObjectFields, Objects, ViewerOverheadHeight};
use benilla_protocol::guid;
use benilla_world::interact::GoPickPart;
use benilla_world::view::WorldCamera;
use benilla_world::world_unit::{ViewerUnit, WorldUnit};
use bevy::camera::primitives::Aabb;
use bevy::prelude::*;

const UNIT_REACH: f32 = 5.4;
const OBJECT_REACH: f32 = 5.0;
const MAX_HEIGHT_DIFFERENCE: f32 = 4.0;
const SWITCH_MARGIN: f32 = 0.75;
const OBJECT_HEAD_HEIGHT: f32 = 1.6;
const UNIT_HEAD_FALLBACK: f32 = 2.2;
const PLAYER_HEIGHT_SMOOTHING: f32 = 0.02;
const AUTO_USE_INTERVAL_SECS: f64 = 0.15;
const AUTO_USE_RETRY_SECS: f64 = 4.0;
const USABLE_OBJECT_TYPES: [u32; 4] = [2, 3, 10, 19];
const UNIT_FLAG_NOT_SELECTABLE: u32 = 0x0200_0000;
const OBJECT_FLAG_IN_USE: u32 = 0x01;
const OBJECT_FLAG_NO_INTERACT: u32 = 0x10;
const OBJECT_STATE_ACTIVE: u32 = 0;
const PART_OWNER_HOPS: usize = 8;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Candidate {
    pub guid: u64,
    pub entity: Entity,
    pub unit: bool,
    pub entry: u32,
    pub detail: u32,
    pub distance: f32,
    pub feet: Vec3,
    pub head_height: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Pick {
    pub candidate: Candidate,
    pub screen: Option<Vec2>,
}

#[derive(Default, Debug)]
pub struct InteractState {
    pub object_reach: HashMap<u32, f32>,
    pub skip_units: bool,
    pub skip_entries: HashSet<u32>,
    pub skip_types: HashSet<u32>,
    pub auto_use_entries: HashSet<u32>,
    pub auto_used_at: HashMap<u64, f64>,
    pub auto_checked_at: Option<f64>,
    pub nearby: Vec<Candidate>,
    pub pick: Option<Pick>,
    pub player_head: Option<Vec2>,
    pub player_height: f32,
    pub requests: Vec<Entity>,
    pub now: f64,
}

impl InteractState {
    fn is_skipped(&self, candidate: &Candidate) -> bool {
        if candidate.unit {
            return self.skip_units;
        }
        self.skip_entries.contains(&candidate.entry) || self.skip_types.contains(&candidate.detail)
    }

    fn reach_of(&self, entry: u32, unit: bool) -> f32 {
        if unit {
            return UNIT_REACH;
        }
        self.object_reach
            .get(&entry)
            .copied()
            .unwrap_or(OBJECT_REACH)
    }

    pub fn choose(&self, kept: Option<u64>) -> Option<Candidate> {
        let mut usable = self.nearby.iter().filter(|c| !self.is_skipped(c));
        let best = usable
            .clone()
            .min_by(|a, b| a.distance.total_cmp(&b.distance))
            .copied()?;
        let kept = kept.and_then(|guid| usable.find(|c| c.guid == guid).copied());
        match kept {
            Some(kept) if best.distance > kept.distance - SWITCH_MARGIN => Some(kept),
            _ => Some(best),
        }
    }

    pub fn interact(&mut self) -> bool {
        let Some(pick) = self.pick else {
            return false;
        };
        self.requests.push(pick.candidate.entity);
        true
    }

    pub fn auto_use(&mut self) -> bool {
        if self.auto_use_entries.is_empty() {
            return false;
        }
        let now = self.now;
        if self
            .auto_checked_at
            .is_some_and(|at| now - at < AUTO_USE_INTERVAL_SECS)
        {
            return false;
        }
        self.auto_checked_at = Some(now);
        self.auto_used_at
            .retain(|_, used| now - *used < AUTO_USE_RETRY_SECS);
        let nearest = self
            .nearby
            .iter()
            .filter(|c| !c.unit && self.auto_use_entries.contains(&c.entry))
            .filter(|c| !self.auto_used_at.contains_key(&c.guid))
            .min_by(|a, b| a.distance.total_cmp(&b.distance))
            .copied();
        let Some(nearest) = nearest else {
            return false;
        };
        self.auto_used_at.insert(nearest.guid, now);
        self.requests.push(nearest.entity);
        true
    }
}

#[derive(Clone, Default)]
pub struct SharedInteract(pub Rc<RefCell<InteractState>>);

fn unit_candidate(fields: &ObjectFields) -> Option<u32> {
    let npc_flags = fields.unit_npc_flags();
    let alive = fields.unit_health().is_some_and(|health| health > 0);
    let selectable = fields.unit_flags() & UNIT_FLAG_NOT_SELECTABLE == 0;
    (npc_flags != 0 && alive && selectable).then_some(npc_flags)
}

fn object_candidate(fields: &ObjectFields) -> Option<u32> {
    let object_type = u32::try_from(fields.gameobject_type_id()).ok()?;
    let busy = fields.gameobject_flags() & (OBJECT_FLAG_IN_USE | OBJECT_FLAG_NO_INTERACT) != 0;
    let active = fields.gameobject_state() == Some(OBJECT_STATE_ACTIVE);
    (USABLE_OBJECT_TYPES.contains(&object_type) && !busy && !active).then_some(object_type)
}

fn object_scale(fields: &ObjectFields) -> f32 {
    fields
        .object_scale_x()
        .filter(|scale| *scale > 0.05)
        .unwrap_or(1.0)
}

fn to_screen(camera: &Camera, eye: &GlobalTransform, world: Vec3) -> Option<Vec2> {
    let ndc = camera.world_to_ndc(eye, world)?;
    if ndc.z <= 0.0 || ndc.z > 1.0 {
        return None;
    }
    Some(Vec2::new((ndc.x + 1.0) * 0.5, (ndc.y + 1.0) * 0.5))
}

fn owning_object(
    part: Entity,
    objects: &HashSet<Entity>,
    parents: &Query<&ChildOf>,
) -> Option<Entity> {
    let mut entity = part;
    for _ in 0..PART_OWNER_HOPS {
        if objects.contains(&entity) {
            return Some(entity);
        }
        entity = parents.get(entity).ok()?.parent();
    }
    None
}

fn world_box(aabb: &Aabb, transform: &GlobalTransform) -> (Vec3, Vec3) {
    let center = Vec3::from(aabb.center);
    let half = Vec3::from(aabb.half_extents);
    let mut min = Vec3::splat(f32::MAX);
    let mut max = Vec3::splat(f32::MIN);
    for corner in 0..8u8 {
        let side = |bit: u8| if corner & bit == 0 { -1.0 } else { 1.0 };
        let point = transform.transform_point(center + half * Vec3::new(side(1), side(2), side(4)));
        min = min.min(point);
        max = max.max(point);
    }
    (min, max)
}

fn object_boxes(
    objects: &HashSet<Entity>,
    parts: &Query<(Entity, &Aabb, &GlobalTransform), With<GoPickPart>>,
    parents: &Query<&ChildOf>,
) -> HashMap<Entity, (Vec3, Vec3)> {
    let mut boxes: HashMap<Entity, (Vec3, Vec3)> = HashMap::new();
    for (part, aabb, transform) in parts {
        let Some(owner) = owning_object(part, objects, parents) else {
            continue;
        };
        let (min, max) = world_box(aabb, transform);
        boxes
            .entry(owner)
            .and_modify(|joined| {
                joined.0 = joined.0.min(min);
                joined.1 = joined.1.max(max);
            })
            .or_insert((min, max));
    }
    boxes
}

fn distance_to_box(from: Vec3, bounds: (Vec3, Vec3)) -> f32 {
    from.clamp(bounds.0, bounds.1).distance(from)
}

fn smoothed_height(previous: f32, measured: f32) -> f32 {
    if previous > 0.0 {
        previous + (measured - previous) * PLAYER_HEIGHT_SMOOTHING
    } else {
        measured
    }
}

#[allow(clippy::type_complexity)]
pub fn update_interact(
    time: Res<Time<Real>>,
    objects: Objects,
    bodies: Query<(&GlobalTransform, Option<&WorldUnit>)>,
    me: Query<(&GlobalTransform, Option<&WorldUnit>), With<ViewerUnit>>,
    cameras: Query<(&Camera, &GlobalTransform), With<WorldCamera>>,
    shared: NonSend<SharedInteract>,
    mut interacts: MessageWriter<Interact>,
    overhead: Option<Res<ViewerOverheadHeight>>,
    object_parts: Query<(Entity, &Aabb, &GlobalTransform), With<GoPickPart>>,
    parents: Query<&ChildOf>,
) {
    let mut state = shared.0.borrow_mut();
    state.now = time.elapsed_secs_f64();
    for entity in state.requests.drain(..) {
        interacts.write(Interact(entity));
    }
    let player = objects.player();
    let Ok((my_body, my_unit)) = me.single() else {
        state.nearby.clear();
        state.pick = None;
        state.player_head = None;
        return;
    };
    let from = my_body.translation();
    let object_entities: HashSet<Entity> = objects
        .iter()
        .filter(|(object_guid, _, _)| guid::is_gameobject(*object_guid))
        .map(|(_, entity, _)| entity)
        .collect();
    let boxes = object_boxes(&object_entities, &object_parts, &parents);
    let mut nearby = Vec::new();
    for (object_guid, entity, fields) in objects.iter() {
        if Some(entity) == player {
            continue;
        }
        let unit = guid::high(object_guid) == guid::HIGH_UNIT;
        let detail = if unit {
            unit_candidate(fields)
        } else if guid::is_gameobject(object_guid) {
            object_candidate(fields)
        } else {
            None
        };
        let (Some(detail), Ok((body, world_unit))) = (detail, bodies.get(entity)) else {
            continue;
        };
        let feet = body.translation();
        let entry = fields.object_entry().unwrap_or(0);
        let distance = match boxes.get(&entity) {
            Some(&bounds) if !unit => distance_to_box(from, bounds),
            _ => feet.distance(from),
        };
        let too_high = (feet.y - from.y).abs() > MAX_HEIGHT_DIFFERENCE;
        if too_high || distance > state.reach_of(entry, unit) {
            continue;
        }
        let head_height = if unit {
            world_unit.map_or(UNIT_HEAD_FALLBACK, |w| w.height)
        } else {
            OBJECT_HEAD_HEIGHT * object_scale(fields)
        };
        nearby.push(Candidate {
            guid: object_guid,
            entity,
            unit,
            entry,
            detail,
            distance,
            feet,
            head_height,
        });
    }
    state.nearby = nearby;
    let kept = state.pick.map(|pick| pick.candidate.guid);
    let chosen = state.choose(kept);
    let camera = cameras.iter().find(|(camera, _)| camera.is_active);
    state.pick = chosen.map(|candidate| Pick {
        candidate,
        screen: camera.and_then(|(camera, eye)| {
            to_screen(
                camera,
                eye,
                candidate.feet + Vec3::Y * candidate.head_height,
            )
        }),
    });
    let measured = overhead
        .and_then(|o| o.0)
        .or_else(|| my_unit.map(|w| w.height));
    if let Some(height) = measured.filter(|h| *h > 0.0) {
        state.player_height = smoothed_height(state.player_height, height);
    }
    let head_height = if state.player_height > 0.0 {
        state.player_height
    } else {
        UNIT_HEAD_FALLBACK
    };
    state.player_head =
        camera.and_then(|(camera, eye)| to_screen(camera, eye, from + Vec3::Y * head_height));
}

#[cfg(test)]
mod tests {
    use super::*;

    fn candidate(guid: u64, unit: bool, entry: u32, distance: f32) -> Candidate {
        Candidate {
            guid,
            entity: Entity::from_raw_u32(guid as u32).unwrap(),
            unit,
            entry,
            detail: 3,
            distance,
            feet: Vec3::ZERO,
            head_height: 1.0,
        }
    }

    #[test]
    fn an_object_is_reached_from_any_side_of_its_box() {
        let chest = (Vec3::new(0.0, 0.0, 0.0), Vec3::new(4.0, 1.0, 2.0));
        assert_eq!(distance_to_box(Vec3::new(2.0, 0.0, 1.0), chest), 0.0);
        assert!((distance_to_box(Vec3::new(-3.0, 0.0, 1.0), chest) - 3.0).abs() < 1e-5);
        assert!((distance_to_box(Vec3::new(7.0, 0.0, 1.0), chest) - 3.0).abs() < 1e-5);
    }

    #[test]
    fn a_box_follows_its_part_transform() {
        let aabb = Aabb::from_min_max(Vec3::new(-1.0, 0.0, -1.0), Vec3::new(1.0, 1.0, 1.0));
        let transform =
            GlobalTransform::from(Transform::from_xyz(10.0, 0.0, 0.0).with_scale(Vec3::splat(2.0)));
        let (min, max) = world_box(&aabb, &transform);
        assert!(min.abs_diff_eq(Vec3::new(8.0, 0.0, -2.0), 1e-5));
        assert!(max.abs_diff_eq(Vec3::new(12.0, 2.0, 2.0), 1e-5));
    }

    #[test]
    fn the_kept_pick_stays_until_another_is_clearly_closer() {
        let state = InteractState {
            nearby: vec![candidate(1, true, 10, 3.0), candidate(2, true, 11, 2.5)],
            ..Default::default()
        };
        assert_eq!(state.choose(Some(1)).unwrap().guid, 1);
        assert_eq!(state.choose(None).unwrap().guid, 2);
        let state = InteractState {
            nearby: vec![candidate(1, true, 10, 3.0), candidate(2, true, 11, 2.0)],
            ..Default::default()
        };
        assert_eq!(state.choose(Some(1)).unwrap().guid, 2);
    }

    #[test]
    fn skipped_kinds_are_never_picked() {
        let mut state = InteractState {
            nearby: vec![candidate(1, true, 10, 1.0), candidate(2, false, 50, 4.0)],
            skip_units: true,
            ..Default::default()
        };
        assert_eq!(state.choose(None).unwrap().guid, 2);
        state.skip_entries.insert(50);
        assert_eq!(state.choose(None), None);
    }

    #[test]
    fn auto_use_opens_each_object_once_per_retry_window() {
        let mut state = InteractState {
            nearby: vec![candidate(7, false, 50, 2.0)],
            ..Default::default()
        };
        state.auto_use_entries.insert(50);
        assert!(state.auto_use());
        state.now = 1.0;
        assert!(!state.auto_use());
        state.now = 5.0;
        assert!(state.auto_use());
        assert_eq!(state.requests.len(), 2);
    }
}
