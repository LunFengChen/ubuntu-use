# Binary Ninja 在 Ubuntu 下的安装、多版本共存、桌面入口与插件处理

相关仓库：

```text
https://github.com/LunFengChen/ubuntu-use
https://github.com/LunFengChen/ninja-jni-helper
https://github.com/LunFengChen/ninja-goto-offset
https://github.com/LunFengChen/binary_ninja_mcp
```

## 目标

这篇文章记录我在 Ubuntu 桌面环境下对 Binary Ninja 的一套稳定处理方案：

- 保留旧版本，不覆盖安装。
- 默认命令行永远指向最新版本。
- 桌面里同时保留“默认入口”和“指定版本入口”。
- `license.dat`、插件、设置走用户目录，不随版本目录散落。
- 安装我自己开源的两个 Binary Ninja 插件。

本文对应本机一次实际整理结果，时间点是 `2026-06-13`。


## 安装来源说明

Binary Ninja 建议使用自己账号可用的官方安装包，或团队内部已经授权的归档包。

这篇文章只记录本机的目录组织、版本切换、桌面入口、插件和 MCP 配置方式；公开仓库里不记录私有下载链接、授权文件或临时脚本。安装包准备好之后，后续步骤都一样。


## 当前机器的结果

当前机器上：

- 旧版本保留：`5.2.8722`
- 新版本安装：`5.3.9434`
- 默认版本：`5.3.9434`

核心目录结构：

```text
~/.local/opt/binaryninja-5.2.8722          # 旧版本 5.2.8722
~/.local/opt/binaryninja -> ~/.local/opt/binaryninja-5.2.8722
~/.local/opt/binaryninja-5.3.9434          # 新版本 5.3.9434
~/.local/opt/binaryninja-current -> ~/.local/opt/binaryninja-5.3.9434

~/.local/bin/binaryninja -> ~/.local/opt/binaryninja-current/binaryninja
~/.local/bin/binaryninja-5.2.8722 -> ~/.local/opt/binaryninja-5.2.8722/binaryninja
~/.local/bin/binaryninja-5.3.9434 -> ~/.local/opt/binaryninja-5.3.9434/binaryninja

~/.binaryninja/license.dat
~/.binaryninja/lastrun
~/.binaryninja/plugins/

~/.local/share/applications/com.vector35.binaryninja.desktop
~/.local/share/applications/com.vector35.binaryninja-5.2.8722.desktop
~/.local/share/applications/com.vector35.binaryninja-5.3.9434.desktop
```

这里有一个小取舍：

- 旧版本真实目录已经规范成 `~/.local/opt/binaryninja-5.2.8722`
- `~/.local/opt/binaryninja` 只保留为兼容软链接，指向 `binaryninja-5.2.8722`

也就是说，这台机器当前是：

- `binaryninja-5.2.8722` = 旧版本真实目录
- `binaryninja` = 兼容软链接
- `binaryninja-current` = 当前默认版本软链接

## 为什么不要直接覆盖安装

Linux 下 Binary Ninja 本质上就是解压运行。

因此最稳的做法不是“把新包覆盖旧目录”，而是：

- 每个版本单独一个目录
- 默认版本靠软链接切换
- 用户数据全部放在 `~/.binaryninja`

这样做的好处：

- 回滚简单
- 默认入口清晰
- 不容易把旧插件、旧配置、旧桌面入口弄乱

## 默认版本如何切到最新

默认版本不是靠“哪个目录叫 binaryninja”决定的，而是靠下面两个软链接：

```text
~/.local/opt/binaryninja-current
~/.local/bin/binaryninja
```

当前设计：

```text
binaryninja-current -> 实际想作为默认版本的安装目录
binaryninja -> binaryninja-current/binaryninja
```

这样以后升级只要改一处：

```bash
ln -sfn ~/.local/opt/binaryninja-5.3.9434 ~/.local/opt/binaryninja-current
ln -sfn ~/.local/opt/binaryninja-current/binaryninja ~/.local/bin/binaryninja
```

终端里直接：

```bash
binaryninja
```

就始终走最新默认版本。

## Python API 默认版本怎么切

Binary Ninja 的 Python API 路径由 `binaryninja.pth` 控制。

本机把它切到了 `binaryninja-current`：

```text
~/.local/lib/python3.14/site-packages/binaryninja.pth
```

内容类似：

