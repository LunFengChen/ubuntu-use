# Ubuntu 命令行、AppImage 与 desktop 启动项记录

本文记录 Ubuntu 下几个常见场景：

- 命令行运行程序的基本方式
- AppImage 如何使用
- 如何给 AppImage 制作应用菜单入口，也就是 `.desktop` 文件
- 如果自己发布程序，AppImage 大概怎么制作

## 命令行运行程序的基本概念

Linux 里命令行启动程序通常关注三件事：

1. 文件有没有执行权限
2. 当前命令是否能找到这个程序
3. 是否需要传递参数或指定工作目录

### 直接运行当前目录里的程序

如果程序就在当前目录，前面要加 `./`：

```bash
chmod +x ./app
./app
```

`chmod +x` 的意思是给文件增加可执行权限。

### 用绝对路径运行

```bash
/home/xiaofeng/Applications/cc-switch/cc-switch.AppImage
```

这种方式最稳定，适合写进 `.desktop` 的 `Exec=` 字段。

### 放到 PATH 后运行

如果希望在任意目录都能直接输入命令，可以把程序或软链接放到 `~/.local/bin`：

```bash
mkdir -p ~/.local/bin
ln -sfn /home/xiaofeng/Applications/cc-switch/cc-switch.AppImage ~/.local/bin/cc-switch
chmod +x /home/xiaofeng/Applications/cc-switch/cc-switch.AppImage
```

之后终端里可以直接执行：

```bash
cc-switch
```

如果提示 `command not found`，确认 `~/.local/bin` 是否在 PATH 里：

```bash
echo "$PATH" | tr ':' '\n' | grep -x "$HOME/.local/bin"
```

没有的话，可以写入 `~/.bashrc`：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## AppImage 怎么使用

AppImage 可以理解为 Linux 下的“单文件绿色应用”。常见使用方式：

```bash
chmod +x xxx.AppImage
./xxx.AppImage
```

例如：

```bash
cd /home/xiaofeng/Applications/cc-switch
chmod +x cc-switch*.AppImage
./cc-switch*.AppImage
```

### FUSE 缺失问题

有些系统直接运行 AppImage 时会提示 FUSE 相关错误，可以安装兼容库：

```bash
sudo apt update
sudo apt install libfuse2
```

在较新的 Ubuntu 版本上，如果没有 `libfuse2` 包，可以尝试：

```bash
sudo apt install libfuse2t64
```

### 解包查看 AppImage 内容

AppImage 可以临时解包：

```bash
./xxx.AppImage --appimage-extract
```

会生成：

```text
squashfs-root/
```

里面通常能找到图标、desktop 文件、二进制和资源文件。

## 给 AppImage 制作 desktop 启动项

`.desktop` 文件是 Linux 桌面环境识别应用菜单入口的配置文件。个人用户的启动项通常放在：

```text
~/.local/share/applications/
```

### 以 cc-switch 为例

假设 AppImage 在：

```text
/home/xiaofeng/Applications/cc-switch/cc-switch.AppImage
```

创建启动项：

```bash
mkdir -p ~/.local/share/applications
nano ~/.local/share/applications/cc-switch.desktop
```

内容示例：

```ini
[Desktop Entry]
Type=Application
Name=CC Switch
Comment=Claude Code Switcher
Exec=/home/xiaofeng/Applications/cc-switch/cc-switch.AppImage
Icon=/home/xiaofeng/Applications/cc-switch/icon.png
Terminal=false
Categories=Utility;Development;
StartupNotify=true
```

保存后执行：

