//! `--charge`: warrior Charge (spell 100) at a creature 8–25 yd out must bring an
//! `SMSG_MONSTER_MOVE` for our own guid (a self spline), and the session must survive our
//! `CMSG_MOVE_SPLINE_DONE` ack.

use std::time::{Duration, Instant};

use anyhow::{bail, Context, Result};
use benilla_protocol::{guid, EntityKind, SessionEvent};

use crate::probes::{Ctx, Probe};

/// Open ground about 18 yd west of the kobold camp: kobolds in charge range but outside aggro,
/// since Charge refuses to fire while the caster is in combat.
const CHARGE_TP: &str = ".go xyz -8798.71 -164.568 81.94";

#[derive(Default)]
pub(crate) struct Charge {
    charge_target: Option<u64>,
    /// The pending self-spline ack: (endpoint, splineId, when to send).
    charge_ack: Option<([f32; 3], u32, Instant)>,
    charge_acked: bool,
    /// `World::total` when the ack went out, so `verify` can count the packets after it.
    total_at_ack: Option<u32>,
}

impl Probe for Charge {
    fn stage(&mut self, cx: &mut Ctx) -> Result<()> {
        cx.session.send_chat(".learn 100")?; // Charge rank 1 (GM: teach it to the warrior)
        cx.session.send_chat(CHARGE_TP)?;
        println!("sent GM: .learn 100 (Charge); teleport {CHARGE_TP}");
        Ok(())
    }

    fn poll(&mut self, cx: &mut Ctx) -> Result<()> {
        // Once landed, charge the farthest creature inside Charge's 8–25 yd band, clear of any
        // kobold already on us. One shot.
        if self.charge_target.is_none() {
            if let Some(pos) = cx.world.attack_pos {
                let pick = cx
                    .world
                    .tracked
                    .iter()
                    .filter(|(g, t)| t.kind == EntityKind::Unit && guid::is_creature_or_pet(**g))
                    .map(|(&g, t)| {
                        (
                            g,
                            t.position,
                            (t.position[0] - pos[0]).hypot(t.position[1] - pos[1]),
                        )
                    })
                    .filter(|(_, _, d)| (8.0..=25.0).contains(d))
                    .max_by(|a, b| a.2.total_cmp(&b.2));
                if let Some((guid, tpos, dist)) = pick {
                    // Face it first: Charge refuses a target not in front (124,
                    // `SPELL_FAILED_UNIT_NOT_INFRONT`). Orientation is `atan2(Δy, Δx)`.
                    let orientation = (tpos[1] - pos[1]).atan2(tpos[0] - pos[0]);
                    cx.session.stop(pos, orientation)?;
                    cx.session.set_selection(guid)?;
                    cx.session.cast_spell(100, Some(guid))?;
                    println!(
                        "sent CMSG_CAST_SPELL 100 (Charge) at {guid:#x} ({dist:.1} yd, faced)"
                    );
                    self.charge_target = Some(guid);
                }
            }
        }
        // Ack at the endpoint once the ride is over: the server holds a player mover
        // spline-pending until `CMSG_MOVE_SPLINE_DONE` arrives.
        if let Some((endpoint, spline_id, at)) = self.charge_ack {
            if !self.charge_acked && Instant::now() >= at {
                cx.session.move_spline_done(endpoint, 0.0, spline_id)?;
                println!(
                    "sent CMSG_MOVE_SPLINE_DONE (splineId {spline_id}) at endpoint ({:.1}, {:.1}, {:.1})",
                    endpoint[0], endpoint[1], endpoint[2]
                );
                self.charge_acked = true;
                self.total_at_ack = Some(cx.world.total);
            }
        }
        Ok(())
    }

    fn on_event(&mut self, ev: &SessionEvent, cx: &mut Ctx) -> Result<()> {
        if let SessionEvent::MonsterMove {
            guid,
            spline_id,
            path,
            stop,
            duration_ms,
            ..
        } = ev
        {
            // Ack at the last waypoint after `duration_ms` plus a margin, never mid-spline.
            if *guid == cx.world.self_guid && self.charge_ack.is_none() && !*stop {
                if let Some(&endpoint) = path.last() {
                    let at = Instant::now() + Duration::from_millis(u64::from(*duration_ms) + 200);
                    self.charge_ack = Some((endpoint, *spline_id, at));
                }
            }
        }
        Ok(())
    }

    fn verify(&mut self, cx: &mut Ctx) -> Result<()> {
        if cx.world.attack_pos.is_none() {
            bail!("--charge: the GM teleport never arrived (is the account gmlevel ≥ 2?)");
        }
        let target = self
            .charge_target
            .context("--charge: no creature streamed in charge range [8,25] yd to cast at")?;
        let self_moves = cx.world.self_moves;
        if self_moves == 0 {
            bail!("--charge: cast Charge at {target:#x} but the server sent NO SMSG_MONSTER_MOVE for our guid (check the CAST_RESULT reason above — combat / range / stance)");
        }
        println!("✅ charge: {self_moves} self SMSG_MONSTER_MOVE — Charge drives the caster via a server spline (target {target:#x}).");
        // A malformed ack body drops the session, so traffic after the ack proves it parsed.
        if self.charge_acked {
            let msgs_after_ack = cx.world.total
                - self
                    .total_at_ack
                    .expect("total_at_ack is set together with charge_acked");
            if msgs_after_ack == 0 {
                bail!("--charge: sent CMSG_MOVE_SPLINE_DONE but the stream went silent afterward — the server may have rejected/dropped us (malformed ack body?)");
            }
            println!("✅ charge ack: server accepted CMSG_MOVE_SPLINE_DONE — stream continued ({msgs_after_ack} packets after the ack).");
        } else {
            println!("⚠️  charge ack: never sent (no self spline endpoint captured to ack).");
        }
        Ok(())
    }
}
