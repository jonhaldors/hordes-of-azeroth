//! `SMSG_MONSTER_MOVE`: a mover, its start, a spline id, a `moveType` facing, then (unless a stop)
//! spline flags, a duration and the waypoints. `SMSG_MONSTER_MOVE_TRANSPORT` inserts the
//! transport's packed guid after the mover's, and every coordinate is then deck-local, waypoints
//! included (vmangos `MoveSplineInit.cpp:138-170`, `PathFinder.cpp:76-84`).

use std::io;

use crate::messages::{MonsterMoveFacing, ServerPacket};
use crate::wire::{
    capacity_hint, packed_to_vector3d, read_f32_le, read_i32_le, read_packed_guid, read_u32_le,
    read_u64_le, read_u8, Vector3d,
};

const MONSTER_MOVE_STOP: u8 = 0x1;
/// `SplineFlags::Flying`, also `Mask_CatmullRom` (tested at `0x6018f0`). Set, the unit keeps the
/// path's own Z along a curve; clear, the 1.12 client drops the spline Z (`0x616cb0`) and takes Z
/// from the terrain (`0x634040`), moving along straight segments.
const SPLINE_FLAG_FLYING: u32 = 0x200;
/// `SPLINEFLAG_RUNMODE`: run speed. The 1.12 client passes it to `CMovement::SetRunMode`
/// (`0x7c71c0`, from `0x7c6ac2`), so a spline without it sets `MOVEFLAG_WALK_MODE` on the unit.
const SPLINE_FLAG_RUNMODE: u32 = 0x100;

/// A stop (`moveType` 1) ends after the head: the 1.12 client reads no spline block and implies
/// `flags = 0x100, count = 1, duration = 0`. Otherwise the path runs `[start, …, endpoint]`.
pub(super) fn read_monster_move(r: &mut &[u8], on_transport: bool) -> io::Result<ServerPacket> {
    let guid = read_packed_guid(r)?;
    let transport = on_transport.then(|| read_packed_guid(r)).transpose()?;
    let start = Vector3d::read(r)?;
    // Echoed in `CMSG_MOVE_SPLINE_DONE` when the spline moves our own player (charge, knockback,
    // taxi); the server checks it against its newest spline id.
    let spline_id = read_u32_le(r)?;
    let move_type = read_u8(r)?;
    // Final facing (jumptable `0x602114`); the 1.12 client snaps the unit to it (`0x7c6f30`).
    let facing = match move_type {
        2 => {
            let spot = Vector3d::read(r)?;
            MonsterMoveFacing::Spot([spot.x, spot.y, spot.z])
        }
        3 => MonsterMoveFacing::Target(read_u64_le(r)?),
        4 => MonsterMoveFacing::Angle(read_f32_le(r)?),
        _ => MonsterMoveFacing::None,
    };
    Ok(if move_type == MONSTER_MOVE_STOP {
        ServerPacket::MonsterMove {
            guid,
            transport,
            start,
            spline_id,
            path: Vec::new(),
            facing,
            stop: true,
            duration_ms: 0,
            flying: false,
            // A stop carries no flags and builds no path; nothing reads this.
            run_mode: true,
        }
    } else {
        let spline_flags = read_u32_le(r)?;
        let duration_ms = read_u32_le(r)?;
        let flying = spline_flags & SPLINE_FLAG_FLYING != 0;
        let run_mode = spline_flags & SPLINE_FLAG_RUNMODE != 0;
        // Both layouts ship only the points after the start, so the head's `start` leads the path.
        let tail = read_monster_move_spline(r, flying)?;
        let path = if tail.is_empty() {
            Vec::new()
        } else {
            std::iter::once(start).chain(tail).collect()
        };
        ServerPacket::MonsterMove {
            guid,
            transport,
            start,
            spline_id,
            path,
            facing,
            stop: false,
            duration_ms,
            flying,
            run_mode,
        }
    })
}

