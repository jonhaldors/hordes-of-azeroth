//! `--giverstatus`: the questgiver status wire behind the overhead `!`/`?` markers.
//! `CMSG_QUESTGIVER_STATUS_QUERY` on Marshal McBride must draw an `SMSG_QUESTGIVER_STATUS`.

use std::time::{Duration, Instant};

use anyhow::{Context, Result};
use benilla_protocol::{decode, guid, EntityKind, SessionEvent};

use crate::probes::{Ctx, Probe, QUESTLOG_ID, QUEST_TURNIN_ENTRY, QUEST_TURNIN_TP};

pub(crate) struct GiverStatus;

impl Probe for GiverStatus {
    fn stage(&mut self, cx: &mut Ctx) -> Result<()> {
        // Shared with --questlog: `mcbride_staged` sends the cleanup and teleport once.
        if !cx.world.mcbride_staged {
            cx.session
                .send_chat(&format!(".quest remove {QUESTLOG_ID}"))?;
            cx.session.send_chat(QUEST_TURNIN_TP)?;
            cx.world.mcbride_staged = true;
            println!(
                "sent GM: .quest remove {QUESTLOG_ID}; teleport onto McBride {QUEST_TURNIN_TP}"
            );
        }
        Ok(())
    }

    fn verify(&mut self, cx: &mut Ctx) -> Result<()> {
        let world = &mut *cx.world;
        let session = &mut *cx.session;

        // Quest 7 was removed in staging, so McBride answers AVAILABLE, 5
        // (`QuestHandler.cpp:36-77`).
        let mcbride = world
            .tracked
            .iter()
            .filter(|(g, t)| t.kind == EntityKind::Unit && guid::is_creature_or_pet(**g))
            .find(|(g, _)| guid::entry(**g) == Some(QUEST_TURNIN_ENTRY))
            .map(|(&g, _)| g)
            .context(
                "--giverstatus: Marshal McBride (entry 197) didn't stream — did the GM teleport \
                 land? (needs gmlevel >= 2; try a longer --seconds)",
            )?;
        println!("\nMarshal McBride: guid {mcbride:#x}");
        println!("CMSG_QUESTGIVER_STATUS_QUERY({mcbride:#x})");
        session.questgiver_status_query(mcbride)?;
        let mut got: Option<u32> = None;
        let drain_until = Instant::now() + Duration::from_secs(5);
        while Instant::now() < drain_until && got.is_none() {
            let Ok(msg) = session.recv() else { continue };
            for ev in decode(msg) {
                if let SessionEvent::QuestGiverStatus { npc, status } = ev {
                    if npc == mcbride {
                        got = Some(status);
                    }
                }
            }
        }
        let status = got.context("--giverstatus: no SMSG_QUESTGIVER_STATUS within 5s")?;
        println!(
            "✅ dialog status: {status} ({})",
            match status {
                0 => "NONE",
                1 => "UNAVAILABLE",
                2 => "CHAT",
                3 => "INCOMPLETE — white ?",
                4 => "REWARD_REP — gold ?",
                5 => "AVAILABLE — gold !",
                6 => "REWARD_OLD — gold ?",
                7 => "REWARD2 — gold ?",
                _ => "unknown",
            }
        );
        println!("\n✅ --giverstatus PASS: the marker wire answers.");
        Ok(())
    }
}
