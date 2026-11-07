# 国际化（i18n）

## 1. 目标

- 语言由**账号/会话**决定，不由客户端安装数据的语言决定。
- 服务端、客户端、插件、启动器的所有用户可见文本都能本地化。
- 翻译以稳定 ID 为键；英文改动不会让旧翻译失效。
- 缺翻译时有明确回退和 CI 报警，不出现“这里怎么还是英文”的黑盒。

非目标：不在本阶段支持从右到左语言、配音本地化、实时机器翻译。

首发语言：**enUS、zhCN、zhTW**。zhTW 优先使用官方 1.12.1 繁中名称；没有的条目由 zhCN 转换后人工校对，注意字形和用词差异（如「法術」「拾取」「設定」），字体使用 Noto Sans TC。

## 2. 语言从哪里来

```
启动器/游戏内设置 → 账号语言（服务端 bonk_account.locale 一类字段）
                    ↓ 世界登录握手
              客户端加载对应语言包
                    ↓
      服务端按语言返回物品/生物/法术查询结果和 HoA 文本
```

- 客户端安装的 1.12.1 数据语言（`Data/*.MPQ`、DBC）只用于解析模型、贴图、音频和基础数据。
- 客户端自己的界面文本不再读 DBC/FrameXML 里的英文字符串，而是读语言包。
- 插件不再用 `GetLocale()` 决定文本；它读服务端下发的语言或客户端设置。
- 语言切换：更新账号设置 → 服务端刷新可见名字（现有 `RefreshCreatureNames` 思路扩展到物品/法术）→ 客户端重载界面并清掉旧语言缓存。不需要重启整个游戏。

## 3. 文本分类

| 类别 | 例子 | 源 | 运行时 |
| --- | --- | --- | --- |
| 内容名称/描述 | 物品、法术、光环、生物、地图、天赋、卡牌 | `shared/content` 条目 + `*_id` | 服务端本地化查询；客户端内容包覆盖 |
| 服务端运行时文本 | 阶段解锁、奖励、战斗提示、错误 | `shared/i18n/messages` | 消息 ID + 参数，服务端查表 |
| 客户端界面 | 选项、菜单、错误、Glue、角色选择 | `shared/i18n/ui` | 客户端语言包 |
| 插件界面 | 窗口标题、按钮、提示 | `shared/i18n/addon` | 生成的 Lua 语言表 |
| 启动器/联机 | 安装、启动、直连/局域网房间 | `shared/i18n/launcher` | .NET 资源 |

## 4. 消息目录

源文件按领域拆分，例如 `shared/i18n/messages/run.yaml`：

```yaml
- id: hoa.run.stage_unlocked
  enUS: "Stage {stage} unlocked."
  zhCN: "第{stage}阶段已解锁。"
  zhTW: "第{stage}階段已解鎖。"
  placeholders:
    stage: number

- id: hoa.run.gear_found
  enUS: "You found {item}."
  zhCN: "你获得了{item}。"
  zhTW: "你獲得了{item}。"
  placeholders:
    item: text
```

规则：

- `id` 用小写点分命名，按功能分组；一旦发布不再改名（改语义就新建 ID 并废弃旧 ID）。
- 英文是源语言，但**不是键**；以英文句子为键会让英文修改导致翻译失效（当前 `source_hash` 机制的问题）。
- `placeholders` 声明类型；编译期检查各语言占位符集合一致，运行时按类型格式化。
- 复数：`id.one` / `id.other`（或 `_one` / `_other`），格式化器按语言规则选；中文通常只用 `other`。
- 长文本允许换行；CJK 换行由客户端排版层处理，不在文本里插硬换行。
- 颜色/链接等富文本用显式标记（如 `{c:ffd100}...{/c}`）或单独的样式字段，不把颜色码写进译文。

## 5. 生成物

```
shared/i18n/
  messages/            源（按领域 YAML/JSON）
  ui/                  客户端界面源
  addon/               插件文本源
  launcher/            启动器文本源
  generated/
    messages.json      所有消息 + 各语言 + 占位符元数据
    messages.hash      版本哈希
```

