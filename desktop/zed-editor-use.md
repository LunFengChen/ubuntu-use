# Zed 编辑器安装与使用记录

记录本机在 Ubuntu 上使用 Zed 的安装方式、语法选择、快捷键和崩溃恢复预期。

## 当前结论

Zed 适合作为 Linux 上的现代轻量代码编辑器：

- 比 Vim/Emacs 这类传统编辑器更符合现代 GUI 使用习惯；
- 启动和交互速度快；
- 支持 LSP、语法高亮、项目搜索、Git、AI/Agent 等能力；
- 适合日常写代码，终端长期任务则建议交给 Ghostty + tmux。

当前版本：

```text
Zed 1.7.2
```

安装位置：

```text
~/.local/zed.app
~/.local/bin/zed
~/.local/share/applications/dev.zed.Zed.desktop
```

## 安装记录

官方安装脚本：

```bash
curl -f https://zed.dev/install.sh | sh
```

本次实际安装时，官方下载源到本机网络很慢，因此改为下载官方 Linux tarball 后手动按官方脚本逻辑安装到用户目录。

验证：

```bash
zed --version
```

输出：

```text
Zed 1.7.2 aa8ac4b04e261f19c2465f68e9ce2fa9721ae1a2  – /home/xiaofeng/.local/zed.app/libexec/zed-editor
```

## 常用启动方式

打开 Zed：

```bash
zed
```

打开当前目录：

```bash
zed .
```

打开指定目录或文件：

```bash
zed ~/Desktop/projects/ubuntu-use
zed README.md
```

## 未保存文件的语法高亮

Zed 默认通常根据文件名或扩展名判断语言。新建的未保存文件没有扩展名，所以可能先显示为 Plain Text。

不需要保存文件也可以手动选择语言：

```text
Ctrl+Shift+L
```

或者使用本机额外配置的快捷键：

```text
Ctrl+K，然后 M
```

然后输入语言名称，例如：

```text
python
javascript
typescript
html
css
rust
markdown
```

回车后即可对当前未保存 buffer 启用对应语法高亮。

## 当前快捷键配置

配置文件：

```text
~/.config/zed/keymap.json
```

当前内容：

```json
[
  {
    "bindings": {
      "ctrl-k m": "language_selector::Toggle"
    }
  }
]
```

这个快捷键的目的：模仿 VS Code 的 `Ctrl+K M` 语言模式选择习惯。

Zed 默认也有语言选择器快捷键：

```text
Ctrl+Shift+L
```

## 崩溃恢复预期

Zed 有 session/workspace 恢复能力，正常关闭后再次打开，通常会恢复：

- 上次打开的项目或窗口；
- 打开的标签页；
- 部分未保存 buffer；
- 光标位置和布局等编辑状态。

如果是崩溃，Zed 也会尽量恢复最近状态，但不要把它当成绝对可靠的持久化机制。重要内容仍然应该及时保存或提交到 Git。

## 终端恢复预期

Zed 的内置终端不适合承担“长期任务保险箱”的角色。

一般预期：

- 终端面板位置可能恢复；
- 终端里正在跑的命令通常不会可靠恢复；
- `npm run dev`、`python server.py`、`ssh`、`htop` 等进程在 Zed 崩溃或关闭后不要指望还在。

长期任务建议放在外部终端 Ghostty 里的 tmux 会话中。

推荐组合：

```text
Zed：写代码、看项目、编辑文件
Ghostty：日常终端
fish：交互 shell
tmux：长期任务和崩溃/断开后的会话恢复
```

## 轻量编辑器选择建议

当前个人排序：

```text
首选现代 GUI：Zed
稳定快速备选：Sublime Text
开源稳妥备选：Kate
轻量 IDE：Geany
终端里替代 Vim/Nano：micro
```

Zed 的优点：

- 现代 GUI；
- 响应快；
- 开源；
- Linux 官方支持；
- 项目、LSP、Git、AI 能力比较完整。

Zed 的限制：

- 插件生态不如 VS Code/Sublime 成熟；
- Linux 图形栈和显卡驱动组合可能带来边角问题；
- 终端任务恢复不如 tmux；
- 只是临时改配置文件时，`micro` 这类终端编辑器更直接。

## 回滚/卸载

如果只想移除用户目录安装的 Zed：

```bash
rm -rf ~/.local/zed.app
rm -f ~/.local/bin/zed
rm -f ~/.local/share/applications/dev.zed.Zed.desktop
```

如果要保留程序但清理用户配置，需要谨慎处理：

```bash
# 会删除 Zed 配置和状态，执行前确认不需要恢复旧会话
rm -rf ~/.config/zed
rm -rf ~/.local/share/zed
```
