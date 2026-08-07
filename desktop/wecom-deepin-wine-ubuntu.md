# 企业微信 deepin-wine 在 Ubuntu 24.04 下安装与启动修复记录

记录本机 Ubuntu 24.04 上安装企业微信 deepin-wine 版时遇到的依赖、菜单入口、首次启动解压和 pyenv Python 环境问题。

## 环境

```text
系统：Ubuntu 24.04.4 LTS / GNOME / Wayland
架构：amd64
企业微信包：com.qq.weixin.work.deepin 5.0.7.6005deepin3
deepin-wine：deepin-wine10-stable 10.14deepin8
deepin-wine-helper：5.4.10-1
安装源：https://deepin-wine.i-m.dev/
```

查看状态：

```bash
dpkg-query -W -f='${db:Status-Abbrev} ${Package} ${Version}\n' \
  com.qq.weixin.work.deepin \
  deepin-wine10-stable \
  deepin-wine-helper \
  libsane
```

本机安装完成后结果类似：

```text
ii  com.qq.weixin.work.deepin 5.0.7.6005deepin3
ii  deepin-wine-helper 5.4.10-1
ii  deepin-wine10-stable 10.14deepin8
ii  libsane 1.2.1-7build4+compat1
```

## 安装源配置

deepin-wine 源配置：

```bash
sudo dpkg --add-architecture i386
sudo apt-get update

sudo tee /etc/apt/sources.list.d/deepin-wine.i-m.dev.list >/dev/null <<'EOF_LIST'
deb [trusted=yes] https://deepin-wine.i-m.dev /
EOF_LIST

sudo tee /etc/apt/preferences.d/deepin-wine.i-m.dev.pref >/dev/null <<'EOF_PREF'
Package: *
Pin: release l=deepin-wine
Pin-Priority: 400
EOF_PREF

sudo apt-get update --no-list-cleanup \
  -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/deepin-wine.i-m.dev.list \
  -o Dir::Etc::sourceparts=-
```

正常安装命令：

```bash
sudo apt-get install -y com.qq.weixin.work.deepin
```

## 问题 1：Ubuntu 24.04 下 `libsane` 依赖无法解析

现象：

```text
deepin-wine10-stable : Depends: libsane (>= 1.0.24)
E: Unable to correct problems, you have held broken packages.
```

原因：Ubuntu 24.04 使用的是 `libsane1`，而 deepin-wine 包依赖里写的是旧包名 `libsane`。

处理方式：安装系统实际库 `libsane1`，再做一个本机兼容空包 `libsane`，让依赖解析通过。

```bash
sudo apt-get install -y libsane1 libosmesa6 fonts-wqy-microhei

rm -rf /tmp/libsane-compat
mkdir -p /tmp/libsane-compat/DEBIAN

cat >/tmp/libsane-compat/DEBIAN/control <<'EOF_CONTROL'
Package: libsane
Version: 1.2.1-7build4+compat1
Section: libs
Priority: optional
Architecture: amd64
Depends: libsane1 (>= 1.2.1)
Maintainer: local <root@localhost>
Description: compatibility package for deepin-wine on Ubuntu 24.04
 Empty compatibility package. Ubuntu Noble provides the SANE library as libsane1.
EOF_CONTROL

dpkg-deb --build /tmp/libsane-compat /tmp/libsane_1.2.1-7build4+compat1_amd64.deb
sudo dpkg -i /tmp/libsane_1.2.1-7build4+compat1_amd64.deb

sudo apt-get install -y --no-install-recommends com.qq.weixin.work.deepin
```

## 问题 2：应用菜单里看不到企业微信

deepin-wine 包的 desktop 文件在：

```text
/opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop
```

当前 GNOME 会话的 `XDG_DATA_DIRS` 可能没有包含 `/opt/apps/.../entries`，所以应用菜单暂时搜不到。

处理方式：复制到用户级菜单目录。

```bash
mkdir -p ~/.local/share/applications
cp /opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop \
  ~/.local/share/applications/
chmod +x ~/.local/share/applications/com.qq.weixin.work.deepin.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

验证：

```bash
grep -nE '^(Name|Exec|Icon|Categories)=' \
  ~/.local/share/applications/com.qq.weixin.work.deepin.desktop
