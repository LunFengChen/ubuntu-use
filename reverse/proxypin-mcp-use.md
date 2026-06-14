# ProxyPin MCP 抓包工具接入记录

本文记录本机把魔改版 ProxyPin 与 `proxypin-mcp-server` 接入 Gateway-Mcp 的结果。

## 相关仓库

本次两个仓库都放在 `~/Desktop/projects` 下：

```text
~/Desktop/projects/proxypin
~/Desktop/projects/proxypin-mcp-server
```

仓库地址：

```text
https://github.com/LunFengChen/proxypin
https://github.com/LunFengChen/proxypin-mcp-server
```

说明：

- `proxypin`：魔改版 ProxyPin，本体抓包软件，release 里有 Linux 包。
- `proxypin-mcp-server`：给 AI/MCP 客户端用的 stdio MCP server，转发到 ProxyPin 内置 MCP HTTP 端口。

## 端口概念

不要把两个端口搞混：

```text
9099   ProxyPin 抓包代理端口，手机/系统代理走这个
17777  ProxyPin 内置 MCP 通信端口，proxypin-mcp-server 调这个
```

`proxypin-mcp-server.py` 默认读取：

```python
PROXYPIN_HOST = 127.0.0.1
PROXYPIN_PORT = 17777
BASE_URL = http://127.0.0.1:17777
MESSAGES_URL = http://127.0.0.1:17777/messages
```

## ProxyPin 本体安装

从自己仓库的 release 下载了 Linux 包：

```text
proxypin-with-mcp-1.2.3-linux.deb
proxypin-with-mcp-1.2.3-linux.tar.gz
```

安装的是 deb：

```bash
sudo apt-get install -y /tmp/proxypin-release/proxypin-with-mcp-1.2.3-linux.deb
```

安装后文件：

```text
/opt/proxypin/ProxyPin
/usr/share/applications/proxy-pin.desktop
```

本机还加了命令行启动器：

```text
~/.local/bin/proxypin -> /opt/proxypin/ProxyPin
```

启动方式：

```bash
proxypin
# 或者从桌面应用菜单打开 ProxyPin
```

注意：本次不强行自动验证 GUI 和端口；后续使用时手动打开 ProxyPin，确认 17777 MCP 端口和 9099 代理端口可用即可。

## proxypin-mcp-server 安装

目录：

```text
~/Desktop/projects/proxypin-mcp-server
```

创建 venv 并安装依赖：

```bash
cd ~/Desktop/projects/proxypin-mcp-server
python3 -m venv .venv
.venv/bin/python -m pip install -U pip setuptools wheel fastmcp requests
```

验证 import：

```bash
.venv/bin/python - <<'PY'
import proxypin_mcp_server as s
print(s.BASE_URL)
print(type(s.mcp).__name__)
PY
```

当前结果：

```text
http://127.0.0.1:17777
FastMCP
```

短启动验证：

```bash
timeout 3s .venv/bin/python proxypin_mcp_server.py
```

能看到 FastMCP 启动横幅和：

```text
Starting MCP server 'ProxyPin' with transport 'stdio'
```

## Gateway-Mcp 接入

Gateway-Mcp 已从：

```text
~/Applications/Gateway-Mcp
```

迁移到：

```text
~/Desktop/projects/Gateway-Mcp
```

旧路径保留 symlink，避免旧配置立刻断：

```text
~/Applications/Gateway-Mcp -> ~/Desktop/projects/Gateway-Mcp
```

Gateway 配置文件：

```text
~/Desktop/projects/Gateway-Mcp/mcps_config.json
```

新增 server：

```json
"proxypin-mcp": {
  "command": "/home/xiaofeng/Desktop/projects/proxypin-mcp-server/.venv/bin/python",
  "args": [
    "/home/xiaofeng/Desktop/projects/proxypin-mcp-server/proxypin_mcp_server.py"
  ],
  "profiles": ["reverse", "traffic", "proxypin", "capture"],
  "disabled": false,
  "env": {
    "PROXYPIN_HOST": "127.0.0.1",
    "PROXYPIN_PORT": "17777"
  }
}
```

