# addon / 插件

导入自主仓库 `Interface/AddOns/HordesOfAzeroth`（`3ca658b`，2026-11-04）；许可证 GPL-3.0。当前源码在 `addon/HordesOfAzeroth/`。

## 重构后的职责

插件只做**表现层**：

- 读取客户端原生接口（`UnitBuff`、`UnitLevel`、`GetTime`、战斗事件）来显示 HoA 界面。
- 不再维护 buff/效果的计时器、层数、状态机；这些全部在服务端光环里（见 [光环与效果](../../auras/README_zh.md)）。
- 不再自己计算物品等级、装备属性等服务器已经算好的数据；这些由内容包或协议下发。
- 语言文本全部从 `shared/i18n` 生成的 Lua 表读取，语言由服务端/客户端设置决定，不读取客户端安装语言。`VanillaBonkLocaleData.lua` 由 `shared/i18n/addon/addon.yaml` 生成，一个文件承载全部语言。

## 模块系统

每个功能是一个具名模块：同一个名字调用 `UI.Module("bags")` 会返回同一张表。
`Module:Listen(handlers, frame)` 拥有一个事件帧（也可复用已有帧），
`Module:OnEnterWorld`、`:OnLeaveWorld`、`:OnRunStart`、`:OnRunEnd` 注册生命周期钩子。
`VanillaBonkUI.lua` 里只有一个分发帧监听 `PLAYER_ENTERING_WORLD`、`PLAYER_LEAVING_WORLD`
和类型化的 `HOA_RUN_START`/`HOA_RUN_END`，按加载顺序调用钩子，并把跑团开始/结束字段传进去。
`UI.modules` / `UI.moduleOrder` 可用于诊断，`UI.RunLifecycle(field, ...)` 可手动分发。
`VanillaBonk.lua` 的核心跑团状态仍直接处理这两个跑团消息。

## UI 对象

`UI.Class(parent)` / `UI.New` / `UI.Mixin` 是纯 Lua 表的类（frame 是 userdata，仍用工厂函数创建）。
`UI.PanelObject(name, frames)` 包住一个或多个 frame，注册进 `UI.panels`，提供
`Show/Hide/Toggle/IsShown/Refresh`，可挂 `OnShow`/`OnHide`/`OnRefresh`；`UI.RefreshPanels()`
统一刷新。`UI.List(parent, opts)` 管理具名 `UI.Row` 对象，行提供 `SetValue`、`SetLabel`、
`Show`、`Hide`，由 `Layout` 统一计算位置。Tracker 是第一个面板/列表试点。

`VanillaBonk.lua` 已按领域拆分：`VanillaBonkOffer.lua`（稀有度、放逐、关键词、报价卡、结算）、
`VanillaBonkStarters.lua`（跑团大师的初始选择）、`VanillaBonkShop.lua`（商店、天赋树、预设）、
`VanillaBonkGearStats.lua`（装备、属性面板、提示）和 `VanillaBonkChatFilter.lua`。共享跑团表是
`VanillaBonkRun`，拆分文件从它读取状态和辅助函数。

## 计划目录

```
addon/
  HordesOfAzeroth/
    core/            核心状态、UI 工具箱、语言、选项文本、聊天过滤
    run/             跑团机制及其面板（报价、商店、装备、HeroBar 等）
    panels/          菜单、图鉴、地图、任务、设置、手柄、联机等
    Fonts/           语言字体回退（Noto Sans SC / Noto Sans TC）
    VanillaBonkAuraIds.lua       生成的内容 ID（根目录）
    VanillaBonkLocaleData.lua    生成的语言数据（根目录）
    HordesOfAzeroth.toc
```

## 保留

现有插件里的可用部分（窗口布局、卡牌/奖励界面、提示、绑定、GlueXML 语言机制）继续保留，逐步迁移到新数据源。