```

如果菜单仍不刷新，注销后重新登录。

## 问题 3：首次启动解压 Wine 容器失败

首次启动时 deepin-wine 会把：

```text
/opt/apps/com.qq.weixin.work.deepin/files/files.7z
```

解压到：

```text
~/.deepinwine/Deepin-WXWork
```

本机 Ubuntu 24.04 上 7-Zip 23.01 会拦截压缩包里的 Windows/Wine 软链接，日志里出现大量：

```text
ERROR: Dangerous link path was ignored
ERROR: Dangerous symbolic link path was ignored
解压失败
```

处理方式：手动用 `-snl-` 解压，禁用“按符号链接恢复”的行为，让 Wine 容器能完整落地。

```bash
PREFIX="$HOME/.deepinwine/Deepin-WXWork"
APPDIR="/opt/apps/com.qq.weixin.work.deepin/files"

rm -rf "$PREFIX"
mkdir -p "$PREFIX"
7z x -snl- "$APPDIR/files.7z" -o"$PREFIX"

if [ -d "$PREFIX/drive_c/users/@current_user@" ]; then
  mv "$PREFIX/drive_c/users/@current_user@" "$PREFIX/drive_c/users/$USER"
fi

if compgen -G "$PREFIX/*.reg" >/dev/null; then
  sed -i "s#@current_user@#$USER#g" "$PREFIX"/*.reg
fi

if [ -f "$APPDIR/files.md5sum" ]; then
  cat "$APPDIR/files.md5sum" > "$PREFIX/PACKAGE_VERSION"
else
  echo "5.0.7.6005deepin3" > "$PREFIX/PACKAGE_VERSION"
fi

mkdir -p "$PREFIX/dosdevices"
ln -sfn ../drive_c "$PREFIX/dosdevices/c:"
ln -sfn / "$PREFIX/dosdevices/z:"
ln -sfn "$HOME" "$PREFIX/dosdevices/y:"

mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents"
mkdir -p "$PREFIX/drive_c/users/$USER"
ln -sfn "$HOME/Desktop" "$PREFIX/drive_c/users/$USER/Desktop"
ln -sfn "$HOME/Downloads" "$PREFIX/drive_c/users/$USER/Downloads"
ln -sfn "$HOME/Documents" "$PREFIX/drive_c/users/$USER/My Documents"
```

验证主程序已存在：

```bash
ls -l "$HOME/.deepinwine/Deepin-WXWork/drive_c/Program Files (x86)/WXWork/WXWork.exe"
```

## 问题 4：pyenv 覆盖 `python3` 导致 deepin-wine 脚本找不到 dbus

日志：

```text
ModuleNotFoundError: No module named 'dbus'
```

本机原因：`/usr/bin/env python3` 解析到了 pyenv 的 Python 3.14，而不是系统 Python；系统实际已安装 `python3-dbus`。

验证：

```bash
which python3
/usr/bin/python3 -c 'import dbus; print(dbus.__file__)'
```

处理方式：给企业微信单独写一个用户级启动脚本，把系统路径放在前面。

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/wecom-deepin-wine <<'EOF_RUN'
#!/bin/sh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH
export WINEPREFIX="$HOME/.deepinwine/Deepin-WXWork"
export WINEDLLPATH=/opt/deepin-wine10-stable/lib:/opt/deepin-wine10-stable/lib64
export WINEPREDLL=/opt/apps/com.qq.weixin.work.deepin/files/dlls
export WINEDEBUG=-all
exec deepin-wine10-stable 'c:/Program Files (x86)/WXWork/WXWork.exe'
EOF_RUN

chmod +x ~/.local/bin/wecom-deepin-wine
```

然后把 desktop 启动项改为这个脚本：

```bash
python3 - <<'PY'
from pathlib import Path
p = Path.home() / '.local/share/applications/com.qq.weixin.work.deepin.desktop'
s = p.read_text()
s = s.replace(
    'Exec="/opt/apps/com.qq.weixin.work.deepin/files/run.sh" -f %f',
    f'Exec={Path.home()}/.local/bin/wecom-deepin-wine -f %f',
)
p.write_text(s)
PY

update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

## GNOME 下 deepin 托盘检测问题

在 GNOME 上，deepin-wine 的 `/opt/deepinwine/tools/run_v4.sh` 还会尝试访问 deepin 桌面的托盘服务：

```text
com.deepin.dde.TrayManager
```

Ubuntu GNOME 没有这个服务，日志里可能出现：

```text
org.freedesktop.DBus.Error.ServiceUnknown: The name com.deepin.dde.TrayManager was not provided by any .service files
```

因此本机最终更倾向于直接调用 `deepin-wine10-stable` 启动 `WXWork.exe`，避开 deepin 启动外壳里的托盘检测逻辑。

## 问题 5：应用菜单 / Dock 图标显示异常

现象：企业微信能运行，但 GNOME 应用菜单、桌面快捷方式或 Dock 里可能显示默认图标，或没有图标。

### 先区分两类图标

截图里企业微信窗口左上角的图片属于企业微信应用内部的头像/账号区域；这不一定是系统菜单或 Dock 图标。系统侧图标主要看下面两项：

```text
~/.local/share/applications/com.qq.weixin.work.deepin.desktop 里的 Icon=
窗口 WM_CLASS / StartupWMClass 匹配关系
```

### 复制包内图标到用户图标目录

deepin-wine 包自带图标位置：

```text
/opt/apps/com.qq.weixin.work.deepin/entries/icons/hicolor/48x48/apps/com.qq.weixin.work.deepin.svg
```

GNOME 当前会话不一定会扫描 `/opt/apps/*/entries/icons`，所以复制到用户图标主题目录，并使用绝对路径最稳定：

```bash
SRC=/opt/apps/com.qq.weixin.work.deepin/entries/icons/hicolor/48x48/apps/com.qq.weixin.work.deepin.svg
LOCAL_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
LOCAL_ICON="$LOCAL_ICON_DIR/com.qq.weixin.work.deepin.svg"
DESKTOP="$HOME/.local/share/applications/com.qq.weixin.work.deepin.desktop"

