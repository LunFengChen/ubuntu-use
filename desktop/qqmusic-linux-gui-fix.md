# QQMusic Linux 启动失败与白屏修复记录

记录本机 Ubuntu 上 QQMusic Linux 版启动失败、窗口白屏的排查和最终可用启动参数。

## 环境

```text
系统：Ubuntu 24.04.4 LTS / GNOME / Wayland
软件包：qqmusic 1.1.8 amd64
安装路径：/opt/qqmusic/qqmusic
系统启动项：/usr/share/applications/qqmusic.desktop
用户启动项：~/.local/share/applications/qqmusic.desktop
```

查看安装信息：

```bash
dpkg -s qqmusic
dpkg -L qqmusic | sed -n '1,80p'
cat /usr/share/applications/qqmusic.desktop
```

## 现象

直接启动：

```bash
/opt/qqmusic/qqmusic --enable-logging=stderr --v=1
```

会在启动过程中退出，关键日志：

```text
WARNING:gpu_process_host.cc(1166)] The GPU process has crashed
FATAL:gpu_data_manager_impl_private.cc(1034)] The display compositor is frequently crashing. Goodbye.
```

说明 QQMusic 自带的旧 Electron/Chromium 在当前图形环境下 GPU/合成器路径不兼容。

## 尝试过但不够的参数

下面参数可以避免立即崩溃或让窗口出现，但实际 GUI 可能全白：

```bash
/opt/qqmusic/qqmusic --disable-features=VizDisplayCompositor
```

如果再配合干净配置目录：

```bash
/opt/qqmusic/qqmusic \
  --user-data-dir="$HOME/.config/qqmusic-codex-fixed" \
  --disable-features=VizDisplayCompositor
```

可以看到窗口对象被创建，例如 `xwininfo` 能看到：

```text
"qqmusic" 1000x750
"歌词" 900x120
```

但这不代表 GUI 正常；本机实际表现为窗口全白。

## 最终可用方案

最小可用参数是禁用 GPU sandbox：

```bash
/opt/qqmusic/qqmusic --disable-gpu-sandbox
```

之前为了排查白屏，曾经配合新的持久用户数据目录启动：

```bash
/opt/qqmusic/qqmusic \
  --user-data-dir="$HOME/.config/qqmusic-codex-gpusandbox" \
  --disable-gpu-sandbox
```

这个组合也能让 GUI 正常渲染，但会把 Chromium/Electron 的登录态隔离到
`~/.config/qqmusic-codex-gpusandbox`，和 QQMusic 默认配置目录
`~/.config/qqmusic` 分开。实际使用时更推荐只保留 `--disable-gpu-sandbox`，
让 QQMusic 继续使用默认配置目录，避免出现每次都像新 profile 一样要求扫码登录。

`--disable-gpu-sandbox` 在本机表现为：

- 不再触发 `The display compositor is frequently crashing. Goodbye.`；
- QQMusic 主窗口能出现；
- GUI 内容能正常渲染，不再全白。

### 2026-06-30 复测结论

已经实测可用的最终启动方式：

```bash
/opt/qqmusic/qqmusic --disable-gpu-sandbox
```

不要再额外指定 `--user-data-dir="$HOME/.config/qqmusic-codex-gpusandbox"`。
原因是该参数会让 QQMusic 使用一个独立 profile，虽然 GUI 能打开，但登录态和默认
`~/.config/qqmusic` 分离，表现上容易像每次都要重新扫码登录。

当前用户级 desktop 启动项已改为：

```desktop
Exec=/opt/qqmusic/qqmusic --disable-gpu-sandbox %U
```

用户反馈：按该方式启动后 GUI 可显示，且扫码登录问题已解决。

## 写入用户级 desktop 启动项

不要直接改 `/usr/share/applications/qqmusic.desktop`，升级或重装包时容易被覆盖。使用用户级启动项覆盖即可：

```bash
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/qqmusic.desktop <<EOF_DESKTOP
[Desktop Entry]
Name=qqmusic
Exec=/opt/qqmusic/qqmusic --disable-gpu-sandbox %U
Terminal=false
Type=Application
Icon=qqmusic
StartupWMClass=qqmusic
Comment=Tencent QQMusic
Categories=AudioVideo;
EOF_DESKTOP

chmod 644 ~/.local/share/applications/qqmusic.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

验证当前菜单入口：

```bash
grep -nE '^(Name|Exec|Icon|Terminal|Categories)=' ~/.local/share/applications/qqmusic.desktop
```

模拟应用菜单启动：

```bash
gtk-launch qqmusic
```

## 回滚

删除用户级覆盖启动项后，会恢复使用系统包自带启动项：

```bash
rm -f ~/.local/share/applications/qqmusic.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

如果要清理本次新建的 QQMusic 配置目录：

```bash
rm -rf ~/.config/qqmusic-codex-gpusandbox
```

原始配置目录没有删除：

```text
~/.config/qqmusic
```

## 备注

排查时要区分三种状态：

1. 进程是否存活；
2. 窗口对象是否创建；
3. GUI 内容是否真正渲染。

这次 `--disable-features=VizDisplayCompositor` 能解决前两项，但会白屏；`--disable-gpu-sandbox` 才是本机实际可用的参数。
