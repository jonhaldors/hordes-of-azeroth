# shared/i18n / 国际化

语言是**会话/账号属性**，由服务端在登录时确定；客户端安装数据的语言只用于解析资源，不决定显示语言。

## 文本分类

| 类别 | 存放位置 | 运行时来源 |
| --- | --- | --- |
| 游戏内容文本（物品/法术/光环/地图/生物/天赋/卡牌） | `shared/content` 条目内 | 服务端本地化查询响应 + 客户端内容包 |
| 服务端运行时文本（通知、奖励、战斗提示） | `shared/i18n/messages` | 服务端按消息 ID + 参数发送 |
| 客户端界面文本（选项、菜单、Glue、错误） | `shared/i18n/ui` | 客户端语言包 |
| 插件文本 | `shared/i18n/addon` | 插件 Lua 语言表 |

## 消息目录（草案）

```yaml
- id: hoa.notice.stage_unlocked
  enUS: "Stage {stage} unlocked."
  zhCN: "第{stage}阶段已解锁。"
  placeholders:
    stage: number
```

- 用**稳定 ID**，不用英文句子当键；改英文不会让旧翻译失效。
- 客户端专用条目可以用 `ref: <已有 id>` 复用另一条的 enUS/zhCN，避免复制译文；静态 XML 键用 `global: HOA_UI_*` 显式指定，省略时由 ID 派生。
- 占位符统一 `{name}`，编译期检查类型和缺失；复数用 `_one` / `_other` 变体。
- 缺翻译时回退 enUS；CI 在缺条目、占位符不一致、未使用条目时报错。
- 首发语言：enUS、zhCN、zhTW，格式为以后加语言留好。
- zhTW 优先使用官方 1.12.1 繁中名称；没有的条目由 zhCN 转换后人工校对，字体使用 Noto Sans TC。

## 当前种子

目录现在有 995 条服务端消息（`messages/server.yaml`）、1558 条插件文本（`addon/addon.yaml`）、1328 条客户端界面文本（`ui/options.yaml`、`ui/glue.yaml`、`ui/keybindings.yaml`）和 304 条启动器文本（`launcher/launcher.yaml`），都包含 enUS、zhCN 和 zhTW。`BonkStrings.h/.cpp`、`addon/HordesOfAzeroth/VanillaBonkLocaleData.lua` 和客户端语言包都由它生成。旧消息里的数字占位符（`{1}`、`{2}`）暂时保留，等服务器调用点迁移为命名参数后再改。

```bash
python tools/i18n/gen_server_strings.py       # 从目录生成 BonkStrings.h/.cpp
python tools/i18n/gen_addon_locale.py         # 生成插件语言表
python tools/i18n/gen_client_pack.py          # 生成客户端界面语言包
python tools/i18n/gen_launcher_strings.py      # 生成启动器字符串表
python tools/i18n/check.py                    # 校验 ID、ref、global、占位符和必需语言
python tools/i18n/build.py                    # 生成 shared/i18n/generated
python tools/i18n/check_ui_xml.py             # 校验已发布 XML/Glue 的键
python tools/i18n/build.py --check            # 生成物过期时失败
python -m unittest discover -s tools/i18n -p "test_*.py"
```

## 生成物

- `server/src/game/Bonk/BonkStrings.h/.cpp`：枚举 + 英文源，由目录生成
- `shared/i18n/generated/`：JSON 目录（翻译工具/导出）
- `client/crates/benilla-app/assets/i18n/<locale>.json`：客户端界面语言包
- `launcher/LauncherStrings.g.cs`：启动器字符串表
- `addon/HordesOfAzeroth/VanillaBonkLocaleData.lua`：生成的插件数据文件，一个文件包含全部语言（文件名由 TOC 固定）

## 客户端与缓存

- 登录握手携带账号语言和内容版本；客户端据此加载语言包。登录前使用启动器/上次保存的 `hoaLanguage`。
- 第一阶段覆盖 HoA 自己的客户端 UI（Options、GameMenu、ScriptLog、Realmlist、KeyBindings）和 GlueXML；安装目录的原生 `GlobalStrings.lua`/FrameXML 仍提供原生界面文本，后续再接。
- `GetLocale()` 返回语言包语言；安装 locale 仍用于 DBC 列和名字字符集。
- WDB/模板缓存键加入 `(locale, content version)`；语言切换或内容更新时自动丢弃旧缓存，避免“切换中文后装备还是英文”的问题。
- 字体：各语言自带回退字体（zhCN 使用 Noto Sans SC），客户端统一按语言选择。
- 客户端 UI 语言变更后重载界面，不要求重启整个游戏。

## 翻译流程

1. 开发只改英文源和 ID。
2. `tools/translate` 增量列出缺失/变更条目。
3. 翻译写入 `shared/i18n/messages/<locale>.yaml`、`addon/` 或 `ui/`（按领域拆分）。
4. Glue 文本放在 `shared/i18n/ui/glue.yaml`；已废弃的 `BonkGlueLocale<locale>.lua` 表不再生成。
5. CI 校验后由内容编译器生成各端产物。
