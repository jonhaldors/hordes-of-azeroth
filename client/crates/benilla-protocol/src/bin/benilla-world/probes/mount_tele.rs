//! `--mount-tele`: what the server sends when a teleport dismounts you. vmangos strips the mount
//! in `HandleMoveWorldportAckOpcode` right after the destination's own create block
//! (`Map::Add` → `SendInitSelf`, then `RemoveSpellsCausingAura(SPELL_AURA_MOUNTED)` unless
//! `IsMountAllowed`), so the two arrive back to back in one tick.
//!
//! Mounts with `.aura` on open ground, then `.go xyz` into a dungeon, and requires in order
//! `SMSG_NEW_WORLD`, a self create block still at the mounted run speed, and the dismount's
//! `SMSG_FORCE_RUN_SPEED_CHANGE` back to base, printing the gap. Needs GM.

use std::time::Instant;

use anyhow::{ensure, Result};
use benilla_protocol::{SessionEvent, SpeedKind};

use crate::probes::{Ctx, Probe};
use crate::world::ATTACK_TP;

/// Brown Horse (60%): `SPELL_AURA_MOUNTED` + `SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED`, so `.aura`
/// makes the holder a real mount cast would; `.modify mount` sets only a display id.
const MOUNT_SPELL: u32 = 458;

/// Ragefire Chasm. A dungeon, and not one of `MapEntry::IsMountAllowed`'s four exceptions
/// (Zul'Gurub, Zul'Farrak, AQ Ruins, Caverns of Time), so arriving there strips the mount.
const DUNGEON_MAP: u32 = 389;

/// Inside Ragefire Chasm's entrance, a sane place to be stranded if a run is interrupted.
const DUNGEON_TP: &str = ".go xyz 3.0 -14.0 -18.0 389";

/// The 1.12 base run speed (yd/s), which the strip restores.
const BASE_RUN: f32 = 7.0;

/// The starting map: open ground where a mount is allowed.
const OUTDOOR_MAP: u32 = 0;

#[derive(Default)]
pub(crate) struct MountTele {
    /// Sent `.aura` once we were confirmed standing on [`OUTDOOR_MAP`].
    mount_requested: bool,
    /// The mounted run speed the pre-teleport `SMSG_FORCE_RUN_SPEED_CHANGE` announced.
    mounted_run: Option<f32>,
    ported: bool,
    /// `SMSG_NEW_WORLD`'s map, and when it landed.
    arrived: Option<(u32, Instant)>,
    /// Our own create block on the destination map: its `LIVING` run speed + arrival instant.
    create_after: Option<(f32, Instant)>,
    /// The first self Run force-change after that create: its speed + arrival instant.
    strip_after: Option<(f32, Instant)>,
}

impl Probe for MountTele {
    fn stage(&mut self, cx: &mut Ctx) -> Result<()> {
        // Unmount and go outdoors first: from inside the dungeon the scenario's teleport would be
        // a same-map port, which sends no `SMSG_NEW_WORLD`. `.go xyz` defaults to the current map,
        // so the map id is explicit.
        cx.session.send_chat(&format!(".unaura {MOUNT_SPELL}"))?;
        cx.session
            .send_chat(&format!("{ATTACK_TP} {OUTDOOR_MAP}"))?;
        cx.world.attack_tp_staged = true;
        Ok(())
    }

