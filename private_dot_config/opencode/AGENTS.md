# OpenCode 子系统说明

## 概览

`private_dot_config/opencode/` 管理 OpenCode 的全局配置、命令与技能容器。这里的核心规则是：**目录级边界在本文件维护，具体技能行为以各自 `SKILL.md` 为准。**

## 结构

```text
private_dot_config/opencode/
├── oh-my-opencode.jsonc   # agent/category/feature 总配置
├── commands/              # 自定义命令
├── skills/                # 多个技能包
└── encrypted_opencode.jsonc.age
```

## 到哪里改

| 任务 | 位置 | 说明 |
|---|---|---|
| 调整 agent、category、feature 开关 | `oh-my-opencode.jsonc` | 全局编排入口 |
| 改提交类命令 | `commands/commit.md` | 命令层工作流，不是技能层 |
| 改某个技能触发描述或流程 | `skills/<skill>/SKILL.md` | 技能自己的真正规范入口 |
| 改技能脚本/资源 | `skills/<skill>/scripts|references|rules|data` | 先读该技能 `SKILL.md` |
| 改敏感 OpenCode 配置 | `encrypted_opencode.jsonc.age` | 保持加密路径 |

## 本地约定

- `oh-my-opencode.jsonc` 定义了 agents、categories 及功能开关，是容器级配置，不应掺入单个技能细节。
- `skills/` 下每个目录都已经有自己的 `SKILL.md` 或显式规则文件；这些文件比 `AGENTS.md` 更接近执行语义。
- `skill-creator` 明确强调：技能目录应保持精简，避免重复文档、避免深层嵌套、避免把细节同时写进 `SKILL.md` 和引用文件。
- `ui-ux-pro-max` 是本仓库最复杂的技能之一，核心在 Python 脚本与数据协作；`remotion-best-practices` 则以规则索引为主。它们共享容器规则，但不应在这里被全文复述。

## 本目录反模式

- 不要在这里复制任何单个技能的 `SKILL.md` 内容；本文件只描述容器边界与入口。
- 不要给每个技能再新增一层泛化文档，除非技能自身已经跨脚本、数据、规则形成新的维护边界。
- 不要把明文敏感配置放进 Git；OpenCode 私密配置继续走 `.age`。
- 不要把命令目录和技能目录混为一谈：`commands/` 是用户命令入口，`skills/` 是能力包入口。

## 重点入口

- `oh-my-opencode.jsonc`：全局 agent/category 映射。
- `commands/commit.md`：提交工作流命令，内容偏流程规范。
- `skills/ui-ux-pro-max/`：数据 + Python 脚本型技能热点。
- `skills/remotion-best-practices/`：规则文档型技能热点。
- `skills/skill-creator/`：技能创建/验证/打包规范来源。

## 备注

- 如果任务落在某个具体技能目录，下一步永远是读取该技能的 `SKILL.md`，而不是继续停留在本文件。
- 当前仓库不需要在 `skills/*` 下再铺一层 `AGENTS.md`；现有 `SKILL.md` 已经承担主说明职责。
