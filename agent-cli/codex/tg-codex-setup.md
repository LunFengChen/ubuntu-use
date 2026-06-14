# Telegram 远程控制 Codex 部署指南

## 概述

TeleCodex 是一个 Telegram 桥接程序，运行在你的笔记本上，把 Telegram bot 和 Codex CLI SDK 连起来。你可以从手机（或任何设备）通过 Telegram 聊天来控制笔记本上的 Codex，每个 TG 私聊窗口或论坛话题都是一个独立的 Codex session。

```
手机 TG  ──►  Telegram Bot API  ──►  笔记本上的 TeleCodex  ──►  Codex CLI (本地)
```

---

## 前置条件

| 项目          | 说明                      |
| ----------- | ----------------------- |
| Node.js 22+ | `node -v` 确认            |
| Codex CLI   | 能正常聊天                   |
| Telegram 账号 | 你的个人 TG 账号              |
| 网络          | 笔记本能访问 api.telegram.org |

---

## 第一步：创建 Telegram Bot

1. 在 TG 里搜 **@BotFather**
2. 发 `/newbot`
3. 按提示输入 bot 显示名和用户名（用户名必须以 `bot` 结尾，如 `my_codex_bot`）
4. 拿到 bot token，格式类似：`1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`

---

## 第二步：获取你的 TG 用户 ID

1. 在 TG 里搜 **@userinfobot**
2. 发 `/start`
3. 记下返回的数字 ID（如 `8097627516`）

这个 ID 用于白名单，只允许你操作 bot。

---

## 第三步：克隆并安装

```bash
cd ~/Desktop/projects
git clone https://github.com/benedict2310/telecodex tg-control-codex
cd tg-control-codex

# 安装依赖（跳过可选的 native 模块）
npm install --no-optional
```

---

## 第四步：配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填以下内容：

```bash
# ===== 必填 =====
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz   # 从 @BotFather 拿到的 token
TELEGRAM_ALLOWED_USER_IDS=8097627516                         # 你的 TG 用户 ID（可逗号分隔多个）

# ===== 可选（Codex 认证） =====
CODEX_API_KEY=                                               # API Key 认证（与 CLI 登录二选一）
CODEX_MODEL=                                                 # 默认模型，如 gpt-5.4, o3

# ===== 安全配置 =====
CODEX_SANDBOX_MODE=workspace-write                           # read-only | workspace-write | danger-full-access
CODEX_APPROVAL_POLICY=never                                  # never | on-request | on-failure | untrusted
ENABLE_UNSAFE_LAUNCH_PROFILES=false                          # 设为 true 才允许 danger-full-access

# ===== 显示配置 =====
TOOL_VERBOSITY=summary                                       # all | summary | errors-only | none
SHOW_TURN_TOKEN_USAGE=false                                  # 是否在回复末尾显示 token 用量
ENABLE_TELEGRAM_REACTIONS=false                              # 是否启用 👀/👍 表情反馈
ENABLE_TELEGRAM_LOGIN=true                                   # 是否允许从 TG 执行 /login

# ===== 语音转文字（可选） =====
OPENAI_API_KEY=                                              # 用于 Whisper 云端转写，不填则只用本地 parakeet
```

---

## 第五步：修复 SDK 二进制路径

`@openai/codex-sdk` 默认从 npm 包中查找 codex 二进制，但平台包不在公开 registry 中。需要修改一行源码指向系统 codex：

```bash
# 确认 codex 位置
which codex
# 输出: /home/YOUR_USER/.local/bin/codex

# 编辑 src/codex-session.ts，在 resetCodexClient() 方法中加上 codexPathOverride
```

修改前：

```typescript
private resetCodexClient(): void {
    this.codex = new Codex({
      apiKey: this.config.codexApiKey,
      ...
    });
}
```

修改后：

```typescript
private resetCodexClient(): void {
    this.codex = new Codex({
      codexPathOverride: "/home/YOUR_USER/.local/bin/codex",  // ← 加这一行
      apiKey: this.config.codexApiKey,
      ...
    });
}
```

---

## 第六步：启动

```bash
# 务必确保 codex 在 PATH 中
export PATH="$HOME/.local/bin:$PATH"

cd ~/Desktop/projects/tg-control-codex
npm run dev
```

看到以下输出表示成功：

```
TeleCodex running
Auth: authenticated (cli)
Workspace: /home/.../tg-control-codex
Default launch profile: Default (workspace-write / never)
Session mode: per Telegram context
```

---

## 第七步：开始使用

