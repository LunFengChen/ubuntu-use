# Ghostty 使用与美化

相关仓库：

```text
https://github.com/LunFengChen/ghostty-use
```

## 用途

这个仓库记录 Ghostty 在 Ubuntu 桌面环境下的使用、美化和集成方式。

当前方案：

- 终端使用 Ghostty。
- Shell 保留 Bash，不切换 zsh/fish。
- Prompt 使用 Starship。
- 字体使用 JetBrainsMono Nerd Font。
- Nautilus 右键菜单集成 Ghostty。

## 关键配置

本机配置文件：

```text
~/.config/ghostty/config
~/.config/starship.toml
~/.bashrc
```

参考仓库里的配置：

```text
configs/ghostty.config
configs/starship.toml
```

## Ghostty 外观

当前 Ghostty 外观方向：

- 深色主题。
- JetBrainsMono Nerd Font。
- 适中的字号和窗口边距。
- block 光标。
- 关闭透明和背景模糊，保证长期编码时清晰稳定。

参考配置片段：

```text
theme = Everforest Dark Hard
font-family = "JetBrainsMono Nerd Font"
font-size = 13
background = #181818
foreground = #d8d8d8
background-opacity = 1.0
background-blur = false
window-padding-x = 10
window-padding-y = 8
cursor-style = block
cursor-style-blink = true
```

## VS Code 集成终端字体

Ghostty 的配置只影响 Ghostty 自己的窗口，不会自动影响 VS Code 的集成终端。也就是说：

```text
~/.config/ghostty/config
```

里的：

```text
font-family = "JetBrainsMono Nerd Font"
```

不会让 VS Code terminal 自动跟着变。

VS Code 需要单独写：

```text
~/.config/Code/User/settings.json
```

本机当前配置：

```json
{
  "terminal.integrated.fontFamily": "JetBrainsMono Nerd Font Mono",
  "terminal.integrated.fontSize": 13,
  "editor.fontFamily": "'JetBrainsMono Nerd Font', 'Droid Sans Mono', 'monospace', monospace"
}
```

这里 terminal 选择 `JetBrainsMono Nerd Font Mono`，是因为 VS Code 集成终端更适合使用 Mono 版本，Nerd Font 图标宽度也更稳定。

如果改完没生效：

1. 关闭当前 VS Code terminal，重新新建一个 terminal。
2. 或执行 `Developer: Reload Window`。
3. 确认字体存在：

```bash
fc-match "JetBrainsMono Nerd Font Mono"
fc-match "JetBrainsMono Nerd Font"
```

## Starship Prompt

Prompt 展示的信息：

- 用户
- 主机
- 当前目录
- Git 分支
- Git 工作区改动标记
- 上一条命令执行耗时（超过 500ms 时显示）
- 时间
- CPU 使用率和核心数
- 内存使用率和总量

初始化方式通常放在 `~/.bashrc`：

```bash
eval "$(starship init bash)"
```

### 命令执行耗时

Starship 的 `cmd_duration` 模块可以显示上一条命令执行时间。本机把它放在右侧状态区，超过 `500ms` 时显示：

```toml
format = """
[╭─](fg:surface0)$username$hostname$directory$git_branch${custom.git_dirty}$fill$cmd_duration${custom.local_time}${custom.cpu}${custom.ram}
[╰─](fg:surface0)$character"""

[cmd_duration]
min_time = 500
show_milliseconds = true
style = "fg:mauve bold"
format = "[ 󱎫 $duration ]($style)"
```

如果想每条命令都显示耗时，可以把 `min_time` 改成 `0`；如果觉得太吵，可以改成 `1000` 或 `2000`。

## Nautilus 右键打开 Ghostty

目标是在 Ubuntu 文件管理器里右键使用 Ghostty 打开当前目录。

先把默认终端设为 Ghostty：

```bash
gsettings set org.gnome.desktop.default-applications.terminal exec "ghostty"
gsettings set org.gnome.desktop.default-applications.terminal exec-arg "-e"
xdg-mime default com.mitchellh.ghostty.desktop x-scheme-handler/terminal
```

Ghostty 的 Nautilus 扩展依赖 `python3-nautilus`。

系统级推荐做法：

```bash
sudo apt-get update
sudo apt-get install -y python3-nautilus
sudo apt-get remove -y nautilus-extension-gnome-terminal
nautilus -q
```

完成后重新打开“文件”，右键菜单应出现：

```text
Open in Ghostty
```

## 用户级 Scripts 方案

如果不想移除 GNOME Terminal 的 Nautilus 扩展，可以添加用户级脚本：

```bash
mkdir -p ~/.local/share/nautilus/scripts
nano ~/.local/share/nautilus/scripts/"Open in Ghostty"
```

脚本内容：

```sh
#!/bin/sh
if [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
  path=$(python3 -c "import sys, urllib.parse; print(urllib.parse.urlparse(sys.argv[1]).path)" "$NAUTILUS_SCRIPT_CURRENT_URI")
else
  path="$PWD"
fi
exec ghostty --working-directory="$path" --gtk-single-instance=false
```

赋权并重启 Nautilus：

```bash
chmod +x ~/.local/share/nautilus/scripts/"Open in Ghostty"
nautilus -q
```

入口通常在：

```text
右键 -> Scripts -> Open in Ghostty
```

## 检查

```bash
ghostty --version
gsettings get org.gnome.desktop.default-applications.terminal exec
gsettings get org.gnome.desktop.default-applications.terminal exec-arg
xdg-mime query default x-scheme-handler/terminal
```
