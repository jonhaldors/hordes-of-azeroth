# 导入的代码与来源

本仓库的 0.1.0 不是从零写的，第一版代码是以下几个上游快照，导入时保留各自许可证和版权。之后的改动在新历史里进行，不再自动合并上游。

机器可读的记录在根目录 [`provenance.yaml`](../../provenance.yaml)，每个导入目录下也有 `UPSTREAM.md`。

| 目录 | 开源仓库 | 导入分支/提交 | 许可证 |
| --- | --- | --- | --- |
| `server/` | https://github.com/jonhaldors/hordes-of-azeroth-server | `zhcn-063` / `930628c2c05f44af067a138b93e8726955f3b8a6`（上游 `vanilla-bonk` 基线 `b41bf911790061dc539bc62140b256a69d44edc7`） | GPL-3.0 分发（源码头 GPL-2.0-or-later） |
| `client/` | https://github.com/jonhaldors/hordes-of-azeroth-client | `zhcn-063` / `74a4e4eb8ef5030fcde1657531217d3f3f4b384f`（上游 `main` 基线 `1f23d0eaf02afe8831e9229bff027a93d387f5eb`） | MIT 或 Apache-2.0 |
| `addon/HordesOfAzeroth/` | https://github.com/jonhaldors/hordes-of-azeroth | `zhcn-063` / `3ca658b525bd67bf0302fa30c80829305295f3c5`（`Interface/AddOns/HordesOfAzeroth`） | GPL-3.0 |
| `glue/` | https://github.com/jonhaldors/hordes-of-azeroth | 同上（`Interface/GlueXML`） | GPL-3.0 |
| `launcher/` | https://github.com/jonhaldors/hordes-of-azeroth | 同上（`tools/launcher`） | GPL-3.0 |
| `tools/`（除 launcher） | https://github.com/jonhaldors/hordes-of-azeroth | 同上（`tools/`，排除 `tools/launcher`、`tools/lobby-server`） | GPL-3.0 |
| `config/` | https://github.com/jonhaldors/hordes-of-azeroth | 同上（`config/`） | GPL-3.0 |
| `localization/` | https://github.com/jonhaldors/hordes-of-azeroth | 同上（`localization/`） | GPL-3.0 |

导入日期：2026-11-04。实际代码来自我们自己的 fork：
[`xenoglossy-asyncio/hordes-of-azeroth-server`](https://github.com/xenoglossy-asyncio/hordes-of-azeroth-server)、
[`xenoglossy-asyncio/hordes-of-azeroth-client`](https://github.com/xenoglossy-asyncio/hordes-of-azeroth-client)、
[`xenoglossy-asyncio/hordes-of-azeroth`](https://github.com/xenoglossy-asyncio/hordes-of-azeroth)。

## 没有导入的内容

- `tools/lobby-server/`：新方案只做局域网和 `ip/domain:port` 直连，不维护公网大厅/注册服务。
- `Interface/AddOns/BonkAuras/`：独立的 WA 风格插件，不属于 HoA 核心；继续放在它自己的仓库。
- 构建产物（`target/`、`build/`、`bin/`、`obj/`）、数据库文件、服务端运行目录、日志、截图、测试配置。
- 子模块的 git 历史：新仓库从 0.1.0 开始一条新历史；需要追溯旧改动时回到上表的来源仓库。

## 版本

- 上游 0.6.3 → 新仓库 **0.1.0**，表示架构重写的起点，不表示功能缩减。
- `VERSION` 在仓库根目录；各组件不再单独维护版本号，打包时由根版本派生。

## 许可证

导入的目录各自保留原许可证文件：

- `server/LICENSE`（GPL-3.0）
- `client/LICENSE-MIT`、`client/LICENSE-APACHE`
- 根目录 `LICENSE`、`THIRD-PARTY-NOTICES.md` 覆盖 addon/glue/launcher/tools 等来自主仓库的部分
- 新写的 `shared/`、`scripts/`、`docs/`、部分 `tools/` 使用 GPL-3.0

详见 [LICENSE-NOTICE.md](../../LICENSE-NOTICE.md)。
