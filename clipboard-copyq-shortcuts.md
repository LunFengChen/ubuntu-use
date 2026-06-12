# 剪切板选用及其快捷键处理

## 目标

在 Ubuntu 24.04 GNOME Wayland 环境下保留剪切板历史，至少支持最近 100 条，并且能通过快捷键打开历史窗口、通过命令行查看历史内容。

## 工具选择

选用 CopyQ。

原因：

- 支持长期剪切板历史。
- 同时提供 GUI 和命令行接口。
- 可以用户级安装 AppImage，不依赖 sudo。
- 在 GNOME Wayland 下可以通过 GNOME custom shortcut 打开窗口，避免应用自己抢全局快捷键失败。

## 安装位置

CopyQ AppImage 放在：

```bash
/home/xiaofeng/.local/opt/copyq/CopyQ-16.0.0-x86_64.AppImage
```

命令入口：

```bash
/home/xiaofeng/.local/bin/copyq
```

这是一个软链接，指向上面的 AppImage。

## 历史容量

设置保留最近 100 条：

```bash
copyq config maxitems 100
```

检查：

```bash
copyq config maxitems
```

期望输出：

```text
100
```

## 命令行查看

额外创建了一个便捷命令：

```bash
/home/xiaofeng/.local/bin/clip100
```

查看最近 100 条：

```bash
clip100
```

查看最近 20 条：

```bash
clip100 20
```

读取最新一条：

```bash
copyq read 0
```

## 登录自启动

CopyQ 登录自启动文件：

```bash
/home/xiaofeng/.config/autostart/copyq.desktop
```

启动命令：

```bash
/home/xiaofeng/.local/bin/copyq --start-server count
```

## 快捷键

最终使用：

```text
Super+Shift+V -> 打开 CopyQ 剪切板历史
Super+M       -> 打开 GNOME 通知中心
```

CopyQ 快捷键命令：

```bash
/home/xiaofeng/.local/bin/copyq --start-server show
```

## 为什么不用 Super+V

GNOME 默认把 `Super+V` 绑定给通知中心：

```text
org.gnome.shell.keybindings toggle-message-tray ['<Super>v', '<Super>m']
```

尝试给 CopyQ 使用 `Super+V` 时，`gsd-media-keys` 日志出现：

```text
Failed to grab accelerator for keybinding custom0
```

所以保留通知中心为 `Super+M`，把 CopyQ 改成 `Super+Shift+V`，避免冲突。

## 当前 GNOME custom shortcut

```text
name: CopyQ Clipboard History
command: /home/xiaofeng/.local/bin/copyq --start-server show
binding: <Super><Shift>v
```

## 注意

剪切板历史会保存复制过的敏感内容。复制密码、token、私钥、验证码后，应及时在 CopyQ 里删除相关历史。
