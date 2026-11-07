//! The loot window sends: open, take, coin, close, roll, and the master looter's give.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_LOOT`: open the loot of a corpse, creature or player (`SMSG_LOOT_RESPONSE`).
    pub fn loot(&mut self, guid: u64) -> Result<()> {
        self.send(opcode::CMSG_LOOT, &messages::loot(guid))
    }

    /// `CMSG_AUTOSTORE_LOOT_ITEM`: take the 0-based row `loot_slot` into the first free bag slot.
    pub fn autostore_loot_item(&mut self, loot_slot: u8) -> Result<()> {
        self.send(
            opcode::CMSG_AUTOSTORE_LOOT_ITEM,
            &messages::autostore_loot_item(loot_slot),
        )
    }

    /// `CMSG_LOOT_MONEY`, empty: answered by `SMSG_LOOT_MONEY_NOTIFY` with our share, then
    /// `SMSG_LOOT_CLEAR_MONEY` to every looter.
    pub fn loot_money(&mut self) -> Result<()> {
        self.send(opcode::CMSG_LOOT_MONEY, &messages::loot_money())
    }

    /// `CMSG_LOOT_RELEASE`: the server ignores `guid` and releases the loot it has stored for us.
    pub fn loot_release(&mut self, guid: u64) -> Result<()> {
        self.send(opcode::CMSG_LOOT_RELEASE, &messages::loot_release(guid))
    }

    /// `CMSG_LOOT_ROLL`: addressed by the `(looted_target, item_slot)` of `SMSG_LOOT_START_ROLL`,
    /// not the UI's `rollID`; a [`messages::roll_vote`] of 3 or more is dropped unanswered.
    pub fn loot_roll(&mut self, looted_target: u64, item_slot: u32, roll_type: u8) -> Result<()> {
        self.send(
            opcode::CMSG_LOOT_ROLL,
            &messages::loot_roll(looted_target, item_slot, roll_type),
        )
    }

    /// `CMSG_LOOT_MASTER_GIVE`: the master looter hands 0-based row `slot` of `loot_guid` to a
    /// member; a refusal is an `SMSG_LOOT_RESPONSE` error with a `MASTER_*` loot error code.
    pub fn loot_master_give(&mut self, loot_guid: u64, slot: u8, player_guid: u64) -> Result<()> {
        self.send(
            opcode::CMSG_LOOT_MASTER_GIVE,
            &messages::loot_master_give(loot_guid, slot, player_guid),
        )
    }
}
