# Neovim 子系统说明

## 概览

`private_dot_config/nvim/` 是 LazyVim 风格的 Neovim 配置入口，结构轻量，真实入口从 `init.lua` 跳到 `lua/config/lazy.lua`。

## 结构

```text
private_dot_config/nvim/
├── init.lua
├── lua/config/      # 启动、选项、快捷键、autocmd
├── lua/plugins/     # 插件规格与覆盖
├── lazyvim.json
└── stylua.toml
```

## 到哪里改

| 任务 | 位置 | 说明 |
|---|---|---|
| 调整启动或插件管理方式 | `init.lua` / `lua/config/lazy.lua` | 启动链最核心位置 |
| 改编辑器基础选项 | `lua/config/options.lua` | 先看是否已有默认能力 |
| 改快捷键 | `lua/config/keymaps.lua` | 尽量只放增量映射 |
| 改自动命令 | `lua/config/autocmds.lua` | 与 keymaps 分离 |
| 增加或覆盖插件 | `lua/plugins/*.lua` | 插件层逻辑只放这里 |

## 本地约定

- 当前布局明显沿用 LazyVim 默认分层：`config/` 管基础设施，`plugins/` 管扩展与覆盖。
- `init.lua` 很薄，说明启动流程应继续保持单入口；不要把大量逻辑重新塞回根文件。
- `lua/plugins/example.lua` 是示例规格文件，改真实插件时应新增或替换为明确用途的插件文件，而不是把示例注释当文档中心。
- `lazy.lua` 里已经定义 `lazy.nvim` 自举、spec 导入和性能相关开关，调整插件加载策略时优先在这里收口。

## 本目录反模式

- 不要在根 `AGENTS.md` 或其他子目录重复记录 LazyVim 细节。
- 不要把插件规格和基础选项混写；`config/` 与 `plugins/` 边界保持清晰。
- 不要把示例文件误判为完整生产配置，它更多是参考模板。
- 不要无理由扩大自举逻辑复杂度；这里现状是极简入口。

## 验证

```bash
nvim --headless "+Lazy! sync" +qa
```

## 备注

- 当前仓库中 `lua/plugins/` 只有一个示例文件，说明此子系统规模不大，文档应保持短小。
- 如果后续插件文件显著增多，再考虑是否细分到更深层级；目前不需要额外 `AGENTS.md`。
