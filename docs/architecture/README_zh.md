# 总体架构

## 1. 背景

Hordes of Azeroth 目前由三个独立仓库组成：主仓库（插件、GlueXML、启动器、合作联机）、VMaNGOS 服务端、benilla 客户端。这种拆分在跟随上游时是合理的，但我们的重构方向——账号级多语言、统一光环、单一内容源——需要同时修改服务端、客户端和插件，跨仓库会让每一次改动都变成三次 PR 和三次版本对齐。

因此新仓库把全部组件放在一起，硬分叉，独立演进。

## 2. 要解决的问题

### 2.1 语言绑定在客户端安装上

- 客户端的 locale 只有一个来源：安装目录的 `Wow.ini`（`client/crates/benilla-formats/src/wow_ini.rs:23-41`、`chain.rs:98-109`）。`GetLocale`、插件 `Title`/`Notes` 选择、登录 challenge、WDB 缓存头都用这个值（`benilla-app/src/ui_script/lifecycle.rs:160-161`、`ui_script/addons.rs:486-492`、`glue_session/login.rs:122`、`wdb.rs:500-504`）。
- 客户端界面文本硬编码英文：`assets/ui/OptionsFrame.xml`、`GameMenuAdapters.xml`、`ScriptLogFrame.xml`、`AccountLoginRealmlist.xml`；`GlobalStrings.lua` 也直接来自安装的 MPQ（`ui_script/lifecycle.rs:1165-1188`）。文字排版引擎甚至写死 `"en-US"` 的 shaping locale（`ui_text/engine/mod.rs:169`）。
- 自定义 spell 没有查询通道：客户端只支持 name/creature/pet/item 查询（`benilla-app/src/net.rs:1034-1058`）。`Spell.dbc` 里没有的 ID 在法术书里被直接丢弃（`ui_spellbook.rs:351-355`），`GetSpellName`/`GetSpellTexture` 返回空（`benilla-ui/src/script/spellbook.rs:404-435`），施法条为空（`ui_cast.rs:207-215`），光环名称/图标为 None（`ui_aura.rs:256-260`）。服务端无法补名称、图标、描述。
- 语言设置通过插件聊天命令传给服务端；服务端文本可以按账号语言本地化，但客户端界面、DBC 名称、自定义法术名称仍不受控。

**目标**：语言是账号/会话属性。客户端安装只需提供资源（模型、贴图、音频、基础 DBC），不决定显示语言。任何语言的 1.12.1 安装都能运行中文或英文。

**进度（2026-11-04）**：客户端第一阶段已落地。`shared/i18n/ui` + `tools/i18n/gen_client_pack.py` 生成 enUS/zhCN 语言包；HoA 自有 UI 和 GlueXML 读取 `HOA_UI_*` 键；`GetLocale` 使用账号/启动器语言，安装 locale 仍用于 DBC 列和名字字符集。原生 FrameXML/GlobalStrings、DBC 名称覆盖、zhTW 和写死的 shaper locale 仍待后续。

### 2.2 buff/效果有三套表示

- **真光环，但只做了一半**：移速/最大生命用 spell 17498/19255（`BonkRun.cpp:11365-11376`）；坏死有 aura 18951（`BonkRun.cpp:4411`），但治疗削减实际读的是 `m_necroticStacks`（`BonkRun.cpp:4439`）；护盾视觉 16051（`BonkRun.cpp:4754-4758`）；武器 buff 施放后又在 `m_buffs` 存了一份到期时间（`BonkRun.cpp:8071-8072,7913-7922`）。
- **纯服务端变量 + 插件绘制**：护盾量 `m_spellShield`（`BonkRun.h:2263`）通过 `shield~` 发插件（`BonkRun.cpp:4767`）；冲刺 `m_dashSpent/m_dashRechargeMs`（`BonkPlayer.h:544-545`、`BonkPlayerDash.cpp:194-221`）；决心 `m_determination`（`BonkPlayer.h:514`，写库 `BonkPlayer.cpp:2322-2335`）；Boss 伤口 `m_bossWoundStacks`（`BonkRun.h:1796`、`BonkRun.cpp:4629`）。这些在原生 buff 栏都看不到。
- **原生法术 + 插件副本**：剑刃乱舞/狂怒等复用原生 spell，但插件另有一套计时。
- **卡牌 proc 横跨三套**：以 Zandalarian Hero Charm 为例，“每 30 秒获得 25% 力量，持续 10 秒”（`server/core/sql/migrations/20261027710000_world.sql:46-47`）。服务端用 `m_cardSurgeUntilMs` + 冷却记录（`BonkRunCards.cpp:486-493`），`GetCardPower` 把加成折进伤害和属性（`BonkRunCards.cpp:156-170`、`BonkRun.cpp:4867,6284`），没有 Unit aura。界面靠每秒 `cardnow~` 文本（`BonkRunCards.cpp:507-533,586-596`）和一次 `Notify`（`:491`），插件再在 tooltip 里拼出来（`VanillaBonkCards.lua:84-86,205,313-328`）。

