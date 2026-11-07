//! The GM ticket sends. The client holds no ticket state; the server's answers are the only truth.
//!
//! Never retry one on a timeout: vmangos refuses several silently (queue off, under
//! `GMTickets.MinLevel`, category >= 11, `GMTicketHandler.cpp:91,106-113`), and more than two
//! `CMSG_GMTICKET_UPDATETEXT` in one world tick is flooding, kicked by default
//! (`WorldSession.cpp:1316-1342`).

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// File a ticket (`CMSG_GMTICKET_CREATE`, sender `0x5ef740`): `category` is a
    /// `GMTicketCategory.dbc` id 1-10, `map` and `pos` where the player stands. Answered by
    /// `SMSG_GMTICKET_CREATE`, or by silence.
    pub fn gm_ticket_create(
        &mut self,
        category: u8,
        map: u32,
        pos: [f32; 3],
        text: &str,
    ) -> Result<()> {
        self.send(
            opcode::CMSG_GMTICKET_CREATE,
            &messages::gm_ticket_create(category, map, pos, text),
        )
    }

    /// Edit the open ticket's text (sender `0x5efac0`); vmangos discards the category byte.
    pub fn gm_ticket_updatetext(&mut self, category: u8, text: &str) -> Result<()> {
        self.send(
            opcode::CMSG_GMTICKET_UPDATETEXT,
            &messages::gm_ticket_updatetext(category, text),
        )
    }

    /// Ask for the open ticket, on world entry and every 10 minutes with the toast up; vmangos also
    /// sends an unsolicited `SMSG_QUERY_TIME_RESPONSE` (`GMTicketHandler.cpp:34`).
    pub fn gm_ticket_get(&mut self) -> Result<()> {
        self.send(opcode::CMSG_GMTICKET_GETTICKET, &[])
    }

    /// Abandon the open ticket; the reply carries 9, and vmangos sends none if there is no ticket.
    pub fn gm_ticket_delete(&mut self) -> Result<()> {
        self.send(opcode::CMSG_GMTICKET_DELETETICKET, &[])
    }

    /// Ask whether the ticket queue is open, as `GetGMStatus` does when the Help window shows.
    pub fn gm_ticket_system_status(&mut self) -> Result<()> {
        self.send(opcode::CMSG_GMTICKET_SYSTEMSTATUS, &[])
    }
}
