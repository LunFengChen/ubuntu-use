# Reqable MCP 与 Gateway-Mcp 接入记录

本文记录本机把 Reqable 自带 MCP Server 接入 Codex 和 Gateway-Mcp 的配置、验证方式与常用能力。

对应时间点：`2026-07-12`。

## 目标

- 让 Codex 能读取 Reqable 当前实时抓包记录。
- 日常逆向优先通过 Gateway-Mcp 搜索和调用 Reqable 工具，避免一次暴露 143 个工具。
- 保留直接注册入口，便于 Gateway 故障时单独排查 Reqable MCP。

## 工具选择原因

- Reqable `3.2.4` 安装包已经自带 stdio MCP Server，不需要额外安装 Python 项目。
- MCP 可以直接查询当前 GUI 中保留的流量，不必先导出 HAR 或 PCAP。
- 除了读取请求，还能管理断点、重写、脚本、镜像、代理、SSL 代理和网络限速等配置。
- Gateway-Mcp 的 search 模式只在顶层暴露少量路由工具，更适合工具数量较多的 Reqable MCP。

## 当前本机状态

| 项目 | 当前值 |
| --- | --- |
| Debian 包 | `reqable 3.2.4` |
| Reqable 进程 | `/usr/share/reqable/reqable` |
| MCP Server | `/usr/share/reqable/mcp-server` |
| Gateway 项目 | `~/Desktop/projects/Gateway-Mcp` |
| Gateway 配置 | `~/Desktop/projects/Gateway-Mcp/mcps_config.json` |
| Gateway server 名 | `reqable` |
| Gateway profiles | `reverse`、`traffic`、`reqable`、`capture` |
| 验证时工具数量 | `143` |
| 当前代理监听 | `0.0.0.0:9000` |

确认 MCP Server 属于 Reqable 包：

```bash
dpkg-query -S /usr/share/reqable/mcp-server
dpkg-query -W -f='${Package} ${Version}\n' reqable
```

本次没有重新安装 Reqable。若以后从 `.deb` 恢复，使用实际下载文件路径：

```bash
sudo apt install /path/to/reqable.deb
```

## Codex 直接注册

直接注册命令：

```bash
codex mcp add reqable -- "/usr/share/reqable/mcp-server"
```

当前结果：

```text
reqable
  enabled: true
  transport: stdio
  command: /usr/share/reqable/mcp-server
```

Reqable MCP Server 支持可选参数：

```text
--host  Reqable 所在设备的 IP，默认 127.0.0.1
--port  Reqable 端口；不指定时优先读取本地应用配置，失败时回退 9000
```

本机 Reqable 与 Codex 在同一台机器，所以保持无参数配置。

## Gateway-Mcp 接入

在 `~/Desktop/projects/Gateway-Mcp/mcps_config.json` 的 `mcpServers` 中新增：

```json
"reqable": {
  "command": "/usr/share/reqable/mcp-server",
  "args": [],
  "profiles": [
    "reverse",
    "traffic",
    "reqable",
    "capture"
  ],
  "disabled": false
}
```

Codex 顶层已经注册 Gateway-Mcp：

```bash
codex mcp add gateway-mcp -- \
  /home/xiaofeng/Desktop/projects/Gateway-Mcp/.venv/bin/python \
  /home/xiaofeng/Desktop/projects/Gateway-Mcp/gateway_mcp_server.py \
  --config /home/xiaofeng/Desktop/projects/Gateway-Mcp/mcps_config.json
```

查看当前注册：

```bash
codex mcp get reqable
codex mcp get gateway-mcp
codex mcp list
```

当前机器同时保留直接 `reqable` 和 `gateway-mcp` 两个入口。日常逆向优先使用 Gateway；如果以后只想保留网关入口，可以执行：

```bash
codex mcp remove reqable
```

## Gateway 结构化结果兼容

Reqable 的很多查询工具会把真正的数据放在 MCP `structuredContent` 中，而普通文本 `content` 只返回类似：

```text
Successfully retrieved the live capture record details.
```

Gateway-Mcp 原来的 `call_gateway_tool` 只提取文本，因此能调用成功但看不到流量详情。本机已修复为：

1. 优先返回 FastMCP 客户端的 `structured_content`。
2. 没有结构化内容时再回退到原来的文本结果。
3. 显式设置 `max_chars` 时，把结构化结果序列化为 JSON 后再截断。

对应实现与测试：

```text
~/Desktop/projects/Gateway-Mcp/gateway_mcp_server.py
~/Desktop/projects/Gateway-Mcp/tests/test_gateway_mcp_server.py
```

修改配置或 Gateway 代码后，已经启动的 Codex MCP 进程不会热重载，需要重新连接或新开 Codex 会话。

## Gateway 使用方式

先确认服务和搜索工具：

```text
gateway_status(server="reqable", verbose=true)
search_gateway_tools(
  query="live capture filter record",
  server="reqable",
  force_refresh=true
)
```

