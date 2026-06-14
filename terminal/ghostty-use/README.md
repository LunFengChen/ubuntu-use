# Ghostty 使用与美化笔记

这个仓库记录 Ghostty 在 Ubuntu 桌面环境下的使用、美化和集成方式。

## 文档目录

- [终端美化教程](./终端美化.md)
  讲 Ghostty + Starship + Nerd Font 的分工，以及如何调整 prompt 里的用户、主机、目录、Git、时间、CPU、内存。

- [Ghostty 美化教程](./ghostty美化.md)
  讲 Ghostty 本身的背景、字体、字号、边距、光标、主题和选中颜色怎么调。

- [Ubuntu 文件管理器右键使用 Ghostty](./右键open-in-Ghostty.md)
  讲如何让 Nautilus 右键菜单打开 Ghostty。

## 当前方案概览

当前终端方案正在从 Bash 试用迁移到 fish。Prompt 仍使用 Starship，字体使用 JetBrainsMono Nerd Font。Bash/fish 的详细取舍见 `../bash-terminal-config.md` 和 `../fish-shell-migration.md`。

当前展示的信息：

- 用户
- 电脑/主机
- 当前目录
- Git 分支
- Git 工作区改动标记
- 北京时间
- CPU 使用率和核心数
- 内存使用率和总量

Bash 里曾经额外加了历史辅助（现在 fish 试用中）：

- 可选启用 ble.sh 后，输入命令时会弹出类似 PowerShell PSReadLine 的历史建议菜单，最多 5 条
- `h5` 查看最近 5 条历史命令
- `h10` 查看最近 10 条历史命令

当前真机效果截图：

![终端真机截图](./images/terminal-real.png)

## 关键配置文件

```text
~/.config/ghostty/config    # Ghostty 外观
~/.config/starship.toml     # Prompt 内容和样式
~/.bashrc                   # Bash 初始化 Starship
~/.blerc                    # Bash 输入时历史建议
```

仓库里的可参考配置：

```text
configs/ghostty.config
configs/starship.toml
configs/blerc
```

## 备份说明

本机生成的配置备份放在 `backups/`，该目录不会提交到仓库。
