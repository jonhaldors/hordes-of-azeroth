//! The honor wire end to end: an opcode dispatches to its reader, names itself, and reaches its
//! event unchanged.

mod common;

use benilla_protocol::events::{decode, SessionEvent};
use benilla_protocol::messages;
use benilla_protocol::ServerPacket;
use common::hx;

/// The 50-byte `MSG_INSPECT_HONOR_STATS` reply, in vmangos
/// `InspectHonorStatsResponse::AppendBodyTo` order.
fn inspect_honor_body() -> Vec<u8> {
    hx(concat!(
        "b32a000001000000", // u64 playerGuid
        "0b",               // u8  highestRank
        "11000200",         // u32 sessionKills (17 HK | 2 DK)
        "2900",             // u16 yesterdayHK
        "0000",             // u16 unknownOld1
        "a401",             // u16 lastWeekHK
        "0000",             // u16 unknownOld2
        "7b00",             // u16 thisWeekHK
        "0000",             // u16 unknownOld3
        "430f0000",         // u32 lifetimeHK
        "0c000000",         // u32 lifetimeDHK
        "80020000",         // u32 yesterdayHonor
        "ef200000",         // u32 lastWeekHonor
        "e2040000",         // u32 thisWeekHonor
        "39000000",         // u32 lastWeekRank (the standing)
        "bf",               // u8  rankBar
    ))
}

/// `MSG_INSPECT_HONOR_STATS` (0x2D6) also carries our request, a bare guid; `parse_server` only
/// sees the reply.
#[test]
fn inspect_honor_stats_wire() {
    let body = inspect_honor_body();
    assert_eq!(body.len(), 50, "the 1.12.1 reply body is exactly 50 bytes");
    let packet = messages::parse_server(messages::opcode::MSG_INSPECT_HONOR_STATS, &body).unwrap();
    assert_eq!(packet.name(), "MSG_INSPECT_HONOR_STATS");
    let ServerPacket::InspectHonorStats(stats) = packet else {
        panic!("inspect honor stats");
    };
    assert_eq!(stats.player_guid, 0x0000_0001_0000_2AB3);
    assert_eq!(stats.highest_rank, 11);
    assert_eq!(stats.session_kills(), (17, 2));
    assert_eq!(
        (stats.yesterday_hk, stats.last_week_hk, stats.this_week_hk),
        (41, 420, 123)
    );
    assert_eq!(
        (stats.unknown_old1, stats.unknown_old2, stats.unknown_old3),
        (0, 0, 0),
        "vmangos writes all three deprecated slots as 0"
    );
    assert_eq!((stats.lifetime_hk, stats.lifetime_dhk), (3_907, 12));
    assert_eq!(
        (
            stats.yesterday_honor,
            stats.last_week_honor,
            stats.this_week_honor
        ),
        (640, 8_431, 1_250)
    );
    assert_eq!(stats.last_week_rank, 57, "the STANDING, not a rank");
    assert_eq!(stats.rank_bar, 191);

    match decode(ServerPacket::InspectHonorStats(stats)).as_slice() {
        [SessionEvent::InspectHonorStats(ev)] => assert_eq!(*ev, stats),
        other => panic!("one inspect-honor event, got {other:?}"),
    }

    assert_eq!(
        messages::inspect_honor_stats(0x0000_0001_0000_2AB3),
        hx("b32a000001000000")
    );
}

/// `SMSG_PVP_CREDIT` (0x28C): honor, victim guid, and the victim's internal rank (vmangos
/// `SendPVPCredit`, floored at 5 for a player), a `PVP_RANK_<rank>_<team>` key, not the badge.
#[test]
fn pvp_credit_wire() {
    // i32 honor = 143, u64 victimGuid = 0x0000000100002AB3, i32 victimRank = 11.
    let body = hx("8f000000b32a0000010000000b000000");
    assert_eq!(body.len(), 16);
    let packet = messages::parse_server(messages::opcode::SMSG_PVP_CREDIT, &body).unwrap();
    assert_eq!(packet.name(), "SMSG_PVP_CREDIT");
    let ServerPacket::PvpCredit(credit) = packet else {
        panic!("pvp credit");
    };
    assert_eq!(credit.honor, 143);
    assert_eq!(credit.victim_guid, 0x0000_0001_0000_2AB3);
    assert_eq!(credit.victim_rank, 11);

    match decode(ServerPacket::PvpCredit(credit)).as_slice() {
        [SessionEvent::PvpCredit(ev)] => assert_eq!(*ev, credit),
        other => panic!("one pvp-credit event, got {other:?}"),
    }

    // A dishonorable kill rides the same packet with negative honor (`HonorMgr.cpp:807`).
    let dk = hx("fbffffffb32a0000010000000b000000");
    let ServerPacket::PvpCredit(credit) =
        messages::parse_server(messages::opcode::SMSG_PVP_CREDIT, &dk).unwrap()
    else {
        panic!("pvp credit");
    };
    assert_eq!(credit.honor, -5);
}

#[test]
fn truncated_honor_bodies_error_at_the_dispatch() {
    let full = inspect_honor_body();
    assert!(
        messages::parse_server(messages::opcode::MSG_INSPECT_HONOR_STATS, &full[..49]).is_err()
    );
    assert!(messages::parse_server(messages::opcode::SMSG_PVP_CREDIT, &[0u8; 15]).is_err());
}
