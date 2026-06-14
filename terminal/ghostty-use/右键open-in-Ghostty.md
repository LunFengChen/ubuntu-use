# Ubuntu 文件管理器右键使用 Ghostty

这份教程用于把 Ubuntu GNOME 文件管理器 Nautilus 里的右键“在终端打开”改成 Ghostty。

## 适用环境

- Ubuntu GNOME
- 文件管理器是 Nautilus，也就是系统自带的“文件”
- 已安装 Ghostty

先确认 Ghostty 可用：

```bash
ghostty --version
```

如果能看到版本号，例如 `Ghostty 1.3.1`，说明 Ghostty 已安装。

## 设置系统默认终端

先把系统默认终端设置为 Ghostty：

```bash
gsettings set org.gnome.desktop.default-applications.terminal exec "ghostty"
gsettings set org.gnome.desktop.default-applications.terminal exec-arg "-e"
xdg-mime default com.mitchellh.ghostty.desktop x-scheme-handler/terminal
```

检查结果：

```bash
gsettings get org.gnome.desktop.default-applications.terminal exec
gsettings get org.gnome.desktop.default-applications.terminal exec-arg
xdg-mime query default x-scheme-handler/terminal
readlink -f /usr/bin/x-terminal-emulator
```

期望看到类似：

```text
'ghostty'
'-e'
com.mitchellh.ghostty.desktop
/usr/bin/ghostty
```

## 处理 Nautilus 右键菜单

Ubuntu 默认的 Nautilus 右键“在终端打开”通常来自 GNOME Terminal 扩展：

```text
nautilus-extension-gnome-terminal
```

这个扩展会打开 GNOME Terminal，不一定跟随系统默认终端。

Ghostty 自带 Nautilus 扩展脚本，但需要 `python3-nautilus` 才能加载。所以需要安装 Ghostty 菜单加载器，并移除 GNOME Terminal 的 Nautilus 扩展：

```bash
sudo apt-get update
sudo apt-get install -y python3-nautilus
sudo apt-get remove -y nautilus-extension-gnome-terminal
nautilus -q
```

执行完后，重新打开“文件”应用。

现在右键文件夹或空白处，应该可以看到：

```text
Open in Ghostty
```

## 如果没有出现

先确认包状态：

```bash
dpkg -l | grep -E "python3-nautilus|nautilus-extension-gnome-terminal|ghostty"
```

理想状态是：

```text
ghostty 已安装
python3-nautilus 已安装
nautilus-extension-gnome-terminal 不存在或已移除
```

再确认 Ghostty 的 Nautilus 扩展文件存在：

```bash
ls /usr/share/nautilus-python/extensions/ghostty.py
```

如果文件存在，但菜单仍然没出现，重启 Nautilus：

```bash
nautilus -q
```

然后重新打开“文件”。

如果还是没有出现，注销并重新登录一次。

## 可选：添加 Scripts 菜单入口

如果暂时不想移除 GNOME Terminal 扩展，也可以添加一个用户级脚本入口。

创建脚本目录：

```bash
mkdir -p ~/.local/share/nautilus/scripts
```

创建脚本：

```bash
nano ~/.local/share/nautilus/scripts/"Open in Ghostty"
```

写入：

```sh
#!/bin/sh
if [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
  path=$(python3 -c "import sys, urllib.parse; print(urllib.parse.urlparse(sys.argv[1]).path)" "$NAUTILUS_SCRIPT_CURRENT_URI")
else
  path="$PWD"
fi
exec ghostty --working-directory="$path" --gtk-single-instance=false
```

赋予执行权限：

```bash
chmod +x ~/.local/share/nautilus/scripts/"Open in Ghostty"
nautilus -q
```

重新打开“文件”后，入口通常在：

```text
右键 -> Scripts -> Open in Ghostty
```

这个方法不会替换原来的“在终端打开”，只是额外增加一个菜单入口。

## 推荐做法

推荐使用系统级方式：

```bash
sudo apt-get install -y python3-nautilus
sudo apt-get remove -y nautilus-extension-gnome-terminal
nautilus -q
```

这样右键菜单会更干净，直接显示 Ghostty 的入口。
