# CI

`.github/workflows/ci.yml` 在每次 pull request 和 push 到 `main` 时运行：

| Job | 内容 |
| --- | --- |
| `docs-check` | 检查中英文 README 配对、相对链接，以及 `provenance.yaml` / `UPSTREAM.md` 记录 |
| `i18n-check` | 校验共享消息目录和生成产物 |
| `content-check` | 重新生成内容 SQL 和类型化协议，并检查与源文件一致 |
| `addon-lua` | 用 LuaJIT 解析插件和 GlueXML 的所有 Lua 文件 |
| `launcher-build` | Avalonia 启动器 `dotnet build` |
| `client-check` | 客户端 workspace `cargo check -p hoa` |
| `server-build` | Ubuntu 24.04 上 CMake 配置 + `mangosd` 构建 |

这七项是合并门槛。**分支保护还没启用**：GitHub 的私有仓库需要 GitHub Pro 才能使用 branch protection/ruleset，本仓库目前在免费计划下。升级 Pro 或把仓库改为公开后，运行 `scripts/protect-main.sh` 即可把七项检查设为 `main` 的必需项。

本地可以用 `scripts/build.ps1`/`build.sh`（addon、launcher、client、server、i18n、content）、`python scripts/check-docs.py` 和 `python tools/i18n/check.py` 跑同一组检查。
