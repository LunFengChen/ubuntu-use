# Fish Shell 试用迁移记录：补全、历史预测与 adb 手机路径

这篇记录本次从 Bash 终端体验问题出发，对 Bash、fzf、tmux、ble.sh 和 fish 的实际试验结论。当前最终方案是：**保留 Bash 不动，安装并配置 fish 作为可试用 shell**。

## 背景问题

原始痛点有两个：

1. Bash 的 `↑/↓` 历史在多个终端之间混在一起，不适合常驻 CLI 场景。
2. Bash 的命令提示/补全偏“单词补全”，不像 PowerShell PSReadLine 那样能从历史里提示完整命令。

后来又补充了 adb 场景：

```bash
adb -s 13081FDD4002VL push Desktop/reqable-ca.crt /sdcard/
```

希望在手机路径位置按 Tab 时，可以看到手机里的路径候选，并且能像选择器一样上下选择，而不是把候选刷满终端日志。

## 试过但放弃的方案

### Bash + ble.sh

`ble.sh` 可以给 Bash 提供类似 PSReadLine 的历史预测，但在当前 Ghostty + Starship 环境下出现过 prompt 重复绘制：

```text
同一个 Starship prompt 出现两次
```

即使尝试调整 `bleopt`，体验也不够稳定，所以最终没有继续使用。

### Bash + fzf Tab completion

试过 `fzf-tab-completion` 和自定义 `bind -x`。问题是：

- Bash/Readline 在调用外部选择器前后会重绘命令行，容易闪烁；
- 全局接管 Tab 会破坏普通补全，例如 `adb -s <Tab>`；
- 对 adb 手机远程路径这种动态候选，稳定性不如 shell 原生 pager。

结论：**fzf 很适合 `Ctrl+R` 历史搜索、文件选择等显式动作，但不适合强行替代 Bash 的 Tab 补全主流程。**

### tmux popup

`tmux` 的 popup 可以减少 fzf 重绘感，但 tmux 本身是终端复用器，不是 shell。为了解决补全问题引入 tmux 过重，体验也不符合当前习惯，所以已卸载并清理。

## 为什么选择 fish

fish 的关键优势是：补全选择器、历史预测、历史搜索都在 shell 内部实现，不依赖外部 fzf 接管 Tab，因此更接近想要的体验。

fish 源码里相关位置：

```text
fish autosuggestion:
/tmp/fish-shell/src/complete.rs
/tmp/fish-shell/src/history/history.rs
/tmp/fish-shell/src/highlight/highlight.rs

fish pager / key binding:
/tmp/fish-shell/share/functions/__fish_shared_key_bindings.fish
/tmp/fish-shell/src/input/binding.rs

fish adb completion:
/tmp/fish-shell/share/completions/adb.fish
```

默认按键里能看到：

```fish
bind --preset $argv tab complete
bind --preset $argv shift-tab complete-and-search
bind --preset $argv ctrl-s pager-toggle-search
bind --preset $argv down down-or-search
bind --preset $argv up up-or-search
bind --preset $argv ctrl-r history-pager
```

也就是说：

- `Tab` 打开/操作补全 pager；
- `Shift+Tab` 进入补全搜索；
- `↑/↓` 可以在 pager 或历史中移动；
- `Ctrl+R` 是 fish 原生历史 pager；
- 输入命令时 fish 会显示灰色 autosuggestion，右方向键接受。

## fish 的 adb 手机路径补全

fish 自带 `adb.fish`，其中核心逻辑是用当前命令行里的 `-s` 参数拼回 adb 命令，再列手机文件：

```fish
function __fish_adb_run_command -d 'Runs adb with any -s parameters already given on the command line'
    ...
    adb $sopt shell $argv | string replace -a \r ''
end

function __fish_adb_list_files
    set -l token (commandline -ct)

    if test -z "$token"
        set token /
    end

    __fish_adb_run_command find -H "$token*" -maxdepth 0 -type d 2\>/dev/null | string replace -r '$' /
    __fish_adb_run_command find -H "$token*" -maxdepth 0 -type f 2\>/dev/null
end
```

对应补全：