```text
/home/xiaofeng/.local/opt/binaryninja-current/python
/home/xiaofeng/.local/opt/binaryninja-current/python3
```

切换方式：

```bash
python3 ~/.local/opt/binaryninja-current/scripts/install_api.py -s -f
```

这一步做完后，Python 默认也会跟着最新版本走。

## `license.dat` 应该放哪

Linux 下推荐位置是用户目录：

```text
~/.binaryninja/license.dat
```

结论：

- `license.dat` 不需要每个安装目录都复制一份
- 新装 5.3 时，不需要再同步到 `~/.local/opt/binaryninja-5.3.9434`
- 只要 `~/.binaryninja/license.dat` 在，默认用户目录就能复用

也就是说，版本目录负责：

- 可执行文件
- 库
- 内置资源

用户目录负责：

- license
- settings
- plugins
- repositories
- signatures
- lastrun

## `lastrun` 的作用

当前：

```text
~/.binaryninja/lastrun
```

内容被写成：

```text
/home/xiaofeng/.local/opt/binaryninja-current
```

这样插件或某些组件在 Linux 非标准安装路径下定位 Binary Ninja 时，更容易跟到当前默认版本。

## 桌面入口如何处理

只保留一个桌面图标不够，因为会有两个需求：

- 日常直接点最新版
- 有时要手动点旧版本回滚验证

所以这里保留 3 个桌面入口。

### 1）默认入口

文件：

```text
~/.local/share/applications/com.vector35.binaryninja.desktop
```

关键项：

```ini
Name=Binary Ninja
Exec=/home/xiaofeng/.local/bin/binaryninja %u
Icon=/home/xiaofeng/.local/opt/binaryninja-current/docs/img/logo.png
```

特点：

- 名字最短，适合 `Super` 搜索
- 始终走默认版本

### 2）固定 5.2 入口

文件：

```text
~/.local/share/applications/com.vector35.binaryninja-5.2.8722.desktop
```

关键项：

```ini
Name=Binary Ninja 5.2.8722
Exec=/home/xiaofeng/.local/bin/binaryninja-5.2.8722 %u
TryExec=/home/xiaofeng/.local/bin/binaryninja-5.2.8722
```

### 3）固定 5.3 入口

文件：

```text
~/.local/share/applications/com.vector35.binaryninja-5.3.9434.desktop
```

关键项：

```ini
Name=Binary Ninja 5.3.9434
Exec=/home/xiaofeng/.local/bin/binaryninja-5.3.9434 %u
TryExec=/home/xiaofeng/.local/bin/binaryninja-5.3.9434
```

这样在 Ubuntu 里按 `Super` 可以搜索：

- `Binary Ninja`
- `5.2`
- `5.3`

都能直接启动对应版本。

## 多版本并存的安装步骤

假设下载了：

```text
~/Downloads/binaryninja_linux_5.3.9434_personal.zip
```

推荐安装流程：

### 1）解压到新目录

```bash
mkdir -p ~/.local/opt/_bn_tmp
unzip ~/Downloads/binaryninja_linux_5.3.9434_personal.zip -d ~/.local/opt/_bn_tmp
mv ~/.local/opt/_bn_tmp/binaryninja ~/.local/opt/binaryninja-5.3.9434
rmdir ~/.local/opt/_bn_tmp
```

### 2）切默认版本

```bash
ln -sfn ~/.local/opt/binaryninja-5.3.9434 ~/.local/opt/binaryninja-current
ln -sfn ~/.local/opt/binaryninja-current/binaryninja ~/.local/bin/binaryninja
```

### 3）更新 `lastrun`

```bash
printf '%s\n' ~/.local/opt/binaryninja-current > ~/.binaryninja/lastrun
```

### 4）更新 Python API

```bash
python3 ~/.local/opt/binaryninja-current/scripts/install_api.py -s -f
```

### 5）桌面入口改到默认版本

默认入口推荐写成：

```ini
Exec=/home/xiaofeng/.local/bin/binaryninja %u
Icon=/home/xiaofeng/.local/opt/binaryninja-current/docs/img/logo.png
```

这样以后换版本时不需要反复改 desktop 文件。

## 安装的 Binary Ninja 插件

第一轮默认安装的是我 GitHub 上这两个更偏“日常 Binary Ninja 工作流”的插件：

- `ninja-jni-helper`
- `ninja-goto-offset`

