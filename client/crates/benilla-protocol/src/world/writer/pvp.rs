//! The honor send: another player's honor stats. Unlike inspect, it does not set our selection
//! (`MiscHandler.cpp:962`).

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `MSG_INSPECT_HONOR_STATS`: the reply rides the same opcode. An offline, distant or hostile
    /// target gets no reply at all, so keep what is on screen until one lands.
    pub fn inspect_honor_stats(&mut self, guid: u64) -> Result<()> {
        self.send(
            opcode::MSG_INSPECT_HONOR_STATS,
            &messages::inspect_honor_stats(guid),
        )
    }
}
