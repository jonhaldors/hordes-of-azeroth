//! Mirror timers: the breath, fatigue and feign-death bars. The server owns the countdown and the
//! client integrates it between packets. Any change is re-sent as a full `START`
//! (`Player::SendMirrorTimers`), so `START` also re-states a running timer; vmangos never sends
//! `PAUSE`, whose stock `MirrorTimer.lua` handler errors on it.

use std::io::{self, Read};

use crate::wire::{read_i32_le, read_u32_le, read_u8};

/// The wire's `timerType` (vmangos `Objects/MirrorTimer.h`), also the reference client's index
/// into its 3-entry timer name table.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MirrorTimerKind {
    /// `0`: swimming in deep, uncharted water.
    Fatigue,
    /// `1`: head under the surface.
    Breath,
    /// `2`: feigning death; its duration is zero unless a script sets it, so it rarely shows.
    FeignDeath,
}

impl MirrorTimerKind {
    /// The server's `NUM_CLIENT_TIMERS` gate keeps its internal `ENVIRONMENTAL` (3) off the wire.
    pub fn from_wire(value: u32) -> Option<Self> {
        match value {
            0 => Some(Self::Fatigue),
            1 => Some(Self::Breath),
            2 => Some(Self::FeignDeath),
            _ => None,
        }
    }

    pub fn to_wire(self) -> u32 {
        match self {
            Self::Fatigue => 0,
            Self::Breath => 1,
            Self::FeignDeath => 2,
        }
    }
}

/// `SMSG_START_MIRROR_TIMER`: starts, or wholly re-states, one mirror timer.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MirrorTimerStart {
    /// The raw `timerType`, left unmapped so an unknown one still decodes.
    pub kind: u32,
    /// Time left in ms, counting toward 0 while draining and toward `duration_ms` while refilling.
    pub remaining_ms: u32,
    /// The bar's maximum in ms (breath: 60 s by default, `CONFIG_UINT32_MIRRORTIMER_BREATH_MAX`).
    pub duration_ms: u32,
    /// Signed rate in bar seconds per second: `-1` while draining, `+10` while refilling after
    /// surfacing. The client integrates `scale * elapsed` between packets.
    pub scale: i32,
    /// Frozen: the bar holds its value and stops integrating.
    pub paused: bool,
    /// The spell driving the timer (water breathing) or `0`; the reference Lua never sees it.
    pub spell_id: u32,
}

/// `SMSG_START_MIRROR_TIMER` (vmangos `Server/Packets/Misc.cpp:472`).
pub fn read_start_mirror_timer(r: &mut impl Read) -> io::Result<MirrorTimerStart> {
    Ok(MirrorTimerStart {
        kind: read_u32_le(r)?,
        remaining_ms: read_u32_le(r)?,
        duration_ms: read_u32_le(r)?,
        scale: read_i32_le(r)?,
        paused: read_u8(r)? != 0,
        spell_id: read_u32_le(r)?,
    })
}

/// `SMSG_PAUSE_MIRROR_TIMER` (vmangos `Misc.cpp:487`): the raw type and the paused flag.
pub fn read_pause_mirror_timer(r: &mut impl Read) -> io::Result<(u32, bool)> {
    Ok((read_u32_le(r)?, read_u8(r)? != 0))
}