```fish
complete -n '__fish_seen_subcommand_from pull' -c adb -F -a "(__fish_adb_list_files)" -d 'File on device'
complete -n '__fish_seen_subcommand_from push' -c adb -ka "(__fish_adb_list_files)" -d 'File on device'
complete -n '__fish_seen_subcommand_from push' -c adb -ka "(__fish_adb_list_local_files)"
```

本机验证：

```fish
complete -C "adb -s "
```

输出包含：

```text
13081FDD4002VL    redfin Pixel_5
35051FDH2000NQ    aosp_panther AOSP_on_Panther
```

手机路径补全验证：

```fish
complete -C "adb -s 13081FDD4002VL push Desktop/reqable-ca.crt /sdcard/"
```

输出包含：

```text
/sdcard/Alarms/       File on device
/sdcard/Android/      File on device
/sdcard/DCIM/         File on device
/sdcard/Download/     File on device
/sdcard/EVPlayer/     File on device
```

## 当前安装结果

安装命令：

```bash
sudo apt install fish
```

当前版本：

```text
fish 3.7.0
```

fish 路径：

```text
/usr/bin/fish
```

当前没有把默认 shell 改成 fish，只是试用：

```bash
fish
```

退出 fish 回 Bash：

```fish
exit
```

## 当前 fish 配置

配置文件：

```text
~/.config/fish/config.fish
~/.config/fish/functions/fish_greeting.fish
```

当前 `config.fish` 负责：

- 加入 `~/.local/bin`、`~/bin`、`~/Applications`；
- 加入 `~/.cargo/bin`；
- 初始化 `pyenv`；
- 设置 `SDKMAN_DIR` 并加入当前 Java 路径；
- 固定使用 Node `v24.16.0`；
- 启用 Starship；
- 添加常用 alias。

关键配置：

```fish
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/bin
fish_add_path -g $HOME/Applications
fish_add_path -g $HOME/.cargo/bin

set -gx PYENV_ROOT $HOME/.pyenv
fish_add_path -g $PYENV_ROOT/bin
if type -q pyenv
    pyenv init - fish | source
end

set -gx SDKMAN_DIR $HOME/.sdkman
fish_add_path -g $SDKMAN_DIR/candidates/java/current/bin

set -l nvm_node_v24 $HOME/.nvm/versions/node/v24.16.0/bin
if test -d $nvm_node_v24
    fish_add_path -g $nvm_node_v24
end

if type -q starship
    starship init fish | source
end
```

关闭 fish 欢迎语：

```fish
function fish_greeting
end
```

## 已验证的工具

在 fish 中验证过：

```text
node   v24.16.0
npm    11.13.0
python Python 3.14.6
java   openjdk 21.0.11
adb    Android Debug Bridge 1.0.41
starship 1.25.1
```

也验证了这些命令可用：

```text
pyenv
fzf
rg
fd
bat
eza
code
gh
cargo
rustc
```

## Bash 历史导入 fish

为了让 fish 的 autosuggestion 试用时就有历史数据，已从 `~/.bash_history` 导入部分历史到：

```text
~/.local/share/fish/fish_history
```

本次导入数量：

```text
381 条
```

验证：

```fish
history search --prefix adb --max 5
```

可以看到 adb 相关历史命令。

## 当前未做的事

还没有执行：

```bash
chsh -s /usr/bin/fish
```

也就是说：

- 默认 shell 仍是 Bash；
- fish 只是手动输入 `fish` 后进入；
- Bash 配置没有被 fish 覆盖。

如果试用几天后确认满意，再考虑改默认 shell。

## 回滚方式

如果不想继续试 fish：

```bash
sudo apt remove --purge fish fish-common
rm -rf ~/.config/fish
rm -rf ~/.local/share/fish
```

如果只是退出当前 fish：

```fish
exit
```

## 结论

这次的核心结论：

- Bash + 外部 fzf 很难把 Tab 补全做成“不闪、可选、可搜索”的原生体验；
- ble.sh 能改善 Bash，但与当前 Ghostty + Starship 组合不够稳；
- fish 原生支持历史预测、补全 pager、adb 手机路径补全，更符合当前想要的终端体验；
- 最稳迁移方式是：先保留 Bash，fish 配好后手动试用，确认满意后再 `chsh`。