/// The absolute waypoints after the start, endpoint last (vmangos `PacketBuilder`). Flying
/// (`WriteCatmullRomPath`): a `u32` count, then that many absolute points. Ground
/// (`WriteLinearPath`): a `u32` count, the absolute endpoint, then `count - 1` packed
/// `endpoint - waypoint` offsets. The start is not among them: vmangos writes from
/// `firstPoint = 1` (`MoveSplineInit.cpp:169`), and the reference decoder (`0x6018f0`) reads
/// the same `count - 1`.
fn read_monster_move_spline(r: &mut &[u8], catmull_rom: bool) -> io::Result<Vec<Vector3d>> {
    let count = read_u32_le(r)?;
    // 0xFFFF bounds only the pre-allocation against a corrupt `count`.
    if catmull_rom {
        let mut points = Vec::with_capacity(capacity_hint(count, 0xFFFF));
        for _ in 0..count {
            points.push(Vector3d::read(r)?);
        }
        return Ok(points);
    }
    if count == 0 {
        return Ok(Vec::new());
    }
    let endpoint = Vector3d::read(r)?;
    let mut points = Vec::with_capacity(capacity_hint(count, 0xFFFF));
    // `count == 1` is a straight hop: no offsets (vmangos: `if (last_idx > 1)`).
    for _ in 1..count {
        let off = packed_to_vector3d(read_i32_le(r)?);
        points.push(Vector3d {
            x: endpoint.x - off.x,
            y: endpoint.y - off.y,
            z: endpoint.z - off.z,
        });
    }
    points.push(endpoint);
    Ok(points)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::messages::{opcode, parse_server, parse_server_with_tail};
    use crate::wire::write_packed_guid;

    /// The fixed head: packed guid, start, splineId, moveType.
    fn head(guid: u64, start: [f32; 3], move_type: u8) -> Vec<u8> {
        let mut b = Vec::new();
        write_packed_guid(guid, &mut b).unwrap();
        for f in start {
            b.extend_from_slice(&f.to_le_bytes());
        }
        b.extend_from_slice(&7u32.to_le_bytes()); // splineId
        b.push(move_type);
        b
    }

    /// vmangos `WriteLinearPath` from `firstPoint = 1` over `path = [c₀, …, cₙ₋₁]`: the count
    /// `n - 1`, the endpoint, then `c₁ … cₙ₋₂` as packed `endpoint - point` offsets.
    fn append_linear_path(body: &mut Vec<u8>, path: &[[f32; 3]]) {
        let (&endpoint, leading) = path.split_last().expect("a path has an endpoint");
        let last_idx = path.len() - 1;
        body.extend_from_slice(&(last_idx as u32).to_le_bytes()); // last_idx − start + 1
        for f in endpoint {
            body.extend_from_slice(&f.to_le_bytes());
        }
        if last_idx <= 1 {
            return; // vmangos `packet_builder.cpp:92`: `if (last_idx > 1)`
        }
        // `for (i = start; i < last_idx; ++i)` with `start = 1`, packed in ¼-yd units.
        for &p in &leading[1..] {
            let pack = |v: f32, shift: u32, mask: i32| ((v * 4.0).round() as i32 & mask) << shift;
            let off = [endpoint[0] - p[0], endpoint[1] - p[1], endpoint[2] - p[2]];
            let packed = pack(off[0], 0, 0x7FF) | pack(off[1], 11, 0x7FF) | pack(off[2], 22, 0x3FF);
            body.extend_from_slice(&packed.to_le_bytes());
        }
    }

    /// Each opcode reads its own layout; the plain one must not find a transport guid.
    #[test]
    fn monster_move_transport_reads_the_deck_guid_first() {
        let mut body = Vec::new();
        write_packed_guid(0x55, &mut body).unwrap(); // the mover
        write_packed_guid(0x2000_0000_0000_0007, &mut body).unwrap(); // the transport
        for f in [1.5f32, -2.5, 0.75] {
            body.extend_from_slice(&f.to_le_bytes()); // deck-local start
        }
        body.extend_from_slice(&7u32.to_le_bytes()); // splineId
        body.push(0); // moveType: a plain move
        body.extend_from_slice(&0u32.to_le_bytes()); // spline flags: ground, walk
        body.extend_from_slice(&2_000u32.to_le_bytes()); // duration
        append_linear_path(&mut body, &[[1.5, -2.5, 0.75], [4.0, -2.5, 0.75]]);

        match parse_server(opcode::SMSG_MONSTER_MOVE_TRANSPORT, &body).expect("parses") {
            ServerPacket::MonsterMove {
                guid,
                transport,
                start,
                path,
                ..
            } => {
                assert_eq!(guid, 0x55);
                assert_eq!(transport, Some(0x2000_0000_0000_0007));
                assert_eq!((start.x, start.y, start.z), (1.5, -2.5, 0.75));
                assert_eq!(path.len(), 2, "start + endpoint, both deck-local");
                assert_eq!((path[1].x, path[1].y, path[1].z), (4.0, -2.5, 0.75));
            }
            _ => panic!("expected MonsterMove"),
        }

        // The plain opcode over the same bytes must not come back with a transport.
        match parse_server(opcode::SMSG_MONSTER_MOVE, &body) {
            Ok(ServerPacket::MonsterMove { transport, .. }) => assert_eq!(transport, None),
            Ok(_) => panic!("expected MonsterMove"),
            Err(_) => {} // an under-run is fine too: it is not the same read
        }
    }

    #[test]
    fn monster_move_stop_has_no_tail() {
        let body = head(0x1234, [1.0, 2.0, 3.0], MONSTER_MOVE_STOP);
        let p = parse_server(opcode::SMSG_MONSTER_MOVE, &body).expect("a stop parses head-only");
        match p {
            ServerPacket::MonsterMove { stop, path, .. } => {
                assert!(stop, "moveType 1 is a stop");
                assert!(path.is_empty(), "a stop carries no path");
            }
            _ => panic!("expected MonsterMove"),
        }
    }

    #[test]
    fn monster_move_facing_angle_is_captured() {
        // moveType 4 carries a facing angle.
        let mut body = head(0x55, [0.0, 0.0, 0.0], 4);
        body.extend_from_slice(&1.25f32.to_le_bytes()); // facing angle
        body.extend_from_slice(&0u32.to_le_bytes()); // spline flags (ground)
        body.extend_from_slice(&500u32.to_le_bytes()); // duration
        body.extend_from_slice(&1u32.to_le_bytes()); // count = 1 → endpoint only, no packed
        for f in [10.0f32, 0.0, 0.0] {
            body.extend_from_slice(&f.to_le_bytes()); // the single (absolute) endpoint
        }
        let p = parse_server(opcode::SMSG_MONSTER_MOVE, &body).expect("a facing move parses");
        match p {
            ServerPacket::MonsterMove {
                facing,
                path,
                duration_ms,
                stop,
                ..
            } => {
                assert!(!stop);
                assert_eq!(duration_ms, 500);
                assert_eq!(path.len(), 2, "start + endpoint");
                assert!((path[0].x - 0.0).abs() < 1e-6, "anchored at the wire start");
                assert!((path[1].x - 10.0).abs() < 1e-6, "endpoint verbatim");
                match facing {
                    MonsterMoveFacing::Angle(a) => assert!((a - 1.25).abs() < 1e-6),
                    other => panic!("expected an Angle facing, got {other:?}"),
                }
            }
            _ => panic!("expected MonsterMove"),
        }
    }

    #[test]
    fn monster_move_two_point_path_carries_no_offsets() {
        let mut body = head(0x77, [4.0, 8.0, 0.0], 0);
        body.extend_from_slice(&0u32.to_le_bytes()); // spline flags: ground
        body.extend_from_slice(&1_000u32.to_le_bytes()); // duration
        append_linear_path(&mut body, &[[4.0, 8.0, 0.0], [12.0, 8.0, 0.0]]);
        let (p, tail) = parse_server_with_tail(opcode::SMSG_MONSTER_MOVE, &body)
            .expect("a two-point hop parses");
        assert_eq!(tail, 0, "the body is exactly the count and the destination");
        match p {
            ServerPacket::MonsterMove { path, .. } => {
                assert_eq!(path.len(), 2, "start + destination, got {path:?}");
                assert!((path[0].x - 4.0).abs() < 1e-6 && (path[1].x - 12.0).abs() < 1e-6);
            }
            _ => panic!("expected MonsterMove"),
        }
    }

    /// Hand-assembled rather than through `append_linear_path`: the route `c₀ → c₁ → c₂` is
    /// `count = 2`, the endpoint `c₂` and one packed offset `c₂ - c₁`.
    #[test]
    fn monster_move_one_corner_path_keeps_its_corner() {
        let mut body = head(0x77, [0.0, 0.0, 0.0], 0); // c₀ in the head
        body.extend_from_slice(&0u32.to_le_bytes()); // spline flags: ground
        body.extend_from_slice(&2_000u32.to_le_bytes()); // duration
        body.extend_from_slice(&2u32.to_le_bytes()); // count = last_idx − start + 1 = 2
        for f in [10.0f32, 10.0, 0.0] {
            body.extend_from_slice(&f.to_le_bytes()); // endpoint c₂
        }
        // c₂ − c₁ = (0, 10, 0): x 0, y 10·4 = 40 at bit 11, z 0 (`appendPackXYZ`'s ¼-yd fields).
        body.extend_from_slice(&(40i32 << 11).to_le_bytes());
        let (p, tail) =
            parse_server_with_tail(opcode::SMSG_MONSTER_MOVE, &body).expect("a corner path parses");
        assert_eq!(tail, 0, "the one offset is read, not left behind");
        match p {
            ServerPacket::MonsterMove { path, .. } => {
                let got: Vec<[f32; 3]> = path.iter().map(|v| [v.x, v.y, v.z]).collect();
                assert_eq!(
                    got,
                    vec![[0.0, 0.0, 0.0], [10.0, 0.0, 0.0], [10.0, 10.0, 0.0]]
                );
            }
            _ => panic!("expected MonsterMove"),
        }
    }

    #[test]
    fn monster_move_ground_path_decodes_every_waypoint() {
        // ¼-yd multiples, so the packed quantization is exact.
        let want = [
            [0.0f32, 0.0, 0.0], // start
            [10.0, 0.0, 0.0],   // corner east
            [10.0, 10.0, 0.0],  // corner north
            [10.0, 10.0, 5.0],  // endpoint, up a step
        ];
        let mut body = head(0xABCD, want[0], 0); // moveType 0 (normal)
        body.extend_from_slice(&0u32.to_le_bytes()); // spline flags (ground/linear)
        body.extend_from_slice(&4000u32.to_le_bytes()); // duration
        append_linear_path(&mut body, &want);
        let p = parse_server(opcode::SMSG_MONSTER_MOVE, &body).expect("a ground path parses");
        match p {
            ServerPacket::MonsterMove {
                path, flying, stop, ..
            } => {
                assert!(!stop && !flying, "a normal ground move");
                assert_eq!(
                    path.len(),
                    4,
                    "all four waypoints survive, not just the endpoint"
                );
                for (got, exp) in path.iter().zip(want.iter()) {
                    assert!(
                        (got.x - exp[0]).abs() < 1e-4
                            && (got.y - exp[1]).abs() < 1e-4
                            && (got.z - exp[2]).abs() < 1e-4,
                        "waypoint {got:?} != {exp:?}"
                    );
                }
            }
            _ => panic!("expected MonsterMove"),
        }
    }

    #[test]
    fn monster_move_flying_path_reads_absolute_points() {
        let mids = [[3.0f32, 4.0, 50.0], [6.0, 8.0, 55.0]];
        let mut body = head(0x77, [0.0, 0.0, 40.0], 0);
        body.extend_from_slice(&SPLINE_FLAG_FLYING.to_le_bytes()); // flying ⇒ catmull-rom layout
        body.extend_from_slice(&3000u32.to_le_bytes()); // duration
        body.extend_from_slice(&(mids.len() as u32).to_le_bytes()); // count = absolute points
        for pt in mids {
            for f in pt {
                body.extend_from_slice(&f.to_le_bytes());
            }
        }
        let p = parse_server(opcode::SMSG_MONSTER_MOVE, &body).expect("a flying path parses");
        match p {
            ServerPacket::MonsterMove { path, flying, .. } => {
                assert!(flying, "the FLYING flag drives the catmull-rom layout");
                assert_eq!(path.len(), 3, "start + two absolute waypoints");
                assert!(
                    (path[0].z - 40.0).abs() < 1e-6,
                    "anchored at the wire start (Z kept — flying)"
                );
                assert!((path[2].x - 6.0).abs() < 1e-6 && (path[2].z - 55.0).abs() < 1e-6);
            }
            _ => panic!("expected MonsterMove"),
        }
    }
}