    fn on_event(&mut self, ev: &SessionEvent, cx: &mut Ctx) -> Result<()> {
        match ev {
            // The mounted speed change cues the teleport, gated on a tracked self: `World` acks
            // only once our pose is known, and vmangos applies no change before its ack.
            SessionEvent::ForceSpeedChange {
                guid, kind, speed, ..
            } if *guid == cx.world.self_guid && *kind == SpeedKind::Run => {
                if !cx.world.tracked.contains_key(guid) {
                    return Ok(());
                }
                if self.ported {
                    // After arrival, the first Run change after the create block is the dismount.
                    if self.create_after.is_some() && self.strip_after.is_none() {
                        self.strip_after = Some((*speed, Instant::now()));
                    }
                } else if self.mounted_run.is_none() && *speed > BASE_RUN + 0.05 {
                    self.mounted_run = Some(*speed);
                    println!("mounted: run {speed} yd/s — teleporting into map {DUNGEON_MAP}");
                }
            }
            // `SMSG_LOGIN_VERIFY_WORLD` also decodes to this: gate on the teleport being sent.
            SessionEvent::Worldport { map_id, .. } if self.ported && self.arrived.is_none() => {
                self.arrived = Some((*map_id, Instant::now()));
                println!("SMSG_NEW_WORLD: map {map_id}");
            }
            // Our create on the new map, from `SendInitSelf` before the strip; its LIVING block
            // seeds a fresh entity's speeds.
            SessionEvent::ObjectCreate { guid, speeds, .. }
                if *guid == cx.world.self_guid && self.ported && self.arrived.is_some() =>
            {
                if let (None, Some(s)) = (self.create_after, speeds) {
                    self.create_after = Some((s.run, Instant::now()));
                    println!("self create block on the new map: run {} yd/s", s.run);
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn poll(&mut self, cx: &mut Ctx) -> Result<()> {
        // Mount only once the staging teleport has landed us outdoors.
        if !self.mount_requested && cx.world.self_map == OUTDOOR_MAP {
            self.mount_requested = true;
            cx.session.send_chat(&format!(".aura {MOUNT_SPELL}"))?;
            println!(
                "on map {OUTDOOR_MAP}; sent GM: .aura {MOUNT_SPELL} (Brown Horse) — expecting the \
                 mounted run speed"
            );
        }
        if self.mounted_run.is_some() && !self.ported {
            self.ported = true;
            cx.session.send_chat(DUNGEON_TP)?;
        }
        Ok(())
    }

    fn verify(&mut self, cx: &mut Ctx) -> Result<()> {
        // Restore before asserting. The exit names map 0: `.go xyz` defaults to the current map,
        // so a bare `ATTACK_TP` would land on Northshire's coordinates inside Ragefire Chasm.
        cx.session.send_chat(&format!(".unaura {MOUNT_SPELL}"))?;
        cx.session
            .send_chat(&format!("{ATTACK_TP} {OUTDOOR_MAP}"))?;
        // Stay to ack the exit port: a far teleport the client never acks does not happen.
        // Advisory only, since `stage` recovers a stranded character.
        let until = Instant::now() + std::time::Duration::from_secs(5);
        while Instant::now() < until && cx.world.self_map != OUTDOOR_MAP {
            match cx.session.recv() {
                Ok(msg) => {
                    for ev in benilla_protocol::decode(msg) {
                        cx.world.on_event(&ev, cx.session)?;
                    }
                }
                Err(_) => continue,
            }
        }

        ensure!(
            self.mount_requested,
            "--mount-tele: never reached map {OUTDOOR_MAP} — the staging teleport did not land \
             (raise --seconds, or check the `.go` GM level)"
        );
        let mounted = self.mounted_run.ensure_some(
            "--mount-tele: no mounted run speed arrived — did `.aura` take (GM account?), or does \
             this build's mount spell differ?",
        )?;
        let (map, _) = self
            .arrived
            .ensure_some("--mount-tele: no SMSG_NEW_WORLD — the `.go xyz <map>` never ported us")?;
        ensure!(
            map == DUNGEON_MAP,
            "--mount-tele: ported to map {map}, wanted {DUNGEON_MAP}"
        );
        let (create_run, create_at) = self.create_after.ensure_some(
            "--mount-tele: no self create block on the destination map — was the worldport acked?",
        )?;
        let (strip_run, strip_at) = self.strip_after.ensure_some(
            "--mount-tele: the arrival sent no Run force-change — this map did not strip the mount",
        )?;

        ensure!(
            (create_run - mounted).abs() < 0.01,
            "--mount-tele: the destination's create block should still carry the MOUNTED run \
             speed ({mounted}), got {create_run} — the strip would then precede the create, \
             the opposite of the order this probe expects"
        );
        ensure!(
            (strip_run - BASE_RUN).abs() < 0.01,
            "--mount-tele: the dismount should restore the {BASE_RUN} base run speed, got {strip_run}"
        );
        let gap = strip_at.duration_since(create_at);
        println!(
            "\n--mount-tele PASS: arrived on map {map}; create block carried the mount's \
             {create_run} yd/s, the dismount's SMSG_FORCE_RUN_SPEED_CHANGE followed {} µs later \
             at {strip_run} yd/s.\n  Both packets are written by one HandleMoveWorldportAckOpcode \
             call, so a client that drains its socket once a frame sees them in ONE drain.",
            gap.as_micros()
        );
        Ok(())
    }
}

/// `Option::ok_or_else` with a message, so each `verify` line reads as one claim.
trait EnsureSome<T> {
    fn ensure_some(&self, msg: &str) -> Result<T>;
}

impl<T: Copy> EnsureSome<T> for Option<T> {
    fn ensure_some(&self, msg: &str) -> Result<T> {
        self.ok_or_else(|| anyhow::anyhow!("{msg}"))
    }
}
