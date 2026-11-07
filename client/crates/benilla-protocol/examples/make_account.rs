//! Dev helper: prints the SQL that creates a vmangos account, with the SRP6 verifier and salt
//! from `benilla-srp`. vmangos stores `v` and `s` as big-endian hex; we compute little-endian.
//!
//! ```text
//! cargo run -p benilla-protocol --example make_account -- <user> <pass> \
//!   | docker exec -i <db-container> mariadb -uroot -ppassword realmd
//! ```

use benilla_srp::NormalizedString;

fn big_endian_hex(little_endian_bytes: &[u8]) -> String {
    little_endian_bytes
        .iter()
        .rev()
        .map(|b| format!("{b:02X}"))
        .collect()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let user = args.get(1).expect("usage: make_account <user> <pass>");
    let pass = args.get(2).expect("usage: make_account <user> <pass>");

    let username = NormalizedString::new(user).expect("invalid username");
    let password = NormalizedString::new(pass).expect("invalid password");
    let (salt, verifier) = benilla_srp::generate_account(&username, &password);

    println!(
        "INSERT INTO account (username, v, s, gmlevel, expansion) VALUES ('{}', '{}', '{}', 3, 0);",
        user.to_uppercase(),
        big_endian_hex(&verifier),
        big_endian_hex(&salt),
    );
}