mkdir -p "$LOCAL_ICON_DIR" "$HOME/.local/share/pixmaps" "$HOME/.local/share/applications"
cp "$SRC" "$LOCAL_ICON"
cp "$SRC" "$HOME/.local/share/pixmaps/com.qq.weixin.work.deepin.svg"
```

把 desktop 文件里的 `Icon=` 改成绝对路径：

```bash
python3 - <<'PY_ICON'
from pathlib import Path
home = Path.home()
desktop = home / '.local/share/applications/com.qq.weixin.work.deepin.desktop'
icon = home / '.local/share/icons/hicolor/scalable/apps/com.qq.weixin.work.deepin.svg'
s = desktop.read_text()
lines = []
for line in s.splitlines():
    if line.startswith('Icon='):
        lines.append(f'Icon={icon}')
    else:
        lines.append(line)
desktop.write_text('\n'.join(lines) + '\n')
PY_ICON

update-desktop-database ~/.local/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true
```

验证：

```bash
grep -nE '^(Name|Icon|Exec|StartupWMClass)=' \
  ~/.local/share/applications/com.qq.weixin.work.deepin.desktop

ls -l \
  ~/.local/share/icons/hicolor/scalable/apps/com.qq.weixin.work.deepin.svg \
  ~/.local/share/pixmaps/com.qq.weixin.work.deepin.svg