插件过去只解析 `BONK~` 聊天行，完全没有用 `UNIT_AURA`/`GetPlayerBuff`；现在它消费 Rust 客户端解码后的类型化 `HOA_*` 事件，`C_UnitAuras` 用于敌方姓名板和 Boss debuff。聊天解析器已不存在。

**进度（2026-11-05）：** 阶段 3 已把效果集迁到真实光环，阶段 5 已把服务端所有展示/状态字符串换成类型化协议。上面的条目是重构前的基线，保留作背景。

重复和轮询的例子：

- 关键词计时存在四份：aura、`m_dotStacks`、服务端 200ms `kwdt` 刷新（`BonkKeywords.cpp:29,342-361,497-555`）、插件倒计时（`VanillaBonkDebuffs.lua:328-350,385-399`）。
- 卡牌冷却：服务端 `m_cardCooldowns`，插件每帧重建倒计时（`VanillaBonkCards.lua:255-271,298-310`）。
- 护盾值：服务端 `m_spellShield`，插件再存一份（`VanillaBonk.lua:3611,3623`）。
- 每帧 `OnUpdate`：`VanillaBonkDebuffs.lua:385`（每个图标还有一圈 `:219`）、`VanillaBonkCards.lua:255`、`VanillaBonkPlates.lua:652`（每个姓名板 `:464`）、`VanillaBonkHurt.lua:59`、`VanillaBonkDash.lua:89`、`VanillaBonkController.lua:1900`。

结果：玩家看到的、插件显示的、服务端实际生效的可能是三份状态；其他插件/战斗日志无法通过标准 API 识别 HoA 效果。

**目标**：一个效果 = 一个真实光环。服务端是唯一状态源，客户端原生 buff 栏/`UnitBuff` 能读到，插件只负责显示。

### 2.3 同一份数据存在多处

盘点结果（服务端 = `server/core/src/game/Bonk/`，插件 = `Interface/AddOns/HordesOfAzeroth/`）：