同时把 `jadx-mcp-server` 的路径从 `~/Applications` 改到 `~/Desktop/projects`。

## Claude / Codex 顶层入口

Claude 的 Gateway-Mcp 路径已改到新位置：

```text
/home/xiaofeng/Desktop/projects/Gateway-Mcp/.venv/bin/python
/home/xiaofeng/Desktop/projects/Gateway-Mcp/gateway_mcp_server.py
/home/xiaofeng/Desktop/projects/Gateway-Mcp/mcps_config.json
```

Codex 当前也重新注册了 Gateway-Mcp：

```bash
codex mcp add GateWay-Mcp -- \
  /home/xiaofeng/Desktop/projects/Gateway-Mcp/.venv/bin/python \
  /home/xiaofeng/Desktop/projects/Gateway-Mcp/gateway_mcp_server.py \
  --config /home/xiaofeng/Desktop/projects/Gateway-Mcp/mcps_config.json
```

验证：

```bash
codex mcp list
```

能看到：

```text
GateWay-Mcp ... enabled
```

## Gateway 验证

用 FastMCP 客户端直接探测 Gateway：

```python
from fastmcp import Client
```

验证结果：

```text
gateway_tools: gateway_status, search_gateway_tools, describe_gateway_tool, call_gateway_tool
profile=proxypin: status=ok, tool_count=23
```

搜索示例返回了 ProxyPin 工具：

```text
proxypin_mcp_search_requests
proxypin_mcp_get_recent_requests
proxypin_mcp_export_har
proxypin_mcp_import_har
proxypin_mcp_compare_requests
proxypin_mcp_clear_requests
```

这说明 Gateway 已能索引 proxypin-mcp。真正调用请求数据时，需要 ProxyPin GUI 本体已启动，并且内置 MCP 端口 `17777` 可访问。

## Applications 到 projects 的迁移

以下 MCP/逆向相关项目已从 `~/Applications` 移到 `~/Desktop/projects`，并在旧路径保留 symlink：

```text
~/Applications/Gateway-Mcp      -> ~/Desktop/projects/Gateway-Mcp
~/Applications/ida-pro-mcp      -> ~/Desktop/projects/ida-pro-mcp
~/Applications/jadx-ai-mcp      -> ~/Desktop/projects/jadx-ai-mcp
~/Applications/jadx-mcp-server  -> ~/Desktop/projects/jadx-mcp-server
```

迁移前检查过没有正在运行的 MCP 进程，也没有监听这些常见端口：

```text
13337  IDA MCP
8650   JADX GUI 插件
8651   jadx-mcp-server HTTP
9009   Binary Ninja MCP
17777  ProxyPin MCP
9099   ProxyPin 抓包代理
```

## 当前保留在原位置的项目

Binary Ninja MCP 仍保留在 Binary Ninja 插件目录：

```text
~/.binaryninja/plugins/binary_ninja_mcp
```

原因：这是 Binary Ninja 插件，不只是普通 MCP server，放在插件目录更符合加载机制。

IDA MCP 的 CLI 命令仍走：

```text
~/.local/opt/idapro9-python312/bin/ida-pro-mcp
```

但源码仓库已迁移到：

```text
~/Desktop/projects/ida-pro-mcp
```

## 常用检查命令

看 Gateway 配置：

```bash
python3 -m json.tool ~/Desktop/projects/Gateway-Mcp/mcps_config.json
```

看 Claude MCP：

```bash
claude mcp list
```

看 Codex MCP：

```bash
codex mcp list
```

看 ProxyPin 端口：

```bash
ss -ltnp | grep -E ':17777|:9099'
```

看 ProxyPin 进程：

```bash
pgrep -a ProxyPin
```

## 结论

当前 MCP 侧已经完成：

- `proxypin-mcp-server` 已安装依赖并可启动；
- `proxypin-mcp` 已加入 Gateway-Mcp；
- Gateway profile `proxypin` 可索引到 23 个工具；
- Claude / Codex 都走新的 Gateway-Mcp 路径；
- ProxyPin Linux 本体已安装，后续由用户手动打开 GUI 验证抓包和 17777 端口。
