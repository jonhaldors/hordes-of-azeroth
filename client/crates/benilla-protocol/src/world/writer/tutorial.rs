//! The tutorial system's sends.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_TUTORIAL_FLAG`, a 0-based id: sent by `FlagTutorial` and six auto-acknowledge sites,
    /// only when that tutorial's bit was clear.
    pub fn tutorial_flag(&mut self, id: u32) -> Result<()> {
        self.send(opcode::CMSG_TUTORIAL_FLAG, &messages::tutorial_flag(id))
    }

    /// `CMSG_TUTORIAL_CLEAR`, empty: `ClearTutorials()`, marking every tutorial acknowledged.
    pub fn tutorial_clear(&mut self) -> Result<()> {
        self.send(opcode::CMSG_TUTORIAL_CLEAR, &[])
    }

    /// `CMSG_TUTORIAL_RESET`, empty: `ResetTutorials()`, forgetting every tutorial.
    pub fn tutorial_reset(&mut self) -> Result<()> {
        self.send(opcode::CMSG_TUTORIAL_RESET, &[])
    }
}
