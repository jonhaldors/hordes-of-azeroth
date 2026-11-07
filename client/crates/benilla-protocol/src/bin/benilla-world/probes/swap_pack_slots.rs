//! `--swap-pack-slots`: `CMSG_SWAP_INV_ITEM` swaps two 1-based backpack slots, then swaps them
//! back so the character is left as found.

use std::time::{Duration, Instant};

use anyhow::{bail, Context, Result};
use benilla_protocol::{decode, SessionEvent};

use crate::probes::{Ctx, Probe};

pub(crate) struct SwapPackSlots {
    pub(crate) a: u8,
    pub(crate) b: u8,
}

impl Probe for SwapPackSlots {
    fn verify(&mut self, cx: &mut Ctx) -> Result<()> {
        let world = &mut *cx.world;
        let session = &mut *cx.session;
        let (a, b) = (self.a, self.b);

        // Backpack slots are player-array slots from 23 (`INVENTORY_SLOT_ITEM_START`).
        let sf = world
            .self_fields
            .as_mut()
            .context("no self descriptor — can't read the pack slots")?;
        let (a0, b0) = (a - 1, b - 1);
        let (wire_a, wire_b) = (23 + a0, 23 + b0);
        let guid_a = sf
            .player_pack_slot(a0)
            .filter(|g| *g != 0)
            .with_context(|| format!("pack slot {a} is empty/unsent — need an item to swap"))?;
        let guid_b = sf.player_pack_slot(b0).unwrap_or(0);
        println!(
            "\nswapping backpack slots {a}↔{b} (guid {guid_a:#x} ↔ {guid_b:#x}) → \
             CMSG_SWAP_INV_ITEM src {wire_a} dst {wire_b}"
        );

        session.swap_inv_item(wire_a, wire_b)?;
        let mut settled = false;
        let drain_until = Instant::now() + Duration::from_secs(5);
        while Instant::now() < drain_until && !settled {
            let Ok(msg) = session.recv() else { continue };
            for ev in decode(msg) {
                if let SessionEvent::ObjectValues { guid: g, fields } = ev {
                    if g == world.self_guid {
                        sf.merge(fields);
                    }
                }
            }
            settled = sf.player_pack_slot(a0).unwrap_or(0) == guid_b
                && sf.player_pack_slot(b0).unwrap_or(0) == guid_a;
        }
        if !settled {
            bail!(
                "swap didn't land: slot {a} = {:#x}, slot {b} = {:#x} (wanted {guid_b:#x} / {guid_a:#x})",
                sf.player_pack_slot(a0).unwrap_or(0),
                sf.player_pack_slot(b0).unwrap_or(0)
            );
        }
        println!("✅ swap: slots {a}↔{b} exchanged in the descriptor (guids confirmed).");

        session.swap_inv_item(wire_a, wire_b)?;
        let mut restored = false;
        let drain_until = Instant::now() + Duration::from_secs(5);
        while Instant::now() < drain_until && !restored {
            let Ok(msg) = session.recv() else { continue };
            for ev in decode(msg) {
                if let SessionEvent::ObjectValues { guid: g, fields } = ev {
                    if g == world.self_guid {
                        sf.merge(fields);
                    }
                }
            }
            restored = sf.player_pack_slot(a0).unwrap_or(0) == guid_a
                && sf.player_pack_slot(b0).unwrap_or(0) == guid_b;
        }
        if !restored {
            bail!(
                "swap-back didn't restore: slot {a} = {:#x}, slot {b} = {:#x} (wanted {guid_a:#x} / {guid_b:#x})",
                sf.player_pack_slot(a0).unwrap_or(0),
                sf.player_pack_slot(b0).unwrap_or(0)
            );
        }
        println!("✅ swap-back: the original layout is restored (character left as found).");
        Ok(())
    }
}
