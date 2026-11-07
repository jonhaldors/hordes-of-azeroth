# 客户端原生能力

原则：**客户端已经有的状态和事件，就用客户端的；只有原版完全没有的东西才新增 HoA 消息。**

这样做的收益：原生 buff 栏、单位框架、施法条、战斗日志、其他插件都能直接工作；HoA 插件变薄；状态不会出现两份。

## 对应关系

| HoA 概念 | 原生能力 | 备注 |
| --- | --- | --- |
| 角色/远征等级 | `PLAYER_LEVEL`、`UnitLevel`、`PLAYER_LEVEL_UP`、`UNIT_LEVEL` | 服务端已经用 `m_player->GetLevel()` 表示远征等级；插件不要另存一份 |
| Buff / Debuff | 服务端 aura → `SMSG_AURA_UPDATE`；插件 `UnitBuff`/`UnitDebuff`/`UNIT_AURA` | 见 [光环与效果](../auras/README_zh.md) |
| 层数 | aura stack | `GetPlayerBuffApplications` 或 aura 的 stack 字段 |
| 生命/法力 | 原生 unit 字段；`UNIT_HEALTH`、`UNIT_MANA`、`UNIT_MAXHEALTH` | 现有插件已在用一部分 |
| 战斗状态 | `UnitAffectingCombat`、`PLAYER_REGEN_ENABLED/DISABLED`、`UNIT_COMBAT` | 不要用服务端布尔值同步 |
| 施法/引导 | `UnitCastingInfo`、`UnitChannelInfo`、`UNIT_SPELLCAST_*` | 施法条、打断提示直接用 |
| 冷却 | `GetSpellCooldown`、`SPELL_UPDATE_COOLDOWN` | 卡牌/技能的冷却由服务端 spell 驱动 |
| 装备 | `GetInventoryItemLink`、`UNIT_INVENTORY_CHANGED`、`GetContainerItemLink` | 物品名称由服务端本地化查询提供 |
| 目标/队伍 | 原生 target/party API | HoA 队伍界面读原生成员 |
| 死亡/复活 | `UnitIsDeadOrGhost`、`PLAYER_DEAD`、`PLAYER_ALIVE` | 不要用自定义消息 |
| 金币/经验 | `GetMoney`、`GetXP` | 原生 |
| 移动速度 | 服务端 aura（移速类） | 客户端不自己算 |

## 只保留 HoA 消息的部分

原版没有、HoA 才有的数据：

- 远征阶段/波次/难度、Boss 进度；
- 卡牌选择、奖励、图鉴、排行榜；
- 商店/军需官的自定义库存；
- 需要服务端计算且原版单位字段放不下的数值（例如护盾剩余量、特殊的层数上限）。

这些走类型化协议 + 客户端 Lua API（见 [协议](../protocol/README_zh.md)），不再走 `BONK~` 字符串。

## 客户端 Lua API 审计

benilla 的 Lua/FrameXML 覆盖不完整，迁移前要先盘点并补齐标准 API，至少包括：

- `UnitBuff`/`UnitDebuff`/`GetPlayerBuff`/`GetPlayerBuffApplications`/`GetPlayerBuffTimeLeft`
- `UnitCastingInfo`/`UnitChannelInfo`、`UNIT_SPELLCAST_*` 事件
- `GetSpellCooldown`/`SPELL_UPDATE_COOLDOWN`
- `UnitLevel`/`PLAYER_LEVEL_UP`
- `UnitAffectingCombat`/`PLAYER_REGEN_*`
- 队伍成员与目标相关 API

`C_UnitAuras` 现在服务敌方姓名板、Boss debuff、关键词层数和玩家光环；剩余缺口是上面列出的原版法术/冷却和队伍 API。

## 插件迁移

阶段 5 已完成：

- `BONK~state` 解析和本地状态计时器已删除；服务端状态走类型化 `HOA_*` 事件，效果本身走原生光环。

剩余：

- 每帧 `OnUpdate` 里重建冷却/倒计时；
- 自己算的物品等级/属性/装备提示（改读服务端数据）。

保留：

- 窗口布局、卡牌/奖励/图鉴的视觉呈现；
- 从原生 API 读数据后的自定义样式显示。
