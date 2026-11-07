//! The honor wire messages: the inspect-honor request/reply pair and the honor-gain credit.
//! Durable honor state rides the player descriptor; these carry what it cannot, another player's
//! stats and the moment a kill pays out.

use std::io;

use crate::wire::{read_i32_le, read_u16_le, read_u32_le, read_u64_le, read_u8};

/// Another player's honor stats, the `MSG_INSPECT_HONOR_STATS` reply (opcode 726): 50 bytes in
/// vmangos `Misc.cpp:301-325` order, from the target's `PLAYER_FIELD_*` honor block. Their
/// current rank is not here; it streams publicly in `PLAYER_BYTES_3`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct InspectHonorStats {
    /// Echoed from the request. There is no error reply: a missing, distant (10 yd) or hostile
    /// target gets no answer at all (`MiscHandler.cpp:977`).
    pub player_guid: u64,
    /// The highest lifetime rank (`MiscHandler.cpp:985`), internal 0..18 like
    /// [`crate::messages::ObjectFields::player_honor_rank`], not the visual number.
    pub highest_rank: u8,
    /// Today's kills, the packed `PLAYER_FIELD_SESSION_KILLS` dword (`MiscHandler.cpp:988`).
    pub session_kills: u32,
    /// Yesterday's honorable kills, the low half of `PLAYER_FIELD_YESTERDAY_KILLS`.
    pub yesterday_hk: u16,
    /// Always 0 from vmangos (`MiscHandler.cpp:994`); decoded, not skipped.
    pub unknown_old1: u16,
    /// Last week's honorable kills.
    pub last_week_hk: u16,
    /// Always 0 from vmangos.
    pub unknown_old2: u16,
    /// This week's honorable kills.
    pub this_week_hk: u16,
    /// Always 0 from vmangos.
    pub unknown_old3: u16,
    /// Lifetime honorable kills (`PLAYER_FIELD_LIFETIME_HONORBALE_KILLS`, vmangos's spelling).
    pub lifetime_hk: u32,
    /// Lifetime dishonorable kills.
    pub lifetime_dhk: u32,
    /// Yesterday's honor points (`PLAYER_FIELD_YESTERDAY_CONTRIBUTION`).
    pub yesterday_honor: u32,
    /// Last week's honor points.
    pub last_week_honor: u32,
    /// This week's honor points.
    pub this_week_honor: u32,
    /// Last week's standing, the ladder position and not a rank; 0 if unranked that week.
    pub last_week_rank: u32,
    /// Progress within the target's current rank, 0..255, computed as
    /// [`crate::messages::ObjectFields::player_honor_rank_bar`] is.
    pub rank_bar: u8,
}

impl InspectHonorStats {
    /// The packed field split into `(honorable, dishonorable)`, low half then high half.
    pub fn session_kills(&self) -> (u16, u16) {
        (self.session_kills as u16, (self.session_kills >> 16) as u16)
    }
}

/// Read the `MSG_INSPECT_HONOR_STATS` reply. Our 8-byte request shares the opcode, but only
/// server packets reach this reader.
pub(super) fn read_inspect_honor_stats(r: &mut &[u8]) -> io::Result<InspectHonorStats> {
    Ok(InspectHonorStats {
        player_guid: read_u64_le(r)?,
        highest_rank: read_u8(r)?,
        session_kills: read_u32_le(r)?,
        yesterday_hk: read_u16_le(r)?,
        unknown_old1: read_u16_le(r)?,
        last_week_hk: read_u16_le(r)?,
        unknown_old2: read_u16_le(r)?,
        this_week_hk: read_u16_le(r)?,
        unknown_old3: read_u16_le(r)?,
        lifetime_hk: read_u32_le(r)?,
        lifetime_dhk: read_u32_le(r)?,
        yesterday_honor: read_u32_le(r)?,
        last_week_honor: read_u32_le(r)?,
        this_week_honor: read_u32_le(r)?,
        last_week_rank: read_u32_le(r)?,
        rank_bar: read_u8(r)?,
    })
}