编译器再生成：

- `server/src/game/Hoa/i18n/generated/Messages.h/.cpp`：ID 枚举 + 英文源 + 查表
- `client/assets/i18n/<locale>.json`：客户端语言包
- `addon/HordesOfAzeroth/VanillaBonkLocaleData.lua`：生成的插件数据文件，一个文件包含全部语言（TOC 固定文件名）
- `tools/translate` 直接读写 `shared/i18n` 源，不再维护独立 JSON

## 6. 服务端

- 运行时 API：`Hoa::I18n::Get(locale, id, args...)`。
- 数据库里的长文本（地图描述、天赋说明）仍可按 `*_locale` 表存放，但行键是内容 ID，不是英文句子；生成器负责同步。
- 物品/生物/法术名称：优先 `locales_item`/`locales_creature` 等现有机制；自定义法术/光环的名称来自内容表。
- 语言变更时刷新已缓存的名字：
  - 生物：现有可见生物重发 `SMSG_CREATURE_QUERY_RESPONSE`。
  - 物品：重发玩家拥有的物品 + 当前可获得的装备/物品模板（或由客户端按内容版本重新查询）。
  - 自定义法术：随内容包更新，不依赖客户端 DBC。

## 7. 客户端

- **语言包**：客户端启动时根据启动器/上次语言加载 `client/crates/benilla-app/assets/i18n/<locale>.json`；登录后用账号语言覆盖。enUS、zhCN、zhTW 都编译进客户端。
- **GlobalStrings**：原生界面仍读安装 MPQ 里的 `GlobalStrings.lua`。如果存在 `benilla-config/locale/<语言>/GlobalStrings.lua`，`Chain` 会优先返回它，因此原生 FrameXML 跟随账号语言，而不用替换安装文件。
- **DBC 名称**：法术书、地图、天赋、职业/种族等显示名称读 DBC 列。如果存在 `benilla-config/locale/<语言>/DBFilesClient/*.dbc`，链会读这些文件并选择对应语言列；否则继续用安装数据的列。用 `tools/install-locale-pack.ps1 -Client <官方客户端> -Language zhCN -Config <benilla-config>` 通过 `benilla-extract locale-pack` 填充该目录（GlobalStrings 加所有未被补丁删除的 `DBFilesClient` 表）；需要一份该语言的 1.12.1 客户端，例如简中版。zhTW 暂无原生资源包，回落到安装语言。
- **`GetLocale`**：已用独立的 UI locale 实现：登录前返回启动器/上次语言，登录后返回账号语言；插件调用 `GetLocale()` 得到的是游戏语言，不是安装语言。安装 `Wow.ini` 的 locale 仍用于解析 DBC 列、资源和名字字符集。
- **界面文本**：`OptionsFrame.xml`、`GameMenuAdapters.xml`、`ScriptLogFrame.xml`、`AccountLoginRealmlist.xml`、`KeyBindingsPage.xml` 和 GlueXML 已改为读取语言包生成的 `HOA_UI_*` 键；Lua/FrameXML 读同一张表。
- **DBC 名称**：法术书、地图、天赋、职业/种族等显示名称目前仍来自安装数据的本地化列；内容包名称覆盖留到后续。
- **字体**：按所选界面语言选字体回退链（zhCN：Noto Sans SC；zhTW：Noto Sans TC；enUS：原版字体），缺字回退顺序固定。
- **排版**：CJK 无空格换行、禁则处理、按钮/标签最小宽度；长文本自动缩放或换行。排版引擎从 `UiLanguage::shaping_locale()` 取得 `zh-CN`/`zh-TW`/`en-US`。

