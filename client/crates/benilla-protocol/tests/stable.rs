//! Stable-master wire: send bodies per vmangos `Server/Packets/Npc.cpp:51-76`, the pet list per
//! `Handlers/NPCHandler.cpp:522-575` and the result byte per `Npc.cpp:99-102`.

use benilla_protocol::messages::{self, stable_result, StabledPet};
use benilla_protocol::ServerPacket;

fn hx(s: &str) -> Vec<u8> {
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16).unwrap())
        .collect()
}

const NPC: u64 = 0x1234_5678_9abc_def0;
const NPC_HEX: &str = "f0debc9a78563412";

#[test]
fn stable_send_bodies_golden() {
    // Three guid-only verbs with identical bodies: only the opcode tells them apart.
    assert_eq!(
        messages::list_stabled_pets(NPC),
        hx(NPC_HEX),
        "MSG_LIST_STABLED_PETS body"
    );
    assert_eq!(
        messages::stable_pet(NPC),
        hx(NPC_HEX),
        "CMSG_STABLE_PET body"
    );
    assert_eq!(
        messages::buy_stable_slot(NPC),
        hx(NPC_HEX),
        "CMSG_BUY_STABLE_SLOT body"
    );

    // u64 npcGuid + u32 petNumber, the pet's own id (`character_pet.id`), never its slot.
    assert_eq!(
        messages::unstable_pet(NPC, 42),
        hx(&format!("{NPC_HEX}2a000000")),
        "CMSG_UNSTABLE_PET body"
    );
    assert_eq!(
        messages::stable_swap_pet(NPC, 42),
        hx(&format!("{NPC_HEX}2a000000")),
        "CMSG_STABLE_SWAP_PET body"
    );
}

/// Appends one pet record in wire order; `wire_slot` is 1-based, unlike the decoded index.
fn push_pet(
    body: &mut Vec<u8>,
    pet_number: u32,
    entry: u32,
    level: u32,
    name: &str,
    loyalty: u32,
    wire_slot: u8,
) {
    body.extend_from_slice(&pet_number.to_le_bytes());
    body.extend_from_slice(&entry.to_le_bytes());
    body.extend_from_slice(&level.to_le_bytes());
    body.extend_from_slice(name.as_bytes());
    body.push(0);
    body.extend_from_slice(&loyalty.to_le_bytes());
    body.push(wire_slot);
}

fn list_body(num_stable_slots: u8, pets: &[(u32, u32, u32, &str, u32, u8)]) -> Vec<u8> {
    let mut body = NPC.to_le_bytes().to_vec();
    body.push(pets.len() as u8);
    body.push(num_stable_slots);
    for &(n, e, l, name, loy, slot) in pets {
        push_pet(&mut body, n, e, l, name, loy, slot);
    }
    body
}

fn parse_list(body: &[u8]) -> (u64, u8, Vec<StabledPet>) {
    match messages::parse_server(messages::opcode::MSG_LIST_STABLED_PETS, body).unwrap() {
        ServerPacket::ListStabledPets {
            npc,
            num_stable_slots,
            pets,
        } => (npc, num_stable_slots, pets),
        _ => panic!("expected ListStabledPets"),
    }
}

/// Wire slots are 1-based (`SendStablePet` writes 1 for the current pet and `slot + 1` for a
/// stabled one); decoded slots are 0-based.
#[test]
fn a_full_stable_decodes_with_client_slot_indices() {
    let body = list_body(
        2,
        &[
            (7, 299, 41, "Rex", 6, 1),
            (8, 1126, 38, "Bruiser", 4, 2),
            (9, 883, 12, "Nibbles", 1, 3),
        ],
    );
    let (npc, slots, pets) = parse_list(&body);
    assert_eq!(npc, NPC);
    assert_eq!(slots, 2, "purchased slots, not occupied ones");
    assert_eq!(pets.len(), 3);

    // Wire 1 → client 0 (the current pet), wire 3 → client 2 (the second stable slot).
    assert_eq!(
        pets[0],
        StabledPet {
            pet_number: 7,
            creature_entry: 299,
            level: 41,
            name: "Rex".into(),
            loyalty: 6,
            slot: 0,
        }
    );
    assert_eq!(pets[1].slot, 1);
    assert_eq!(pets[2].slot, 2);
    // The name is a cstring mid-record; every later field depends on consuming it exactly.
    assert_eq!(pets[2].name, "Nibbles");
    assert_eq!((pets[2].loyalty, pets[2].creature_entry), (1, 883));
}

/// vmangos sends the slot-0 row only for a live or cached `HUNTER_PET`, so rows are read by slot,
/// never by position.
#[test]
fn an_absent_current_pet_leaves_no_slot_zero_row() {
    let body = list_body(1, &[(8, 1126, 38, "Bruiser", 4, 2)]);
    let (_, slots, pets) = parse_list(&body);
    assert_eq!(slots, 1);
    assert_eq!(pets.len(), 1);
    assert_eq!(
        pets[0].slot, 1,
        "the lone row is stable slot 1, not current"
    );
    assert!(!pets.iter().any(|p| p.slot == 0));
}

/// The purchased slot count and the row count are independent numbers.
#[test]
fn an_empty_list_still_carries_the_purchased_slot_count() {
    let (_, slots, pets) = parse_list(&list_body(1, &[]));
    assert_eq!(slots, 1);
    assert!(pets.is_empty());

    let (_, slots, pets) = parse_list(&list_body(0, &[]));
    assert_eq!(slots, 0);
    assert!(pets.is_empty());
}

/// Each result byte parses as itself, and the codes are vmangos's `StableResultCode` values.
#[test]
fn stable_result_codes_parse_as_their_vmangos_bytes() {
    for code in [
        stable_result::ERR_MONEY,
        stable_result::ERR_STABLE,
        stable_result::SUCCESS_STABLE,
        stable_result::SUCCESS_UNSTABLE,
        stable_result::SUCCESS_BUY_SLOT,
    ] {
        match messages::parse_server(messages::opcode::SMSG_STABLE_RESULT, &[code]).unwrap() {
            ServerPacket::StableResult { result } => assert_eq!(result, code),
            _ => panic!("expected StableResult"),
        }
    }

    // vmangos's `StableResultCode` values (`NPCHandler.cpp:40-47`).
    assert_eq!(
        [
            stable_result::ERR_MONEY,
            stable_result::ERR_STABLE,
            stable_result::SUCCESS_STABLE,
            stable_result::SUCCESS_UNSTABLE,
            stable_result::SUCCESS_BUY_SLOT,
        ],
        [0x01, 0x06, 0x08, 0x09, 0x0A]
    );
}
