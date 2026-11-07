//! `--query-names`: the name-query pair. `CMSG_NAME_QUERY` for our own name and
//! `CMSG_CREATURE_QUERY` for the first streamed creature must both be answered and parse.

use anyhow::{bail, Context, Result};
use benilla_protocol::{guid, EntityKind};

use crate::probes::{Ctx, Probe};

#[derive(Default)]
pub(crate) struct QueryNames {
    creature_asked: bool,
}

impl Probe for QueryNames {
    fn stage(&mut self, cx: &mut Ctx) -> Result<()> {
        cx.session.name_query(cx.world.self_guid)?;
        println!(
            "sent CMSG_NAME_QUERY for self (guid {})",
            cx.world.self_guid
        );
        Ok(())
    }

    fn poll(&mut self, cx: &mut Ctx) -> Result<()> {
        // Ask the first streamed creature for its template name, once.
        if !self.creature_asked {
            if let Some((&guid, _)) = cx
                .world
                .tracked
                .iter()
                .find(|(g, t)| t.kind == EntityKind::Unit && guid::is_creature_or_pet(**g))
            {
                let entry = guid::entry(guid).expect("creature guid carries its entry");
                cx.session.creature_query(entry, guid)?;
                println!("sent CMSG_CREATURE_QUERY for entry {entry} (guid {guid:#x})");
                self.creature_asked = true;
            }
        }
        Ok(())
    }

    fn verify(&mut self, cx: &mut Ctx) -> Result<()> {
        // The creature answer is required only if a creature streamed in.
        let own = cx
            .world
            .player_name_answer
            .clone()
            .context("no SMSG_NAME_QUERY_RESPONSE for our own guid")?;
        if !own.eq_ignore_ascii_case(&cx.world.self_name) {
            bail!(
                "name query answered '{own}', expected '{}'",
                cx.world.self_name
            );
        }
        match (self.creature_asked, &cx.world.creature_name_answer) {
            (true, Some((entry, Some(name)))) => {
                println!("✅ query: self = '{own}', creature entry {entry} = '{name}'.");
            }
            (true, Some((entry, None))) => {
                bail!("creature query for entry {entry} answered 'unknown entry'")
            }
            (true, None) => bail!("no SMSG_CREATURE_QUERY_RESPONSE arrived"),
            (false, _) => {
                println!("✅ query: self = '{own}' (no creature streamed in range to ask about).");
            }
        }
        Ok(())
    }
}
