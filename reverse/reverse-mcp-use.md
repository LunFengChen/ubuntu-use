# IDA / JADX / Binary Ninja MCP 在 Ubuntu 下的整理记录

本文记录本机逆向工具 MCP 的当前组织方式，重点是 IDA 和 JADX，并补充 Binary Ninja 与 MCP Gateway 的关系。

对应时间点：`2026-06-13`。

## 总体思路

逆向工具 MCP 现在分两层：

```text
Claude Code / Agent
  -> GateWay-Mcp
      -> ida-pro-mcp
      -> jadx-mcp-server
      -> binary-ninja-mcp
```

这样做的原因：

- 不让客户端一次性暴露一堆 MCP 工具，减少上下文和工具列表噪声。
- 通过 `profile` 按场景过滤，比如 `ida`、`jadx`、`android`、`native`。
- 某个工具没开，不影响其他 MCP server。
- 后续换 IDA / JADX / Binary Ninja 版本时，只改 Gateway 配置即可。

## 当前本机目录

```text
~/Applications/Gateway-Mcp
~/Applications/ida-pro-mcp
~/Applications/jadx-mcp-server
~/Applications/jadx-ai-mcp
~/.binaryninja/plugins/binary_ninja_mcp
```

其中：

- `Gateway-Mcp` 是我自己的 MCP 聚合网关。
- `ida-pro-mcp` 是 IDA MCP，本机 fork 到了我的 GitHub。
- `jadx-mcp-server` 是 Python MCP server，负责把 MCP 请求转发给 JADX GUI 插件。
- `jadx-ai-mcp` 是 JADX GUI 侧插件项目。
- `binary_ninja_mcp` 是 Binary Ninja 插件和 bridge。

## Claude Code 侧配置

当前 Claude Code 全局配置里主要挂 Gateway：

```text
~/.claude.json
```

核心配置类似：

```json
{
  "mcpServers": {
    "GateWay-Mcp": {
      "type": "stdio",
      "command": "/home/xiaofeng/Applications/Gateway-Mcp/.venv/bin/python",
      "args": [
        "/home/xiaofeng/Applications/Gateway-Mcp/gateway_mcp_server.py",
        "--config",
        "/home/xiaofeng/Applications/Gateway-Mcp/mcps_config.json"
      ],
      "env": {}
    }
  }
}
```

有些 MCP 也可以直接挂到 Claude Code，但逆向场景建议默认走 Gateway，避免工具列表太大。

## Gateway 配置

配置文件：

```text
~/Applications/Gateway-Mcp/mcps_config.json
```

当前逆向 MCP server 配置核心内容：

```json
{
  "mcpServers": {
    "ida-pro-mcp": {
      "command": "/home/xiaofeng/.local/opt/idapro9-python312/bin/ida-pro-mcp",
      "args": [],
      "profiles": ["reverse", "native", "ida"],
      "disabled": false
    },
    "jadx-mcp-server": {
      "command": "/home/xiaofeng/Applications/jadx-mcp-server/.venv/bin/python",
      "args": [
        "/home/xiaofeng/Applications/jadx-mcp-server/jadx_mcp_server.py",
        "--jadx-host",
        "127.0.0.1",
        "--jadx-port",
        "8650"
      ],
      "profiles": ["reverse", "android", "jadx"],
      "disabled": false
    },
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

Gateway 使用方式：

```text
gateway_status(profile="ida")
gateway_status(profile="jadx")
search_gateway_tools(query="decompile", profile="ida")
search_gateway_tools(query="class source", profile="jadx")
describe_gateway_tool(name="...")
call_gateway_tool(name="...", arguments={...})
```

## IDA MCP

### 本机仓库

```text
~/Applications/ida-pro-mcp
```

remote：

```text
origin   https://github.com/LunFengChen/ida-pro-mcp.git
upstream https://github.com/mrexodia/ida-pro-mcp
```

当前我自己的 fork 已经包含本机工作流改动：

```text
https://github.com/LunFengChen/ida-pro-mcp
```

当前提交：

```text
6d00bcd Enable local IDA MCP autostart workflow
```

### IDA 插件入口

```text
~/.idapro/plugins/ida_mcp.py -> ~/Applications/ida-pro-mcp/src/ida_pro_mcp/ida_mcp.py
~/.idapro/plugins/ida_mcp    -> ~/Applications/ida-pro-mcp/src/ida_pro_mcp/ida_mcp
```

### 自动启动处理

IDA MCP 原本会把 autostart 配置保存在 IDB 的 netnode 里。如果某个旧 IDB 保存过“关闭自动启动”，下次打开该库时 MCP 就不会自动起来。

本机 fork 里把有效 autostart 固定为 `True`：

```python
def _get_autostart() -> bool:
    return True
