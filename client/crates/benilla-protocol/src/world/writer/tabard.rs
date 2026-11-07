//! The tabard designer's sends, and the battlemaster greeting.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `MSG_TABARDVENDOR_ACTIVATE`: the NPC-click ladder's `TABARDDESIGNER` arm.
    pub fn tabard_vendor_activate(&mut self, npc: u64) -> Result<()> {
        self.send(
            opcode::MSG_TABARDVENDOR_ACTIVATE,
            &messages::tabard_vendor_activate(npc),
        )
    }

    /// `MSG_SAVE_GUILD_EMBLEM`: `TabardModel:Save()`, once its fourteen client-side checks pass.
    pub fn save_guild_emblem(&mut self, vendor: u64, design: [u32; 5]) -> Result<()> {
        self.send(
            opcode::MSG_SAVE_GUILD_EMBLEM,
            &messages::save_guild_emblem(vendor, design),
        )
    }

    /// `CMSG_BATTLEMASTER_HELLO`: the NPC-click ladder's `BATTLEMASTER` arm.
    pub fn battlemaster_hello(&mut self, npc: u64) -> Result<()> {
        self.send(
            opcode::CMSG_BATTLEMASTER_HELLO,
            &messages::battlemaster_hello(npc),
        )
    }
}
