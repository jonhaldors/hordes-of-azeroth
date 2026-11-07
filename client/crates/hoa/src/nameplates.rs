use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;

use benilla_mlua::Table;
use benilla_ui::script::{add_in_game_event, ScriptValue, VmKind};
use bevy::prelude::*;

const TOKEN_PREFIX: &str = "nameplate";
const PLATE_ADDED: &str = "NAME_PLATE_UNIT_ADDED";
const PLATE_REMOVED: &str = "NAME_PLATE_UNIT_REMOVED";

pub fn add_plate_events() {
    add_in_game_event(PLATE_ADDED);
    add_in_game_event(PLATE_REMOVED);
}

#[derive(Default)]
pub struct PlateUnits {
    session: u64,
    slots: Vec<Option<u64>>,
    frames: HashMap<u64, Table>,
}

#[derive(Default, Debug, PartialEq)]
pub struct PlateChanges {
    pub removed: Vec<String>,
    pub added: Vec<String>,
}

pub fn plate_token(slot: usize) -> String {
    format!("{TOKEN_PREFIX}{}", slot + 1)
}

pub fn plate_slot(token: &str) -> Option<usize> {
    let prefix = token.get(..TOKEN_PREFIX.len())?;
    if !prefix.eq_ignore_ascii_case(TOKEN_PREFIX) {
        return None;
    }
    let number: usize = token[TOKEN_PREFIX.len()..].parse().ok()?;
    number.checked_sub(1)
}

impl PlateUnits {
    pub fn guid_of(&self, token: &str) -> Option<u64> {
        self.slots.get(plate_slot(token)?).copied().flatten()
    }

    pub fn token_of(&self, guid: u64) -> Option<String> {
        self.slots
            .iter()
            .position(|slot| *slot == Some(guid))
            .map(plate_token)
    }

    pub fn frame_of(&self, guid: u64) -> Option<Table> {
        self.frames.get(&guid).cloned()
    }

    pub fn frames(&self) -> impl Iterator<Item = &Table> {
        self.frames.values()
    }

    pub fn leaving(&self, session: u64, live: &[u64]) -> Vec<String> {
        if session != self.session {
            return Vec::new();
        }
        let live_guids: HashSet<u64> = live.iter().copied().collect();
        self.slots
            .iter()
            .enumerate()
            .filter(|(_, held)| held.is_some_and(|guid| !live_guids.contains(&guid)))
            .map(|(slot, _)| plate_token(slot))
            .collect()
    }

    pub fn sync(&mut self, session: u64, live: &[u64], mut frame_of: impl FnMut(u64) -> Option<Table>) -> PlateChanges {
        if session != self.session {
            self.session = session;
            self.slots.clear();
            self.frames.clear();
        }
        let live_guids: HashSet<u64> = live.iter().copied().collect();
        let mut changes = PlateChanges::default();
        for (slot, held) in self.slots.iter_mut().enumerate() {
            if held.is_some_and(|guid| !live_guids.contains(&guid)) {
                changes.removed.push(plate_token(slot));
                *held = None;
            }
        }
        self.frames.retain(|guid, _| live_guids.contains(guid));
        for &guid in live {
            if self.frames.contains_key(&guid) {
                continue;
            }
            let Some(frame) = frame_of(guid) else {
                continue;
            };
            self.frames.insert(guid, frame);
            let slot = match self.slots.iter().position(Option::is_none) {
                Some(free) => free,
                None => {
                    self.slots.push(None);
                    self.slots.len() - 1
                }
            };
            self.slots[slot] = Some(guid);
            changes.added.push(plate_token(slot));
        }
        changes
    }

    fn unchanged(&self, session: u64, live: &[u64]) -> bool {
        session == self.session && live.len() == self.frames.len() && live.iter().all(|guid| self.frames.contains_key(guid))
    }
}

#[derive(Clone, Default)]
pub struct SharedPlates(pub Rc<RefCell<PlateUnits>>);

pub fn track_nameplates(world: &mut World) {
    let Some(shared) = world.get_non_send_resource::<SharedPlates>().cloned() else {
        return;
    };
    benilla_app::run_hosted(world, |script| {
        let Some(script) = script.filter(|s| s.vm_kind() == VmKind::InGame) else {
            return;
        };
        let session = script.session();
        let live = script.nameplate_guids();
        if shared.0.borrow().unchanged(session, &live) {
            return;
        }
        let leaving = shared.0.borrow().leaving(session, &live);
        for token in leaving {
            script.fire_event(PLATE_REMOVED, vec![ScriptValue::Str(token)]);
        }
        let changes = shared.0.borrow_mut().sync(session, &live, |guid| script.nameplate_frame(guid));
        for token in changes.added {
            script.fire_event(PLATE_ADDED, vec![ScriptValue::Str(token)]);
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plate_tokens_count_from_one() {
        assert_eq!(plate_token(0), "nameplate1");
        assert_eq!(plate_slot("nameplate1"), Some(0));
        assert_eq!(plate_slot("NamePlate12"), Some(11));
        assert_eq!(plate_slot("nameplate0"), None);
        assert_eq!(plate_slot("nameplate"), None);
        assert_eq!(plate_slot("target"), None);
    }

    #[test]
    fn a_freed_slot_is_reused_and_reported() {
        let lua = benilla_mlua::Lua::new();
        let frame = || lua.create_table().unwrap();
        let mut plates = PlateUnits::default();
        let first = plates.sync(1, &[10, 20], |_| Some(frame()));
        assert_eq!(first.added.len(), 2);
        assert!(plates.guid_of("nameplate1").is_some());
        let gone = plates.token_of(10).unwrap();
        let next = [20, 30];
        assert_eq!(plates.leaving(1, &next), vec![gone.clone()]);
        assert_eq!(plates.guid_of(&gone), Some(10));
        let second = plates.sync(1, &next, |_| Some(frame()));
        assert_eq!(second.removed, vec![gone.clone()]);
        assert_eq!(second.added, vec![gone.clone()]);
        assert_eq!(plates.guid_of(&gone), Some(30));
        assert_eq!(
            plates.sync(1, &[20, 30], |_| Some(frame())),
            PlateChanges::default()
        );
    }

    #[test]
    fn a_new_vm_starts_the_numbering_over() {
        let lua = benilla_mlua::Lua::new();
        let mut plates = PlateUnits::default();
        plates.sync(1, &[10], |_| lua.create_table().ok());
        let after = plates.sync(2, &[20], |_| lua.create_table().ok());
        assert!(after.removed.is_empty());
        assert_eq!(after.added, vec!["nameplate1".to_string()]);
        assert_eq!(plates.guid_of("nameplate1"), Some(20));
    }
}
