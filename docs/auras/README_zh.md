# 光环与效果

## 1. 问题

HoA 的效果目前有三种表示，互相之间没有唯一权威：

1. **真正的服务端光环，但只做了一半**：移速/最大生命用 spell 17498/19255（`BonkRun.cpp:11365-11376`）；坏死有 aura 18951（`BonkRun.cpp:4411`），但治疗削减实际读 `m_necroticStacks`（`BonkRun.cpp:4439`）；护盾视觉 16051、Deterrence 33467、复活护盾 33468 是 aura；武器 buff 施放后又在 `m_buffs` 存了一份到期时间（`BonkRun.cpp:8071-8072,7913-7922`）。
2. **插件自维护状态**：护盾量 `m_spellShield`（`BonkRun.h:2263`）通过 `shield~` 发插件（`BonkRun.cpp:4767`）；冲刺 `m_dashSpent/m_dashRechargeMs`（`BonkPlayer.h:544-545`、`BonkPlayerDash.cpp:194-221`）；决心 `m_determination`（`BonkPlayer.h:514`，写库 `BonkPlayer.cpp:2322-2335`）；Boss 伤口 `m_bossWoundStacks`（`BonkRun.h:1796`、`BonkRun.cpp:4629`）。这些由 BONK 聊天行同步，插件自己计时/绘制；原生 buff 栏看不到，重载界面或重连可能丢失。
3. **直接复用原生法术**：剑刃乱舞、狂怒等，但插件又维护一份计时副本。

暗月卡牌的触发型属性加成横跨三类。以 Zandalarian Hero Charm 为例，“每 30 秒获得 25% 力量，持续 10 秒”（`server/core/sql/migrations/20261027710000_world.sql:46-47`）：服务端用 `m_cardSurgeUntilMs` + 冷却记录（`BonkRunCards.cpp:486-493`），`GetCardPower` 把加成折进伤害和属性（`BonkRunCards.cpp:156-170`、`BonkRun.cpp:4867,6284`），没有 Unit aura；界面靠每秒 `cardnow~` 文本（`BonkRunCards.cpp:507-533,586-596`）和一次 `Notify`（`:491`），插件再在 tooltip 里拼出来（`VanillaBonkCards.lua:84-86,205,313-328`）。

插件过去只解析 `BONK~` 聊天行，没有用 `UNIT_AURA`/`GetPlayerBuff`；现在它消费类型化 `HOA_*` 事件，并通过 `C_UnitAuras` 读取姓名板和 Boss debuff。仍有若干每帧 `OnUpdate`（`VanillaBonkDebuffs.lua`、`VanillaBonkCards.lua`、`VanillaBonkPlates.lua`、`VanillaBonkDash.lua`）。

**进度（2026-11-05）：** 阶段 3 已把效果集迁到真实光环，阶段 4 统一了法术与内容源，阶段 5 把剩余状态/展示聊天行换成了类型化协议。上面的“三种表示”是重构前基线，保留作背景；后续工作是阶段 6（每帧轮询、重复计时器、光环刷新频率）。

结果：玩家看到的、插件显示的、服务端实际生效的可能是三份状态；其他插件/战斗日志无法通过标准 API 识别 HoA 效果。

## 2. 原则

1. **一个效果 = 一个光环（spell/aura）。** 服务端应用，客户端原生系统显示。
2. **服务端是唯一状态源。** 效果的持续时间、层数、剩余量都由服务端光环或与光环生命周期绑定的状态决定；插件不独立计时。
3. **优先使用原生 aura 类型。** 属性、攻强、伤害百分比、移速、回复、触发等能用原版 `SPELL_AURA_*` 表达的就用原版；表达不了的用 `SPELL_AURA_DUMMY` + 服务端逻辑，但状态仍挂在光环上。
4. **插件只读。** 插件用 `UnitBuff`/`UnitDebuff`/`UNIT_AURA` 读取并绘制，不再解析状态聊天行、不再自己倒计时。
5. **客户端能显示自定义法术。** 自定义 spell ID 不在安装的 `Spell.dbc` 里，客户端必须从内容包取名称、图标、描述、层数显示规则。