/// `SMSG_STOP_MIRROR_TIMER` (vmangos `Misc.cpp:482`): the raw type alone.
pub fn read_stop_mirror_timer(r: &mut impl Read) -> io::Result<u32> {
    read_u32_le(r)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn start_reads_every_field_in_the_servers_order() {
        let mut body = Vec::new();
        body.extend_from_slice(&1u32.to_le_bytes()); // type: BREATH
        body.extend_from_slice(&45_000u32.to_le_bytes()); // remaining ms
        body.extend_from_slice(&60_000u32.to_le_bytes()); // duration ms
        body.extend_from_slice(&(-1i32).to_le_bytes()); // scale: draining
        body.push(0); // paused
        body.extend_from_slice(&0u32.to_le_bytes()); // spellId
        assert_eq!(body.len(), 21, "the server's body is 4+4+4+4+1+4 bytes");
        assert_eq!(
            read_start_mirror_timer(&mut &body[..]).unwrap(),
            MirrorTimerStart {
                kind: 1,
                remaining_ms: 45_000,
                duration_ms: 60_000,
                scale: -1,
                paused: false,
                spell_id: 0,
            }
        );
    }

    #[test]
    fn start_carries_a_signed_scale_and_the_owning_spell() {
        let mut body = Vec::new();
        body.extend_from_slice(&1u32.to_le_bytes());
        body.extend_from_slice(&30_000u32.to_le_bytes());
        body.extend_from_slice(&60_000u32.to_le_bytes());
        body.extend_from_slice(&10i32.to_le_bytes());
        body.push(1);
        body.extend_from_slice(&5697u32.to_le_bytes()); // Water Breathing
        let start = read_start_mirror_timer(&mut &body[..]).unwrap();
        assert_eq!(
            start.scale, 10,
            "refilling ten times faster than it drained"
        );
        assert!(start.paused);
        assert_eq!(start.spell_id, 5697);

        // The draining rate, -1 on the wire, reads back negative.
        body[12..16].copy_from_slice(&(-1i32).to_le_bytes());
        let start = read_start_mirror_timer(&mut &body[..]).unwrap();
        assert_eq!(start.scale, -1, "draining");
        assert_eq!(start.spell_id, 5697);
    }

    #[test]
    fn only_the_three_client_timer_types_map() {
        assert_eq!(
            MirrorTimerKind::from_wire(0),
            Some(MirrorTimerKind::Fatigue)
        );
        assert_eq!(MirrorTimerKind::from_wire(1), Some(MirrorTimerKind::Breath));
        assert_eq!(
            MirrorTimerKind::from_wire(2),
            Some(MirrorTimerKind::FeignDeath)
        );
        assert_eq!(
            MirrorTimerKind::from_wire(3),
            None,
            "ENVIRONMENTAL: server-only"
        );
        assert_eq!(MirrorTimerKind::from_wire(u32::MAX), None);
        for kind in [
            MirrorTimerKind::Fatigue,
            MirrorTimerKind::Breath,
            MirrorTimerKind::FeignDeath,
        ] {
            assert_eq!(MirrorTimerKind::from_wire(kind.to_wire()), Some(kind));
        }
    }

    #[test]
    fn pause_is_a_type_and_a_flag_byte() {
        let mut body = 0u32.to_le_bytes().to_vec();
        body.push(1);
        assert_eq!(read_pause_mirror_timer(&mut &body[..]).unwrap(), (0, true));
        let mut body = 1u32.to_le_bytes().to_vec();
        body.push(0);
        assert_eq!(read_pause_mirror_timer(&mut &body[..]).unwrap(), (1, false));
    }

    #[test]
    fn stop_is_the_bare_type_word() {
        assert_eq!(
            read_stop_mirror_timer(&mut &1u32.to_le_bytes()[..]).unwrap(),
            1
        );
    }

    /// The cuts fall before `scale`, before `paused`, before `spellId` and inside it.
    #[test]
    fn a_truncated_start_body_is_an_error() {
        let mut full = Vec::new();
        full.extend_from_slice(&1u32.to_le_bytes());
        full.extend_from_slice(&45_000u32.to_le_bytes());
        full.extend_from_slice(&60_000u32.to_le_bytes());
        full.extend_from_slice(&(-1i32).to_le_bytes());
        full.push(0);
        full.extend_from_slice(&0u32.to_le_bytes());
        for cut in [12, 16, 17, 20] {
            assert!(
                read_start_mirror_timer(&mut &full[..cut]).is_err(),
                "a {cut}-byte body must not decode"
            );
        }
        assert!(read_start_mirror_timer(&mut &full[..]).is_ok());
    }
}
