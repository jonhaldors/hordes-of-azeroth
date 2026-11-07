//! `--spirit`: `CMSG_SPIRIT_HEALER_ACTIVATE` must clear the ghost flag and push the 25%
//! durability loss as `ITEM_FIELD_DURABILITY` deltas.

use std::collections::HashMap;
use std::time::{Duration, Instant};

use anyhow::{bail, Result};
use benilla_protocol::{guid, EntityKind, ObjectFields, SessionEvent};

use crate::probes::{Ctx, Probe};

/// Per-item merged descriptors, the durability baseline at activate time, and the deltas after.
#[derive(Default)]
pub(crate) struct Spirit {
    healer: Option<(u64, [f32; 3])>,
    healer_tp_sent: bool,
    healer_tp_landed: Option<Instant>,
    activate_sent: bool,
    dur_baseline: HashMap<u64, (u32, u32)>,
    dur_deltas: Vec<(u64, u32)>,
    item_fields: HashMap<u64, ObjectFields>,
}

impl Probe for Spirit {
    fn stage(&mut self, cx: &mut Ctx) -> Result<()> {
        // Full durability, so each post-activate delta reads as a drop; `.repairitems` needs
        // SEC_GAMEMASTER (vmangos `Chat.cpp:1297`).
        cx.session.send_chat(".repairitems")?;
        println!("sent GM: .repairitems (full-durability baseline)");
        Ok(())
    }

    fn poll(&mut self, cx: &mut Ctx) -> Result<()> {
        // Teleport onto the healer: the repop spot can be outside the activate's 5 yd
        // interaction gate (vmangos `GetNPCIfCanInteractWith`).
        if !self.healer_tp_sent
            && cx
                .world
                .death_arc
                .as_ref()
                .is_some_and(|a| a.ghost_seen && a.graveyard_pos.is_some())
        {
            if let Some((hg, hp)) = self.healer {
                cx.session
                    .send_chat(&format!(".go xyz {} {} {}", hp[0], hp[1], hp[2]))?;
                println!("sent GM teleport onto Spirit Healer (guid {hg:#x})");
                self.healer_tp_sent = true;
            }
        }
        // On the healer, snapshot the baseline and send the XP_LOSS popup's accept. The server
        // queues movement acks apart from world packets, so an activate sent too soon after the
        // teleport is range-checked from the old spot and silently refused; hence the 2 s wait.
        if !self.activate_sent {
            if let (Some((hg, hp)), Some(landed)) = (self.healer, self.healer_tp_landed) {
                let (pos, _) = cx.world.self_pose();
                let d2 =
                    (pos[0] - hp[0]).powi(2) + (pos[1] - hp[1]).powi(2) + (pos[2] - hp[2]).powi(2);
                if d2 < 25.0 && landed.elapsed() > Duration::from_secs(2) {
                    self.dur_baseline = self
                        .item_fields
                        .iter()
                        .filter_map(|(&g, f)| {
                            f.item_durability()
                                .zip(f.item_max_durability())
                                .filter(|&(_, max)| max > 0)
                                .map(|p| (g, p))
                        })
                        .collect();
                    cx.session.spirit_healer_activate(hg)?;
                    println!(
                        "sent CMSG_SPIRIT_HEALER_ACTIVATE (guid {hg:#x}) — baseline: {} durable item(s)",
                        self.dur_baseline.len()
                    );
                    self.activate_sent = true;
                    if let Some(arc) = &mut cx.world.death_arc {
                        arc.revive_initiated = true;
                    }
                }
            }
        }
        Ok(())
    }

