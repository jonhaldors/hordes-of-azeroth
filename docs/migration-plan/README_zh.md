# 迁移计划

分阶段交付，每个阶段结束时仓库可构建、可运行、可回退。

## 阶段 0：设计与骨架（当前）

- 产出：本仓库、架构/i18n/光环/内容/协议文档、组件目录说明、许可证说明。
- 验收：你确认设计方向和目录结构。
- 不做：导入代码、改任何现有实现。

## 阶段 1：导入与基线

- 把以下快照导入 monorepo，保留各自许可证和版权：
  - `server/` ← `hordes-of-azeroth-server`（VMaNGOS，0.6.3 的 `vanilla-bonk`/中文分支）
  - `client/` ← `hordes-of-azeroth-client`（benilla，0.6.3 快照）
  - `addon/` ← `Interface/AddOns/HordesOfAzeroth`
  - `glue/` ← `Interface/GlueXML`
  - `launcher/` ← `tools/launcher`
  - `config/`、`localization/`、`tools/` ← 主仓库对应目录
- 不导入 `tools/lobby-server`：联机只做局域网和 `ip/domain:port` 直连，不维护公网目录/注册服务。
- 版本从 **0.1.0** 开始（`VERSION`）。
- 建立统一构建脚本和 CI：服务端 CMake、客户端 Cargo、启动器 dotnet、插件 Lua 语法检查。
- 验收：一条命令构建全部组件；现有功能可运行；CI 绿。
- 进度（2026-11-04）：代码已导入并提交；`scripts/build.ps1 -Component server` 构建通过，launcher 通过，addon 64 个 Lua 文件语法通过，client 完整 `cargo build -p benilla-app` 通过。
- 风险：仓库体积（只导入 tracked 文件，不含 `target/`、`bin/`、`obj/`、数据库）；许可证混用（按目录保留）。

## 阶段 2：i18n 基础

- 建立 `shared/i18n` 消息目录（稳定 ID、占位符、语言表）。
- 服务端 `Hoa::I18n` 运行时；把现有 `BonkStrings`/`BonkLocale` 的 900+ 条消息迁移为 ID。
- 客户端语言包：界面文本（选项、菜单、Glue）从语言包读取；登录握手带账号语言。
- 插件语言表改为生成物；删除英文键索引和反向查找。
- 缓存键加入 `(locale, contentVersion)`；语言切换刷新物品/生物/法术名字。
- 验收：任意语言 1.12.1 安装 + 中文账号 → 全中文；切换 enUS/zhCN 不重启游戏、不残留旧名字；缺翻译有清单。
- 进度（2026-11-06）：995 条服务端字符串、1558 条插件文本、1328 条客户端界面文本和 304 条启动器文本已抽成稳定 ID（`shared/i18n/messages/server.yaml`、`shared/i18n/addon/addon.yaml`、`ui/options.yaml`、`ui/glue.yaml`、`ui/keybindings.yaml`，enUS、zhCN、zhTW 完整）；`tools/i18n` 的提取/校验/生成工具和 CI `i18n-check` 已加；`BonkStrings.h/.cpp`、`addon/HordesOfAzeroth/VanillaBonkLocaleData.lua`（一个文件承载全部语言）和 `client/crates/benilla-app/assets/i18n/{enUS,zhCN,zhTW}.json` 都由目录生成；HoA UI/GlueXML 使用 `HOA_UI_*` 键，`GetLocale` 跟账号语言，客户端 WDB 头部已把 HOA 账号语言折进缓存 tag（FORMAT 2），zhTW 使用 Noto Sans TC 排版和绘制。下一步：原生 GlobalStrings 和 DBC 名称覆盖。
- 说明：这一步会触碰客户端大量文本，但不动游戏数值。

## 阶段 3：光环统一

