 # Ubuntu Use Skills
 
 本项目记录个人 Ubuntu 桌面环境的工具选择、配置原因和可复现安装命令。
 
 ## 文档规范
 
 ### 语言
 
 **所有文档和注释一律使用中文**。
 
 - 标题、正文、说明全部用中文写。
 - 代码块里的命令、标识符、输出内容保持原样。
 - 专有名词（如 Everything、AppImage、GNOME）保留英文，不加翻译。
 
 ### 文件命名
 
 一律使用 `kebab-case.md`：
 
 ```text
 appimage-desktop-cli.md ✓
 file-search-tools.md    ✓
 文件搜索工具.md         ✗
 ```
 
 ### 每篇文档的结构
 
 每篇工具笔记至少包含以下部分：
 
 1. **目标**：一句话说明这篇文档在记什么
 2. **工具选择原因**：为什么选这个，不选别的
 3. **安装命令**：可复现的安装方式（apt / 手动 / AppImage / 脚本）
 4. **使用方式**：常用命令或 GUI 操作
 5. **当前本机状态**：已安装版本、目录结构、配置文件位置
 6. **验证命令**：如何确认工具正常工作
 
 ### 文件位置
 
 ```text
 ubuntu-use/
 ├── README.md                     # 总索引，每个文档必加入口
 ├── *.md                          # 工具笔记（根目录平铺）
 ├── scripts/                      # 可复现安装脚本
 │   └── install-*.sh
 └── skills/                       # 本规范与自定义技能
     └── SKILL.md
 ```
 
 ## README 入口规则
 
 新增 *.md 工具笔记后，必须在 `README.md` 相应分类下添加一行链接，格式：
 
 ```markdown
 - [笔记标题](笔记文件名.md)
 ```
 
 ## 脚本规范
 
 - 安装类脚本统一放 `scripts/`。
 - 以 `install-<功能>.sh` 命名。
 - 脚本开头写用途注释和用法。
 - 必须有 root 检查（`EUID`），避免非 sudo 执行到一半才失败。
 - 尽量不依赖交互输入。
 
 ### 示例结构
 
 ```bash
 #!/usr/bin/env bash
 set -euo pipefail
 # ...
 if [ "${EUID:-$(id -u)}" -ne 0 ]; then
   echo "Please run as root: sudo bash scripts/install-xxx.sh" >&2
   exit 1
 fi
 export DEBIAN_FRONTEND=noninteractive
 apt-get update
 apt-get install -y pkg1 pkg2
 ```
 
 ## Codex 工作约定
 
 如果你（Codex）在这个仓库里工作，请遵守以下约定：
 
 1. **先用 `rg`、`fd`、`rtk git status` 熟悉当前状态**，不要假设仓库里有什么。
 2. **新增文档时，同时更新 `README.md` 和 `skills/SKILL.md`（如果规范需要补充）**。
 3. **新增安装脚本时，同步检查 `skills/SKILL.md` 是否需要补充**。
 4. **尽量不要改已有文档的已有结构**，新内容追加在新章节或新文件里。
 5. **先确认工具在 apt/snap/PPA 里的状态**，再写安装命令。
 6. **写完文档或脚本后，做一次最小的验证**，并把验证命令写入文档。
 7. **当前 repo 默认分支：`master`。功能改动统一走 `features/<short-topic>` 分支**。
