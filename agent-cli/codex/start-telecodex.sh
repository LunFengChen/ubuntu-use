#!/bin/bash
# TeleCodex 启动脚本
# 用法: ./start-telecodex.sh

PROJECT_DIR="$HOME/Desktop/projects/tg-control-codex"
LOG_FILE="/tmp/telecodex.log"

cd "$PROJECT_DIR" || exit 1

# 确保 codex 在 PATH 中
export PATH="$HOME/.local/bin:$PROJECT_DIR/node_modules/.bin:$PATH"

# 杀掉旧进程
pkill -f "tsx src/index" 2>/dev/null
sleep 1

# 后台启动
nohup ./node_modules/.bin/tsx src/index.ts > "$LOG_FILE" 2>&1 &

echo "TeleCodex 已启动 (PID: $!)"
echo "日志: $LOG_FILE"
echo "Bot: t.me/xiaofeng_codex_bot"
echo ""
echo "查看日志: tail -f $LOG_FILE"
echo "停止: pkill -f 'tsx src/index'"
