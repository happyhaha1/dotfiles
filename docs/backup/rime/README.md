# Rime 配置备份（已下架）

Rime 在 2026-10-29 被水杉输入法（MSIME）取代，仓库不再安装它：`fcitx5-rime`、
`rime-ice-pinyin-git`、`rime-wanxiang-gram-zh-hans` 已从
`.chezmoidata/omarchy.yaml` 移除，`~/.local/share/fcitx5/rime/` 会被
`run_onchange_after_12` 在包消失后清掉。

这里只是**存档**，不会安装到任何机器：`docs/` 被 `.chezmoiignore` 忽略。

- `default.custom.yaml` — 原本部署到 `~/.local/share/fcitx5/rime/default.custom.yaml`
- `rime_ice.custom.yaml` — 原本部署到 `~/.local/share/fcitx5/rime/rime_ice.custom.yaml`

## 恢复办法

```bash
# 1) 重新声明包
#    .chezmoidata/omarchy.yaml
#      omarchyPackages.shared:    + fcitx5-rime
#      omarchyAurPackages.shared: + rime-ice-pinyin-git
#                                 + rime-wanxiang-gram-zh-hans
# 2) 把这两个文件放回 private_dot_local/share/fcitx5/rime/ 并 git mv 回受管路径
mkdir -p private_dot_local/share/fcitx5/rime
git mv docs/backup/rime/default.custom.yaml    private_dot_local/share/fcitx5/rime/
git mv docs/backup/rime/rime_ice.custom.yaml   private_dot_local/share/fcitx5/rime/
# 3) 在 private_profile.tmpl 里把 rime 加回 Items，并在 after_12 恢复
#    「删除 default.yaml / build/default.yaml 触发重新部署」那段
chezmoi apply
```

注意：`userdb`（学习词频）、`sync/`、`build/` 属于运行时数据，没有备份，
恢复后是全新的词频起点。
