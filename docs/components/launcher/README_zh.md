# launcher / 启动器

导入自主仓库 `tools/launcher`（`3ca658b`，2026-11-04）；许可证 GPL-3.0。当前源码在 `launcher/`。

Avalonia C# 启动器。

## 重构要点

- 语言选择是启动器/客户端设置的一部分，与客户端安装语言解耦；语言值随账号/配置进入游戏，而不是通过改客户端数据实现。
- 不再要求英文版 1.12.1：校验任意语言的 1.12.1 build 5875（文件版本号），英文 MD5 只作为快速路径。相关实验已在上游 PR #25 验证。
- 启动前按 `(locale, content version)` 清理/失效客户端缓存（当前实现的 `*.bin` 清理逻辑保留并升级）。
- 服务端、数据库、realmlist 的启动/停止逻辑保留。
- 联机只做直连：房主显示自己的局域网/VPN 地址 `ip:port`，玩家输入该地址（以及房主设置的可选密码）加入。不做公网大厅、房间注册或任何中心通知服务；公网穿透由玩家自己解决（端口转发、ZeroTier/Tailscale 等）。
- 启动器自身文本走 i18n 资源，随语言设置切换。

## 构建

见 [构建说明](../../../BUILDING_zh.md)。`dotnet build` 已通过；发布与打包待补。

## 待改

- 语言选择改为账号级，启动前按 `(locale, contentVersion)` 失效缓存。
- 保持 `config/release.json` 与本仓库的 GitHub、Gitee 地址同步。

## 更新源

`config/release.json` 指定 GitHub 仓库、对应的 Gitee 镜像（`giteeRepository`）和第三方下载。
启动器从 `https://github.com/<repository>/releases/latest/download/` 读取
`manifest.json` / `manifest-linux.json`；在中国大陆（或 GitHub 失败后）改用
`https://gitee.com/<giteeRepository>/releases/download/<tag>/<asset>`，最新 tag 通过 Gitee API
（`/releases/latest`）解析。两个仓库上的包 zip 使用相同 tag 和文件名，因此
`tools/publish-gitee.ps1 -Version x.y.z` 可以镜像一次发布：创建或复用 `packages-vX` 和 `vX`
两个 release，并上传 `release/<version>/assets`（需要设置 `HOA_GITEE_TOKEN`，token 要有仓库写权限；
脚本也会把 Gitee 默认分支设为 `main`）。
MariaDB 在 `thirdParty[].mirrors` 里配置清华、阿里云、中科大镜像；启动器在中国大陆优先使用它们，
其它地区在主源失败后回退。可选的 R2 私有镜像（`HOA_MIRROR_URL`）仍然保留。

## 直连联机

`CoopAgent` 不再连接大厅服务。房主在 gate 端口（默认 3725）上直接响应 `HOA1 ASK`、`HOA1 POLL`
和 `HOA1 CANCEL`；玩家在 Glue 联机界面输入房主的 `ip:port`。房主在显示请求前检查版本和协议，
原有的 token gate 继续承载 `LOGIN`、`WORLD`、`UPLOAD`、`LEDGER`、`ANSWERS` 和 `LEAVE`。
房主状态会列出所有可用的局域网地址，VPN/代理地址排在局域网地址之后；也可以手动填写公网地址。
