#!/usr/bin/env bash
set -euo pipefail

# 给 FSearch 配置 GNOME 快捷键：Shift+Space
# 用法：
#   bash scripts/setup-fsearch-shortcut.sh
#
# 注意：
# - 需要先安装 fsearch。
# - 如果 Shift+Space 被输入法占用，GNOME 可能无法触发；可先在系统快捷键里检查冲突。

if command -v fsearch >/dev/null 2>&1; then
  command="$(command -v fsearch)"
elif command -v snap >/dev/null 2>&1 && snap list fsearch >/dev/null 2>&1; then
  command="snap run fsearch"
else
  echo "没有找到 fsearch，请先安装：sudo snap install fsearch" >&2
  exit 1
fi

base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
name="FSearch"
binding="<Shift>space"

current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
path="$base/custom-fsearch/"

if [[ "$current" == "@as []" ]]; then
  new="['$path']"
elif [[ "$current" == *"$path"* ]]; then
  new="$current"
else
  new="${current%]} , '$path']"
  new="${new/[ ,/[,}"
fi

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$path" name "$name"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$path" command "$command"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$path" binding "$binding"

echo "已设置快捷键：Shift+Space -> $command"
echo "验证："
echo "gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding"