后面又补装了：

- `binary_ninja_mcp`

也就是说，当前本机最终是“三个插件都装了”，其中 `ninja-jni-helper` 和 `ninja-goto-offset` 是 Binary Ninja 日常逆向辅助，`binary_ninja_mcp` 是 AI/MCP 协同逆向入口。

### 插件 1：JNI Helper

仓库：

```text
https://github.com/LunFengChen/ninja-jni-helper
```

用途：

- 自动加载 JNI 类型库
- 自动给 `JNI_OnLoad`、`Java_*` 这类函数补签名
- 支持导入 Frida `RegisterNatives` JSON

这个插件对 Android SO 分析非常实用，尤其是：

- `JNIEnv*`
- `JavaVM*`
- `jobject`
- `Java_*`

这类 JNI 场景很多时候不想手工一个个补。

根据插件源码，它会注册：

```text
Plugins -> JNI Helper -> Import Frida RegisterNatives JSON
```

### 插件 2：Go to Offset

仓库：

```text
https://github.com/LunFengChen/ninja-goto-offset
```

用途：

- 通过偏移地址直接跳转
- 适合 Android SO、偏移分析、配合日志/脚本/Frida 输出定位

根据插件源码，它会注册：

```text
Plugins -> Go to Offset
快捷键：Ctrl+G
```

## 插件安装方式：JNI Helper / Go to Offset

用户插件目录：

```text
~/.binaryninja/plugins
```

安装命令：

```bash
cd ~/.binaryninja/plugins
git clone https://github.com/LunFengChen/ninja-jni-helper.git
git clone https://github.com/LunFengChen/ninja-goto-offset.git
```

本机这次实际安装后的版本：

```text
ninja-jni-helper  370de2a
ninja-goto-offset cf377ce
```

为了先做一层快速校验，我还做了 Python 语法检查：

```bash
python3 -m py_compile \
  ~/.binaryninja/plugins/ninja-jni-helper/__init__.py \
  ~/.binaryninja/plugins/ninja-goto-offset/__init__.py
```

Binary Ninja 如果当时已经开着，装完插件后建议重启一次。

## Binary Ninja MCP

仓库：

```text
https://github.com/LunFengChen/binary_ninja_mcp
```

这个 MCP 由两层组成：

- **Binary Ninja 插件层**：运行在 Binary Ninja 进程里，提供本地 HTTP API，默认监听 `127.0.0.1:9009`。
- **MCP bridge 层**：`bridge/binja_mcp_bridge.py` 是 stdio MCP server，MCP 客户端通过它转发到 `http://localhost:9009`。

也就是说，客户端不是直接连 Binary Ninja 进程，而是：

```text
Claude/Codex/Gateway
  -> binja_mcp_bridge.py (stdio MCP)
  -> http://localhost:9009
  -> Binary Ninja 插件
```

### 安装位置

```text
~/.binaryninja/plugins/binary_ninja_mcp
```

本机这次实际安装后的版本：

```text
binary_ninja_mcp 8c5134e
```

### 安装命令

```bash
mkdir -p ~/.binaryninja/plugins
cd ~/.binaryninja/plugins
git clone https://github.com/LunFengChen/binary_ninja_mcp.git
cd binary_ninja_mcp
python3 -m venv .venv
.venv/bin/python -m pip install -U pip setuptools wheel
.venv/bin/python -m pip install -r bridge/requirements.txt
```

安装后建议重启 Binary Ninja，让插件重新加载。

### MCP 客户端注册方式

本机现在推荐 **统一走 Gateway-Mcp**，不要让 Claude/Codex 直接看到 Binary Ninja 的 50+ 个工具。

Gateway 里添加这一段：

```json
{
  "mcpServers": {
    "binary-ninja-mcp": {
      "command": "/home/xiaofeng/.binaryninja/plugins/binary_ninja_mcp/.venv/bin/python",
      "args": [
        "/home/xiaofeng/.binaryninja/plugins/binary_ninja_mcp/bridge/binja_mcp_bridge.py"
      ],
      "profiles": ["reverse", "native", "binaryninja", "bn"],
      "disabled": false
    }
  }
}
```

Claude / Codex 只注册 Gateway：

