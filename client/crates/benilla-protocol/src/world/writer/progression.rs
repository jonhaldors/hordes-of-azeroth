//! The talent sends: spending points and confirming a respec.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_LEARN_TALENT`: a `Talent.dbc` row and the 0-based rank to learn up to. No reply:
    /// success is the rank spell's learn plus a fresh `PLAYER_CHARACTER_POINTS1`.
    pub fn learn_talent(&mut self, talent_id: u32, requested_rank: u32) -> Result<()> {
        self.send(
            opcode::CMSG_LEARN_TALENT,
            &messages::learn_talent(talent_id, requested_rank),
        )
    }

    /// `MSG_TALENT_WIPE_CONFIRM`: the `CONFIRM_TALENT_WIPE` dialog's Accept; declining sends
    /// nothing. The server resets the talents and has the trainer cast spell 14867.
    pub fn talent_wipe_confirm(&mut self, trainer_guid: u64) -> Result<()> {
        self.send(
            opcode::MSG_TALENT_WIPE_CONFIRM,
            &messages::talent_wipe_confirm(trainer_guid),
        )
    }
}