- 实现 `Hoa::Auras` 和 `AuraState`；建立效果清单。
- 客户端内容包支持自定义 spell 的名称/图标/描述/层数；先让客户端能显示一个测试 aura。
- 逐类迁移：原生法术副本 → 自定义 buff → 资源/层数状态 → 护盾量等特殊数值。
- 插件改为 `UnitBuff`/`UNIT_AURA` 读取；删除状态计时器和 `BONK~state` 消息。
- 验收：buff 栏能看到所有 HoA 效果；插件/服务端/战斗日志状态一致；重载、重连、换语言后一致。
- 进度（2026-11-04）：武器 buff、坏死、决心（60001）、伤口（60003）、暗月爆发（60004）、护盾（60005）、急速爆发（60006）、迅捷（60007）、免疫（60008）、灵魂石（60009）、荆棘（60010）、猛虎之怒（60012）、奥术强化（60013）、暗影之舞（60014）、毒伤（60015）、黑暗契约（60016）、灵魂收割（60017）、Glyph 血性狂暴（60018）、冰封（60019）、游牧惩罚（60020）、击杀之力（60021）、未受伤之力（60022）；剑刃乱舞、狂怒、圣盾、毁灭之风改为读取已有光环都已挂到真实光环上。冲刺保持为技能：充能和恢复在 `BonkPlayer` 内部，只通过 `hoa.dash` 报告，不产生 buff 图标。自定义 ID 在迁移 `20261104120000_world.sql`，客户端覆盖层负责显示，插件通过 `C_UnitAuras`（`UI.AuraStacks`）读层数。护盾数值在 `AuraState` 落地前仍走服务端计算的消息。武器 buff 改为读取生效中的光环，删除了 `m_buffs` 到期表；坏死层数挂在 spell 60056 上，服务端读 `GetStackAmount`，插件通过 `C_UnitAuras` 读层数，只从提示消息里取服务端算好的治疗削减百分比。其余限时天赋 proc、宠物狂化和敌人减益（60023-60047）也已镜像到真实光环，定义在 `shared/content/spells/spells.yaml`，由 `tools/content/compile.py` 生成。一次性 proc 节能施法、寒冰指、奥术潜能、神盾、消失（60048-60052）同样以光环显示。
- 风险：自定义 spell 的客户端显示、aura 包频率、某些效果无法用原版 aura 类型表达。

## 阶段 4：内容单一来源

- `tools/content-dump` 导出当前 `bonk_*`、自定义物品、文本。
- `tools/content-compiler` 生成等价 SQL；测试库逐行对比。
- 切换为生成流程；插件/客户端重复表替换为生成物或协议数据。
- 验收：同一份源生成三端产物；改内容只改源文件；CI 检查生成物 diff。
- 进度（2026-11-04）：源文件是 `shared/content/cards/cards.yaml`、`shared/content/spells/spells.yaml` 和 `shared/content/tables/` 下的 49 张设计表。`tools/content/compile.py` 生成世界库 SQL、服务端 spell ID 头、`hoa_aura`/`hoa_aura_locale` 行、`content.hash`、`hoa_content.sql` 和 `BonkContentHash.h`，`--check` 在 CI 里守住这些产物。服务端在登录时把本地化光环目录下发给客户端，客户端不再保留生成副本。`tools/content/apply.py` 把 SQL 应用到数据库；生成表与旧数据逐行一致；服务端启动时对比数据库哈希和构建哈希。生成表 `bonk_hidden_creature`、`bonk_hidden_gameobject` 按决定继续留在数据库。
- 风险：内容量大、迁移期间与旧 SQL 冲突；用“导出→生成→对比”保证等价。

## 阶段 5：协议整理

