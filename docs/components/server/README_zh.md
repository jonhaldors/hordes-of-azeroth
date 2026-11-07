# server / 服务端

导入自 `hordes-of-azeroth-server` 的 `zhcn-063` 快照（`930628c2c`，2026-11-04）；源码头是 GPL-2.0-or-later，按 GPL-3.0 分发。这是重构起点，不是最终结构。

VMaNGOS 1.12.1 服务端（C++，GPL-3.0 分发），HoA 游戏逻辑在 `src/game/Bonk/`。

**状态：已导入**，按 [架构文档](../../architecture/README_zh.md) 逐步调整目录。

## BonkRun 拆分

`BonkRun` 原来全在一个 14.8k 行的 `BonkRun.cpp` 里，现在按领域拆分，文件级常量和辅助函数放在 `BonkRunInternal.h`：

- `BonkRunLifecycle.cpp`：构造、选关、进入跑团、路线学习。
- `BonkRunUpdate.cpp`：每帧更新、选项、事件和编队。
- `BonkRunSpawn.cpp`：刷怪目标、扇区、路线、怪群落位、出怪和寻路检查。
- `BonkRunCombat.cpp`：伤害上限与减伤、死疽、Boss 压力、护盾、暴击、死亡与复活。
- `BonkRunLoot.cpp`：刷怪、宝箱、光柱、勇气和强化道具。
- `BonkRunStage.cpp`：清关、传送门、下一关和无尽切换。
- `BonkRunWeapons.cpp`：武器攻击、飞弹、射击、关键词云雾、陷阱和投射物。
- `BonkRun.cpp`：波次、缩放、属性、敌人攻击和其余跑团逻辑。

`BonkRunInternal.h` 保存匿名命名空间的常量和辅助函数，并在 `BonkRunShared` 里声明可变文件状态；定义只在 `BonkRun.cpp` 出现一次，所以所有拆分文件共享同一份 `s_spawnKit`、`s_spawnLookLeadMs`、`s_nextHelperLevel` 和 `t_missileLookSource`。

## 计划中的分层

```
server/
  src/
    game/
      Bonk/          现有 HoA 游戏层（跑团、掉落、卡牌、天赋、光环）
      Hoa/           重构后的 HoA 层（建议）
        content/     从 shared/content 生成的数据访问
        auras/       效果注册表与光环生命周期
        i18n/        消息目录运行时
        run/         远征流程
        combat/      战斗钩子、触发器、proc
  sql/
    base/            VMaNGOS 基础库结构
    content/         由共享内容编译器生成（不手改）
    migrations/      仅结构/数据修复
```

## 原则

- 所有 HoA 效果通过真实光环实现，服务端只保留一份效果状态（见 [光环与效果](../../auras/README_zh.md)）。
- 服务端不硬编码英文句子；文本走消息 ID 和语言表（见 [i18n](../../i18n/README_zh.md)）。
- 内容数据由 `tools/content-compiler` 生成；`sql/content/` 是构建产物。
- 保留内核，只对性能热点做必要重构（见 [总体架构](../../architecture/README_zh.md)）。

## 构建

见 [构建说明](../../../BUILDING_zh.md)。CMake 配置 + `mangosd` Release 构建已在本机通过；数据库初始化步骤待补。
