# Bash 终端配置：历史隔离与命令预测提示

记录 Bash 终端的两项核心配置修改，解决默认体验的两个痛点。

## 痛点1：按上下键会跨终端找历史记录

### 原因

`~/.bashrc` 里的 `__history_sync` 函数同时做了两件事：

```bash
history -a   # 把当前终端的新命令追加到 ~/.bash_history
history -n   # 从 ~/.bash_history 读取其他终端新写进来的命令
```

`history -n` 导致每个终端的 `history` 列表混入其他终端的命令，按上下键时也被混在一起。

### 修复

去掉 `history -n`，只保留 `history -a`：

```bash
__history_sync() {
    history -a
}
```

现在：
- **↑/↓**：只看当前终端的历史记录
- **全部历史搜索**：仍然可以通过 `Ctrl+R`（fzf）或 ble.sh 的预测提示访问

## 痛点2：命令提示只有单个词，不是完整命令行

### 原因

Bash 自带的 Tab 补全（bash-completion）是按词补全的，不会从历史记录中预测完整命令。

### 方案：ble.sh（Bash Line Editor）

安装 [ble.sh](https://github.com/akinomyoga/ble.sh) 提供类似 PowerShell PSReadLine、fish、zsh-autosuggestions 的体验：

- **输入时自动显示完整命令预测**（灰色提示文字）
- 按 **Ctrl+F** 或 **→** 接受建议
- 语法高亮
- 增强的补全菜单

### 安装方式

安装到用户目录（不需要 root）：

```bash
# 下载 release tarball
curl -sSfL -o /tmp/ble.tar.xz \
  "https://github.com/akinomyoga/ble.sh/releases/download/v0.4.0-devel3/ble-0.4.0-devel3.tar.xz"

# 解压到用户目录
mkdir -p ~/.local/share/blesh
tar -xJf /tmp/ble.tar.xz -C ~/.local/share/blesh --strip-components=1
```

然后在 `~/.bashrc` 中添加：

```bash
if [[ $- == *i* && -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    source -- "$HOME/.local/share/blesh/ble.sh"
fi
```

### ble.sh 与 Ghostty 的兼容性

极少数情况下，ble.sh 可能导致 Ghostty 下第一次 Starship 提示重复绘制。如果遇到，可以在打开的第一个终端里运行：

```bash
BASH_ENABLE_BLESH=1 bash
```

或者暂时禁用它（注释掉 `~/.bashrc` 中的加载行）。

## 附加增强：fzf 模糊搜索

配合 [fzf](https://github.com/junegunn/fzf)（已安装 0.73.1），提供更多搜索能力：

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+R` | 模糊搜索全部历史记录（所有终端） |
| `Ctrl+T` | 模糊搜索文件名并粘贴 |
| `Alt+C`  | 模糊切换工作目录 |

`~/.bashrc` 中通过以下方式加载：

```bash
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
fi
```

## 最终行为总结

| 操作 | 搜索范围 | 来源 |
|------|----------|------|
| ↑/↓ 翻历史 | 仅当前终端 | `history -a` |
| Ctrl+R | 全部终端历史 | fzf 读 `~/.bash_history` |
| 输入时预测提示（灰色） | 全部终端历史 | ble.sh 读 `~/.bash_history` |
| Tab 补全 | 命令/参数/文件 | bash-completion + ble.sh |

## 已修改的文件

```text
~/.bashrc     # 去掉 history -n，启用 ble.sh，加载 fzf 绑定
~/.local/share/blesh/   # ble.sh v0.4.0-devel3 安装目录
```
