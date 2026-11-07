//! The stable window's sends. Each names the stable master, whose reach the server re-checks
//! (`NPCHandler.cpp:584`), so an out-of-range window fails with `ERR_STABLE`. A mutation is
//! answered only by a one-byte `SMSG_STABLE_RESULT`; on success, re-ask for the list.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// `MSG_LIST_STABLED_PETS`: the refresh; the window first opens on the server's unasked send
    /// from the gossip stable option (`Player.cpp:12400`).
    pub fn list_stabled_pets(&mut self, npc_guid: u64) -> Result<()> {
        self.send(
            opcode::MSG_LIST_STABLED_PETS,
            &messages::list_stabled_pets(npc_guid),
        )
    }

    /// `CMSG_STABLE_PET`: the server picks the first free bought slot (`NPCHandler.cpp:609`);
    /// a dead player, no live hunter pet or no free slot gets `ERR_STABLE`.
    pub fn stable_pet(&mut self, npc_guid: u64) -> Result<()> {
        self.send(opcode::CMSG_STABLE_PET, &messages::stable_pet(npc_guid))
    }

    /// `CMSG_UNSTABLE_PET`: by `pet_number`, never slot. vmangos refuses it while any current pet
    /// exists, even an unsummoned one (`NPCHandler.cpp:657`); with a pet out, swap instead.
    pub fn unstable_pet(&mut self, npc_guid: u64, pet_number: u32) -> Result<()> {
        self.send(
            opcode::CMSG_UNSTABLE_PET,
            &messages::unstable_pet(npc_guid, pet_number),
        )
    }

    /// `CMSG_STABLE_SWAP_PET`: the live pet takes the named pet's slot (`NPCHandler.cpp:735`).
    /// Success is `SUCCESS_UNSTABLE`, the same code as a plain unstable.
    pub fn stable_swap_pet(&mut self, npc_guid: u64, pet_number: u32) -> Result<()> {
        self.send(
            opcode::CMSG_STABLE_SWAP_PET,
            &messages::stable_swap_pet(npc_guid, pet_number),
        )
    }

    /// `CMSG_BUY_STABLE_SLOT`: the server buys the next slot at its `StableSlotPrices.dbc` price
    /// (`NPCHandler.cpp:704`); past the two 1.12 slots it answers `ERR_STABLE`. Only the next
    /// list carries the new count.
    pub fn buy_stable_slot(&mut self, npc_guid: u64) -> Result<()> {
        self.send(
            opcode::CMSG_BUY_STABLE_SLOT,
            &messages::buy_stable_slot(npc_guid),
        )
    }
}
