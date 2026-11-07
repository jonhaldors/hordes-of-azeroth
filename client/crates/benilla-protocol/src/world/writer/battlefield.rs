//! The battleground queue's sends.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// Enter or decline a ready battleground by map id, as `AcceptBattlefieldPort` sends.
    pub fn battlefield_port(&mut self, map_id: u32, accept: bool) -> Result<()> {
        self.send(
            opcode::CMSG_BATTLEFIELD_PORT,
            &messages::battlefield_port(map_id, accept),
        )
    }

    /// Ask the scoreboard (`RequestBattlefieldScoreData`); the caller throttles it to 5000 ms.
    pub fn request_battlefield_score_data(&mut self) -> Result<()> {
        self.send(opcode::MSG_PVP_LOG_DATA, &[])
    }

    /// Leave the battleground, sent only once the scoreboard's "ended" byte has arrived.
    pub fn leave_battlefield(&mut self, map_id: u32) -> Result<()> {
        self.send(
            opcode::CMSG_LEAVE_BATTLEFIELD,
            &messages::leave_battlefield(map_id),
        )
    }

    /// Reopen a queued slot's instance list by map, as `ShowBattlefieldList` sends.
    pub fn battlefield_list(&mut self, map_id: u32) -> Result<()> {
        self.send(
            opcode::CMSG_BATTLEFIELD_LIST,
            &messages::battlefield_list(map_id),
        )
    }

    /// Join through the list's battlemaster, as `JoinBattlefield` sends for a non-zero guid.
    pub fn battlemaster_join(
        &mut self,
        battlemaster: u64,
        map_id: u32,
        instance_id: u32,
        as_group: bool,
    ) -> Result<()> {
        self.send(
            opcode::CMSG_BATTLEMASTER_JOIN,
            &messages::battlemaster_join(battlemaster, map_id, instance_id, as_group),
        )
    }

    /// Join without a battlemaster, as `JoinBattlefield` sends when the list had a zero guid.
    pub fn battlefield_join(
        &mut self,
        map_id: u32,
        instance_id: u32,
        as_group: bool,
    ) -> Result<()> {
        self.send(
            opcode::CMSG_BATTLEFIELD_JOIN,
            &messages::battlefield_join(map_id, instance_id, as_group),
        )
    }

    /// Ask every queue slot's state; the reference sends it once per world entry.
    pub fn battlefield_status(&mut self) -> Result<()> {
        self.send(opcode::CMSG_BATTLEFIELD_STATUS, &[])
    }

    /// Ask teammates' positions (`RequestBattlefieldPositions`); the caller throttles to 5000 ms.
    pub fn request_battlefield_positions(&mut self) -> Result<()> {
        self.send(opcode::MSG_BATTLEGROUND_PLAYER_POSITIONS, &[])
    }
}
