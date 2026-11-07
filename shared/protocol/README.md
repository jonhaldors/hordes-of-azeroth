# shared/protocol / typed protocol

`messages.yaml` defines the HoA messages that travel between the server, the Rust client and the
client's Lua bridge. It is the single source for message ids and field order.

`tools/protocol/gen.py` emits:

- `server/src/game/Bonk/HoaProtocol.h`: message ids and one writer per message.
- `client/crates/hoa/src/protocol_generated.rs`: constants, structs and decoders.

`tools/content/compile.py` runs the generator together with the content compiler; `--check` fails
when either output is stale.

## Wire format

- Custom opcode `SMSG_HOA_MESSAGE` (826).
- Body: `u16 message id`, then the fields in schema order.
- `string` is a `u16` byte length followed by UTF-8 bytes.
- Integers are little-endian. There is no padding.

The current `hello` message (protocol version 29) is sent after the addon's `.bonk hello`: it
carries the protocol version, this build's content hash, the per-section content hashes and the
account language. The client compares the version and hashes, then fires `HOA_HELLO` into Lua.
A content mismatch reports the sections that differ (`cards`, `spells`, `tables`) instead of only
the single whole-content hash.

## Adding a message

1. Add it to `messages.yaml` with a unique id and typed fields.
2. Run `python tools/content/compile.py`.
3. Use the generated writer on the server and `protocol_generated::decode` in the client.
4. Bump `version` for an incompatible field change.
