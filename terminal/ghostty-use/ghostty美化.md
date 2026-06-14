# Ghostty 美化教程

这份文档专门讲 Ghostty 本身怎么美化。Prompt 怎么显示用户、Git、CPU、内存，见 [终端美化.md](./终端美化.md)。

当前真机效果截图如下。截图来自当前电脑，CPU、内存、主机名等信息会随机器和运行状态变化：

![Ghostty 真机截图](./images/terminal-real.png)

## Ghostty 负责什么

Ghostty 是终端模拟器，它主要控制这些东西：

- 背景色
- 字体和字号
- 窗口边距
- 光标样式
- 选中文本的颜色
- 终端主题

它不负责显示 Git 分支、CPU、内存。这些是 Starship prompt 负责的。

## 配置文件在哪里

Ghostty 配置文件是：

```bash
~/.config/ghostty/config
```

仓库里有一份可参考配置：

```bash
configs/ghostty.config
```

修改这个文件后，通常新开一个 Ghostty 窗口就能看到效果。

修改后可以验证配置是否写错：

```bash
ghostty +validate-config
```

没有输出就表示配置通过。

## 当前配置

当前最终配置如下：

```conf
theme = Everforest Dark Hard

font-family = "JetBrainsMono Nerd Font"
font-size = 13

background = #181818
foreground = #d8d8d8
background-opacity = 1.0
background-blur = false

window-padding-x = 10
window-padding-y = 8
window-decoration = true

cursor-style = block
cursor-style-blink = true
cursor-color = #a7c080

selection-background = #2a2a2a
selection-foreground = #eeeeee
```

## 背景怎么选

当前背景是：

```conf
background = #181818
```

这是中性深灰，比纯黑柔和，但不偏蓝、不偏绿。

之前试过几个方向：

```conf
background = #0b0f0d  # 偏墨绿，感觉抽象
background = #111111  # 更接近黑色，但偏暗
background = #181818  # 当前值，深灰、柔和、可读性好
```

如果之后还想调，可以按这个思路：

更黑：

```conf
background = #121212
```

更亮：

```conf
background = #202020
```

更接近 VS Code 深色：

```conf
background = #1e1e1e
```

改完保存，开新窗口看效果。

## 为什么关掉透明度

当前是：

```conf
background-opacity = 1.0
background-blur = false
```

含义：

- `1.0` 表示完全不透明
- `false` 表示不做模糊

这样做的好处是文字更稳，不会被桌面背景干扰。你之前说“不需要透明度这么高”，最终这里选择了完全不透明。

如果以后想要一点点透明：

```conf
background-opacity = 0.96
background-blur = false
```

不建议开很强的透明和模糊，长时间看代码会更累。

## 字体为什么用 Nerd Font

当前字体是：

```conf
font-family = "JetBrainsMono Nerd Font"
font-size = 13
```

`JetBrainsMono Nerd Font` 的作用不是只让字好看，更重要的是让真实 Ghostty 里的 prompt 图标正常显示：

```text
            󰍛
```

如果不用 Nerd Font，这些图标可能会变成方块。注意：Markdown 预览器和浏览器不一定会使用 Ghostty 的字体设置；真实效果以 Ghostty 新窗口为准。

想确认字体是否安装成功：

```bash
fc-match "JetBrainsMono Nerd Font"
```

想确认 Ghostty 是否真的在用这个字体：

```bash
ghostty +show-config | grep font-family
```

## 字号和边距怎么调

当前字号：

```conf
font-size = 13
```

如果你觉得字小：

```conf
font-size = 14
```

如果你觉得字大：

```conf
font-size = 12
```

当前边距：

```conf
window-padding-x = 10
window-padding-y = 8
```

含义：

- `x` 是左右边距
- `y` 是上下边距

更紧凑：

```conf
window-padding-x = 8
window-padding-y = 6
```

更宽松：

```conf
window-padding-x = 14
window-padding-y = 10
```

## 光标怎么调

当前光标：

```conf
cursor-style = block
cursor-style-blink = true
cursor-color = #a7c080
```

含义：

- `block` 是块状光标
- `blink = true` 表示闪烁
- `#a7c080` 是低饱和绿色

如果不喜欢闪烁：

```conf
cursor-style-blink = false
```

如果想用竖线光标：

```conf
cursor-style = bar
```

## 主题怎么换

当前主题：

```conf
theme = Everforest Dark Hard
```

Ghostty 自带很多主题，可以查看：

```bash
ghostty +list-themes
```

可试的深色主题：

```conf
theme = Everforest Dark Hard
theme = Gruvbox Dark Hard
theme = Kanagawa Dragon
theme = Catppuccin Mocha
theme = Dracula
theme = Nord
```

注意：如果主题本身设置了背景色，你又手动写了 `background = #181818`，最终背景会以手动设置为准。

## 选中文本颜色

当前选中颜色：

```conf
selection-background = #2a2a2a
selection-foreground = #eeeeee
```

含义：

- 选中区域是深灰
- 选中文字是浅灰白

如果选中不明显，可以把背景调亮一点：

```conf
selection-background = #3a3a3a
```

## 推荐调整顺序

以后你想继续调 Ghostty，建议按这个顺序：

1. 先调 `background`
2. 再调 `foreground`
3. 再调 `font-size`
4. 最后调 `window-padding-x/y`

不要一口气换主题、换背景、换字体、换 prompt。一次只改一类，比较容易判断哪里变好了、哪里变差了。

## 常用检查命令

验证 Ghostty 配置：

```bash
ghostty +validate-config
```

查看 Ghostty 当前实际配置：

```bash
ghostty +show-config
```

只看关键项：

```bash
ghostty +show-config | grep -E "^(theme|background|foreground|font-family|font-size)"
```

查看可用主题：

```bash
ghostty +list-themes
```

查看字体是否可用：

```bash
fc-match "JetBrainsMono Nerd Font"
```