在 TG 里搜你创建的 bot 用户名（如 `@my_codex_bot`），发送 `/start`。

---

# TG 命令参考

## 会话管理

| 命令             | 说明                              |
| -------------- | ------------------------------- |
| `/start`       | 欢迎信息 & 状态概览                     |
| `/help`        | 命令列表                            |
| `/new`         | 在当前聊天中创建新的 Codex 线程             |
| `/session`     | 查看当前线程 ID、workspace、模型、token 用量 |
| `/sessions`    | 浏览 `~/.codex` 中所有历史线程，点击按钮切换    |
| `/switch <id>` | 直接切换到指定线程 ID                    |
| `/attach <id>` | 绑定终端创建的 Codex 线程到当前 TG 会话（与 /handback 反向：终端 → TG）       |
| `/retry`       | 重发上一轮 prompt                    |
| `/abort`       | 取消当前正在执行的任务                     |

## 模型 & 配置

| 命令                 | 说明                                                     |
| ------------------ | ------------------------------------------------------ |
| `/model`           | 查看可用模型列表，点击切换                                          |
| `/effort`          | 设置推理力度：`minimal` · `low` · `medium` · `high` · `xhigh` |
| `/launch_profiles` | 选择启动配置（sandbox 模式 + 审批策略）                              |

## 认证 & 状态

| 命令        | 说明                       |
| --------- | ------------------------ |
| `/auth`   | 查看 Codex 认证状态            |
| `/login`  | 从 TG 发起 Codex 设备认证（无需终端） |
| `/logout` | 退出 Codex 登录              |
| `/voice`  | 查看语音转文字后端状态              |

## 交还 CLI

| 命令          | 说明                                |
| ----------- | --------------------------------- |
| `/handback` | 打印 `codex resume <id>` 命令，交还给终端操作 |

---


## `/handback` 详解：TG ↔ 终端无缝交接

`/handback` 让你把 TG 里正在用的 Codex 会话**交还给笔记本终端**继续操作——同一个线程，两边都能续。

### 典型场景

你在外面用手机 TG 跟 Codex 聊了半天写代码。回到笔记本前，想在终端里继续同一个线程。

### 操作流程

1. 在 TG 里发 `/handback`
2. Bot 回复：
   ```
   cd '/home/xiaofeng/Desktop/projects/tg-control-codex' && codex resume 'thread-abc123'
   ```
3. 终端粘贴执行 → Codex CLI 恢复同一个线程继续对话
4. TG 这边的 session 同时释放，可以随时 `/new` 起新线程
5. 反之亦然——终端创建的新线程也可以用 `/attach <id>` 拉到 TG 里续

# 多 Session 架构


> **注意：** 一个 TG 用户对一个 bot 只能有一个私聊窗口。以下两种方式实现多 session 隔离。

## 方式一：群组 + 论坛话题（推荐 ✅）

建一个只有你和 bot 的群组，开启 Topics（话题）。每个话题自动获得独立的 Codex session，互不干扰。

1. TG 新建群组 → 拉 bot 进去（搜 @你的bot用户名）
2. 群信息（点顶部群名） → Edit / 编辑 → 开启 Topics
3. 回到群聊界面 → 点右上角 **+ Create Topic** 创建话题

桌面端入口不太好找；手机端很简单，输入框左边直接有个 **✏️** 编辑图标，点进去就能建。

创建多个话题：

```
群组 "我的 Codex"
  ├── #前端重构      →  Codex Session A（独立 thread、独立 busy）
  ├── #数据库迁移    →  Codex Session B
  └── #写脚本        →  Codex Session C
```

> 源码层面：`context-key.ts` 用 `chatId:threadId` 做隔离，每个话题天然就是独立 session。

## 方式二：单窗口 + 命令切换

只在私聊窗口里操作，通过命令在不同线程间切换：

| 命令 | 说明 |
|---|---|
| `/sessions` | 列出 `~/.codex` 中所有历史线程，点按钮切换 |
| `/switch <id>` | 直接跳到指定线程 |
| `/new` | 起新线程（旧线程保留，随时切回） |

> 同一时间只有一个活跃 session，切走后随时能从 `/sessions` 列表回来。

# 其他输入方式

| 输入类型 | 说明                                                  |
| ---- | --------------------------------------------------- |
| 文字消息 | 直接发给 Codex 处理                                       |
| 语音消息 | 自动转文字（本地 parakeet-coreml 或 OpenAI Whisper）后发给 Codex |
| 图片   | 作为视觉输入传给 Codex（可附带文字说明）                             |
| 文件   | 上传到 workspace，Codex 处理后的生成文件自动回传 TG                 |

