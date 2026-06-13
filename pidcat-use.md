# pidcat 在 Ubuntu 下的安装与使用记录

本文记录我在 Ubuntu 桌面环境下使用 Android `logcat` 过滤工具 `pidcat` 的方式，包括为什么保留它、这次的实际安装结果、Python 3 兼容修正，以及常用命令。

对应时间点：`2026-06-13`。

## 为什么还留 `pidcat`

现在官方 `adb logcat` 已经支持 `--pid`、`--regex` 等过滤能力，通用性更强。

但 `pidcat` 依然有一个很实用的点：

- 直接按 **应用包名** 看日志
- 自带彩色输出
- 不用每次先查 PID
- 适合只盯一个 app 的日常调试

也就是说：

- **通用/脚本化/官方能力优先**：`adb logcat`
- **单 app 日常盯日志更省心**：`pidcat`

## 这台机器当前结果

当前机器上：

- `adb` 已安装：`/usr/bin/adb`
- `pidcat` 已安装到：`~/.local/bin/pidcat`
- `pidcat` 当前版本：`2.1.0`

这次没有走 `sudo apt install pidcat`，因为当前 shell 里 `sudo` 需要交互输入密码；为了不依赖 root，改成了**用户态安装**。

当前确认结果：

```text
command -v pidcat -> /home/xiaofeng/.local/bin/pidcat
pidcat -v         -> pidcat 2.1.0
adb version       -> 34.0.4-debian
```

另外，本机还补了一层 **Python 3 兼容修正**，因为直接下载上游 raw 脚本时，实际运行可能会出现：

```text
b'...'
```

也就是把整行日志当成 `bytes` 打印出来。

## 推荐安装方式

### 方式 1：有 sudo 时，优先直接用 apt

```bash
sudo apt install pidcat
```

这种方式最省事，也更适合长期由系统包管理。

### 方式 2：没有 sudo 时，用用户态安装

本机这次实际采用的是这个方式。

先下载安装：

```bash
mkdir -p ~/.local/bin
curl -L https://raw.githubusercontent.com/JakeWharton/pidcat/master/pidcat.py -o ~/.local/bin/pidcat
chmod +x ~/.local/bin/pidcat
```

然后做 Python 3 兼容修正：

```bash
python3 - <<'PY'
from pathlib import Path
p = Path.home() / '.local/bin' / 'pidcat'
text = p.read_text()
repls = {
    '#!/usr/bin/env -S python -u': '#!/usr/bin/env python3',
    '  running_package_name = re.search(".*TaskRecord.*A[= ]([^ ^}]*)", str(system_dump)).group(1)': '''  if isinstance(system_dump, bytes):
    system_dump = system_dump.decode('utf-8', 'replace')
  match = re.search(".*TaskRecord.*A[= ]([^ ^}]*)", system_dump)
  if match is None:
    print('Unable to determine current app from dumpsys output.', file=sys.stderr)
    sys.exit(1)
  running_package_name = match.group(1)''',
    'named_processes = map(lambda package: package if package.find(":") != len(package) - 1 else package[:-1], named_processes)': 'named_processes = list(map(lambda package: package if package.find(":") != len(package) - 1 else package[:-1], named_processes))',
    'def colorize(message, fg=None, bg=None):\n  return termcolor(fg, bg) + message + RESET if stdout_isatty else message': '''def colorize(message, fg=None, bg=None):
  return termcolor(fg, bg) + message + RESET if stdout_isatty else message

def readline_text(stream):
  line = stream.readline()
  if isinstance(line, bytes):
    line = line.decode('utf-8', 'replace')
  return line.strip()''',
    "    line = ps_pid.stdout.readline().decode('utf-8', 'replace').strip()": '    line = readline_text(ps_pid.stdout)',
    "    line = adb.stdout.readline().decode('utf-8', 'replace').strip()": '    line = readline_text(adb.stdout)',
    "  print(linebuf.encode('utf-8'))": '  print(linebuf)',
}
for old, new in repls.items():
    if old not in text:
        raise SystemExit(f'missing patch pattern: {old[:60]!r}')
    text = text.replace(old, new)
p.write_text(text)
PY
```

如果 `~/.local/bin` 已在 PATH 里，装完后执行：

```bash
pidcat -v
```

即可。

## 这次本机修了什么

本机这次针对用户态 `pidcat` 补了几处修正：

- shebang 改成 `python3`
- `map(...)` 改成 `list(map(...))`，避免 Python 3 迭代器行为差异
- 增加统一的 bytes/str 读取处理
- `--current` 场景先 decode `dumpsys` 输出
- 最终输出从 `print(linebuf.encode(...))` 改成 `print(linebuf)`

修完后，终端里实际运行 `pidcat <package>` 已确认**不再打印 `b'...'` 前缀**。

## 常用命令

### 按包名看日志

```bash
pidcat com.example.app
```

这是最常用场景。

### 只看当前前台 app

```bash
pidcat --current
```

适合你已经把 app 切到前台，不想手打包名。

### 清空旧日志再看

```bash
pidcat -c com.example.app
```

适合只想看“这一次启动/点击”产生的日志。

### 只看错误级别以上

```bash
pidcat -l E com.example.app
```

常见级别：

- `V`
- `D`
- `I`
- `W`
- `E`
- `F`

### 只保留特定 tag

```bash
pidcat -t ActivityManager -t AndroidRuntime com.example.app
```

### 忽略某些 tag

```bash
pidcat -i OpenGLRenderer -i ViewRootImpl com.example.app
```

### 同时看多个包

```bash
pidcat com.example.app com.example.helper
```

## 什么时候直接改用 `adb logcat`

`pidcat` 适合“看某个 app 的实时日志”，但下面这些场景还是更建议直接上 `adb logcat`：

- 要看 `crash` buffer
- 要看 `system` / `radio` / `events`
- 要按 `pid` 精确过滤
- 要做正则过滤
- 要把日志导出到文件长期分析

例如：

```bash
adb logcat -b crash
adb logcat --pid 12345
adb logcat -v threadtime > logcat.txt
```

## 本机验证命令

这次实际做过的有效验证：

```bash
command -v pidcat
pidcat -v
pidcat --help | sed -n '1,40p'
printf '%s\n' "W/cr_AwAutofillManager( 1234): Autofill is disabled" | pidcat -a
```

另外还做了真实终端短时验证：

```bash
timeout 3s pidcat <你的包名>
```

当前有效结果：

- `pidcat` 可执行路径正确
- `pidcat --help` 正常输出
- `pidcat -v` 返回 `2.1.0`
- 模拟输入和真实终端输出都已确认**没有 `b'...'` 前缀**
- `adb` 已安装且可调用

## 我的结论

Ubuntu 下如果你已经有 `adb`，那么：

- **最稳的基础方案**：`adb logcat`
- **最好用的单 app 终端体验**：`pidcat`

所以 `pidcat` 不是必须替代 `adb`，而是一个非常顺手的补充工具。
