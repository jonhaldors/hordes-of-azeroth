//! The instance lockout family's one send: "Reset all instances" from the player's portrait.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_RESET_INSTANCES`, empty: the `CONFIRM_RESET_INSTANCES` dialog's Yes. The server sends
    /// one `SMSG_INSTANCE_RESET` per map it reset and nothing when none could; raids are skipped,
    /// and only the group path refuses (vmangos `Group::ResetInstances`).
    pub fn reset_instances(&mut self) -> Result<()> {
        self.send(opcode::CMSG_RESET_INSTANCES, &messages::reset_instances())
    }
}