```bash
codex mcp add GateWay-Mcp -- \
  /home/xiaofeng/Applications/Gateway-Mcp/.venv/bin/python \
  /home/xiaofeng/Applications/Gateway-Mcp/gateway_mcp_server.py \
  --config /home/xiaofeng/Applications/Gateway-Mcp/mcps_config.json

claude mcp add -s user GateWay-Mcp -- \
  /home/xiaofeng/Applications/Gateway-Mcp/.venv/bin/python \
  /home/xiaofeng/Applications/Gateway-Mcp/gateway_mcp_server.py \
  --config /home/xiaofeng/Applications/Gateway-Mcp/mcps_config.json
```

如果临时不走 Gateway，也可以用插件自带 installer 直接写 MCP 客户端配置：

```bash
cd ~/.binaryninja/plugins/binary_ninja_mcp
.venv/bin/python scripts/mcp_client_installer.py --install
```

它写入的核心配置大概是：

```json
{
  "mcpServers": {
    "binary_ninja_mcp": {
      "command": "/home/xiaofeng/.binaryninja/plugins/binary_ninja_mcp/.venv/bin/python3",
      "args": [
        "/home/xiaofeng/.binaryninja/plugins/binary_ninja_mcp/bridge/binja_mcp_bridge.py"
      ],
      "timeout": 1800,
      "disabled": false
    }
  }
}
```

注意：如果后面继续使用 Gateway，直连的 `binary_ninja_mcp` 可以从 Claude/Codex 里移除，避免重复暴露工具。

## Binary Ninja MCP 自动启动

这个 MCP 方案要求 Binary Ninja UI 插件先正常加载，并且当前有一个有效的 `BinaryView`。本机已经把插件改成“打开/切换/完成分析 BinaryView 后自动启动服务”，正常情况下不需要每次手动点 `MCP Server -> Start MCP Server`。

补丁点：

```text
~/.binaryninja/plugins/binary_ninja_mcp/plugin/__init__.py
```

自动启动关键链路：

1. `BinaryNinjaMCP.start_server(bv)` 是真正启动入口。
   - 要求 `bv is not None`。
   - 设置 `current_view`。
   - 调用 `self.server.start()`，默认监听 `localhost:9009`。
2. `_try_autostart_for_bv(bv)` 是统一自动启动包装。
   - 如果用户手动 stop 过，`_mcp_user_stopped=True`，就不再立刻自动拉起。
   - 否则调用 `plugin.start_server(bv)`。
3. UI 事件触发：
   - `OnViewChange()`：切换视图时注册当前 `BinaryView` 并尝试启动。
   - `OnAfterOpenFile()`：打开文件后注册当前 `BinaryView` 并尝试启动。
4. 启动时补偿触发：
   - 插件加载后立即读 `UIContext.activeContext()`，如果已有 `BinaryView` 就启动。
   - 用 `QTimer.singleShot()` 在 `200/500/1000/1500/2000ms` 做几次重试，避免 UI 还没完全 ready。
5. BinaryView 生命周期触发：
   - `BinaryViewType.add_binaryview_initial_analysis_completion_event(_on_bv_initial_analysis)`
   - `BinaryViewType.add_binaryview_finalized_event(_on_bv_initial_analysis)`
   - 回调里再次执行 `_try_autostart_for_bv(bv)`，并把 view 注册进 `binary_ops`。
6. 后台轻量同步：
   - `_start_bv_monitor()` 起一个 1s 的 `QTimer`。
   - 定期从 UIContext 发现打开的 BinaryView，更新 `/binaries` 列表。

核心代码形态：

```python
def _try_autostart_for_bv(bv):
    global _mcp_user_stopped
    if _mcp_user_stopped:
        return
    plugin.start_server(bv)

class _MCPMaxUINotification(ui.UIContextNotification):
    def OnViewChange(self, *args):
        bv = self._get_active_bv()
        if bv:
            plugin.server.binary_ops.register_view(bv)
            _try_autostart_for_bv(bv)

    def OnAfterOpenFile(self, *args):
        bv = self._get_active_bv()
        if bv:
            plugin.server.binary_ops.register_view(bv)
            _try_autostart_for_bv(bv)

def _on_bv_initial_analysis(bv):
    if bv:
        _try_autostart_for_bv(bv)
    if plugin.server and plugin.server.binary_ops:
        plugin.server.binary_ops.register_view(bv)

BinaryViewType.add_binaryview_initial_analysis_completion_event(_on_bv_initial_analysis)
BinaryViewType.add_binaryview_finalized_event(_on_bv_initial_analysis)
```

