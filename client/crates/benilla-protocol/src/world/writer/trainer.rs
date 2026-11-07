//! The trainer window's sends: the list refresh and the purchase.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_TRAINER_LIST`: the refresh after a purchase, which the server does not resend
    /// (`NPCHandler.cpp:92`); the window first opens from the gossip option.
    pub fn trainer_list(&mut self, trainer_guid: u64) -> Result<()> {
        self.send(
            opcode::CMSG_TRAINER_LIST,
            &messages::trainer_list(trainer_guid),
        )
    }

    /// `CMSG_TRAINER_BUY_SPELL`: answered by `SMSG_TRAINER_BUY_SUCCEEDED` and `SMSG_LEARNED_SPELL`,
    /// or by `SMSG_TRAINER_BUY_FAILED` with a [`messages::train_fail`] code.
    pub fn trainer_buy_spell(&mut self, trainer_guid: u64, spell_id: u32) -> Result<()> {
        self.send(
            opcode::CMSG_TRAINER_BUY_SPELL,
            &messages::trainer_buy_spell(trainer_guid, spell_id),
        )
    }
}