/// Body of the `MSG_INSPECT_HONOR_STATS` request: the raw, unpacked `u64` guid (vmangos
/// `Misc.cpp:93-96`). A refused request gets no answer, and unlike `CMSG_INSPECT` it does not
/// set our selection (`MiscHandler.cpp:962-972`).
pub fn inspect_honor_stats(guid: u64) -> Vec<u8> {
    guid.to_le_bytes().to_vec()
}

/// `SMSG_PVP_CREDIT` (opcode 652): one honor payout, dishonorable ones included (vmangos
/// `HonorMgr.cpp:1061-1093`). The descriptor holds only totals; this is the only per-payout notice.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PvpCredit {
    /// Honor, truncated server-side; negative for a dishonorable kill (`HonorMgr.cpp:807`).
    pub honor: i32,
    /// Who we killed; 0 for an honor row with no source (`HonorMgr.cpp:1069-1071`), which
    /// needs a victim-less phrasing rather than a name lookup.
    pub victim_guid: u64,
    /// The victim's internal rank (0..18), indexing the `PVP_RANK_<rank>_<team>` strings; the
    /// badge's visual rank is `internal > 4 ? internal - 4 : -internal` (`HonorMgr.cpp:991`).
    /// A creature sends 19 if a racial leader, else 0; vmangos floors a player victim at 5
    /// (`HonorMgr.cpp:1078-1089`), a server fallback rather than a rule to re-implement.
    pub victim_rank: i32,
}