---

# 安全说明

- `TELEGRAM_ALLOWED_USER_IDS` 白名单限制只有指定用户能操作 bot
- 默认 sandbox 模式为 `workspace-write`（Codex 只能读写工作目录）
- `danger-full-access` 需要显式设置 `ENABLE_UNSAFE_LAUNCH_PROFILES=true`
- 默认 approval policy 为 `never`（自动执行所有操作，适合 headless 场景）
- `/login` 和 `/logout` 可通过 `ENABLE_TELEGRAM_LOGIN=false` 禁用

---

# 常见问题

### Q: Bot 不回复消息？

检查：

1. `TELEGRAM_ALLOWED_USER_IDS` 中是否包含你的用户 ID
2. Bot 进程是否在运行（`ps aux | grep tsx`）
3. 是否有 409 冲突（`pkill -f "tsx src/index"` 杀掉旧进程后重启）

### Q: Codex SDK 报 "Unable to locate Codex CLI binaries"？

确认 `src/codex-session.ts` 中已添加 `codexPathOverride`，且 codex 二进制路径正确（`which codex`）。

### Q: Auth 显示 not authenticated？

```bash
# 用 API Key
echo "CODEX_API_KEY=sk-..." >> .env

# 或用 CLI 登录
codex login
```

### Q: 如何后台运行？

```bash
nohup npm run dev > telecodex.log 2>&1 &

# 或使用 systemd service
```

---

# 快速启动脚本

创建 `~/start-telecodex.sh`：

```bash
#!/bin/bash
cd ~/Desktop/projects/tg-control-codex
export PATH="$HOME/.local/bin:$PATH"
pkill -f "tsx src/index" 2>/dev/null
sleep 1
nohup ./node_modules/.bin/tsx src/index.ts > /tmp/telecodex.log 2>&1 &
echo "TeleCodex started. Logs: /tmp/telecodex.log"
echo "Bot: @你的bot用户名"
```

```bash
chmod +x ~/start-telecodex.sh
~/start-telecodex.sh
```

---

# 排障：409 Conflict / Bot 不回复

## 现象

终端里反复出现：

```text
Polling error (attempt 1/5): Call to 'getUpdates' failed! (409: Conflict: terminated by other getUpdates request; make sure that only one bot instance is running)
Restarting polling in 3s...
```

或者 TG 里 `/start`、`/new` 有时有回复，有时普通消息不回复。

## 原因

同一个 Telegram bot token **只能有一个进程在调用 `getUpdates` 长轮询**。

如果你同时开了多个：

```bash
npm run dev
rtk npm run dev
nohup npm run dev &
./telecodex-watchdog.sh
```

就会互相抢消息，Telegram 返回 `409 Conflict`，其中一个实例会被踢掉，表现为 bot 时好时坏。

## 检查是否有多个 TeleCodex 实例

```bash
ps -eo pid,ppid,stat,etime,cmd \
  | grep -E 'tg-control-codex|tsx src/index|npm run dev|telecodex-watchdog' \
  | grep -v grep
```

如果看到多组类似下面的进程，就说明重复启动了：

```text
970940 npm run dev
970952 sh -c tsx src/index.ts
970964 node ... tsx ... src/index.ts
971607 npm run dev
971618 sh -c tsx src/index.ts
971630 node ... tsx ... src/index.ts
```

## 清理重复实例

```bash
pkill -f 'tsx src/index'
pkill -f 'npm run dev'
pkill -f 'telecodex-watchdog'
```

确认已清空：

```bash
ps -eo pid,ppid,stat,etime,cmd \
  | grep -E 'tg-control-codex|tsx src/index|npm run dev|telecodex-watchdog' \
  | grep -v grep
```

没有输出才说明清理干净。

## 正确启动方式

只开**一个终端窗口**，运行：

```bash
cd ~/Desktop/projects/tg-control-codex
npm run dev
```

保持这个终端不要关闭。关闭终端后 bot 就会停止。

## 不推荐的启动方式

不要用下面这些方式同时跑多个实例：

```bash
rtk npm run dev          # 不推荐跑长期服务
nohup npm run dev &      # 容易忘记后台进程还在
./telecodex-watchdog.sh  # 容易和手动 npm run dev 冲突
```

如果必须后台运行，先确认没有前台实例，再只保留一个后台实例。

## 重点结论

- `409 Conflict` = 多个 bot 实例抢同一个 token
- 清掉所有旧进程后，只启动一个 `npm run dev`
- 长期服务不要用 `rtk npm run dev`
