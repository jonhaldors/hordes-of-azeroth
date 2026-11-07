//! The empty-bodied toggles that ask the server to flip a bit of our own `PLAYER_FLAGS`. There is
//! no ack, only the next descriptor update, so to reach a given state send only when it differs.

use anyhow::Result;

use crate::messages::opcode;

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_TOGGLE_PVP`: flagging on shows as the `UNIT_FIELD_FLAGS` PvP bit; flagging off clears
    /// only the wish, and the flag drops after vmangos's 300 s timer (`Player::UpdatePvP`).
    pub fn toggle_pvp(&mut self) -> Result<()> {
        self.send(opcode::CMSG_TOGGLE_PVP, &[])
    }

    /// `CMSG_TOGGLE_HELM`: answered by the `PLAYER_FLAGS` `HIDE_HELM` bit, which every client in
    /// range dresses our body from.
    pub fn toggle_helm(&mut self) -> Result<()> {
        self.send(opcode::CMSG_TOGGLE_HELM, &[])
    }

    /// `CMSG_TOGGLE_CLOAK`: the cloak half of [`Self::toggle_helm`].
    pub fn toggle_cloak(&mut self) -> Result<()> {
        self.send(opcode::CMSG_TOGGLE_CLOAK, &[])
    }
}