### 退出清理

为了避免 Binary Ninja 窗口关不干净，本机还补了退出清理：

- `OnBeforeCloseFile()` 显式 `return True`，否则 Binary Ninja 会提示 `expected bool, got NoneType`。
- `QApplication.aboutToQuit` 触发 `_shutdown_mcp_on_quit()`，停止 MCP server 和内部 `QTimer`。

### 验证方式

```bash
ss -ltnp | rg ':9009'
curl -sS http://127.0.0.1:9009/status
```

本机验证时，`9009` 由 `binaryninja` 监听，`/status` 返回当前加载文件，例如：

```json
{"loaded": true, "filename": "/tmp/ls_binja_mcp"}
```

通过 Gateway 验证：

```python
gateway_status(profile="bn")
search_gateway_tools(query="binary status", profile="bn")
call_gateway_tool(name="binary_ninja_mcp_get_binary_status", arguments={})
```

### Binary Ninja 关不掉的 MCP 插件修复

后面测试 5.2 和 5.3 时遇到一个现象：Binary Ninja 窗口关闭不干净，甚至影响保存/退出。关键日志是：

```text
[ScriptingProvider] sys:1: RuntimeWarning: Invalid return value in function 'UIContextNotification.OnBeforeCloseFile', expected bool, got NoneType.
```

定位结果：这不是 5.3 单独的问题，也不是 license 问题，而是用户插件目录 `~/.binaryninja/plugins` 被 5.2 和 5.3 共用，`binary_ninja_mcp` 的 UI close hook 会同时影响两个版本。

修复点仍然在：

```text
~/.binaryninja/plugins/binary_ninja_mcp/plugin/__init__.py
```

处理方式：

- `OnBeforeCloseFile()` 必须显式返回 `bool`。
- 这里返回 `True`，表示允许 Binary Ninja 正常继续关闭文件。
- 插件退出时做 best-effort cleanup：停止 MCP server，停止内部 `QTimer`。
- 不给 5.3 做特权；5.2 和 5.3 都可以自动启动 MCP，谁先绑定 `127.0.0.1:9009` 谁提供 MCP。

核心修复类似：

```python
def OnBeforeCloseFile(self, *args):
    try:
        bv = self._get_active_bv()
        if bv and plugin.server and plugin.server.binary_ops:
            fn = getattr(bv.file, "filename", None)
            if fn:
                plugin.server.binary_ops.unregister_by_filename(fn)
    except Exception as e:
        bn.log_debug(f"MCP Max OnBeforeCloseFile cleanup failed: {e}")
    return True
```

本次相关备份：

```text
~/.binaryninja/plugins/binary_ninja_mcp/plugin/__init__.py.bak-closefix-20260613-012358
~/.binaryninja/plugins/binary_ninja_mcp/plugin/__init__.py.bak-revert-version-guard-20260613-012759
~/.binaryninja/plugins/binary_ninja_mcp/plugin/__init__.py.bak-close-return-bool-20260613-013206
```

修复后需要杀掉或重启已经打开的 Binary Ninja，因为旧进程已经加载了旧插件代码。确认进程和端口清干净可以用：

```bash
ps -eo pid,stat,pcpu,cmd | rg 'binaryninja'
ss -ltnp | rg ':9009'
```

### IDA MCP 自动启动

插件入口：

```text
~/.idapro/plugins/ida_mcp.py
```

IDA 插件原本会把 autostart 状态保存到 IDB 的 netnode 里。如果某个旧数据库保存过“关闭自动启动”，后续打开这个库就会看起来像 MCP 失效。

本机处理方式是把有效的 `_get_autostart()` 固定为 `True`：

```python
def _get_autostart() -> bool:
    return True
```

这样 GUI 版 IDA 打开数据库后，`ready_to_run()` 会自动执行：

```python
self.plugin.run(0)
```

默认监听：

```text
127.0.0.1:13337
```

同时已经把 IDA MCP 也写入 Claude Code 的全局 MCP 配置：

```json
{
  "mcpServers": {
    "ida-pro-mcp": {
      "type": "http",
      "url": "http://127.0.0.1:13337/mcp",
      "disabled": false
    }
  }
}
```

本次修改前备份了配置：

```text
~/.claude.json.bak-ida-pro-mcp-20260613-011248
```

当前验证：