- **职业名称/职业 ID**：服务端 `BonkStrings.cpp:666-674`、`SharedDefines.h:87-99`；插件 `VanillaBonkUI.lua:71-72`、`VanillaBonkCodex.lua:25-33`、`VanillaBonkCoop.lua:71`、`VanillaBonkMeter.lua:22`。
- **属性名称、说明、上限**：服务端 `BonkStrings.cpp:412-429`、`BonkMgr.h:888-899`，拾取上限在 `BonkRun.cpp:228-229`；插件 `VanillaBonk.lua:3030-3052` 又写了一遍（5/50/60/75/20，拾取 400）。
- **物品等级公式**：服务端 `BonkFoundGear.cpp:19-21,39-41`、`BonkFoundGear.h:19`；插件 `VanillaBonkFound.lua:84-98`。
- **数值常量**：地下城 +30% 生命/+20% 伤害（`BonkRun.cpp:252-253` vs `VanillaBonkRunMaster.lua:34`）、携带窗口 10（`BonkMgr.h:1091` vs `VanillaBonkRunMaster.lua:677`）、免费爬塔 49（`BonkLeaderboard.cpp:26` vs `VanillaBonkRunMaster.lua:1352`）、商人补货 +50%（`BonkRunVendor.cpp:30` vs `VanillaBonkVendor.lua:97`）、商人名字 Zixil（`BonkRunVendor.cpp:33` vs `VanillaBonkVendor.lua:17`）。
- **词汇表**：品质（`BonkStrings.cpp:950-954` vs `VanillaBonkUI.lua:42-47`、`VanillaBonk.lua:101-105`）、伤害类型（`BonkRunStats.cpp:90,104-110` vs `VanillaBonkUI.lua:50-68`）、目标类型（`BonkObjectives.cpp:31` vs `VanillaBonkObjectives.lua:4-11`）、任务分类（`BonkQuests.cpp:26` vs `VanillaBonkQuests.lua:46-53`）。
- **ID**：游戏对象 900001-900062（`BonkMgr.h:40-46` vs `VanillaBonkSettings.lua:9-11`、`VanillaBonkController.lua:1699`、`VanillaBonkTutorial.lua:4-8`）、炉石 900230（`BonkMgr.h:1054` vs `VanillaBonkHearth.lua:5`）。
- **关键数量**：法术/被动槽位（`BonkRun.cpp:248-251` vs `VanillaBonkHeroBar.lua:4-5`）、glyph 选项（`BonkRunGlyphs.cpp:20` vs `VanillaBonkGlyphs.lua:9`）、升级选项（`BonkMgr.h:1028` vs `VanillaBonk.lua:353`）、进化等级（`BonkMgr.h:464` vs `VanillaBonkCodex.lua:21`）。
- **重复计算**：排行榜资格（`BonkPlayer.cpp:3388-3401` vs `VanillaBonkRunMaster.lua:1354-1378`）。
- **文本**：已解决。服务端、插件和客户端界面文本现在都由 `shared/i18n` 生成；插件只有一个生成的 `VanillaBonkLocaleData.lua`，不再手工维护中文表。
- **自定义 spell id**：已解决。`shared/content/spells/spells.yaml` 生成 `BonkSpellIds.h` 和插件的 `VanillaBonkAuraIds.lua`；客户端从服务端接收已本地化的自定义光环行，不再自己维护 id 表。
- 法术/物品名称：自定义 HoA 法术通过服务端下发的光环目录显示。原生法术/物品/生物名称仍来自安装的 DBC 列或服务端查询响应，因此在有 DBC 名称覆盖之前仍跟随安装语言，而不是账号语言。
- **文本**：已解决。文本按 `shared/i18n` 里的稳定消息 ID 索引，所有产物都由目录生成。

**目标**：内容只写在 `shared/content`，文本只写在 `shared/i18n`，各端产物由工具生成；服务端是运行时权威，客户端/插件不再保留业务副本。

## 3. 核心原则

1. **服务端权威**：游戏状态、效果、进度、数值都在服务端；客户端和插件只做呈现。
2. **语言与安装解耦**：账号语言决定文本；客户端数据语言只影响资源解析。
3. **光环优先**：能用原生 aura 表达的，绝不用自定义计时器；不能表达的用 dummy aura + 服务端逻辑，但状态仍通过 aura 存在。
4. **单一来源**：内容、文本、协议各只有一份源文件，生成物不手改。
5. **保留内核**：VMaNGOS 和 benilla 的网络、移动、战斗、渲染、Lua 引擎继续使用；只重构 HoA 层和确认的性能热点。
6. **可验证**：每个阶段都有可运行的构建、无头集成测试和明确的验收标准。

## 4. 分层

```
┌──────────────────────────────────────────────────────────────┐
│  shared/content + shared/i18n + shared/protocol（源文件）      │
└───────────────┬──────────────────────────────┬───────────────┘
                │ tools/content-compiler       │ tools/protocol-gen
                ▼                              ▼
   server SQL / C++ 常量           client 内容包 / Rust 代码
   addon Lua 表 / 文本目录          addon Lua 常量
                │                              │
┌───────────────▼──────────────┐  ┌────────────▼───────────────┐
│ server（VMaNGOS 内核）        │  │ client（benilla 内核）      │
│  Hoa 游戏层                   │  │  HoA UI / 内容覆盖层        │
│  ├ aura 生命周期              │  │  ├ 原生 buff/等级/施法      │
│  ├ 远征/战斗/proc             │  │  ├ 语言包 + 字体            │
│  ├ 内容访问（生成）           │  │  └ 缓存 (locale, content)   │
│  └ i18n 运行时                │  │                             │
└───────────────┬──────────────┘  └────────────┬───────────────┘
                │        原版 opcode + HoA 协议  │
                └──────────────┬───────────────┘
                               ▼
                        addon（表现层）
                        launcher（局域网 / 直连）
```