```

因此 GUI IDA 打开数据库后，会在 `ready_to_run()` 阶段自动启动 MCP server。

默认监听：

```text
127.0.0.1:13337
```

### IDA 9.0 SP0 兼容处理

本机还对 `compat.py` 做了 IDA 9.0 SP0 的本地兼容放行。

原因：IDA 9.0 SP0 缺少部分较新的 Python API 方法，但项目里的 wrapper 已经有 fallback 路径。对本机来说，与其直接 hard fail，不如先 best-effort 运行。

### 验证命令

```bash
ida-pro-mcp --config
ss -ltnp | rg ':13337'
curl -sS http://127.0.0.1:13337/config.html | head
```

如果 IDA GUI 已经打开并加载插件，日志里应能看到类似：

```text
Config: http://127.0.0.1:13337/config.html
```

## JADX MCP

JADX 这边是两段式：

```text
jadx-gui + jadx-ai-mcp plugin
  <- HTTP 127.0.0.1:8650 ->
jadx-mcp-server
  <- MCP stdio / Gateway ->
Claude Code / Agent
```

### JADX 本体

当前命令：

```text
~/.local/bin/jadx
~/.local/bin/jadx-gui
~/.local/bin/xfjadx
~/.local/bin/xfjadx-gui
```

安装目录：

```text
~/.local/opt/jadx
~/Desktop/xfjadx
```

桌面入口：

```text
~/.local/share/applications/jadx-gui.desktop
~/.local/share/applications/xfjadx-gui.desktop
```

### JADX GUI dock 图标显示齿轮

现象：

- `jadx-gui` 打开后，Ubuntu dock 上显示默认齿轮图标。
- 鼠标悬浮提示是 `jadx-gui-JadxGUI`，而不是 `JADX GUI`。

原因：

- JADX GUI 是 Java/Swing 程序，桌面环境需要用窗口的 `WM_CLASS` 去匹配 `.desktop` 启动器。
- 如果 `.desktop` 里没有正确的 `StartupWMClass`，GNOME 就会把运行窗口当成未知程序，显示齿轮。
- 注意大小写必须完全一致，本机窗口类名是：

```text
jadx-gui-JadxGUI
```

修复方式是在两个 desktop 文件里加入或修正：

```ini
StartupWMClass=jadx-gui-JadxGUI
```

本机已处理文件：

```text
~/.local/share/applications/jadx-gui.desktop
~/.local/share/applications/xfjadx-gui.desktop
```

可复现命令：

```bash
for f in "$HOME/.local/share/applications/jadx-gui.desktop" \
         "$HOME/.local/share/applications/xfjadx-gui.desktop"; do
  [ -f "$f" ] || continue
  cp -n "$f" "$f.bak" 2>/dev/null || true
  if grep -q '^StartupWMClass=' "$f"; then
    sed -i 's/^StartupWMClass=.*/StartupWMClass=jadx-gui-JadxGUI/' "$f"
  else
    printf '\nStartupWMClass=jadx-gui-JadxGUI\n' >> "$f"
  fi
