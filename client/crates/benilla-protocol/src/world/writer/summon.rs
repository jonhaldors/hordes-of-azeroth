//! The summon accept, the client's one summon send. Declining sends nothing: the server's
//! two-minute window lapses.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_SUMMON_RESPONSE`: the `CONFIRM_SUMMON` Accept. vmangos ignores the guid and teleports
    /// us unless its own `m_summon_expire` has passed (`Player::SummonIfPossible`).
    pub fn summon_response(&mut self, summoner_guid: u64) -> Result<()> {
        self.send(
            opcode::CMSG_SUMMON_RESPONSE,
            &messages::summon_response(summoner_guid),
        )
    }
}