Gateway 会给上游工具增加 `reqable_` 前缀。例如：

```text
上游：capture_live_status
网关：reqable_capture_live_status
```

只读查看当前抓包状态：

```text
call_gateway_tool(
  name="reqable_capture_live_status",
  arguments={}
)
```

列出当前保留的全部记录 ID：

```text
call_gateway_tool(
  name="reqable_capture_live_filter",
  arguments={"filters": []}
)
```

读取一条完整记录：

```text
call_gateway_tool(
  name="reqable_capture_live_get_by_id",
  arguments={"id": 1486}
)
```

按 Host 过滤：

```text
call_gateway_tool(
  name="reqable_capture_live_filter",
  arguments={
    "filters": [
      {
        "type": "host",
        "hosts": ["cinfo-v6.shein.com"]
      }
    ]
  }
)
```

过滤器支持 `keyword`、`url`、`host`、`ip`、`method`、`code` 和 `application`。多个过滤器按逻辑 AND 组合。

## 主要能力

Reqable `3.2.4` 的 MCP 运行时共发现 143 个工具，主要分为：

| 类别 | 代表工具或前缀 | 用途 |
| --- | --- | --- |
| 实时抓包 | `capture_live_*` | 启停、状态、过滤、读取、清空、生成 cURL、组合请求、加入集合 |
| 断点 | `capture_breakpoint_*` | 查询和管理请求/响应断点 |
| 重写 | `capture_rewrite_*` | 查询和管理请求/响应重写规则 |
| Python 脚本 | `capture_script_*`、`script_framework`、`script_template` | 创建和管理流量处理脚本 |
| 镜像与网关 | `capture_mirror_*`、`capture_gateway_*` | 管理域名镜像和流量控制规则 |
| 网络能力 | `capture_network_throttling_*` | 模拟匹配流量的网络条件 |
| 代理链路 | `capture_reverse_proxy_*`、`capture_secondary_proxy_*` | 管理反向代理和上游二级代理 |
| HTTPS | `capture_ssl_proxying_*` | 选择和管理 HTTPS 拦截或绕过规则 |
| 访问与上报 | `capture_access_control_*`、`capture_report_server_*` | 控制客户端访问并把匹配流量上报到 HTTP 服务 |
| API 集合 | `collection_*` | 管理集合、目录、HTTP API 和 cURL |
| 环境 | `environment_*` | 管理环境及变量并选择当前环境 |
| 请求编辑器 | `rest_http_*`、`rest_websocket_*` | 从 URL 或 cURL 创建 HTTP/WebSocket 调试页 |

工具数量和 schema 可能随 Reqable 版本变化。实际使用时先 `search_gateway_tools`，需要参数细节时再 `describe_gateway_tool`。

## 本次验证结果

通过修复后的 Gateway-Mcp 实际调用 Reqable：

```text
capture_status: active
tool_count: 143
record_count: 775
latest_id: 1486
latest_request: HEAD https://cinfo-v6.shein.com/
latest_status: 200
```

记录数量和最新 ID 会随抓包变化，只用于证明当时已经能端到端读取实时流量。

单元测试：

```bash
cd ~/Desktop/projects/Gateway-Mcp
.venv/bin/python -m unittest discover -s tests -v
.venv/bin/python -m py_compile gateway_mcp_server.py tests/test_gateway_mcp_server.py
```

## 常用排查

检查 Reqable 进程和端口：

```bash
pgrep -af 'reqable|Reqable'
ss -ltnp | rg 'reqable|:9000'
```

检查 Gateway 配置：

```bash
jq empty ~/Desktop/projects/Gateway-Mcp/mcps_config.json
rg -n '"reqable"|mcp-server' ~/Desktop/projects/Gateway-Mcp/mcps_config.json
```

常见问题：

- `gateway_status(server="reqable")` 返回 `server_count: 0`：当前 Codex 会话仍使用修改前启动的 Gateway，重启或重新连接 Codex。
- 只能看到 `Successfully retrieved...`：Gateway 仍在使用没有透传 `structuredContent` 的旧代码或旧进程。
- Reqable 工具连接失败：先打开 Reqable GUI，再检查本机端口和 `--host`、`--port`。
- 直接入口导致工具列表太大：删除直接 `reqable` 注册，只保留 Gateway-Mcp。

## 安全注意

本机验证时 Reqable 代理监听在：

```text
0.0.0.0:9000
```

这意味着同网段设备可能访问该端口。只在可信网络中使用，并结合防火墙或 Reqable 的 `capture_access_control_*` 能力限制客户端。

逆向分析默认只读取状态、过滤记录和查看详情。除非用户明确要求，不要调用启停、清空、创建、修改或删除规则的工具，也不要在报告中直接泄露 Cookie、Authorization、Token 或完整敏感请求体。
