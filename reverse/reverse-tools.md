# 逆向常用工具源码安装记录

记录本机从源码放到 `~/Desktop/projects` 的逆向工具、构建入口和桌面入口。

对应时间点：`2026-06-15`。

## 总览

| 工具 | 源码目录 | 构建/安装目录 | 用户入口 |
| --- | --- | --- | --- |
| Rizin | `~/Desktop/projects/rizin` | `~/Desktop/projects/rizin/install` | `~/.local/bin/rizin`, `~/.local/bin/rz-*` |
| Ghidra | `~/Desktop/projects/ghidra` | `~/Desktop/projects/ghidra/install/ghidra_12.2_DEV` | `~/.local/bin/ghidra` |
| Cutter | `~/Desktop/projects/cutter` | `~/Desktop/projects/cutter/install` | `~/.local/bin/cutter` |
| mitmproxy | `~/Desktop/projects/mitmproxy` | `uv tool` 用户态安装 | `~/.local/bin/mitmproxy`, `mitmdump`, `mitmweb` |
| Qt SDK for Cutter | `~/Desktop/projects/Qt/6.10.1/gcc_64` | 同左 | Cutter wrapper 内设置 `LD_LIBRARY_PATH` |

## Rizin

源码：

```text
~/Desktop/projects/rizin
```

构建方式：

```bash
cd ~/Desktop/projects/rizin
meson setup build --buildtype=release --prefix="$HOME/Desktop/projects/rizin/install"
meson compile -C build
meson install -C build
```

验证：

```bash
rizin -v
rz-bin -v
```

当前验证结果：

```text
rizin 0.9.0 @ linux-x86-64
commit: 832ed32cbb87b7cf4d729488c27de1e1130b5a95
```

## Ghidra

Ghidra 是有 GUI 的，GUI 启动脚本是发行目录里的 `ghidraRun`。

源码：

```text
~/Desktop/projects/ghidra
```

构建方式：

```bash
cd ~/Desktop/projects/ghidra
./gradlew --no-daemon -I gradle/support/fetchDependencies.gradle
./gradlew --no-daemon buildGhidra -x test
unzip build/dist/ghidra_12.2_DEV_20260615.zip -d install
```

当前 GUI 入口：

```text
~/Desktop/projects/ghidra/install/ghidra_12.2_DEV/ghidraRun
~/.local/bin/ghidra
~/.local/share/applications/ghidra.desktop
```

验证：

```bash
~/Desktop/projects/ghidra/install/ghidra_12.2_DEV/support/analyzeHeadless
```

会输出 `Headless Analyzer Usage: analyzeHeadless`。

## Cutter

Cutter 是基于 Rizin 的 Qt/C++ GUI。源码放在：

```text
~/Desktop/projects/cutter
```

本机没有免密 sudo，所以 Qt 用 `aqtinstall` 安装到了用户项目目录：

```text
~/Desktop/projects/Qt/6.10.1/gcc_64
```

构建时复用独立编译好的 Rizin：

```bash
cd ~/Desktop/projects/cutter
QT_PREFIX="$HOME/Desktop/projects/Qt/6.10.1/gcc_64"
RZ_PREFIX="$HOME/Desktop/projects/rizin/install"
export LD_LIBRARY_PATH="$QT_PREFIX/lib:$RZ_PREFIX/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$HOME/Desktop/projects/cutter/install" \
  -DCMAKE_PREFIX_PATH="$QT_PREFIX;$RZ_PREFIX" \
  -DQt6_DIR="$QT_PREFIX/lib/cmake/Qt6" \
  -DRizin_DIR="$RZ_PREFIX/lib/x86_64-linux-gnu/cmake/Rizin" \
  -DCUTTER_QT=6 \
  -DCUTTER_USE_BUNDLED_RIZIN=OFF \
  -DCUTTER_ENABLE_PYTHON=OFF \
  -DCUTTER_ENABLE_KSYNTAXHIGHLIGHTING=OFF \
  -DCUTTER_ENABLE_GRAPHVIZ=OFF
cmake --build build --parallel "$(nproc)"
cmake --install build
```

入口：

```text
~/.local/bin/cutter
~/.local/share/applications/cutter.desktop
```

当前验证结果：

```text
cutter 2.4.0-dev-12c119f
```

## mitmproxy

源码：

```text
~/Desktop/projects/mitmproxy
```

安装方式：

```bash
uv tool install --python 3.12.13 ~/Desktop/projects/mitmproxy --force
```

入口：

```text
~/.local/bin/mitmproxy
~/.local/bin/mitmdump
~/.local/bin/mitmweb
```

当前验证结果：

```text
Mitmproxy: 13.0.0.dev
Python:    3.12.13
```

### CA 证书

mitmproxy 第一次启动后生成 CA 文件在：

```text
~/.mitmproxy/mitmproxy-ca-cert.pem
~/.mitmproxy/mitmproxy-ca-cert.cer
~/.mitmproxy/mitmproxy-ca-cert.p12
~/.mitmproxy/mitmproxy-ca.pem      # 含私钥，注意不要外发
~/.mitmproxy/mitmproxy-ca.p12      # 含私钥，注意不要外发
```

已额外复制公开证书到易拿位置：

```text
~/Desktop/mitmproxy-ca-cert.pem
~/Desktop/mitmproxy-ca-cert.cer
~/Desktop/projects/mitmproxy/ca/mitmproxy-ca-cert.pem
~/Desktop/projects/mitmproxy/ca/mitmproxy-ca-cert.cer
~/Desktop/projects/mitmproxy/ca/mitmproxy-ca-cert.p12
```

通常给浏览器/手机导入用 `mitmproxy-ca-cert.pem` 或 `mitmproxy-ca-cert.cer`；不要复制 `mitmproxy-ca.pem`，它包含 CA 私钥。

## 参考

- Rizin: https://github.com/rizinorg/rizin
- Ghidra: https://github.com/NationalSecurityAgency/ghidra
- Cutter: https://github.com/rizinorg/cutter
- mitmproxy: https://github.com/mitmproxy/mitmproxy
