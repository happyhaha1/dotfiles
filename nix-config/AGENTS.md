# NIX 子系统说明

## 概览

`nix-config/` 负责 flake、profile 与 Darwin 模块装配，是系统级配置区，不应混入通用 dotfiles 说明。

## 结构

```text
nix-config/
├── flake.nix.tmpl
├── flake.lock.tmpl
└── modules/
    ├── apps.nix.tmpl
    ├── profile.nix.tmpl
    ├── system.nix.tmpl
    └── host-users.nix
```

## 到哪里改

| 任务 | 位置 | 说明 |
|---|---|---|
| 改 flake 输入、输出结构 | `flake.nix.tmpl` | 这里把 chezmoi 平台/架构映射成 Nix system |
| 改用户态包集合 | `modules/profile.nix.tmpl` | `flakey-profile` 相关逻辑在这里 |
| 改 Darwin 系统行为 | `modules/system.nix.tmpl` | 系统默认值、键位、服务等 |
| 改应用清单 | `modules/apps.nix.tmpl` | macOS app / 包选择 |
| 改主机名与用户 | `modules/host-users.nix` | hostname 与 user 定义 |

## 本地约定

- 这里大部分文件是 `.tmpl`，修改时要同时考虑 `platform`、`hostname`、`username` 等模板变量。
- `flake.nix.tmpl` 同时承担跨平台入口与 Darwin 专属输出，不要把 Darwin-only 逻辑散落到根目录其他位置。
- `modules/` 是真正的边界；新逻辑优先放模块里，再由 `flake.nix.tmpl` 组装。
- `.flake-darwin.lock`、`.flake-linux.lock` 属于流程产物，更新逻辑由 CI 工作流处理，不在这里手工发明新流程。

## 本目录反模式

- 不要把渲染后的 `system.nix` / `apps.nix` 当作源文件提交；源头仍然是 `.tmpl`。
- 不要同时在根目录和这里维护一套 Nix 命令说明，Nix 细节只保留在本目录。
- 不要在模板中硬编码特定机器信息，除非该值明确由 chezmoi 数据注入。
- `capslock` 相关键位逻辑有限制，不要尝试同时映射成 control 和 escape。

## 验证

```bash
just darwin-check
just darwin-build
just up
```

## 备注

- `update-flake-lock.yml` 会在临时目录中渲染模板后执行 `nix flake update`，说明 CI 依赖模板可独立渲染。
- 若改动涉及平台条件，请顺手检查 `.chezmoiignore` 对非 Darwin 与 headless 场景的裁剪是否仍成立。
