# Ubuntu 进程状态查看工具

记录 Ubuntu 下查看电脑进程、CPU、内存、磁盘和网络状态的工具选择。

## 当前已有工具

本机已经安装 Ubuntu 自带的图形化系统监视器：

```bash
gnome-system-monitor
```

打开方式：

```bash
gnome-system-monitor
```

适合场景：

- 想要类似 Windows 任务管理器的图形界面。
- 快速查看进程、CPU、内存、磁盘占用。
- 手动结束卡死进程。

## 推荐安装：btop

`btop` 是终端里的系统监控工具，界面直观，能同时查看：

- CPU
- 内存
- 磁盘
- 网络
- 进程列表

安装：

```bash
sudo apt install btop
```

启动：

```bash
btop
```

推荐理由：

- 比 `top` 直观。
- 比 `htop` 信息更丰富。
- 适合长期放在终端里观察系统状态。

## 备选：htop

`htop` 是经典轻量进程查看工具。

安装：

```bash
sudo apt install htop
```

启动：

```bash
htop
```

适合场景：

- 只想快速看进程列表和 CPU/内存。
- 需要轻量、稳定、到处都能用的工具。

## 当前 apt 源可安装版本记录

检查命令：

```bash
apt-cache policy btop htop gnome-system-monitor
```

当前记录：

```text
btop: candidate 1.3.0-1
htop: candidate 3.3.0-4build1
gnome-system-monitor: installed 46.0-1build1
```

## 个人选择

优先级：

1. 日常图形界面：`gnome-system-monitor`
2. 日常终端监控：`btop`
3. 轻量备用：`htop`

