# 内容与数据

## 1. 目标

- 物品、法术、光环、生物、地图、天赋、卡牌、任务、掉落等内容的**唯一定义**在 `shared/content`。
- 服务端、客户端、插件需要的形态由编译器生成，禁止各自维护副本。
- 运行时服务端仍是权威；客户端内容包只是同一份数据的只读投影。
- 改内容 = 改源文件 + 重新生成 + 提交生成物；不直接改数据库。

## 2. 数据放在哪

| 数据 | 位置 | 说明 |
| --- | --- | --- |
| 原版 1.12.1 资源（模型、贴图、音频、基础 DBC） | 用户安装 | 不随仓库分发；语言无关 |
| 原版物品/法术/生物基础数值 | 服务端 DB（从 VMaNGOS 基础库来） | 不重复定义 |
| HoA 新增/修改的内容 | `shared/content` | 唯一来源 |
| HoA 文本 | `shared/i18n` + 内容条目的 `*_id` | 不写在各端代码里 |
| 客户端界面数据（布局、图标路径） | `client/assets` | 展示资源，不是游戏数值 |
| 插件界面布局 | `addon/` | 展示逻辑 |

判断标准：**影响游戏结果的数值和名称在 `shared/content`；纯展示资源留在对应端。**

## 3. 源文件布局

```
shared/content/
  manifest.yaml          内容版本、包列表
  items/
  spells/
  auras/
  creatures/
  zones/
  talents/
  cards/
  gear/
  loot/
  quests/
  i18n/                  内容文本（按 ID，按语言）
  schemas/               JSON Schema（或 Rust 类型）
```

条目示例：

```yaml
id: hoa.item.darkmoon.ogre_slayer
kind: item
entry: 930359                 # 运行时 uint32 ID（由注册表分配）
name_id: hoa.text.item.ogre_slayer.name
description_id: hoa.text.item.ogre_slayer.desc
icon: Interface/Icons/INV_Misc_Ticket_Darkmoon_01
quality: 3
item_level: 60
slot: trinket
stats: { strength: 12, stamina: 8 }
source: { kind: darkmoon_card }
```

```yaml
id: hoa.text.item.ogre_slayer.name
enUS: "Ogre Slayer"
zhCN: "食人魔杀手"
```

## 4. ID 规则

- 稳定字符串 ID：`hoa.<domain>.<group>.<name>`，发布后不改名。
- 运行时 uint32：由注册表分配并写回生成文件；避开原版 ID 段。
  - 自定义物品：>= 900000（沿用现有约定）
  - 自定义法术/光环：单独区段，和现有 `BONK_SPELL_*` 衔接
  - 自定义生物/地图：沿用现有约定
- 字符串 ID 和 uint32 的映射表是生成物，提交到仓库，CI 检查冲突和意外变更。

## 5. 编译器

`tools/content-compiler`：

```
源文件 → schema 校验 → 中间模型 → 生成器
                                  ├─ server/sql/content/*.sql
                                  ├─ server/src/game/Hoa/content/generated/*.h/.cpp
                                  ├─ client/assets/content/<hash>/content.bin
                                  ├─ addon/HordesOfAzeroth/generated/content.lua
                                  └─ shared/i18n/generated/*
```

要求：

- **确定性输出**：固定排序、无时间戳、无随机 ID；同样的源生成同样的字节，CI 才能检查 diff。
- **幂等 SQL**：重复执行结果一致；内容更新用版本号或先删后插。
- **跨端一致**：同一 ID 的名称/图标/数值在各端生成物中一致，编译器做交叉检查。
- **增量**：只重新生成变化的包，输出内容哈希。

## 6. 版本与校验

- `manifest.yaml` 声明内容版本；编译器计算 `content.hash`（源 + 生成物）。
- 服务端启动时校验 DB 中的内容版本与生成物一致；不一致拒绝启动或记录错误。
- 客户端登录握手带内容哈希；不匹配时提示更新，局域网/直连主机拒绝不同版本联机。
- 内容包按哈希分目录，天然支持多版本并存和回滚。

## 7. 从现状迁移

现有内容散在：

- `server/core/sql/` 的 `bonk_*` 表（约 50 张）和大量迁移；
- `item_template` 中 900000+ 的自定义物品；
- `locales_item`、`locales_creature`、`bonk_*_locale` 等文本；
- 插件里的职业/难度/关键词/精通/装备提示表；
- 客户端 DBC 中的原版名称。

迁移步骤：

1. 写 `tools/content-dump`：从当前 DB 导出 `bonk_*`、自定义 `item_template`、`*_locale` 到 `shared/content` 源文件。
2. 写 `tools/content-compiler` 的 SQL 生成器，先生成与现有表**逐行等价**的结果。
3. 在测试库上跑“导出→生成→对比”，差异归零。
4. 切换到生成流程：迁移只保留结构变更，内容不再手写 SQL。
5. 再把插件/客户端里的重复表替换为生成物或协议数据。

## 8. 客户端内容包

> 当前实现：自定义与原生 reskin 光环走服务端下发的目录
> （`aura_catalog_entry`/`aura_catalog_end`），在 addon ready 和切语言时发送。下面的完整内容包
> 仍是物品、生物和法术书的后续目标。

- 格式：紧凑二进制 + 字符串池 + 按 ID 的索引；包含：
  - 自定义物品/法术/光环/生物/地图的名称、图标、描述、品质、类型；
  - 法术的 buff/debuff 标记、层数显示规则；
  - 装备/卡牌等 UI 需要的展示字段。
- 客户端启动时按内容哈希加载；登录握手校验。
- 原版条目默认不覆盖；只覆盖 HoA 新增或显式改写的条目。
- 语言：内容包按语言分别生成或内含多语言字符串池；客户端按账号语言选择。

## 9. 校验

CI 检查：

- schema 校验、ID 唯一、引用完整（`*_id` 指向存在的文本、图标存在或白名单）；
- uint32 映射无冲突、未意外变更；
- 生成物与源一致（重新生成后 diff 为空）；
- 服务端 SQL 可在空库和现有库上重复执行；
- 客户端/插件生成物能被对应运行时加载（冒烟测试）。
