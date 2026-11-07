# 文档索引

## 当前决策

| 决策 | 结论 |
| --- | --- |
| 仓库形态 | 单仓库，包含服务端、客户端、插件、启动器、GlueXML 和共享内容 |
| 托管 | GitHub 私有仓库 `hoa-core`，硬分叉 |
| 版本线 | 从 **0.1.0** 开始，不沿用上游 0.6.x |
| 与上游关系 | 独立演进，不再自动跟随；上游只作为起点和参考 |
| 内核 | 保留 VMaNGOS 和 benilla；只重构 HoA 层和确认的性能热点 |
| 语言 | 账号/会话属性；首发 **enUS + zhCN + zhTW** |
| 效果 | 一个效果 = 一个真实服务端光环，插件只读 |
| 内容 | `shared/content` 单一来源，工具生成各端产物 |
| 联机 | 只支持局域网和 `ip/domain:port` 直连；不做公网大厅/注册服务器 |
| 第一步 | 阶段 0 文档 + 骨架、阶段 1 代码导入完成；阶段 2 i18n 进行中 |
| 合并门槛 | CI 跑六项检查；分支保护暂缓（私有仓库没有 GitHub Pro），仓库公开后用 `scripts/protect-main.sh` 启用 |

## 文档约定

每个文档目录同时提供英文 `README.md` 和中文 `README_zh.md`，内容保持同步；改一处要改两份。

## 阅读顺序

1. [导入的代码与来源](imported-code/README_zh.md)
2. [总体架构](architecture/README_zh.md)
3. [i18n](i18n/README_zh.md)
4. [光环与效果](auras/README_zh.md)
5. [客户端原生能力](native-capabilities/README_zh.md)
6. [内容与数据](content-data/README_zh.md)
7. [协议](protocol/README_zh.md)
8. [迁移计划](migration-plan/README_zh.md)

## 组件说明

- [server](components/server/README_zh.md)
- [client](components/client/README_zh.md)
- [addon](components/addon/README_zh.md)
- [launcher](components/launcher/README_zh.md)

## 待确认

- zhTW 的术语来源：优先用官方 1.12.1 繁中名称，没有的再用 zhCN 转换并人工校对。
- 是否保留上游的更新/打包脚本，还是完全另起。