## 3. 效果分类

| 类别 | 表示 | 例子 |
| --- | --- | --- |
| 原生 WoW 法术/光环 | 使用原 spell ID，服务端刷新/移除 | 剑刃乱舞、狂怒、盾墙、嗜血 |
| HoA 自定义 Buff | 自定义 spell，原版 aura 效果 | 暗月卡牌的力量 proc、护盾、增伤、移速 |
| HoA 自定义 Debuff | 自定义 spell，原版 debuff 效果 | 坏死、wounds、Boss 施加的减益 |
| 资源/层数型状态 | 自定义 spell + aura stack | 决心层数、冲刺次数、连击/充能 |
| 只有数值、无法放进 aura 字段的状态 | 自定义 spell + 服务端 `AuraState`，随光环生命周期维护 | 护盾剩余量、吸收池 |
| 非战斗/长期状态 | 服务端状态 + 必要时用永久 aura 可视化 | 图鉴解锁、赛季标记 |

## 4. 数据模型（草案）

`shared/content/auras/*.yaml`：

```yaml
id: hoa.aura.darkmoon.ogre_slayer
kind: aura
name_id: hoa.text.aura.ogre_slayer.name
description_id: hoa.text.aura.ogre_slayer.desc
icon: Interface/Icons/INV_Misc_Ticket_Darkmoon_01
duration_ms: 30000
max_stacks: 1
stack_rule: refresh          # refresh | stack | independent
visible: true
server:
  proc: on_melee_hit
  ppm: 1.0
  internal_cooldown_ms: 0
spell:
  school: physical
  effects:
    - type: mod_stat
      stat: strength
      amount: 30
```

实现使用 `shared/content/spells/spells.yaml` 的精简 schema。每个光环声明 `source: card:<id> | mastery:<id> | weapon:<id> | glyph:<id> | keyword:<id> | behavior:<enum> | none`；有来源的光环继承来源行的名称、图标和描述，`display` 覆盖必须写 `reason`。`stacks`、`permanent`、`dynamic` 分别描述实时层数、计时和数值文本。编译器校验所有绑定并生成 `hoa_aura`/`hoa_aura_locale`；服务端在 addon ready 和切语言时通过类型化协议下发本地化行，客户端只存字符串，不读语言。

编译后：

- 服务端：生成 `spell_template` 行（或自定义 spell 注册表）+ 效果 ID 常量 + proc 绑定。
- 客户端内容包：spell ID → 名称/图标/描述/是否 debuff/层数显示。
- 插件：只拿到展示需要的 ID，不再拿数值。

## 5. 服务端

### 5.1 生命周期

```
内容定义 → Hoa::Auras::Apply(target, auraId, caster, duration, stacks)
        → Unit::AddAura(spellId)
        → 客户端 SMSG_AURA_UPDATE → 原生 buff 栏
        → 服务端逻辑通过 HasAura/GetAuraCount 读取
        → 到期/驱散/移除 → AuraState 清理
```

- 所有效果通过 `Hoa::Auras` 门面应用，禁止业务代码直接拼 spell id。
- `AuraState`（护盾量等）与光环同生命周期：aura add 时创建，remove 时销毁；服务端读状态只读这一份。
- 刷新规则（刷新时间/叠加/独立）由数据定义，不在业务代码里手写。

### 5.2 与现有代码的关系

- 现有的 `BONK_SPELL_*` 常量保留并迁入内容表；
- 插件维护的冲刺/决心/护盾状态改为：
  - 能直接映射为 aura 层数的 → aura stack；
  - 护盾剩余量等数值 → aura + `AuraState`，服务端在变化时发送一条轻量更新（不是每帧）；
- 剑刃乱舞/狂怒等原生法术：移除插件副本，统一读原生 aura。

### 5.3 性能