```bash
ss -ltnp | rg ':13337'
```

本机验证时，`13337` 已由 `ida64` 监听。IDA 日志里还能看到类似：

```text
Config: http://127.0.0.1:13337/config.html
```

### 修改后的语法检查

```bash
python3 -m py_compile ~/.idapro/plugins/ida_mcp.py
~/.binaryninja/plugins/binary_ninja_mcp/.venv/bin/python -m py_compile \
  ~/.binaryninja/plugins/binary_ninja_mcp/plugin/__init__.py
```

本次两边都已经通过 `py_compile`。如果 Binary Ninja 或 IDA 已经开着，修改插件后要重启对应 GUI 才会加载新逻辑。

## 验证方式

本次整理里做过的有效验证主要有这些：

### 默认版本

检查软链接：

```bash
ls -ld ~/.local/opt/binaryninja-current
ls -l ~/.local/bin/binaryninja
cat ~/.binaryninja/lastrun
```

### Python API 路径

```bash
python3 - <<'PY'
from site import getusersitepackages
from pathlib import Path
p = Path(getusersitepackages()) / "binaryninja.pth"
print(p)
print(p.read_text())
PY
```

### 桌面入口

```bash
rg -n '^Name=|^Exec=|^TryExec=|^Icon=' ~/.local/share/applications/com.vector35.binaryninja*.desktop
```

### 插件文件是否就位

```bash
find ~/.binaryninja/plugins -maxdepth 2 -type f | sort
```

### 插件 Python 语法

```bash
python3 -m py_compile \
  ~/.binaryninja/plugins/ninja-jni-helper/__init__.py \
  ~/.binaryninja/plugins/ninja-goto-offset/__init__.py

~/.binaryninja/plugins/binary_ninja_mcp/.venv/bin/python -m py_compile \
  ~/.binaryninja/plugins/binary_ninja_mcp/__init__.py \
  ~/.binaryninja/plugins/binary_ninja_mcp/plugin/__init__.py \
  ~/.binaryninja/plugins/binary_ninja_mcp/bridge/binja_mcp_bridge.py \
  ~/.binaryninja/plugins/binary_ninja_mcp/scripts/mcp_client_installer.py
```

## 一个实践上的注意点

本机直接在命令行里做 Binary Ninja 的完整插件初始化时，出现过：

```text
RuntimeError: License is not valid. Please supply a valid license.
```

因此这次没有把“命令行初始化插件成功”作为最终验收条件，而是把验收范围限定在：

- 版本切换链路正确
- desktop 入口正确
- 用户目录 license 路径正确
- 插件仓库已安装到正确目录
- 插件 Python 代码可正常编译

对 Personal 版来说，这种验收方式更稳妥。

## 常用维护命令

### 切回 5.2 做验证

```bash
ln -sfn ~/.local/opt/binaryninja-5.2.8722 ~/.local/opt/binaryninja-current
ln -sfn ~/.local/opt/binaryninja-current/binaryninja ~/.local/bin/binaryninja
printf '%s\n' ~/.local/opt/binaryninja-current > ~/.binaryninja/lastrun
python3 ~/.local/opt/binaryninja-current/scripts/install_api.py -s -f
```

### 再切回 5.3

```bash
ln -sfn ~/.local/opt/binaryninja-5.3.9434 ~/.local/opt/binaryninja-current
ln -sfn ~/.local/opt/binaryninja-current/binaryninja ~/.local/bin/binaryninja
printf '%s\n' ~/.local/opt/binaryninja-current > ~/.binaryninja/lastrun
python3 ~/.local/opt/binaryninja-current/scripts/install_api.py -s -f
```

### 更新插件

```bash
git -C ~/.binaryninja/plugins/ninja-jni-helper pull --ff-only
git -C ~/.binaryninja/plugins/ninja-goto-offset pull --ff-only
git -C ~/.binaryninja/plugins/binary_ninja_mcp pull --ff-only
```

## 最终建议

Ubuntu 下长期维护 Binary Ninja，最稳的方案就是：

- 版本目录独立
- 默认版本用 `binaryninja-current`
- 命令行入口统一走 `~/.local/bin/binaryninja`
- 用户数据只认 `~/.binaryninja`
- 桌面里同时保留默认入口和指定版本入口
- 插件全部装到 `~/.binaryninja/plugins`

这样升级、回滚、试验插件、保留旧版本都不会乱。
