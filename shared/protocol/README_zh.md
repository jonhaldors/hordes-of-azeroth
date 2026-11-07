# shared/protocol / 类型化协议

`messages.yaml` 定义服务端、Rust 客户端和客户端 Lua 桥之间的 HoA 消息，是消息 ID 和字段顺序的唯一来源。

`tools/protocol/gen.py` 生成：

- `server/src/game/Bonk/HoaProtocol.h`：消息 ID 和每条消息的写入函数。
- `client/crates/hoa/src/protocol_generated.rs`：常量、结构体和解码函数。

`tools/content/compile.py` 会一并运行协议生成器；`--check` 在任一产物过期时失败。

## 线上格式

- 自定义 opcode `SMSG_HOA_MESSAGE`（826）。
- 消息体：`u16 消息 ID`，然后按 schema 顺序排列字段。
- `string` 是 `u16` 字节长度加 UTF-8 内容。
- 整数小端，无填充。

当前 `hello` 消息（协议版本 29）在插件发送 `.bonk hello` 后下发：包含协议版本、本次构建的内容哈希、按段的内容哈希和账号语言。客户端比较版本和哈希，然后向 Lua 触发 `HOA_HELLO`。内容不一致时会指出具体变化的段（`cards`、`spells`、`tables`），不再只给一个整体哈希。

## 新增消息

1. 在 `messages.yaml` 里加唯一 ID 和类型化字段。
2. 运行 `python tools/content/compile.py`。
3. 服务端使用生成的写入函数，客户端用 `protocol_generated::decode` 解码。
4. 不兼容的字段变更要提升 `version`。