- 服务端按 tick 合并 aura 更新；proc 增加内部冷却/PPM 限制，避免高频刷新。
- 不为每个效果单独开定时器；用 aura 的到期机制。
- 大护盾/吸收量变化时按阈值或低频同步给插件，避免每帧发包。

## 6. 客户端

- **原生 buff 栏**：`SMSG_AURA_UPDATE` 到达即显示；自定义 spell 的名称/图标来自内容包覆盖层。现状是客户端在 `Spell.dbc` 缺 ID 时光环名/图标为 None（`ui_aura.rs:256-260`），法术书直接丢弃（`ui_spellbook.rs:351-355`）；内容包覆盖层必须先做，否则自定义 aura 在 buff 栏是空白。
- **法术书/提示**：客户端查 `Spell.dbc` 失败时查内容包；描述用内容包文本（按语言）。
- **插件**：用 `UnitBuff("player", i)`、`GetPlayerBuff`、`UNIT_AURA` 事件读取；显示层可以自定义样式，但数据来源必须是原生 aura。
- **重载/重连**：状态由服务端重发，插件不需要恢复自己的计时器。

## 7. 示例

### 7.1 暗月卡牌：30 秒循环的爆发加成

以 Zandalarian Hero Charm 为例：每 30 秒获得 25% 力量，持续 10 秒（`20261027710000_world.sql:46-47`）。

- 内容定义：`hoa.aura.darkmoon.zandalarian_surge`，`duration 10s`，`hoa_power_percent 25`，`internal_cooldown 30s`。
- 服务端：战斗/计时钩子触发 → `Apply` → 真实 aura 生效；伤害计算由 VMaNGOS 的 aura 系统完成。删除 `m_cardSurgeUntilMs`、`GetCardPower` 里的手工加成和每秒 `cardnow~`。
- 客户端：buff 栏出现图标和剩余时间；提示文本来自内容包。
- 首个实现：spell `60004` 是真正的正面光环；服务端按卡牌设置持续时间。源文件是 `shared/content/spells/spells.yaml`；`tools/content/compile.py` 生成 `spell_template` SQL、`hoa_aura`/`hoa_aura_locale` SQL 和服务端 ID。服务端在 addon ready 时下发本地化光环目录（`aura_catalog_entry`/`aura_catalog_end`），客户端通过 `SpellCatalog::set_overlay` 安装，所以即使安装的 `Spell.dbc` 没有这一行，原生 buff 栏和 tooltip 也能显示。`60001`-`60099` 留给 HoA。
- 插件：不再自己计时/拼 tooltip；最多在自定义 UI 中读取该 aura 的剩余时间。

### 7.2 暗月卡牌 buff

暗月卡片：蓝龙（`60006`）、迅捷药水（`60007`）、联盟徽记（`60008`）、倒刺项圈（`60010`）、嗜血胸针（`60021`）、优越护符（`60022`）也都是真实光环：服务端按卡牌持续时间施加，客户端 buff 栏和提示通过服务端下发的目录显示。卡牌窗口仍由插件绘制（卡牌是自定义对象，无法避免），但效果本身不再由插件计时。条件恢复类卡牌只在条件满足时保留光环：厚符文布绷带（`60053`）在未受击时存在，基础营火（`60054`）在原地站立时存在。

### 7.3 职业 buff

猛虎之怒（`60012`）、奥术强化（`60013`）、暗影之舞（`60014`）、毒伤（`60015`）、黑暗契约（`60016`）、灵魂收割（`60017`）、Glyph 血性狂暴（`60018`）、冰封（`60019`）、游牧惩罚（`60020`）、嗜血胸针（`60021`）、优越护符（`60022`）是从内部计时器改成真实光环的效果。剑刃乱舞（`33466`）、狂怒（`33462`）、圣盾（`33463`）和毁灭之风则改为直接读取已有的光环，不再维护平行计时器。服务端施加 dummy aura 并设置持续时间，行为逻辑读 `HasAura`，客户端通过服务端下发的目录显示。其余限时职业效果见 7.6。