```bash
chmod +x ~/.local/share/applications/cc-switch.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

然后按 `Super`，搜索 `CC Switch`。

### `.desktop` 常用字段说明

```ini
Type=Application                         # 类型：应用程序
Name=CC Switch                           # 菜单里显示的名字
Comment=Claude Code Switcher             # 简短说明
Exec=/absolute/path/to/app.AppImage       # 启动命令，推荐绝对路径
Icon=/absolute/path/to/icon.png           # 图标路径，也推荐绝对路径
Terminal=false                           # 是否在终端里打开
Categories=Utility;Development;          # 应用分类，分号结尾
StartupNotify=true                       # 启动时显示反馈
```

如果程序需要参数，可以写在 `Exec=` 后面，例如：

```ini
Exec=/home/xiaofeng/Applications/demo/demo.AppImage --debug
```

如果应用支持打开文件，可以使用 `%f` 或 `%u`：

```ini
Exec=/home/xiaofeng/Applications/demo/demo.AppImage %f
```

## 从 AppImage 里提取图标

如果没有单独的图标，可以从 AppImage 解包后找：

```bash
cd /home/xiaofeng/Applications/cc-switch
./cc-switch.AppImage --appimage-extract
find squashfs-root -iname '*.png' -o -iname '*.svg' -o -iname '*.desktop'
```

常见图标位置：

```text
squashfs-root/usr/share/icons/hicolor/256x256/apps/
squashfs-root/usr/share/pixmaps/
```

复制出来：

```bash
cp squashfs-root/usr/share/icons/hicolor/256x256/apps/*.png ./icon.png
```

然后在 desktop 文件里写：

```ini
Icon=/home/xiaofeng/Applications/cc-switch/icon.png
```

## 一条命令生成 desktop 文件

如果不想手动打开编辑器，也可以用 heredoc：

```bash
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/cc-switch.desktop <<'EOF_DESKTOP'
[Desktop Entry]
Type=Application
Name=CC Switch
Comment=Claude Code Switcher
Exec=/home/xiaofeng/Applications/cc-switch/cc-switch.AppImage
Icon=/home/xiaofeng/Applications/cc-switch/icon.png
Terminal=false
Categories=Utility;Development;
StartupNotify=true
EOF_DESKTOP

chmod +x ~/.local/share/applications/cc-switch.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

验证：

```bash
grep -nE '^(Name|Exec|Icon|Terminal|Categories)=' ~/.local/share/applications/cc-switch.desktop
```

## 桌面图标和应用菜单的区别

应用菜单入口：

```text
~/.local/share/applications/cc-switch.desktop
```

桌面上的快捷方式：

```text
~/Desktop/cc-switch.desktop
```

可以复制一份到桌面：

```bash
cp ~/.local/share/applications/cc-switch.desktop ~/Desktop/
chmod +x ~/Desktop/cc-switch.desktop
```

GNOME 桌面可能还需要右键桌面图标，选择“允许启动”或“Allow Launching”。

## 如果自己发布程序，AppImage 怎么制作

制作 AppImage 的核心思路：

1. 准备一个 `AppDir` 目录
2. 把可执行文件、图标、desktop 文件放进去
3. 用 `appimagetool` 打包成 `.AppImage`

下面是一个最小示例。

### 目录结构

```text
MyApp.AppDir/
├── AppRun
├── myapp.desktop
├── myapp.png
└── usr/
    └── bin/
        └── myapp
```

### 准备 AppDir

```bash
mkdir -p MyApp.AppDir/usr/bin
cp ./myapp MyApp.AppDir/usr/bin/myapp
chmod +x MyApp.AppDir/usr/bin/myapp
```

创建 `AppRun`：

```bash
cat > MyApp.AppDir/AppRun <<'EOF_APPRUN'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/myapp" "$@"
EOF_APPRUN
chmod +x MyApp.AppDir/AppRun
```

创建 `myapp.desktop`：

```bash
cat > MyApp.AppDir/myapp.desktop <<'EOF_DESKTOP'
[Desktop Entry]
Type=Application
Name=MyApp
Exec=myapp
Icon=myapp
Terminal=false
Categories=Utility;
EOF_DESKTOP
```

准备图标：

```bash
cp ./myapp.png MyApp.AppDir/myapp.png
```

### 使用 appimagetool 打包

下载或准备 `appimagetool` 后：

```bash
chmod +x appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage MyApp.AppDir
```

生成的文件类似：

```text
MyApp-x86_64.AppImage
```

测试：

```bash
chmod +x MyApp-x86_64.AppImage
./MyApp-x86_64.AppImage
```

## 实践建议

- AppImage 本体建议放在 `~/Applications/应用名/` 或 `~/.local/opt/应用名/`。
- 命令行入口建议用 `~/.local/bin/应用名` 软链接。
- 桌面入口建议放在 `~/.local/share/applications/应用名.desktop`。
- `Exec=` 和 `Icon=` 尽量使用绝对路径。
- AppImage 升级时，尽量保持软链接名字不变，这样 `.desktop` 不需要反复修改。

推荐最终结构：

```text
/home/xiaofeng/Applications/cc-switch/
├── cc-switch.AppImage
└── icon.png

/home/xiaofeng/.local/bin/cc-switch -> /home/xiaofeng/Applications/cc-switch/cc-switch.AppImage
/home/xiaofeng/.local/share/applications/cc-switch.desktop
```
