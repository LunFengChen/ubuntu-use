# AOSP 编译 nofile 持久化配置

记录时间：`2026-06-23`。

## 背景

AOSP / Soong / Ninja 编译会同时打开大量源码、jar、class 和中间产物文件。如果 shell 或 systemd 用户会话的 `nofile` 仍是 `1024`，可能导致编译过程中随机失败，典型关键词包括：

```text
Too many open files
EMFILE
ninja: fatal
soong_build
```

当前机器内核上限：

```bash
cat /proc/sys/fs/nr_open
```

结果是：

```text
1048576
```

所以本机把 AOSP 编译相关登录会话和 systemd 默认值统一设为 `1048576`。

## 为什么用 drop-in 文件

不直接改 `/etc/security/limits.conf`、`/etc/systemd/system.conf`、`/etc/systemd/user.conf` 主文件，而是在 `.d/` 目录下新增配置文件：

- 是 systemd / PAM 支持的持久化配置方式；
- 系统升级时不容易被覆盖；
- 回滚时直接删除对应文件即可；
- 能明确知道这几行配置是为 AOSP 编译加的。

本机文件名统一使用：

```text
aosp-build.conf
```

## fish shell 下写入配置

fish 不支持 Bash heredoc：

```bash
<<'EOF'
```

所以在 fish 里用 `printf | sudo tee`。

先创建目录：

```fish
sudo mkdir -p \
  /etc/security/limits.d \
  /etc/systemd/system.conf.d \
  /etc/systemd/user.conf.d \
  /etc/systemd/system/user@.service.d
```

写入 PAM limits：

```fish
printf '%s\n' \
'* soft nofile 1048576' \
'* hard nofile 1048576' \
'root soft nofile 1048576' \
'root hard nofile 1048576' \
'xiaofeng soft nofile 1048576' \
'xiaofeng hard nofile 1048576' \
| sudo tee /etc/security/limits.d/aosp-build.conf >/dev/null
```

写入 system manager 默认限制：

```fish
printf '%s\n' \
'[Manager]' \
'DefaultLimitNOFILE=1048576:1048576' \
| sudo tee /etc/systemd/system.conf.d/aosp-build.conf >/dev/null
```

写入 user manager 默认限制：

```fish
printf '%s\n' \
'[Manager]' \
'DefaultLimitNOFILE=1048576:1048576' \
| sudo tee /etc/systemd/user.conf.d/aosp-build.conf >/dev/null
```

写入 `user@.service` drop-in，保证 GUI/用户 session 继承高 nofile：

```fish
printf '%s\n' \
'[Service]' \
'LimitNOFILE=1048576' \
| sudo tee /etc/systemd/system/user@.service.d/aosp-build.conf >/dev/null
```

## 验证配置内容

```fish
cat /etc/security/limits.d/aosp-build.conf
cat /etc/systemd/system.conf.d/aosp-build.conf
cat /etc/systemd/user.conf.d/aosp-build.conf
cat /etc/systemd/system/user@.service.d/aosp-build.conf
```

注意：不要直接对 drop-in 片段执行：

```fish
sudo systemd-analyze verify /etc/systemd/system/user@.service.d/aosp-build.conf
```

这个片段不是完整 unit，可能报：

```text
Failed to prepare filename ... Invalid argument
```

应验证完整 unit：

```fish
sudo systemctl daemon-reload
sudo systemd-analyze verify user@.service
```

查看 drop-in 是否被合并：

```fish
systemctl cat user@.service
```

输出里应该能看到：

```text
# /etc/systemd/system/user@.service.d/aosp-build.conf
[Service]
LimitNOFILE=1048576
```

查看当前用户 service：

```fish
systemctl show user@(id -u).service -p LimitNOFILE
```

## 生效

reload/reexec：

```fish
sudo systemctl daemon-reload
sudo systemctl daemon-reexec
```

最稳方式是重启一次：

```fish
sudo reboot
```

重启后验证当前 shell：

```fish
ulimit -n
cat /proc/$fish_pid/limits | grep 'Max open files'
systemctl show user@(id -u).service -p LimitNOFILE
```

期望看到 `1048576`。

## 回滚

删除这几个 drop-in 文件即可：

```fish
sudo rm -f \
  /etc/security/limits.d/aosp-build.conf \
  /etc/systemd/system.conf.d/aosp-build.conf \
  /etc/systemd/user.conf.d/aosp-build.conf \
  /etc/systemd/system/user@.service.d/aosp-build.conf

sudo systemctl daemon-reload
sudo systemctl daemon-reexec
```

然后重新登录或重启。

## 结论

对 AOSP 编译来说，`nofile=1024` 太低；本机按内核 `nr_open` 上限持久化到 `1048576`。如果之后仍然崩溃，再继续检查：

- OOM / swap；
- 磁盘空间和 inode；
- 编译并发 `-j`；
- 失败日志里是否仍有 `Too many open files` / `EMFILE`。
