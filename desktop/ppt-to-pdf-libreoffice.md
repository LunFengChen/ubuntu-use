# Ubuntu 下批量把 PPT/PPTX 转成 PDF

记录在 Ubuntu 下用 LibreOffice 命令行批量转换 PowerPoint 文件的方法，适合 `.ppt`、`.pptx`、`.pps`、`.ppsx` 等演示文稿。

## 推荐工具

使用 LibreOffice Impress 的无界面转换功能：

```bash
libreoffice --headless --convert-to pdf --outdir 输出目录 输入文件.pptx
```

其中：

- `--headless`：不打开图形界面；
- `--convert-to pdf`：转换为 PDF；
- `--outdir`：指定 PDF 输出目录；
- 输入文件可以是一个，也可以是多个。

## 本机安装依赖

如果系统只有 LibreOffice Writer/Core，可能无法读取 PPT/PPTX，需要安装 Impress 组件：

```bash
sudo apt update
sudo apt install libreoffice-impress fonts-noto-cjk fonts-wqy-zenhei
```

字体包用于改善中文内容的显示和导出效果。

## 单个文件转换

```bash
mkdir -p pdfs
libreoffice --headless --convert-to pdf --outdir pdfs "slides/example.pptx"
```

转换后会生成：

```text
pdfs/example.pdf
```

## 批量转换当前目录下的 PPT/PPTX

在存放演示文稿的目录里执行：

```bash
mkdir -p pdfs
libreoffice --headless --convert-to pdf --outdir pdfs ./*.ppt ./*.pptx ./*.pps ./*.ppsx
```

如果文件名包含空格、中文，或者想递归查找，推荐用 `find -print0`：

```bash
mkdir -p pdfs
find . -type f \( -iname '*.ppt' -o -iname '*.pptx' -o -iname '*.pps' -o -iname '*.ppsx' \) -print0 \
  | xargs -0 -r libreoffice --headless --convert-to pdf --outdir pdfs
```

## 用 Docker 临时转换

如果本机 LibreOffice 缺少 Impress，或者不想改本机环境，可以用 Docker 临时启动 Ubuntu 容器转换。

在 PPT/PPTX 所在目录执行：

```bash
mkdir -p pdfs
docker run --rm \
  -v "$PWD:/work" \
  -w /work \
  -e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  ubuntu:24.04 \
  bash -lc '
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends libreoffice-impress fonts-noto-cjk fonts-wqy-zenhei
    mkdir -p /tmp/lo-profile /work/pdfs
    find /work -maxdepth 1 -type f \( -iname "*.ppt" -o -iname "*.pptx" -o -iname "*.pps" -o -iname "*.ppsx" \) -print0 \
      | xargs -0 -r libreoffice --headless -env:UserInstallation=file:///tmp/lo-profile --convert-to pdf --outdir /work/pdfs
    chown "$HOST_UID:$HOST_GID" /work/pdfs/*.pdf 2>/dev/null || true
  '
```

说明：

- `-v "$PWD:/work"`：把当前目录挂载进容器；
- `fonts-noto-cjk` 和 `fonts-wqy-zenhei`：提供中文字体；
- `-env:UserInstallation=file:///tmp/lo-profile`：使用临时 LibreOffice 配置，避免配置污染；
- `chown`：把容器生成的 PDF 文件属主改回当前用户。

## 验证结果

查看生成文件：

```bash
ls -lh pdfs/*.pdf
file pdfs/*.pdf
```

如果安装了 `pdfinfo`，可以查看页数：

```bash
pdfinfo pdfs/example.pdf | grep '^Pages:'
```

安装 `pdfinfo` 所在工具包：

```bash
sudo apt install poppler-utils
```

## 常见问题

### `Error: source file could not be loaded`

常见原因：

1. 没安装 `libreoffice-impress`，LibreOffice 无法读取演示文稿；
2. 输入路径不对；
3. 当前 LibreOffice 配置损坏或已有后台进程占用。

处理方式：

```bash
sudo apt install libreoffice-impress
```

或者使用 Docker 临时转换方案。

### 中文字体显示不正常

安装 CJK 字体后重新转换：

```bash
sudo apt install fonts-noto-cjk fonts-wqy-zenhei
```

### 输出 PDF 在哪里

由 `--outdir` 决定。例如：

```bash
libreoffice --headless --convert-to pdf --outdir pdfs example.pptx
```

输出就是：

```text
pdfs/example.pdf
```
