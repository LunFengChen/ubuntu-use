# Ghostty + fish + tmux 使用指南

记录本机在 Ghostty 终端里配合 fish 和 tmux 的使用方式。目标是：日常终端体验现代化，同时让长期运行的命令不因为 Zed、Ghostty 或 SSH 断开而丢失。

## 三者关系

```text
Ghostty 窗口
└── tmux 会话
    └── fish shell
        └── npm / python / ssh / 编译任务
```

- **Ghostty**：终端模拟器，负责显示终端窗口、字体、颜色、键盘输入。
- **fish**：shell，负责命令补全、历史预测、alias、环境变量。
- **tmux**：终端会话管理器，负责让终端会话在窗口关闭、终端崩溃或 SSH 断开后继续存在。

fish 和 tmux 不冲突。tmux 里面可以继续使用 fish。

## 什么时候需要 tmux

如果只是开一个终端敲几条命令，Ghostty + fish 就够了。

如果有下面场景，建议进 tmux：

- 长时间跑 `npm run dev`、`pnpm dev`、`python server.py`；
- 编译 AOSP、Rust、Android、Native 项目；
- 长时间下载、训练、跑脚本；
- SSH 到远程机器工作；
- 希望关闭 Ghostty 或 Zed 后任务继续跑；
- 希望重启终端后回到原来的窗口/分屏状态。

一句话：

```text
Ghostty 是终端外壳；tmux 是终端任务保险箱。
```

## 当前安装结果

当前 tmux 版本：

```text
tmux 3.6b
```

安装位置：

```text
~/.local/bin/tmux
```

因为本机 `sudo` 需要交互密码，本次没有通过 apt 安装，而是把依赖和 tmux 安装到用户目录：

```text
~/.local/lib/libevent_core-2.1.so.7
~/.local/bin/tmux
```

fish 路径：

```text
/usr/bin/fish
```

## 当前 tmux 配置

配置文件：

```text
~/.config/tmux/tmux.conf
```

当前内容：

```tmux
set -g mouse on
set -g history-limit 50000
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:RGB,ghostty:RGB"
set -g default-shell "/usr/bin/fish"
```

含义：

- 开启鼠标选择窗格、调整窗格；
- scrollback 历史加到 50000 行；
- 使用 `tmux-256color`；
- 对 Ghostty 启用 RGB/真彩色兼容；
- tmux 新窗口默认进入 fish。

## 最常用命令

新建一个名为 `dev` 的会话：

```fish
tmux new -s dev
```

查看已有会话：

```fish
tmux ls
```

重新进入已有会话：

```fish
tmux attach -t dev
```

如果只有一个会话，也可以：

```fish
tmux attach
```

杀掉指定会话：

```fish
tmux kill-session -t dev
```

杀掉所有 tmux 会话和 server：

```fish
tmux kill-server
```

## 最少需要记住的快捷键

tmux 默认前缀键是：

```text
Ctrl+B
```

常用快捷键：

| 快捷键 | 作用 |
|---|---|
| `Ctrl+B` 然后 `D` | detach，离开 tmux，但任务继续跑 |
| `Ctrl+B` 然后 `C` | 新建窗口 |
| `Ctrl+B` 然后 `N` | 下一个窗口 |
| `Ctrl+B` 然后 `P` | 上一个窗口 |
| `Ctrl+B` 然后 `"` | 上下分屏 |
| `Ctrl+B` 然后 `%` | 左右分屏 |
| `Ctrl+B` 然后方向键 | 切换窗格 |
| `Ctrl+B` 然后 `X` | 关闭当前窗格 |
| `Ctrl+B` 然后 `[` | 进入复制/滚动模式 |

刚开始只记这两个就够：

```text
tmux new -s dev
Ctrl+B，然后 D
```

回来时：

```fish
tmux attach -t dev
```

## 推荐工作流

### 项目开发

进入项目目录后：

```fish
cd ~/Desktop/projects/my-project
tmux new -s my-project
```

在 tmux 里跑开发服务：

```fish
npm run dev
```

如果要离开但保留任务：

```text
Ctrl+B，然后 D
```

之后重新打开 Ghostty：

```fish
tmux attach -t my-project
```

### 长时间编译

```fish
tmux new -s build
```

然后在里面执行：

```fish
make -j(nproc)
```

或者：

```fish
./gradlew assembleDebug
```

这样即使终端窗口关了，编译也不会因为终端退出而中断。

### SSH 远程工作

建议在远程机器上启动 tmux，而不只是本地启动：

```fish
ssh user@server
```

远程 shell 里：

```fish
tmux new -s remote-work
```

如果网络断了，重新 SSH 后：

```fish
tmux attach -t remote-work
```

## 和 Zed 的配合建议

Zed 内置终端适合临时命令，不适合长期任务。

推荐分工：

| 工具 | 适合做什么 |
|---|---|
| Zed | 编辑代码、项目搜索、语法高亮、LSP、Git |
| Zed 内置终端 | 临时跑命令、快速查看输出 |
| Ghostty + fish | 日常终端交互 |
| Ghostty + tmux + fish | 长期任务、远程 SSH、编译、dev server |

如果担心 Zed 崩溃或关闭导致终端任务丢失，把任务放进 tmux。

## 常见问题

### 我用的是 fish，还能用 tmux 吗？

可以。tmux 不是 shell，而是 shell 外面的一层会话管理器。当前配置已经让 tmux 默认启动 `/usr/bin/fish`。

### Ghostty 已经有分屏，还需要 tmux 吗？

Ghostty 分屏负责“显示布局”，tmux 负责“会话存活”。

Ghostty 关闭后，普通 shell 任务通常会退出；tmux detach 后，任务会继续跑。

### 关掉 Ghostty 后 tmux 会不会死？

如果是正常 detach 或窗口关闭，tmux server 通常会继续留在后台。重新打开 Ghostty 后执行：

```fish
tmux attach
```

即可回去。

### 怎么确认自己是否在 tmux 里？

```fish
echo $TMUX
```

有输出一般表示在 tmux 里。

### 怎么彻底退出当前 tmux 会话？

在 tmux 里的每个 shell 执行：

```fish
exit
```

或者从外面杀掉：

```fish
tmux kill-session -t dev
```

## 回滚/卸载

本次是用户目录安装。移除 tmux：

```bash
rm -f ~/.local/bin/tmux
rm -rf ~/.config/tmux
```

如果确认 `~/.local/lib` 里的 libevent 只给 tmux 使用，也可以移除相关文件：

```bash
rm -f ~/.local/lib/libevent*.so*
rm -f ~/.local/lib/libevent*.a
rm -f ~/.local/lib/libevent*.la
rm -f ~/.local/lib/pkgconfig/libevent*.pc
rm -rf ~/.local/include/event2
rm -f ~/.local/include/event.h ~/.local/include/ev*.h
```

注意：如果以后其他用户目录编译的软件也依赖这份 libevent，不要直接删除。
