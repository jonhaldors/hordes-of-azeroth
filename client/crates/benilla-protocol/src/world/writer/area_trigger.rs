//! The area-trigger send.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// Report walking into an `AreaTrigger.dbc` volume (`CMSG_AREATRIGGER`). There is no success
    /// reply; a refusal is `SMSG_AREA_TRIGGER_MESSAGE`, and most triggers answer nothing.
    pub fn area_trigger(&mut self, trigger_id: u32) -> Result<()> {
        self.send(
            opcode::CMSG_AREATRIGGER,
            &messages::area_trigger(trigger_id),
        )
    }
}
