# scripts / 开发脚本

已提供：

- `build.ps1` / `build.sh`：按组件构建（server/client/launcher/addon/i18n/check/all），见 [BUILDING_zh.md](../BUILDING_zh.md)。
- `protect-main.sh`：把六项检查配置为 `main` 的必需项；GitHub 私有仓库需要 Pro 或改为公开后才能用。

计划提供：

- `dev.ps1` / `dev.sh`：启动本地 MariaDB、realmd、world server 和客户端（隔离配置目录）。
- `content.ps1` / `content.sh`：重新生成内容、文本、协议，并跑校验。
- `test.ps1` / `test.sh`：单元测试 + 无头集成测试（登录、语言切换、光环显示）。
- `release.ps1` / `release.sh`：打包服务端、客户端、插件、启动器。

脚本只做编排，不藏业务逻辑；CI 调用同一组脚本。
