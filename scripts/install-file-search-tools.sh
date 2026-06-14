#!/usr/bin/env bash
set -euo pipefail

# 安装 Ubuntu 文件搜索工具（精简版）
# 当前安装：plocate（CLI 快搜）+ catfish（GUI 搜索）
# FSearch 被墙，Recoll/Searchmonkey 非必需，不在此安装
# 用法：
#   sudo bash scripts/install-file-search-tools.sh

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "请用 sudo 执行：sudo bash scripts/install-file-search-tools.sh" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "安装 plocate（终端极速文件名搜索）和 catfish（GUI 搜索）..."
apt-get install -y plocate catfish

# 更新文件名索引数据库
if command -v updatedb >/dev/null 2>&1; then
  updatedb || true
fi

cat <<'MSG'

已安装：
  plocate - 终端快搜：locate <关键词>
  catfish  - GUI 搜索：catfish

如果想装 FSearch（最像 Everything 的桌面版），网络通后手动：
  sudo snap install fsearch
MSG