**进度（2026-11-06）**：`shared/i18n/ui` + `tools/i18n/gen_client_pack.py` 已生成 enUS/zhCN/zhTW 语言包；`HOA_UI_*` 覆盖 HoA 的 Options、GameMenu、ScriptLog、Realmlist、KeyBindings 和 GlueXML，`GetLocale` 已跟账号语言。zhTW 已有自己的字体和 shaping locale。客户端还会从 `benilla-config/locale/<语言>/` 读取原生 GlobalStrings 和 DBC；`tools/install-locale-pack.ps1` 可从官方 1.12.1 客户端生成该资源包，zhCN 包已用官方简中客户端验证。

- **缓存**：WDB/模板缓存文件名或头部加入 `(locale, contentVersion)`；语言或内容变化时旧缓存自动失效。第一块已落在 `client/crates/benilla-app/src/wdb.rs`：WDB 头部（格式 2）把 HOA 账号语言折进 locale tag，另一种语言写的缓存会被丢弃。
- **自定义法术**：客户端没有 spell 查询通道（`benilla-app/src/net.rs:1034-1058`），`Spell.dbc` 里没有的 ID 会显示空白（`ui_spellbook.rs:351-355`、`ui_aura.rs:256-260`）。自定义光环行由服务端在 addon ready 和切语言时下发（`aura_catalog_entry`/`aura_catalog_end`）；Rust 侧只保存已本地化的名称/图标/描述，不再自行选择语言。
- **Glue 职业名**：Glue 代码不能硬编码本地化职业名。优先用服务端下发的职业 ID 映射；拿不到时通过 `GetClassesForRace`/`GetSelectedClass` 在运行时学习客户端当前语言的职业名。旧的硬编码中文表已删除。
- **GlueXML**：登录/选人/建号界面使用同一语言包；语言选择可放在 Glue 或启动器。

## 8. 插件

- 所有语言都放在一个生成的 `VanillaBonkLocaleData.lua` 中，按稳定消息 ID 索引；不再按语言拆 Lua 文件。
- 插件通过 `VanillaBonkLocale.RegisterLanguages` 注册数据。`L()` 调用点仍传英文查找文本，生成器额外输出英文→ID 映射，迁移期间保持兼容。
- 删除 `VanillaBonkLocale.English` 反向查找（它现在用于跨语言匹配 NPC 名字）；NPC 窗口改为按 NPC entry/ID 匹配，不按名字。
- 选项文本（`VanillaBonkOptionsText.lua`）改为语言包驱动，不再在 Lua 里维护英文→中文映射。
- 文本参数统一用 `L(id, args)`；禁止在 Lua 里拼接可变语序的句子。

## 9. 翻译流程

1. 开发改英文源（只改 `shared/i18n`）。
2. `tools/translate` 列出缺失、变更、未使用、占位符错误。
3. 译者填目标语言；工具检查长度、格式、术语表。
4. CI 生成各端产物并检查 diff；缺翻译在开发分支警告，发布分支阻断。
5. 术语表放在 `shared/i18n/glossary.yaml`，按内容 ID 关联，不按英文句子。

## 10. 从现状迁移

| 现状 | 迁移 |
| --- | --- |
| 服务端 `BonkLocale`：英文句子 + `source_hash` | 抽出 900+ 条消息，分配稳定 ID，生成枚举；旧翻译按英文匹配导入 |
| `bonk_*_locale` 表 | 行键改为内容 ID；生成器维护 |
| 插件 `VanillaBonkLocaleData.lua`（约 1000+ 条） | 由目录生成；一个数据文件承载所有语言 |
| `VanillaBonkOptionsText.lua` 的客户端选项补丁 | 改为客户端语言包原生支持；过渡期保留补丁 |
| GlueXML `BonkGlueLocaleZhCN.lua` | 并入 `shared/i18n/ui` 的 Glue 部分 |
| 客户端 `OptionsFrame.xml` 等硬编码英文 | 改为语言包键；随客户端 PR 落地 |
| 客户端 DBC 名称 | 内容包覆盖；语言不再由安装决定 |
| 缓存不随语言失效 | 缓存键加入 `(locale, contentVersion)` |
