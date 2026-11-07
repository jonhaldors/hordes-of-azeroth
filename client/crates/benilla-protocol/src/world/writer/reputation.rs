//! The reputation pane's sends. Each names a faction by its reputation-list slot; none is acked.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_SET_FACTION_ATWAR`: vmangos drops it while the player is in combat.
    pub fn set_faction_at_war(&mut self, rep_list_id: u32, at_war: bool) -> Result<()> {
        self.send(
            opcode::CMSG_SET_FACTION_ATWAR,
            &messages::set_faction_at_war(rep_list_id, at_war),
        )
    }

    /// `CMSG_SET_FACTION_INACTIVE`: move a faction into or out of the pane's inactive group.
    pub fn set_faction_inactive(&mut self, rep_list_id: u32, inactive: bool) -> Result<()> {
        self.send(
            opcode::CMSG_SET_FACTION_INACTIVE,
            &messages::set_faction_inactive(rep_list_id, inactive),
        )
    }

    /// `CMSG_SET_WATCHED_FACTION`: [`messages::WATCHED_FACTION_NONE`] stops watching; the answer is
    /// a `PLAYER_FIELD_WATCHED_FACTION_INDEX` update.
    pub fn set_watched_faction(&mut self, rep_list_id: i32) -> Result<()> {
        self.send(
            opcode::CMSG_SET_WATCHED_FACTION,
            &messages::set_watched_faction(rep_list_id),
        )
    }
}