### 7.4 HoA 护盾/冲刺/决心

- 护盾：自定义 aura `60005`。实时吸收量通过 `hoa.aura_value` 下发；客户端会改写提示文本（“吸收 N 点伤害。”），插件继续画护盾条。buff 栏只有图标、没有倒计时，因为护盾是吸收池而不是限时 buff。
- 冲刺：是技能，不是 buff。充能和恢复留在 `BonkPlayer` 内部；`hoa.dash` 把可用层数和剩余恢复时间发给 UI，消耗或恢复充能时原生 buff 栏不会变化。
- 决心：自定义 aura `60001`，永久，层数镜像账号值；插件从光环读层数，服务端保留账号行作为持久来源。
- 伤口：自定义 aura `60003`，层数和持续时间都在光环上；插件读层数，只从提示消息里取服务端算好的治疗削减百分比。
- 坏死：spell `60056` 的层数就是状态；服务端读它，插件通过 `UI.AuraStacks` 读。
- 武器 buff：服务端读生效中的光环，删除了 `m_buffs` 到期表。

### 7.5 原生法术

- 剑刃乱舞/狂怒：使用原 spell ID，服务端只负责刷新/移除；插件删除自己的计时器，读 `UnitBuff`。
- 若原生法术的数值需要 HoA 化，修改服务端 spell 数据，不另起一套。

### 7.6 天赋 proc

急速射击（`60023`）、切割（`60024`）、借来的时间（`60025`）、乱舞（`60026`）、生命绽放（`60027`）是单计时器光环，行为逻辑直接读 `HasAura`。鲜血涌动（`60028`）、强风（`60029`）、死亡之舞（`60030`）、复仇之怒（`60031`）、狂热（`60032`）、奥术节奏（`60033`）、星辰领主（`60034`）、森林之魂（`60035`）、灵魂收割者（`60036`）、无情风暴（`60037`）、獴之狂怒（`60038`）、壁垒（`60039`）、远古疯狂（`60040`）、血爪（`60041`）保留每层到期时间向量作为账本；`UpdateTalentAuras` 每 400ms 把有效层数和最长剩余时间同步到光环上，只有层数变化或剩余时间差超过 600ms 时才重写。没有到期的条件层数使用永久光环。一次性 proc：节能施法（`60048`）、寒冰指（`60049`）、奥术潜能（`60050`）、神盾（`60051`）、消失（`60052`）在等待消耗期间是永久光环，层数镜像内部计数器。

### 7.7 宠物与敌人效果

狂啸（`60042`）是玩家身上的光环，`IsHowlFrenzied` 直接读它。挫志咆哮（`60043`）、缠绕藤蔓（`60044`）、魅惑（`60045`）、裂隙（`60046`）、破绽（`60047`）是施加在受影响敌人身上的减益，施法者是玩家；伤害钩子读光环而不是平行的计时表。烟雾弹、屏障这类地面区域仍然按区域逻辑处理，不当作单位 buff，因为它们影响的是位置而不是单位。

## 8. 迁移步骤

1. 盘点所有效果（服务端常量、插件状态、原生法术复用），列成表。
2. 为每个效果分配稳定 ID 和内容定义；能映射原生 aura 的优先映射。
3. 服务端实现 `Hoa::Auras` 与 `AuraState`，逐个迁移，保留旧路径开关直至验证通过。
4. 客户端内容包支持自定义 spell 显示；先在开发构建验证图标/名称/层数/持续时间。
5. 插件改为只读原生 aura；删除 BONK 状态消息和自维护计时器。
6. 回归：buff 栏、提示、战斗结果、重载界面、重连、切换语言。

## 9. 测试

- 单元：光环应用/刷新/叠加/到期、`AuraState` 生命周期。
- 集成：固定战斗脚本触发 proc，断言 aura 存在、层数、剩余时间、属性变化。
- 客户端：buff 栏截图对比（enUS/zhCN）、重载/重连后状态一致。
- 性能：高频 proc 下的 aura 包速率和服务器 tick 时间。
