//! The innkeeper bind answer: the Yes to the server's `SMSG_BINDER_CONFIRM`, carrying its guid,
//! which vmangos resolves to an innkeeper in range (`HandleBinderActivateOpcode`).

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// Accept an innkeeper's bind offer (`CMSG_BINDER_ACTIVATE`). The server casts spell 3286 on
    /// us, landing as `SMSG_BINDPOINTUPDATE` and `SMSG_PLAYERBOUND`; declining sends nothing.
    pub fn binder_activate(&mut self, binder_guid: u64) -> Result<()> {
        self.send(
            opcode::CMSG_BINDER_ACTIVATE,
            &messages::binder_activate(binder_guid),
        )
    }
}
