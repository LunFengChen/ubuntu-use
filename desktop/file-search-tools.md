# Ubuntu 文件搜索工具：Everything 替代方案

记录 Ubuntu 下接近 Windows Everything 的文件搜索工具组合、安装命令和使用场景。

## 推荐组合

优先级：

1. `FSearch`：最像 Everything 的图形化文件名搜索工具，适合日常快速找文件。
2. `plocate`：命令行索引式文件名搜索，速度很快，适合终端。
3. `Recoll`：全文搜索工具，适合搜 PDF、Office、文本、邮件等文档内容。
4. `Catfish`：轻量 GUI 搜索工具，适合简单文件名/内容搜索。
5. `Searchmonkey`：偏正则和传统 GUI 搜索，作为补充。
6. `Tracker` / `tracker3`：GNOME 自带/常见的元数据索引后端，可作为系统搜索能力补充。

## 一键安装脚本

当前仓库提供了安装脚本：

```bash
sudo bash scripts/install-file-search-tools.sh
```

脚本会安装：

```text
plocate recoll catfish searchmonkey tracker-miner-fs
```

并尝试安装 `FSearch`：

- 如果 apt 源里已有 `fsearch`，直接安装；
- 否则尝试添加 `ppa:christian-boxdoerfer/fsearch-stable`；
- 如果没有 PPA 工具但有 snap，则尝试 `snap install fsearch`。

## 手动安装命令

基础工具：

```bash
sudo apt update
sudo apt install plocate recoll catfish searchmonkey tracker-miner-fs
```

FSearch：

```bash
sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-stable
sudo apt update
sudo apt install fsearch
```

如果不想加 PPA，也可以尝试 snap：

```bash
sudo snap install fsearch
```

## 使用方式

### FSearch

启动：

```bash
fsearch
```

特点：

- 最像 Everything；
- 主要搜索文件名，不做全文索引；
- 首次建索引需要一点时间，之后搜索很快；
- 建议只索引常用目录，排除 `~/.cache`、`node_modules`、虚拟机镜像和大型缓存目录。

### plocate

更新索引：

```bash
sudo updatedb
```

搜索：

```bash
locate keyword
locate -i keyword
```

特点：

- 终端里很快；
- 依赖索引数据库，刚创建的新文件可能要等定时任务或手动 `updatedb` 后才能搜到；
- 不适合搜文件内容。

### Recoll

图形界面：

```bash
recoll
```

命令行：

```bash
recollq keyword
```

特点：

- 适合全文搜索；
- 索引会比 FSearch/plocate 更占空间；
- 如果只想找文件名，不优先用它。

### Catfish

启动：

```bash
catfish
```

特点：

- GUI 简单；
- 可以作为 FSearch 没装上时的轻量替代。

### Searchmonkey

启动：

```bash
searchmonkey
```

特点：

- 适合 GUI 下用正则/条件搜索；
- 体验不如 FSearch 现代，但作为补充有用。

### Tracker / tracker3

查看状态：

```bash
tracker3 status
```

搜索：

```bash
tracker3 search keyword
```

特点：

- GNOME 桌面环境常见后台索引；
- 更像系统搜索后端，不是 Everything 风格主力工具。


## FSearch 快捷键

目标快捷键：

```text
Shift+Space -> 打开 FSearch
```

配置脚本：

```bash
bash scripts/setup-fsearch-shortcut.sh
```

注意：如果 `Shift+Space` 被输入法占用，GNOME 可能无法触发，需要先在输入法或系统快捷键里解除冲突。

## 本机 apt 源可安装版本记录

检查命令：

```bash
apt-cache policy fsearch plocate recoll catfish searchmonkey tracker-miner-fs
```

当前记录：

```text
plocate: candidate 1.1.19-2ubuntu2
recoll: candidate 1.36.1-1build2
catfish: candidate 4.16.4-2
searchmonkey: candidate 0.8.3-1.2
tracker-miner-fs: installed 3.7.1-1ubuntu0.1
fsearch: 当前 Ubuntu noble 默认 apt 源未列出；可用 PPA 或 snap 安装
```

## 个人选择

日常建议：

1. GUI 文件名搜索：`FSearch`
2. 终端文件名搜索：`plocate` / `locate`
3. 文档全文搜索：`Recoll`
4. 备用 GUI：`Catfish`

如果只装一个，优先装 `FSearch`。如果经常在终端里找文件，再加 `plocate`。