/// Read `SMSG_PVP_CREDIT`: `i32 honor, u64 victimGuid, i32 victimRank`.
pub(super) fn read_pvp_credit(r: &mut &[u8]) -> io::Result<PvpCredit> {
    Ok(PvpCredit {
        honor: read_i32_le(r)?,
        victim_guid: read_u64_le(r)?,
        victim_rank: read_i32_le(r)?,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn inspect_honor_stats_golden() {
        #[rustfmt::skip]
        let body: [u8; 50] = [
            // [0..8) u64 playerGuid = 0x0000_0001_0000_2AB3
            0xB3, 0x2A, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
            // [8] u8 highestRank = 11 (internal)
            0x0B,
            // [9..13) u32 sessionKills = 0x0002_0011: 17 HK low, 2 DK high
            0x11, 0x00, 0x02, 0x00,
            // [13..15) u16 yesterdayHK = 41
            0x29, 0x00,
            // [15..17) u16 unknownOld1 = 0
            0x00, 0x00,
            // [17..19) u16 lastWeekHK = 420
            0xA4, 0x01,
            // [19..21) u16 unknownOld2 = 0
            0x00, 0x00,
            // [21..23) u16 thisWeekHK = 123
            0x7B, 0x00,
            // [23..25) u16 unknownOld3 = 0
            0x00, 0x00,
            // [25..29) u32 lifetimeHK = 3907
            0x43, 0x0F, 0x00, 0x00,
            // [29..33) u32 lifetimeDHK = 12
            0x0C, 0x00, 0x00, 0x00,
            // [33..37) u32 yesterdayHonor = 640
            0x80, 0x02, 0x00, 0x00,
            // [37..41) u32 lastWeekHonor = 8431
            0xEF, 0x20, 0x00, 0x00,
            // [41..45) u32 thisWeekHonor = 1250
            0xE2, 0x04, 0x00, 0x00,
            // [45..49) u32 lastWeekRank = 57 (the standing)
            0x39, 0x00, 0x00, 0x00,
            // [49] u8 rankBar = 191
            0xBF,
        ];
        let mut r = body.as_slice();
        let stats = read_inspect_honor_stats(&mut r).unwrap();
        assert!(r.is_empty(), "the whole 50-byte body is consumed");
        assert_eq!(
            stats,
            InspectHonorStats {
                player_guid: 0x0000_0001_0000_2AB3,
                highest_rank: 11,
                session_kills: 0x0002_0011,
                yesterday_hk: 41,
                unknown_old1: 0,
                last_week_hk: 420,
                unknown_old2: 0,
                this_week_hk: 123,
                unknown_old3: 0,
                lifetime_hk: 3_907,
                lifetime_dhk: 12,
                yesterday_honor: 640,
                last_week_honor: 8_431,
                this_week_honor: 1_250,
                last_week_rank: 57,
                rank_bar: 191,
            }
        );
        assert_eq!(stats.session_kills(), (17, 2));
    }

    /// 49 bytes is everything but the trailing `rankBar`, which is what a pre-1.6.1 server sends.
    #[test]
    fn inspect_honor_stats_truncated_body_errors() {
        let full = [0u8; 50];
        for len in [0usize, 8, 13, 49] {
            let mut r = &full[..len];
            assert!(
                read_inspect_honor_stats(&mut r).is_err(),
                "a {len}-byte inspect-honor body must be rejected"
            );
        }
        // The full length parses, so the loop above really tests truncation.
        let mut r = full.as_slice();
        assert!(read_inspect_honor_stats(&mut r).is_ok());
    }

    #[test]
    fn inspect_honor_stats_request_golden() {
        assert_eq!(
            inspect_honor_stats(0x0000_0001_0000_2AB3),
            vec![0xB3, 0x2A, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00],
        );
        // A zero guid is encoded as-is.
        assert_eq!(inspect_honor_stats(0), vec![0u8; 8]);
    }

    #[test]
    fn pvp_credit_golden() {
        #[rustfmt::skip]
        let body: [u8; 16] = [
            // [0..4) i32 honor = 143
            0x8F, 0x00, 0x00, 0x00,
            // [4..12) u64 victimGuid = 0x0000_0001_0000_2AB3
            0xB3, 0x2A, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
            // [12..16) i32 victimRank = 11 (internal rank, the PVP_RANK_11_<team> key)
            0x0B, 0x00, 0x00, 0x00,
        ];
        let mut r = body.as_slice();
        let credit = read_pvp_credit(&mut r).unwrap();
        assert!(r.is_empty(), "the whole 16-byte body is consumed");
        assert_eq!(
            credit,
            PvpCredit {
                honor: 143,
                victim_guid: 0x0000_0001_0000_2AB3,
                victim_rank: 11,
            }
        );
    }

    #[test]
    fn pvp_credit_dishonorable_kill_is_negative_honor() {
        let mut body = Vec::with_capacity(16);
        body.extend_from_slice(&(-5i32).to_le_bytes());
        body.extend_from_slice(&0x0000_0001_0000_2AB3u64.to_le_bytes());
        body.extend_from_slice(&5i32.to_le_bytes()); // floored to "Scout" server-side
        let mut r = body.as_slice();
        let credit = read_pvp_credit(&mut r).unwrap();
        assert!(r.is_empty());
        assert_eq!(credit.honor, -5);
        assert_eq!(credit.victim_rank, 5);
    }

    #[test]
    fn pvp_credit_zero_guid_means_no_victim() {
        let mut body = Vec::with_capacity(16);
        body.extend_from_slice(&5i32.to_le_bytes());
        body.extend_from_slice(&0u64.to_le_bytes()); // no victim
        body.extend_from_slice(&0i32.to_le_bytes()); // and so no rank
        let mut r = body.as_slice();
        let credit = read_pvp_credit(&mut r).unwrap();
        assert!(r.is_empty());
        assert_eq!(credit.victim_guid, 0, "zero guid = no victim");
        assert_eq!(credit.victim_rank, 0);
    }

    #[test]
    fn pvp_credit_truncated_body_errors() {
        let full = [0u8; 16];
        for len in [0usize, 4, 12, 15] {
            let mut r = &full[..len];
            assert!(
                read_pvp_credit(&mut r).is_err(),
                "a {len}-byte credit body must be rejected"
            );
        }
        let mut r = full.as_slice();
        assert!(read_pvp_credit(&mut r).is_ok());
    }
}