## 5. 关键流程

### 5.1 登录与协商

1. 启动器读取账号语言和内容版本，启动客户端。
2. 客户端用任意语言的 1.12.1 数据启动；登录挑战只带客户端数据语言（用于资源解析）。
3. 世界登录时服务端下发：账号语言、内容版本哈希、协议版本。
4. 客户端加载对应语言包和内容包；版本不匹配则提示更新或拒绝进入。
5. 服务端按账号语言本地化物品/生物/法术查询响应和所有 HoA 文本。

### 5.2 文本

- 内容文本：服务端本地化后随查询响应下发；客户端不查 DBC 名称做显示。
- 自定义法术/光环：客户端内容包含 ID → 名称/图标/描述，覆盖 DBC 查询。
- 服务端运行时文本：消息 ID + 参数，服务端查表后发送。
- 客户端/插件 UI：本地语言包。

### 5.3 光环

- 效果定义在 `shared/content/auras`。
- 服务端 `Hoa::Auras` 负责应用、刷新、移除、层数、持续时间。
- 客户端通过原生 `SMSG_AURA_UPDATE` 收到，buff 栏直接显示；插件用 `UnitBuff` 读取。
- 服务端逻辑读 `Unit::HasAura/GetAuraCount`，不再维护平行的 bool/计时器。

### 5.4 内容发布

- 内容源变更 → 编译器生成 SQL/客户端包/插件表/文本目录 → 版本哈希变化。
- 服务端启动时校验生成物哈希与 DB 一致。
- 客户端/主机握手校验版本，避免旧内容客户端联机。

### 5.5 联机

- 不设公网大厅/注册服务器。
- 主机启动本地服务端后，可以通过局域网广播被同网段发现，或把 `ip/domain:port` 直接给队友。
- 客户端直连主机；握手时校验协议版本、内容哈希和语言能力。
- 公网穿透、动态域名、端口转发由玩家自己解决（或使用现成的 ZeroTier/Tailscale 等），项目不维护通知服务。

## 6. 组件职责

| 组件 | 保留 | 重构 |
| --- | --- | --- |
| server | VMaNGOS 网络、移动、战斗、地图、DB 层 | HoA 游戏层、效果状态、文本、内容访问 |
| client | benilla 渲染、输入、网络、Lua/FrameXML、原版 UI | 语言包、内容覆盖层、自定义法术、缓存键、HoA UI 接入 |
| addon | 窗口布局、卡牌/奖励/图鉴界面 | 去掉状态计时器、数据副本、硬编码文本 |
| launcher | 安装、启动、服务器管理 | 语言选择、任意语言客户端校验、缓存失效、局域网/直连联机 |
| tools | 现有翻译工具的思路 | 内容编译器、协议生成器、CI 校验 |

## 7. 非目标（本阶段）

- 不重写 VMaNGOS 或 benilla 的底层。
- 不追求与上游继续合并；上游只作为内容和 bug 修复的参考。
- 不改变 1.12.1 协议本身；只在原版协议之上定义 HoA 消息。
- 不承诺一次完成全部迁移；按阶段交付，每一阶段都可运行。

## 8. 风险与取舍

| 风险 | 取舍 |
| --- | --- |
| 光环数量增加导致网络/性能压力 | 合并刷新、限制高频 proc、用 aura 事件而非轮询；基准测试门槛 |
| 自定义法术不在 DBC，客户端显示空白 | 客户端内容覆盖层先落地，再迁移效果 |
| 内容编译器改动面大 | 先做“导出→生成→比对”的等价迁移，再切换运行时 |
| 硬分叉后失去上游修复 | 定期人工挑选上游修复；不自动 merge |
| 多语言文本量增长 | 稳定 ID + CI 完整性检查 + 翻译工具增量流程 |

## 9. 阶段

见 [迁移计划](../migration-plan/README_zh.md)。
