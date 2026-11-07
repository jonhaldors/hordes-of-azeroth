# 许可证与仓库结构

本页记录许可证盘点和 monorepo 方案。它是工程文档，不是法律意见；正式分发前应请律师复核。

## 仓库里实际有什么

| 路径 | 许可证 | 说明 |
| --- | --- | --- |
| `server/` | GPL-3.0 分发 | VMaNGOS 分支；`server/LICENSE` 是 GPL-3.0。源码头是 GPL-2.0-or-later，因此服务端可以按 GPL-3.0 分发。Windows 数据库客户端是 MariaDB Connector/C 3.4.10（LGPL-2.1-or-later，动态链接，使用 Schannel），加密是 OpenSSL 3.5.9 LTS（Apache-2.0，`libcrypto` 加 `legacy` provider）。原来的 GPL-2.0-only MySQL 客户端和 OpenSSL 1.0.2 已删除。gSOAP、libmpq 是 GPL-2.0-or-later；recastnavigation 是 zlib；cpptrace 是 MIT；utf8cpp 是 Boost；G3D 是 Modified BSD；zlib、bzip2 是宽松许可证。 |
| `client/` | MIT 或 Apache-2.0 | benilla 分支；所有 workspace crate 都声明 `MIT OR Apache-2.0`。Cargo 依赖为 MIT、Apache-2.0、MPL-2.0、zlib、BSD 等（发行包里的 `CLIENT-LICENSES.md` 会逐条列出）。MIT/Apache-2.0 与 GPL-3.0 分发兼容。 |
| `addon/`、`glue/`、`launcher/`、`config/`、`localization/` | GPL-3.0 | Hordes of Azeroth 的衍生物。启动器依赖的 Avalonia、Mono.Nat 是 MIT。 |
| `shared/`、`scripts/`、`docs/`、`tools/` | GPL-3.0 | 本仓库自己的代码和数据。 |
| 插件字体 | OFL-1.1 | Barlow、Noto Sans SC、Noto Sans TC；字体旁有许可证文件。 |
| MariaDB Server | GPL-2.0（仅第 2 版） | 启动器单独下载、单独运行；不链接进我们的二进制。 |

## 兼容性

- GPL-3.0 可以与 MIT、Apache-2.0、BSD、zlib、Boost、OFL、LGPL-2.1-or-later 组合。
- 服务端不再受 GPL-2.0-only 客户端库或 GPL 不兼容 OpenSSL 的约束：MariaDB Connector/C 是 LGPL-2.1-or-later 动态链接，OpenSSL 3 是 Apache-2.0。
- MariaDB Server 仍是 GPL-2.0-only，但 GPLv2 和 GPLv3 程序可以作为**独立程序聚合**在同一介质上。启动器下载并运行 MariaDB Server；游戏服务端链接的是 MariaDB Connector/C，不是 MariaDB Server。
- MIT 不能作为我们组合作品的许可证：插件、Glue、启动器和服务端都是 GPL-3.0 衍生物。客户端保留 MIT/Apache-2.0 是为了来源清晰，同时与 GPL-3.0 兼容。
- 原来的 GPL-2.0-only MySQL 头和 OpenSSL 1.0.2 是从树里删除，不是改标许可证。

**决定（2026-11-06）**：仓库原创代码、`shared/` 和服务端分发统一采用 **GPL-3.0**；客户端保持 **MIT 或 Apache-2.0**；插件、Glue、启动器、config、localization 保持 **GPL-3.0**。Windows 服务端随附的 MariaDB Connector/C 按 **LGPL-2.1-or-later**、OpenSSL 3 按 **Apache-2.0**；MariaDB Server 仍按其 GPL-2.0-only 单独下载。

**仓库继续使用 monorepo，不引入 submodule。** 许可证义务靠保留许可证和版权声明、标明来源与本地修改、提供对应源码来满足，Git 结构不是许可证要求。submodule 只是可选的来源追踪工具，会增加贡献、跨目录原子修改和 CI 的成本。每个导入目录保留 `LICENSE` 和 `UPSTREAM.md`；`LICENSE-NOTICE.md` 与 `provenance.yaml` 记录其余信息，发布 tag 就是对应源码。

## 结构

```
hoa-core                     GPL-3.0（顶层 LICENSE）
  LICENSES/                  GPL-3.0、GPL-2.0、LGPL-2.1、MIT、Apache-2.0、OFL-1.1 全文
  shared/                    GPL-3.0（content、i18n、protocol）
  server/                    GPL-3.0 + LICENSE + UPSTREAM.md
  client/                    MIT 或 Apache-2.0 + LICENSE-MIT/LICENSE-APACHE + UPSTREAM.md
  addon/ glue/ launcher/     GPL-3.0 + UPSTREAM.md
  config/ localization/      GPL-3.0 + UPSTREAM.md
  tools/ docs/ scripts/      GPL-3.0 原创代码（导入的工具保留原声明）
```

如果以后上游追踪成本太高，可以把 `server/`、`client/` 改成各自 fork 仓库的子模块；那是维护选择，不是许可证要求。届时用相对 URL（`../hoa-server.git`），让 GitHub 克隆都落到同一主机；同时镜像 fork 仓库，并先修发布工具——`git archive` 不包含子模块内容。

## 步骤

1. 保留顶层 `LICENSE`（GPL-3.0）和各目录许可证；决定记录在本页和 `LICENSE-NOTICE.md`。
2. 每个导入目录保留 `LICENSE`/`LICENSE-MIT`/`LICENSE-APACHE` 和 `UPSTREAM.md`，写明上游 URL、提交、基准和本地修改。
3. 保留 `LICENSES/` 全文和 `THIRD-PARTY-NOTICES.md` 依赖清单。Windows 依赖包的版本、来源和哈希在 `server/dep/windows/README.md`。
4. 保持服务端 Windows 依赖与 GPL-3.0 兼容：MariaDB Connector/C（LGPL-2.1-or-later）和 OpenSSL 3（Apache-2.0）。不要再引入 GPL-2.0-only 的 MySQL 客户端或 OpenSSL 1.0.2。
5. 不要把 GPL-2.0-only 的部分改标成 GPL-3.0 或 MIT。以后若引入 submodule，必须同轮更新 CI（`submodules: recursive`）和发布打包。