```

本机修复后关键字段：

```text
Icon=/home/xiaofeng/.local/share/icons/hicolor/scalable/apps/com.qq.weixin.work.deepin.svg
Exec=/home/xiaofeng/.local/bin/wecom-deepin-wine -f %f
Name=企业微信
StartupWMClass=com.qq.weixin.work.deepin
```

### 增加桌面快捷方式

如果 GNOME 应用菜单暂时没刷新，可以先放一份到桌面：

```bash
cp ~/.local/share/applications/com.qq.weixin.work.deepin.desktop ~/Desktop/企业微信.desktop
chmod +x ~/Desktop/企业微信.desktop
gio set ~/Desktop/企业微信.desktop metadata::trusted true 2>/dev/null || true
xdg-desktop-menu forceupdate --mode user 2>/dev/null || true
```

GNOME 桌面图标扩展有时还需要右键快捷方式，选择“允许启动”。

### Dock / 任务栏图标匹配

直接绕过 deepin 外壳启动时，要给 Wine 窗口设置稳定的 WM_CLASS，否则 Dock 里可能仍然显示默认图标。

`~/.local/bin/wecom-deepin-wine` 中加入：

```bash
export WINE_WMCLASS=com.qq.weixin.work.deepin
```

当前本机启动脚本：

```bash
#!/bin/sh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH
export WINEPREFIX="$HOME/.deepinwine/Deepin-WXWork"
export WINEDLLPATH=/opt/deepin-wine10-stable/lib:/opt/deepin-wine10-stable/lib64
export WINEPREDLL=/opt/apps/com.qq.weixin.work.deepin/files/dlls
export WINEDEBUG=-all
export WINE_WMCLASS=com.qq.weixin.work.deepin

# Fcitx5 IME for deepin-wine/WXWork
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8

cd "$WINEPREFIX/drive_c/Program Files (x86)/WXWork" || exit 1
exec deepin-wine10-stable 'c:/Program Files (x86)/WXWork/WXWork.exe'
```

如果图标仍不刷新，注销后重新登录即可刷新 GNOME Shell / Dock 图标缓存。


## 问题 6：托盘右键关不掉 / 需要强制关闭

现象：企业微信 deepin-wine 版在 GNOME / Wayland 下托盘菜单可能不响应，右键退出关不掉。

先查相关进程：

```bash
pgrep -af 'WXWork|WXWorkWeb|WeMail|FlutterPlugins|WXDrive|WeWorkCrashHandler|wemeet|deepin-wine10-stable|wineserver'
```

只关企业微信相关进程，不影响其它 Wine 应用：

```bash
python3 - <<'PY_KILL_WECOM'
import os, signal, time
names = [
    'WX' + 'Work.exe',
    'WX' + 'WorkWeb.exe',
    'We' + 'Mail.exe',
    'Flutter' + 'Plugins.exe',
    'WX' + 'Drive_x64.exe',
    'We' + 'WorkCrashHandler.exe',
    'wemeet' + '.dll',
]
self = os.getpid()
parent = os.getppid()

def matches():
    out = []
    for pid_s in os.listdir('/proc'):
        if not pid_s.isdigit():
            continue
        pid = int(pid_s)
        if pid in (self, parent):
            continue
        try:
            cmd = open(f'/proc/{pid}/cmdline', 'rb').read().replace(b'\0', b' ').decode('utf-8', 'ignore')
        except Exception:
            continue
        if any(name in cmd for name in names):
            out.append(pid)
    return out

for sig in (signal.SIGTERM, signal.SIGKILL):
    for pid in matches():
        try:
            os.kill(pid, sig)
        except ProcessLookupError:
            pass
        except PermissionError:
            print('permission denied:', pid)
    time.sleep(1.5)
PY_KILL_WECOM
```

如果明确当前 Wine 容器只跑企业微信，也可以直接杀容器：

```bash
WINEPREFIX="$HOME/.deepinwine/Deepin-WXWork" wineserver -k
```

重新启动：

```bash
gtk-launch com.qq.weixin.work.deepin
# 或
~/.local/bin/wecom-deepin-wine
```

## 问题 7：deepin-wine 企业微信打不了中文

现象：系统里 `fcitx5` 正常，别的软件可以输入中文，但 deepin-wine 企业微信输入框只能打英文。

本机排查结果：

```text
fcitx5 已运行，但当前 shell/图形会话环境仍有：
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
GTK_IM_MODULE 为空