done
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
```

验证：

```bash
grep -H '^StartupWMClass=' \
  ~/.local/share/applications/jadx-gui.desktop \
  ~/.local/share/applications/xfjadx-gui.desktop
```

改完后需要关闭当前 JADX 窗口，再从应用菜单重新打开。若 dock 上固定过旧齿轮图标，先取消固定，再重新固定。

### JADX AI MCP 插件

插件项目：

```text
~/Applications/jadx-ai-mcp
```

remote：

```text
https://github.com/zinja-coder/jadx-ai-mcp
```

这个项目是 JADX GUI 侧插件，负责在 JADX GUI 里提供 HTTP 能力。默认插件端口是：

```text
127.0.0.1:8650
```

### JADX MCP Server

Python MCP server：

```text
~/Applications/jadx-mcp-server
```

remote：

```text
https://github.com/zinja-coder/jadx-mcp-server
```

venv：

```text
~/Applications/jadx-mcp-server/.venv
```

Gateway 里当前以 stdio 方式启动：

```bash
/home/xiaofeng/Applications/jadx-mcp-server/.venv/bin/python \
  /home/xiaofeng/Applications/jadx-mcp-server/jadx_mcp_server.py \
  --jadx-host 127.0.0.1 \
  --jadx-port 8650
```

这里要区分两个端口：

- `--jadx-port 8650`：JADX GUI 插件监听的端口。
- `--port 8651`：只有 `jadx-mcp-server --http` 时才是 MCP server 自己监听的 HTTP 端口。

当前通过 Gateway/stdio 使用，所以不需要暴露 `8651`。

### JADX MCP 启动顺序

推荐顺序：

1. 打开 `jadx-gui` 或 `xfjadx-gui`。
2. 在 JADX GUI 里打开 APK / DEX / JAR。
3. 确认 `jadx-ai-mcp` 插件已启动，默认监听 `127.0.0.1:8650`。
4. Claude Code 通过 `GateWay-Mcp` 调用 `jadx-mcp-server`。

常用检查：

```bash
ss -ltnp | rg ':8650|:8651'
~/Applications/jadx-mcp-server/.venv/bin/python \
  ~/Applications/jadx-mcp-server/jadx_mcp_server.py --help
```

如果 `8650` 没有监听，通常是 JADX GUI 侧插件没启动，而不是 Python MCP server 的问题。

## Binary Ninja MCP 补充

Binary Ninja 的详细安装、多版本、插件和关不掉修复记录在：

```text
binaryninja-use.md
```

这里只记录它在 Gateway 里的位置：

```text
~/.binaryninja/plugins/binary_ninja_mcp
127.0.0.1:9009
```

策略：5.2 / 5.3 都可以启动 MCP，谁先绑定 `9009` 谁提供 MCP。

## 常用排查命令

### 看 Gateway 配置

```bash
python3 -m json.tool ~/Applications/Gateway-Mcp/mcps_config.json
```

### 看 Claude Code MCP 顶层配置

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / '.claude.json'
data = json.loads(p.read_text())
print(json.dumps(data.get('mcpServers', {}), indent=2, ensure_ascii=False))
PY
```

### 看端口

```bash
ss -ltnp | rg ':13337|:8650|:8651|:9009'
```

### 看进程

```bash
ps -eo pid,stat,pcpu,cmd | rg 'ida|jadx|binaryninja|gateway_mcp|mcp'
```

### Gateway 工具调用建议

优先用 profile 缩小范围：

```text
gateway_status(profile="ida")
gateway_status(profile="jadx")
gateway_status(profile="bn")
search_gateway_tools(query="strings", profile="ida")
search_gateway_tools(query="manifest", profile="jadx")
```

## 安全注意

这些 MCP 服务都应该默认绑定 localhost：

```text
127.0.0.1
```

不要随手改成 `0.0.0.0`，因为这些工具通常没有认证，而且能读取反编译代码、重命名符号、写注释、甚至 patch 数据。除非在可信隔离网络里明确需要远程访问，否则保持本机环回地址。
