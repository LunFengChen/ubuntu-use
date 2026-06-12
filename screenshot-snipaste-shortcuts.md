# 截图选用及其快捷键处理

## 目标

在 Ubuntu 24.04 GNOME Wayland 环境下使用稳定的截图工具，并让快捷键由 GNOME 统一接管，避免应用自己注册全局热键失败。

## 工具选择

选用 Snipaste。

原因：

- 已经作为 AppImage 安装在用户目录。
- 支持截图和贴图工作流。
- 比 Flameshot 更符合当前个人桌面使用习惯。
- 在 Wayland 下不依赖应用自己抢全局快捷键，而是由 GNOME custom shortcut 触发命令。

## 安装位置

Snipaste AppImage：

```bash
/home/xiaofeng/.local/bin/Snipaste.AppImage
```

桌面入口：

```bash
/home/xiaofeng/.local/share/applications/snipaste.desktop
```

## 快捷键

最终使用：

```text
Super+Shift+S -> Snipaste 截图
```

GNOME custom shortcut 命令：

```bash
/home/xiaofeng/.local/bin/Snipaste.AppImage snip
```

当前配置：

```text
name: Snipaste Snip
command: /home/xiaofeng/.local/bin/Snipaste.AppImage snip
binding: <Super><Shift>s
```

## 为什么不用应用内全局快捷键

当前桌面会话是 GNOME Wayland。

Wayland 下，普通应用不能像 X11 那样稳定抢占全局快捷键。Snipaste 自己设置的 `Super+Shift+S` 可能不会触发，不是文件权限问题。

更稳的方式是：

1. 在 Snipaste 内关闭或忽略应用级全局快捷键。
2. 在 GNOME custom shortcuts 里绑定 `Super+Shift+S`。
3. 让 GNOME 直接执行 `/home/xiaofeng/.local/bin/Snipaste.AppImage snip`。

## Flameshot 处理

Flameshot 当前不是主力截图工具，计划卸载。

检查方式：

```bash
command -v flameshot
dpkg -l | grep flameshot
```

卸载 apt 版本：

```bash
sudo apt remove --purge flameshot
sudo apt autoremove
```

卸载后确认：

```bash
command -v flameshot
dpkg -l | grep flameshot
```

## 排障

如果快捷键不触发，先确认 GNOME 快捷键服务还在：

```bash
pgrep -a gsd-media-keys
```

查看 GNOME custom shortcuts：

```bash
dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/
```

如果 `gsd-media-keys` 没有运行，注销当前 GNOME 会话并重新登录，通常会恢复。