- 定义 HoA 消息 schema，生成 C++/Rust。
- 客户端暴露 Lua API；插件迁移展示类数据。
- 删除 `BONK~` 解析器和字符串拼接。
- 验收：状态全部走原生 aura；展示数据走类型化协议；版本不匹配有明确提示。
- 进度（2026-11-05）：`shared/protocol/messages.yaml` 和 `tools/protocol/gen.py` 生成 C++ 写入端和 Rust 解码端；`SMSG_HOA_MESSAGE`（826）承载 `hoa.hello`、`hoa.aura_value`、`hoa.aura_text`、`hoa.aura_catalog_entry`/`aura_catalog_end`、`hoa.dash` 和 `hoa.aura_percent`。客户端向 Lua 触发对应的 `HOA_*` 事件。护盾、决心、坏死、伤口和冲刺已只走类型化消息；`hoa.run_state`、`hoa.run_start` 和 `hoa.run_end` 取代旧的 `state~`/`start~`/`end~` 行，并用表格参数触发事件。暂停、联机暂停策略、跑团经验、波次提示、支援/雕文/队伍计量、目标图钉、敌人/队友姓名板、offer/雷线/雕文选择面板、任务、商人、回城/无尽传送门、发现装备、装备替换、仓库、附魔师、卡牌面板、玩家状态信号、联机提示、跑团小信号以及祭坛/事件计时、死亡回顾/跑团结算、排行榜流程、商店/精通树、装备属性、饰品提示、竞技场面板、难度/等级/地图选择器以及图鉴行也已类型化。服务端不再发送任何 `BONK~` 行，插件的旧解析器也已删除。握手时协议版本或内容哈希不一致会触发 `HOA_INCOMPATIBLE`，客户端停止应用后续类型化消息，插件弹出明确错误提示，避免在版本不匹配的服务端上继续运行。预警圈、道具、飞行物、飞弹和光环锚点也改走 `hoa.visual_*`，客户端不再解析 `HOA~` 聊天行。

## 阶段 6：性能与内核整理

- 盘点并修复热点：Lua 轮询、光环刷新、网格搜索、每帧扫描、重复计算。
- 建立基准（服务器 tick、登录耗时、内存、客户端帧时间）。
- 清理迁移期开关和死代码。
- 验收：基准不低于现状；无回归；文档更新。
- 进度（2026-11-06）：怪物寻路是 Detour A*（`dtNavMeshQuery::findPath`），由 `PathInfo` 封装；Bonk 人群、出生点和跑团校验都使用它。在 Barrens 沙盒用 150 只怪的包做压测，测得服务器 tick 27–28 ms、HoA run 代码 0.1 ms、人群每步 0.04–0.24 ms、寻路 0.00 ms，说明开阔地 A* 不是热点，tick 主要受地图更新间隔限制。阶段 6 剩余的还有插件每帧循环和客户端侧基准。热启动到角色选择约 2.1 秒，进入世界后 UI 0.45 秒就绪，加载画面 2.0 秒后关闭（从进程启动算约 6 秒）；沙盒空闲时 release 客户端工作集 2.36 GB（私有 4.47 GB），`mangosd` 504 MB，服务端热启动 1 秒。`BonkRun.cpp` 已按生命周期、更新、刷怪、战斗、拾取、关卡和武器拆成多个翻译单元（从 14.8k 行降到约 6.4k 行）；内容编译器新增 `content.manifest.json` 和 `hoa_content_section`，hello v30 携带分段哈希，客户端能指出变化的内容段。上游 0.6.3 hotfix 1 已移植：启动器关停/重启修复、排行榜未上榜原因和服务端代码完整性检查。

- 进度（2026-11-06）：上游 0.6.4 已移植：硬核模式（阵亡/安息记录）、同职业多角色与按角色保存进度、幻化与套装、普通/硬核排行榜、职业平衡，以及启动器断点续传和数据库启动修复。新消息使用协议 31；所有新文案已进入共享目录，包含 enUS、zhCN、zhTW。

## 顺序理由

1. **i18n 先做**：它是用户最直接的痛点，且需要服务端/客户端/插件同时改，适合在 monorepo 刚建立、耦合还清楚时完成。
2. **光环第二**：依赖客户端自定义 spell 显示（内容包），但可以和 i18n 的语言包机制共用基础设施。
3. **内容编译第三**：光环和文本定义可以先手写在源里，等结构稳定后再统一编译；避免一开始就卡在巨大迁移上。
4. **协议最后**：等状态和展示数据都稳定，再定消息，减少反复。

## 回退策略

- 每个阶段用分支/开关隔离；旧路径保留到新路径通过回归测试。
- 内容编译器在“生成结果 == 现有 DB”验证前不切换。
- 客户端缓存带版本，回退时旧缓存自动失效。
