//! The guild charter sends. A charter is addressed by its item guid; only `petition_query` takes
//! the petition id. Success is mostly silent, a refusal comes back as the guild family's
//! `SMSG_GUILD_COMMAND_RESULT`, and a failed range or ownership check drops a send unanswered.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `CMSG_PETITION_SHOWLIST`: answered by `SMSG_PETITION_SHOWLIST`, which the petitioner's
    /// gossip option also pushes unasked (`Player.cpp:12428`).
    pub fn petition_show_list(&mut self, npc: u64) -> Result<()> {
        self.send(
            opcode::CMSG_PETITION_SHOWLIST,
            &messages::petition_show_list(npc),
        )
    }

    /// `CMSG_PETITION_BUY`, name capped by the caller: success sends only `SMSG_ITEM_PUSH_RESULT`
    /// (`PetitionsHandler.cpp:130`); a refusal is `SMSG_GUILD_COMMAND_RESULT` (name),
    /// `SMSG_BUY_FAILED` (money) or `SMSG_INVENTORY_CHANGE_FAILURE` (full bag).
    pub fn petition_buy(&mut self, npc: u64, name: &str) -> Result<()> {
        self.send(
            opcode::CMSG_PETITION_BUY,
            &messages::petition_buy(npc, name),
        )
    }

    /// `CMSG_PETITION_SHOW_SIGNATURES`: dropped unanswered if we are in a guild or do not hold the
    /// item (`PetitionsHandler.cpp:140`).
    pub fn petition_show_signatures(&mut self, item: u64) -> Result<()> {
        self.send(
            opcode::CMSG_PETITION_SHOW_SIGNATURES,
            &messages::petition_show_signatures(item),
        )
    }

    /// `CMSG_PETITION_SIGN`: `SMSG_PETITION_SIGN_RESULTS` goes to us and the owner alike; a
    /// guilded or cross-faction signer gets `SMSG_GUILD_COMMAND_RESULT` instead
    /// (`PetitionsHandler.cpp:252`). `arg` carries the optional Lua argument, 1 by default.
    pub fn petition_sign(&mut self, item: u64, arg: i8) -> Result<()> {
        self.send(
            opcode::CMSG_PETITION_SIGN,
            &messages::petition_sign(item, arg),
        )
    }

    /// `CMSG_OFFER_PETITION`: the target gets `SMSG_PETITION_SHOW_SIGNATURES`; we hear back only on
    /// a refusal (`PetitionsHandler.cpp:390`).
    pub fn offer_petition(&mut self, item: u64, player: u64) -> Result<()> {
        self.send(
            opcode::CMSG_OFFER_PETITION,
            &messages::offer_petition(item, player),
        )
    }

    /// `CMSG_TURN_IN_PETITION`: answered by `SMSG_TURN_IN_PETITION_RESULTS`, except that a
    /// non-owner gets nothing (`PetitionsHandler.cpp:432`) and a taken guild name gets only
    /// `SMSG_GUILD_COMMAND_RESULT` (`:445`).
    pub fn turn_in_petition(&mut self, item: u64) -> Result<()> {
        self.send(
            opcode::CMSG_TURN_IN_PETITION,
            &messages::turn_in_petition(item),
        )
    }

    /// `CMSG_PETITION_QUERY`: the only source of the proposed guild name and signature count.
    /// vmangos ignores `item` and looks the petition up by id (`PetitionsHandler.cpp:171`).
    pub fn petition_query(&mut self, petition_id: u32, item: u64) -> Result<()> {
        self.send(
            opcode::CMSG_PETITION_QUERY,
            &messages::petition_query(petition_id, item),
        )
    }

    /// `MSG_PETITION_RENAME`: echoed only on success, else `SMSG_GUILD_COMMAND_RESULT`. vmangos
    /// lets anyone holding the item rename it (`PetitionsHandler.cpp:187`).
    pub fn petition_rename(&mut self, item: u64, name: &str) -> Result<()> {
        self.send(
            opcode::MSG_PETITION_RENAME,
            &messages::petition_rename(item, name),
        )
    }

    /// `MSG_PETITION_DECLINE`: we send the item guid; the owner gets ours on the same opcode.
    pub fn petition_decline(&mut self, item: u64) -> Result<()> {
        self.send(
            opcode::MSG_PETITION_DECLINE,
            &messages::petition_decline(item),
        )
    }
}