企业微信 deepin-wine 进程需要显式注入 fcitx 环境变量。
```

先确认输入法与企业微信进程：

```bash
pgrep -af 'fcitx|ibus'
pgrep -af 'WXWork|WXWorkWeb|WeMail|deepin-wine|wine'
```

确认系统有 `fcitx5` 拼音组件：

```bash
dpkg -l | grep -Ei '^ii\s+(fcitx5|fcitx5-chinese-addons|fcitx5-frontend|im-config)'
```

本机已安装的关键包包括：

```text
fcitx5
fcitx5-chinese-addons
fcitx5-frontend-all
fcitx5-frontend-gtk3
fcitx5-frontend-gtk4
fcitx5-frontend-qt5
fcitx5-frontend-qt6
im-config
```

### 给企业微信启动脚本注入 fcitx5

编辑 `~/.local/bin/wecom-deepin-wine`，在 `exec deepin-wine10-stable ...` 前加入：

```bash
# Fcitx5 IME for deepin-wine/WXWork
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
```

当前完整启动脚本：

```bash
#!/bin/sh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH
export WINEPREFIX="$HOME/.deepinwine/Deepin-WXWork"
export WINEDLLPATH=/opt/deepin-wine10-stable/lib:/opt/deepin-wine10-stable/lib64
export WINEPREDLL=/opt/apps/com.qq.weixin.work.deepin/files/dlls
export WINEDEBUG=-all
export WINE_WMCLASS=com.qq.weixin.work.deepin

# Fcitx5 IME for deepin-wine/WXWork
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8

cd "$WINEPREFIX/drive_c/Program Files (x86)/WXWork" || exit 1
exec deepin-wine10-stable 'c:/Program Files (x86)/WXWork/WXWork.exe'
```

确保可执行：

```bash
chmod +x ~/.local/bin/wecom-deepin-wine
```

### 写入桌面会话级永久环境

Ubuntu GNOME / Wayland 下，单个终端环境修好不代表应用菜单启动的图形程序也能继承，所以同时写入用户级环境文件：

```bash
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/90-fcitx5.conf <<'EOF_FCITX_ENV'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx5
EOF_FCITX_ENV

cat > ~/.xprofile <<'EOF_XPROFILE'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export INPUT_METHOD=fcitx5
EOF_XPROFILE
```

把变量导入当前用户会话，并重启 `fcitx5`：

```bash
export GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx SDL_IM_MODULE=fcitx INPUT_METHOD=fcitx5

dbus-update-activation-environment --systemd \
  GTK_IM_MODULE QT_IM_MODULE XMODIFIERS SDL_IM_MODULE INPUT_METHOD || true

systemctl --user import-environment \
  GTK_IM_MODULE QT_IM_MODULE XMODIFIERS SDL_IM_MODULE INPUT_METHOD || true

pkill -TERM -x fcitx5 2>/dev/null || true
sleep 1
pkill -KILL -x fcitx5 2>/dev/null || true

env \
  GTK_IM_MODULE=fcitx \
  QT_IM_MODULE=fcitx \
  XMODIFIERS=@im=fcitx \
  SDL_IM_MODULE=fcitx \
  INPUT_METHOD=fcitx5 \
  fcitx5 -d --replace
```

验证 XIM 已经有 fcitx：

```bash
xprop -root XIM_SERVERS
fcitx5-remote
```

本机修复后类似：

```text
XIM_SERVERS(ATOM) = @server=fcitx, @server=ibus
```

### 重启企业微信并验证进程环境

先关掉旧企业微信进程，再从菜单入口重新启动：

```bash
python3 - <<'PY_KILL_WECOM'
import os, signal, time
names = ['WX' + 'Work.exe', 'WX' + 'WorkWeb.exe', 'We' + 'Mail.exe']
self = os.getpid()
parent = os.getppid()

def matches():
    for pid_s in os.listdir('/proc'):
        if not pid_s.isdigit():
            continue
        pid = int(pid_s)
        if pid in (self, parent):
            continue
        try:
            cmd = open(f'/proc/{pid}/cmdline', 'rb').read().replace(b'\0', b' ').decode('utf-8', 'ignore')
        except Exception:
            continue
        if any(name in cmd for name in names):
            yield pid

