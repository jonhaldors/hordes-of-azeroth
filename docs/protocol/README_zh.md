# 协议

## 0. 现状

- HoA 的展示数据现在走类型化通道；服务端和插件的旧 `BONK~` 解析器都已删除。
- Rust 客户端通过类型化通道接收展示数据；旧的 `HOA~` 绘制解析器已经删除。
- 客户端没有 spell 查询通道（`benilla-app/src/net.rs:1034-1058`），自定义 spell 的元数据无处可查。
- 状态类数据（护盾量、冲刺、决心、卡牌 proc）以前依赖这套字符串通道；现在状态和展示都走下面的类型化通道。
- 第一块类型化协议（2026-11-04）：opcode `SMSG_HOA_MESSAGE`（826）在插件发送 `.bonk hello` 后下发 `hoa.hello`——协议版本、内容哈希和账号语言。源文件是 `shared/protocol/messages.yaml`；`tools/protocol/gen.py` 生成 `HoaProtocol.h` 和 `protocol_generated.rs`；客户端比较版本/哈希；不一致时触发 `HOA_INCOMPATIBLE`、停止应用后续类型化消息，并由插件弹出明确提示；一致时向 Lua 触发 `HOA_HELLO`。`hoa.aura_value`（`spell_id`、`value`、`max_value`）取代护盾聊天行并触发 `HOA_AURA_VALUE`。`hoa.dash` 携带最大充能、恢复时间、冷却、闪现标记和可用充能数，触发 `HOA_DASH`。`hoa.aura_percent`（`spell_id`、`percent`）覆盖决心、坏死和伤口，触发 `HOA_AURA_PERCENT`。`hoa.aura_text` 和 `hoa.aura_catalog_entry`/`aura_catalog_end` 承载本地化光环显示数据。`hoa.run_state` 承载计时、击杀、金币、阶段、Boss/传送门标记和计量字符串，并向 Lua 触发带表格参数的 `HOA_RUN_STATE`；插件不再解析旧的 `state~` 行。`hoa.run_start` 和 `hoa.run_end` 取代 `start~`/`end~`，分别触发 `HOA_RUN_START`/`HOA_RUN_END` 表格。`hoa.run_paused`、`hoa.coop_no_pause`、`hoa.run_xp` 和 `hoa.wave_beat` 覆盖暂停状态、联机暂停策略、经验和波次提示。`hoa.run_support`、`hoa.run_glyph_meter`、`hoa.run_other_meter` 和 `hoa.run_party_meter` 用类型化文本字段承载高频计量数据。`hoa.objective`、`hoa.objective_clear` 和 `hoa.objective_ping` 覆盖任务目标图钉。`hoa.mob`、`hoa.mob_dead`、`hoa.mob_clear`、`hoa.ally`、`hoa.ally_done` 和 `hoa.affix_info` 覆盖敌人/队友姓名板与词缀图鉴；`mob_clear` 没有字段。`hoa.offer_*` 和 `hoa.ley_*` 覆盖等级/宝箱和雷线选择面板，包括无字段的关闭事件。`hoa.glyph_*` 覆盖雕文选择、已选列表、信息卡和影之哀伤层数。`hoa.quest_*`、`hoa.vendor_*` 和 `hoa.portal_*` 覆盖任务日志/奖励、商人货架以及回城/无尽确认。`hoa.found_*` 和 `hoa.gear_*` 覆盖发现装备卡片和装备替换面板。`hoa.vault_*` 覆盖仓库货架和寄送回家列表。`hoa.enchant_*` 覆盖附魔槽位、报价以及打开/关闭事件。`hoa.cards` 和 `hoa.card_*` 覆盖持有卡牌列表、提示、冷却和实时数值。`hoa.mastery_state`、`hoa.wallet`、`hoa.notice`、`hoa.message`、`hoa.find`、`hoa.npc_name`、`hoa.shard`、`hoa.valor` 和 `hoa.epic_luck` 覆盖剩余玩家状态信号。`hoa.coop_*` 和 `hoa.leash` 覆盖联机等待/观战/倒地/准备以及牵引警告。`hoa.starter*`、`hoa.reach_ring`、`hoa.druid_form`、`hoa.greed` 和 `hoa.hearth` 覆盖剩余的跑团小信号。`hoa.capture`、`hoa.moonwell`、`hoa.ley_bless*` 和 `hoa.event_timer` 覆盖祭坛和事件计时。`hoa.death_*`、`hoa.run_summary`、`hoa.summary_*` 和 `hoa.summary_end` 覆盖死亡回顾和跑团结算。`hoa.board_*` 覆盖排行榜的打开/表头/行/分页/选择流程；行内容暂时仍是格式化 `line` 字符串。`hoa.shop_*` 和 `hoa.mastery_*` 覆盖商店、精通树、节点、预设和关闭事件。`hoa.gear`、`hoa.gear_end`、`hoa.trinket_tip` 和 `hoa.arena` 覆盖装备属性、饰品提示和竞技场面板。`hoa.tier`、`hoa.tier_info`、`hoa.level_*`、`hoa.map_info` 和 `hoa.zone_art` 覆盖难度/地图选择器。`hoa.codex` 用类型化的 kind 加打包行承载剩余图鉴/词汇条目。`hoa.weapon_info`、`hoa.weapon_evolution*`、`hoa.cooldown_pie`、`hoa.quartermaster*`、`hoa.music`、`hoa.loadout`、`hoa.druid_slots`、`hoa.boss_bar`、`hoa.titles`、`hoa.stats` 和 `hoa.keyword_timers` 覆盖最后一批动态信号。`hoa.visual_*` 用类型化坐标承载预警圈、道具、飞行物、飞弹和光环锚点，取代旧的 `HOA~` 聊天行。服务端和插件都不再使用 `BONK~` 通道。

