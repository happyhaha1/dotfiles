# omp 的 `agent/config.yml` 为什么用 `modify_` 脚本

`~/.omp/agent/config.yml` 由 omp 在运行时自己改写：它会重新序列化整份 YAML。
因此这个文件不能当作普通副本（plain copy）交给 chezmoi 管理。

## 问题

omp 的写法有三个和 chezmoi 冲突的特征：

1. **丢弃注释**：每次保存都用 YAML 序列化器重写整份文件，源文件里的注释不会保留。
2. **追加自己的键**：例如 `dev.autoqaConsent`、`browser.headless` 这类随版本或交互
   产生的开关和迁移字段，由 omp 直接写进同一份文件。
3. **不写结尾换行**：omp 的输出末尾没有 `\n`，而编辑器与大多数 YAML 工具会补上。

chezmoi 判断目标“是否被外部改动”用的是**整份内容的 SHA-256**，逐字节比对。
所以只要源文件产不出 omp 的字节序列，每次 `chezmoi apply` 都会询问：

```text
.omp/agent/config.yml has changed since chezmoi last wrote it?
[diff,overwrite,all-overwrite,skip,quit]?
```

拒绝一次只会让下次继续弹；接受 `overwrite` 又会把 omp 刚写下的键冲掉。
plain copy 无法收敛，因为源文件与 omp 的输出永远不可能逐字节相同。

## 方案

源文件是 `private_dot_omp/private_agent/modify_private_config.yml` ——
chezmoi 的 [`modify_` 脚本](https://www.chezmoi.io/user-guide/manage-different-types-of-file/#manage-part-but-not-all-of-a-file)：

- stdin 收到目标文件的当前内容（不存在时为空）；
- stdout 的内容就是 chezmoi 认为目标应当具有的内容。

脚本只声明本仓库拥有的键，并用格式保留的 `yq` 就地修改，其余内容原样透传。
chezmoi 对 `modify_` 目标记录的是**脚本**而不是内容哈希，所以 omp 自己写入的
键不再算作外部改动，提示消失。

### 脚本拥有的键

| 键 | 值 |
| --- | --- |
| `symbolPreset` | `nerd` |
| `composer.shape` | `band` |
| `theme.dark` / `theme.light` | `titanium` / `light` |
| `setupVersion` | `2` |
| `defaultThinkingLevel` | `high` |
| `modelRoles.*` | `home-magpie/group/*` 路由表 |
| `task.agentModelOverrides.security-reviewer` | `@slow` |
| `extensions` | 追加 `~/.pi/agent/extensions/openviking`（去重） |
| `compaction.enabled` | `false` |
| `memory.backend` | `"off"` |

`extensions` 用“追加并去重”而不是整体赋值，避免覆盖 omp 之后加入的扩展。

### 不属于脚本的内容

- `dev.*`、`browser.*` 以及任何 omp 后续新增的键，一律原样保留。
- 注释：omp 自己不会保留，所以这里也不再声明；`compaction` 与 `memory` 的语义
  改由本文档说明。这两个键的作用是让 Magic Context 独占上下文平面：它的插件会
  设置它们，显式写死只是为了防止 `omp config set` 把它们悄悄改回去。
  OpenViking 保持 `takeoverEnabled: false`，长期记忆由 OpenViking 提供。

## 行为

| 情况 | 结果 |
| --- | --- |
| 目标不存在（首次 apply、CI 渲染） | 写出上面的完整基线 |
| omp 追加自己的键、或去掉结尾换行 | `chezmoi status` 干净，apply 不重写文件（字节一致） |
| omp 改动了我们拥有的键 | `chezmoi status` 报 `MM`，apply 恢复我们的值并保留 omp 的键 |
| 目标 YAML 损坏 | `yq` 报错，apply 非零退出，目标不被改写（fail-closed） |
| `yq` 不存在（极早的 bootstrap） | 原样透传并在 stderr 提示，下次 apply 再收敛 |
| 结尾换行 | 保留输入的状态：输入没有就不补，已有就保留 |

## 依赖与检查

- `yq` 固定在 `private_dot_config/aquaproj-aqua/aqua.yaml`（`mikefarah/yq`）。
  脚本先查 `PATH`，再回退到 `${AQUA_ROOT_DIR:-$XDG_DATA_HOME/aquaproj-aqua}/bin/yq`
  和 `~/.local/bin/yq`。
- `.github/workflows/ci.yml` 的 ShellCheck 步骤会对该脚本执行
  `shellcheck --severity=warning`。
- 改动此脚本后，本地验证：

  ```bash
  shellcheck --severity=warning private_dot_omp/private_agent/modify_private_config.yml
  chezmoi diff
  chezmoi status
  ```