for sig in (signal.SIGTERM, signal.SIGKILL):
    for pid in list(matches()):
        try:
            os.kill(pid, sig)
        except Exception:
            pass
    time.sleep(1.5)
PY_KILL_WECOM

gtk-launch com.qq.weixin.work.deepin
```

验证企业微信主进程已经拿到 fcitx 环境：

```bash
python3 - <<'PY_CHECK_WECOM_IME'
import os
main = None
for pid_s in os.listdir('/proc'):
    if not pid_s.isdigit():
        continue
    try:
        cmd = open(f'/proc/{pid_s}/cmdline', 'rb').read().replace(b'\0', b' ').decode('utf-8', 'ignore')
    except Exception:
        continue
    if 'WX' + 'Work.exe' in cmd and 'Program Files' in cmd and 'bugly' not in cmd:
        main = pid_s
if main:
    print('mainpid', main)
    env = open(f'/proc/{main}/environ', 'rb').read().replace(b'\0', b'\n').decode('utf-8', 'ignore')
    for line in env.splitlines():
        if any(k in line for k in ['GTK_IM_MODULE', 'QT_IM_MODULE', 'XMODIFIERS', 'SDL_IM_MODULE', 'LANG=', 'LC_CTYPE', 'WINEPREFIX']):
            print(line)
PY_CHECK_WECOM_IME
```

修复后应看到：

```text
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
LANG=zh_CN.UTF-8
LC_CTYPE=zh_CN.UTF-8
```

然后在企业微信输入框里按 `Ctrl + Space` 或 `Ctrl + Shift` 切到拼音即可输入中文。

如果仍然只出英文，注销当前 GNOME 会话再登录一次，让 `~/.config/environment.d/90-fcitx5.conf` 生效到整个图形会话。

## 当前启动方式

应用菜单入口：

```text
~/.local/share/applications/com.qq.weixin.work.deepin.desktop
```

命令行入口：

```bash
~/.local/bin/wecom-deepin-wine
```

排查时可以用带日志的直接启动命令：

```bash
env \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH \
  WINEPREFIX="$HOME/.deepinwine/Deepin-WXWork" \
  WINEDLLPATH=/opt/deepin-wine10-stable/lib:/opt/deepin-wine10-stable/lib64 \
  WINEPREDLL=/opt/apps/com.qq.weixin.work.deepin/files/dlls \
  WINEDEBUG=err+all,warn+all \
  deepin-wine10-stable 'c:/Program Files (x86)/WXWork/WXWork.exe'
```

注意：上面的 `WINEDEBUG=err+all,warn+all` 日志量很大，只适合排查，不适合长期作为菜单启动参数。

## 回滚

删除用户级启动入口：

```bash
rm -f ~/.local/bin/wecom-deepin-wine
rm -f ~/.local/share/applications/com.qq.weixin.work.deepin.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

删除企业微信 Wine 容器：

```bash
rm -rf ~/.deepinwine/Deepin-WXWork
```

卸载企业微信包：

```bash
sudo apt-get remove com.qq.weixin.work.deepin
```

如果不再需要 deepin-wine 源：

```bash
sudo rm -f /etc/apt/sources.list.d/deepin-wine.i-m.dev.list
sudo rm -f /etc/apt/preferences.d/deepin-wine.i-m.dev.pref
sudo apt-get update
```

## 经验总结

- Ubuntu 24.04 的包名变化会让旧 deepin-wine 依赖卡在 `libsane`；本机用兼容空包解决。
- pyenv 会影响 `/usr/bin/env python3`，deepin-wine 脚本需要系统 Python 的 `dbus` 模块时要特别注意 PATH。
- GNOME 菜单不一定读取 `/opt/apps/*/entries`，用户级 `.desktop` 最稳定。
- 7-Zip 23.01 对绝对软链接更严格，deepin-wine 容器首次解压失败时可用 `7z x -snl-` 手动重建。
- Ubuntu GNOME 没有 deepin 托盘服务，直接 Wine 启动比 deepin 外壳脚本更少受桌面环境影响。
