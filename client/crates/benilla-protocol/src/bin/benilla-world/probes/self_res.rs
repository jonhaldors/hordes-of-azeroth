//! `--self-res`: `PLAYER_SELF_RES_SPELL` arrives at death, the bodyless `CMSG_SELF_RES` spends it,
//! and the field zeroes as we stand. The death holds its release: the button lives on the DEATH
//! dialog, which exists only before release. Reincarnation stands in for a soulstone: vmangos
//! `Player::SelectResurrectionSpellId` arms it with no class check, into the same field.

use anyhow::{bail, Context, Result};
use benilla_protocol::SessionEvent;

use crate::probes::{Ctx, Probe};

/// Reincarnation's learnable passive, the `HasSpell` half of the server's gate.
const REINCARNATION_PASSIVE: u32 = 20608;
/// Reincarnation's effect: the `PLAYER_SELF_RES_SPELL` value, named on the DEATH dialog's button.
const REINCARNATION_EFFECT: u32 = 21169;
/// Ankh, the reagent the same gate counts.
const ITEM_ANKH: u32 = 17030;

#[derive(Default)]
pub(crate) struct SelfRes {
    /// The first non-zero `PLAYER_SELF_RES_SPELL`, and whether health was already 0 when it came:
    /// the DEATH dialog's `OnShow` reads the field.
    self_res_spell: Option<u32>,
    self_res_after_death: bool,
    sent: bool,
    /// `PLAYER_SELF_RES_SPELL` read back as zero after the send: the server spent it.
    field_cleared: bool,
    revived_without_releasing: bool,
}

impl Probe for SelfRes {
    fn stage(&mut self, cx: &mut Ctx) -> Result<()> {
        // A success starts Reincarnation's one-hour cooldown and spends the Ankh. Bare `.cooldown`
        // does nothing; `.cooldown clear` with nothing selected clears our own.
        cx.session.send_chat(".cooldown clear")?;
        cx.session
            .send_chat(&format!(".learn {REINCARNATION_PASSIVE}"))?;
        cx.session.send_chat(&format!(".additem {ITEM_ANKH} 1"))?;
        println!(
            "sent GM: .cooldown clear; .learn {REINCARNATION_PASSIVE} (Reincarnation passive); \
             .additem {ITEM_ANKH} (Ankh)"
        );
        Ok(())
    }

    fn poll(&mut self, cx: &mut Ctx) -> Result<()> {
        // Dead, field set: the DEATH dialog offers button2 while `HasSoulstone()` is non-nil.
        let died = cx
            .world
            .death_arc
            .as_ref()
            .is_some_and(|a| a.died_at.is_some());
        if !self.sent && died && self.self_res_spell.is_some() {
            cx.session.self_res()?;
            println!("sent CMSG_SELF_RES (the DEATH dialog's soulstone button)");
            self.sent = true;
        }
        Ok(())
    }

    fn on_event(&mut self, ev: &SessionEvent, cx: &mut Ctx) -> Result<()> {
        let SessionEvent::ObjectValues { guid, fields } = ev else {
            return Ok(());
        };
        if *guid != cx.world.self_guid {
            return Ok(());
        }
        // The delta, not the merged store: only the delta says which packet carried the field.
        if let Some(spell) = fields.player_self_res_spell() {
            if self.self_res_spell.is_none() {
                self.self_res_spell = Some(spell);
                self.self_res_after_death = cx
                    .world
                    .death_arc
                    .as_ref()
                    .is_some_and(|a| a.died_at.is_some());
                println!(
                    "PLAYER_SELF_RES_SPELL → {spell} (arrived {} the health→0 flush)",
                    if self.self_res_after_death {
                        "after"
                    } else {
                        "before"
                    }
                );
            }
        } else if self.sent && !self.field_cleared {
            // A delta without the field also reads `None`, so the clear counts only once the
            // merged store reads none too.
            if cx
                .world
                .self_fields
                .as_ref()
                .is_some_and(|sf| sf.player_self_res_spell().is_none())
            {
                self.field_cleared = true;
                println!("PLAYER_SELF_RES_SPELL cleared — the server spent it");
            }
        }
        if self.sent && !self.revived_without_releasing {
            if let Some(sf) = &cx.world.self_fields {
                if sf.unit_health().is_some_and(|h| h > 0) && !sf.player_is_ghost() {
                    self.revived_without_releasing = true;
                    println!(
                        "alive again at {} hp, never a ghost — self-resurrected in place",
                        sf.unit_health().unwrap_or(0)
                    );
                }
            }
        }
        Ok(())
    }

    fn verify(&mut self, cx: &mut Ctx) -> Result<()> {
        let arc = cx
            .world
            .death_arc
            .as_ref()
            .expect("death_arc present when --self-res is set");
        arc.death_pos.context(
            "--self-res: `.die` never dropped our health to 0 — is the account gmlevel ≥ 2?",
        )?;
        if arc.ghost_seen {
            bail!(
                "--self-res: released to a ghost — `hold_release` did not hold, and the state \
                 under test (dead, unreleased) was never occupied"
            );
        }
        let spell = self.self_res_spell.context(
            "--self-res: PLAYER_SELF_RES_SPELL never arrived — the server refused the \
             Reincarnation gate (`.learn`/`.additem` rejected, or the effect spell is still on \
             cooldown from a previous run and `.cooldown clear` did not take)",
        )?;
        if spell != REINCARNATION_EFFECT {
            bail!(
                "--self-res: PLAYER_SELF_RES_SPELL = {spell}, expected the Reincarnation EFFECT \
                 {REINCARNATION_EFFECT} (the passive {REINCARNATION_PASSIVE} is what we learn; the \
                 effect is what the field carries and what Spell.dbc names on the button)"
            );
        }
        if !self.field_cleared {
            bail!("--self-res: PLAYER_SELF_RES_SPELL never cleared after CMSG_SELF_RES");
        }
        if !self.revived_without_releasing {
            bail!("--self-res: never came back alive after CMSG_SELF_RES");
        }
        println!(
            "--self-res OK: field {spell} arrived {} the health-zero flush, CMSG_SELF_RES spent \
             it, resurrected dead-unreleased without ever releasing",
            if self.self_res_after_death {
                "after"
            } else {
                "before"
            }
        );
        Ok(())
    }
}
