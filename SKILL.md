---
name: codex-dream-skin
description: 制作、应用、验证、暂停、还原或排查 macOS Codex Desktop 的 Dream Skin 主题。用户提到 Codex 换肤、皮肤、主题、背景图、用一张图定制 Codex、Dream Skin、主题未生效、CDP 注入或还原官方外观时使用。
---

# Codex Dream Skin

此目录是一个自包含的 Codex Skill：`SKILL.md`、`scripts/`、`assets/`、`agents/` 与测试都在同一目录。安装后目录本身位于 `~/.codex/skills/codex-dream-skin`；不要依赖或创建第二份运行时引擎。

它通过仅绑定到 `127.0.0.1` 的 Chrome DevTools Protocol 注入 renderer CSS 和装饰层，不改写官方 `.app`、`app.asar` 或签名。

## 工作目录

对于执行命令的场景，先定位包含 `SKILL.md`、`scripts/` 与 `assets/` 的当前 Skill 根目录。默认安装位置是 `~/.codex/skills/codex-dream-skin`，也可通过 `CODEX_DREAM_SKIN_ROOT` 覆盖；不要假定旧的 `~/.codex/codex-dream-skin-studio` 路径存在。

## 工作流

1. 先运行 `scripts/doctor-macos.sh` 和 `scripts/status-dream-skin-macos.sh`。不修改或重启 Codex。
2. 用 `scripts/customize-theme-macos.sh --image <绝对路径> --no-apply` 制作主题。优先使用获许可的横向图，宽度建议至少 2000px。
3. **只有在用户明确同意重启当前 Codex 后**，运行 `scripts/start-dream-skin-macos.sh --prompt-restart`。普通重启不会开启 CDP，因此不会自动应用皮肤。
4. 用 `scripts/verify-dream-skin-macos.sh --screenshot <绝对路径>` 确认原生侧栏、项目选择、任务内容和输入框仍可见且可交互。
5. 用 `scripts/pause-dream-skin-macos.sh` 软暂停；需恢复官方基础外观时使用 `scripts/restore-dream-skin-macos.sh --restore-base-theme --restart-codex`，该重启同样需要明确确认。

## 安全边界

- CDP 是无认证的 loopback 接口。只在可信本机环境启用，结束后暂停或还原。
- 不修改官方应用安装目录，不 patch `app.asar`，不写入 API Key、Base URL 或认证信息。
- 装饰层必须 `pointer-events: none`；不得以假 UI 覆盖原生控件。
- 注入失败时停止并报告，不要通过修改官方二进制绕过问题。

## 打包与验证

开源分发前运行：

```bash
./tests/run-tests.sh
./scripts/doctor-macos.sh
```

测试会检查脚本语法、主题载荷、配置备份/恢复、应用签名与自包含资源完整性。