    fn on_event(&mut self, ev: &SessionEvent, cx: &mut Ctx) -> Result<()> {
        match ev {
            // `UNIT_NPC_FLAG_SPIRITHEALER` 0x20 (`UnitDefines.h:662`), which the activate's gate
            // checks; the healer streams only to ghosts.
            SessionEvent::ObjectCreate {
                guid,
                kind,
                position,
                fields,
                ..
            } if *kind == EntityKind::Unit && fields.unit_npc_flags() & 0x20 != 0 => {
                if self.healer.is_none() {
                    println!(
                        "Spirit Healer streamed: guid {guid:#x} at ({:.1}, {:.1}, {:.1})",
                        position[0], position[1], position[2]
                    );
                }
                self.healer = Some((*guid, *position));
            }
            SessionEvent::ItemCreate { guid, fields, .. } => {
                // A broken item's create omits its zero `DURABILITY`; it must still read `0/max`.
                if let Some((d, m)) = fields
                    .item_durability()
                    .zip(fields.item_max_durability())
                    .filter(|&(_, m)| m > 0)
                {
                    println!(
                        "item create: guid {guid:#x} entry {} durability {d}/{m}",
                        fields.object_entry().unwrap_or(0)
                    );
                }
                match self.item_fields.entry(*guid) {
                    std::collections::hash_map::Entry::Occupied(mut e) => {
                        e.get_mut().merge(fields.clone())
                    }
                    std::collections::hash_map::Entry::Vacant(e) => {
                        e.insert(fields.clone());
                    }
                }
            }
            // Item values deltas: the post-activate durability ones are the verdict's evidence.
            SessionEvent::ObjectValues { guid, fields } if guid::is_item(*guid) => {
                if let Some(d) = fields.item_durability() {
                    if self.activate_sent {
                        self.dur_deltas.push((*guid, d));
                    }
                    println!(
                        "item durability delta: guid {guid:#x} → {d}{}",
                        if self.activate_sent {
                            " (post-activate)"
                        } else {
                            ""
                        }
                    );
                }
                match self.item_fields.entry(*guid) {
                    std::collections::hash_map::Entry::Occupied(mut e) => {
                        e.get_mut().merge(fields.clone())
                    }
                    std::collections::hash_map::Entry::Vacant(e) => {
                        e.insert(fields.clone());
                    }
                }
            }
            // `healer_tp_sent` follows World's graveyard capture, so this is the healer teleport.
            SessionEvent::Teleport { guid, .. }
                if *guid == cx.world.self_guid
                    && self.healer_tp_sent
                    && self.healer_tp_landed.is_none() =>
            {
                self.healer_tp_landed = Some(Instant::now());
            }
            _ => {}
        }
        Ok(())
    }

    fn verify(&mut self, cx: &mut Ctx) -> Result<()> {
        let ghost_seen = cx.world.death_arc.as_ref().is_some_and(|a| a.ghost_seen);
        let revived_seen = cx.world.death_arc.as_ref().is_some_and(|a| a.revived_seen);
        let healer_tp_sent = self.healer_tp_sent;
        let session = &mut *cx.session;

        // Repair before judging, so the 25% loss does not carry into the next run.
        session.send_chat(".repairitems")?;

        if !self.activate_sent {
            bail!(
                "--spirit: never reached the activate (ghost={ghost_seen}, healer streamed={}, tp sent={healer_tp_sent})",
                self.healer.is_some()
            );
        }
        if !revived_seen {
            // Do not leave the shared GM character a ghost.
            session.send_chat(".revive")?;
            bail!(
                "--spirit: CMSG_SPIRIT_HEALER_ACTIVATE never cleared the ghost flag — the res didn't land (a cleanup .revive was sent)"
            );
        }
        if self.dur_baseline.is_empty() {
            bail!(
                "--spirit: no durable items in the baseline — equip the character with gear that has MaxDurability"
            );
        }
        if self.dur_deltas.is_empty() {
            bail!(
                "--spirit: the res landed but the wire carried NO post-activate ITEM_FIELD_DURABILITY delta ({} durable item(s) at baseline) — the 25% loss never reached the client; a tooltip can only show 100%",
                self.dur_baseline.len()
            );
        }
        println!("\n✅ SPIRIT-HEALER RES + DURABILITY WIRE VERIFIED:");
        println!("  res            ghost flag cleared after CMSG_SPIRIT_HEALER_ACTIVATE");
        println!(
            "  deltas         {} post-activate durability delta(s) over {} durable item(s):",
            self.dur_deltas.len(),
            self.dur_baseline.len()
        );
        let mut dropped = 0u32;
        for (guid, after) in &self.dur_deltas {
            let entry = cx.world.item_entries.get(guid).copied().unwrap_or(0);
            match self.dur_baseline.get(guid) {
                Some(&(before, max)) => {
                    if *after < before {
                        dropped += 1;
                    }
                    println!(
                        "    item {entry:>5} (guid {guid:#x})  {before}/{max} → {after}/{max}"
                    );
                }
                None => println!("    item {entry:>5} (guid {guid:#x})  ?/? → {after}"),
            }
        }
        if dropped == 0 {
            bail!(
                "--spirit: durability deltas arrived but none DROPPED below its baseline — the loss is not visible in the values"
            );
        }
        Ok(())
    }
}