## 1. 目标

- 服务端与客户端之间的 HoA 数据有明确的 schema 和版本，不再靠拼字符串。
- 状态类数据（buff、层数、数值）尽量走原版游戏状态；只有原版协议表达不了的 HoA 展示数据才走自定义消息。
- 一份 schema 生成 C++ 和 Rust 代码，避免两端解析偏差。
- 内容版本、协议版本、语言在握手阶段协商。

## 2. 分层

```
原版 1.12.1 协议（保留）
  ├─ 登录/角色/移动/战斗/物品/光环/聊天……
  └─ 原生 buff、等级、施法、冷却直接使用

HoA 协议（新增，版本化）
  ├─ 握手：账号语言、内容哈希、协议版本、能力位
  ├─ 内容：清单/增量（客户端内容包校验）
  ├─ 远征：开始、波次、Boss、奖励、结算
  └─ 展示：卡牌、图鉴、排行榜、提示、预警圈/飞行物/道具（UI 与客户端视觉）
```

## 3. 握手

登录世界时服务端下发：

```yaml
handshake:
  protocol_version: 1
  content_hash: "sha256:..."
  locale: "zhCN"          # 账号语言
  capabilities: [auras, content_pack, i18n]
```

- 客户端据此加载语言包/内容包；版本或哈希不匹配时触发 `HOA_INCOMPATIBLE`、停止应用类型化消息，插件弹出明确错误。直连/联机应在进入世界前拒绝不同版本的主机。
- 语言变更：客户端发送 `set_locale`（或沿用原版命令），服务端更新账号语言并刷新缓存名字；客户端重载语言包和 UI。

## 4. 消息定义

`shared/protocol/*.yaml`：

```yaml
- name: hoa.run.stage_started
  id: 0xA001
  direction: server_to_client
  fields:
    - { name: stage, type: u8 }
    - { name: difficulty, type: u8 }
    - { name: boss_entry, type: u32 }
```

```yaml
- name: hoa.aura.value
  id: 0xA010
  direction: server_to_client
  fields:
    - { name: unit_guid, type: u64 }
    - { name: spell_id, type: u32 }
    - { name: value, type: u32 }     # 护盾剩余量等 aura 字段放不下的数值
    - { name: max_value, type: u32 }
```

- ID 使用独立的 HoA 区段；不占用原版 opcode。
- 字段类型固定（u8/u16/u32/u64/i32/f32/string/array），字符串 UTF-8，长度前缀。
- 每条消息有版本；不兼容变更升 `protocol_version`。

## 5. 生成

`tools/protocol-gen` 读取 schema，生成：

- C++：`server/src/game/Hoa/protocol/generated/`（序列化/反序列化、消息 ID 常量）
- Rust：`client/crates/hoa-protocol/src/generated/`
- Lua：仅当插件需要消息常量时生成（数据由客户端转交，不让插件解析二进制）

生成物提交到仓库，CI 检查 diff。

## 6. 插件如何拿到数据

现状：服务端用 `BONK~type~...` 聊天行传展示数据，插件解析字符串；状态类数据走类型化通道。

新设计：

1. 客户端 Rust 处理 HoA 消息。
2. 客户端通过一个稳定的 Lua API 暴露给插件，例如：

```lua
Hoa.GetRunState()          -- 远征状态
Hoa.GetAuraValue(spellID)  -- 护盾量等
Hoa.GetCards()             -- 卡牌数据
Hoa.RegisterEvent("RUN_STAGE", fn)
```

3. 插件不再订阅聊天行、不解析 `~` 分隔的字符串。

过渡期可以保留 `BONK~` 通道用于尚未迁移的 UI 数据，但**状态类数据必须优先走原生 aura**，不再新增聊天行状态。

## 7. 兼容性

- 协议版本、内容哈希、客户端版本三者独立；任何一项不匹配都明确提示。
- 局域网发现/直连握手时校验版本；不同版本不允许联机。
- 旧客户端连接新服务端：握手拒绝，消息明确要求更新。
- 新客户端连接旧服务端：按能力位降级或拒绝。

## 8. 迁移

1. 盘点现有 `BONK~` 消息，按“状态/展示/命令”分类。
2. 状态类迁到 aura（见 [光环与效果](../auras/README_zh.md)）。
3. 展示类定义 HoA 消息 + 客户端 Lua API。
4. 命令类（`.bonk ...`）保留聊天命令入口，但处理器改为调用服务端 API，不依赖字符串拼装。
5. 最后删除插件里的 `BONK~` 解析器和手工字段索引。
