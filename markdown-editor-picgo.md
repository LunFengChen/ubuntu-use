# Markdown 编辑器与 PicGo 图床

目标：在 Ubuntu 上用开源 Markdown 编辑器写文档，粘贴图片后自动上传到 GitHub 图床，并把文档里的图片链接替换成 GitHub/CDN 镜像地址。

## 结论

当前选择：

- Markdown 编辑器：MarkText
- 图片上传器：PicGo-Core CLI
- 图床：GitHub 仓库
- 链接输出：PicGo 的 `customUrl`，默认建议用 `https://cdn.jsdelivr.net/gh/<user>/<repo>@<branch>` 这种 CDN 地址

原因：

- MarkText 是开源 Markdown 编辑器。
- MarkText 新版本内置图片上传器配置，支持检测 `picgo` 命令。
- PicGo-Core 内置 GitHub uploader，支持 `repo`、`branch`、`token`、`path`、`customUrl`。

## 本机安装位置

```text
~/Applications/MarkText/marktext-linux-0.19.1.AppImage
~/.local/share/applications/marktext.desktop
~/.local/share/icons/hicolor/256x256/apps/marktext.png
~/.nvm/versions/node/v24.16.0/bin/picgo
~/.picgo/config.json
```

MarkText 已设置为 Markdown 文件默认打开程序：

```bash
xdg-mime query default text/markdown
xdg-mime query default text/x-markdown
```

预期输出：

```text
marktext.desktop
marktext.desktop
```

## 安装命令

MarkText：

```bash
mkdir -p ~/Applications/MarkText
cd ~/Applications/MarkText
curl -L --fail \
  -o marktext-linux-0.19.1.AppImage \
  https://github.com/marktext/marktext/releases/download/v0.19.1/marktext-linux-0.19.1.AppImage
chmod +x marktext-linux-0.19.1.AppImage
```

PicGo-Core：

```bash
npm install -g picgo
picgo --version
```

## GitHub 图床配置

本机放了一个交互式配置脚本：

```bash
~/Applications/MarkText/config-picgo-github.sh
```

运行后它会询问：

- GitHub 仓库，默认 `LunFengChen/blog-imgbed`
- 分支，默认 `main`
- 图片存储目录，默认 `images/`
- 自定义访问地址，默认 `https://cdn.jsdelivr.net/gh/<repo>@<branch>`
- GitHub token

运行：

```bash
~/Applications/MarkText/config-picgo-github.sh
```

它会写入：

```text
~/.picgo/config.json
```

配置结构大概是：

```json
{
  "picBed": {
    "uploader": "github",
    "current": "github",
    "github": {
      "repo": "LunFengChen/blog-imgbed",
      "branch": "main",
      "token": "<GitHub token>",
      "path": "images/",
      "customUrl": "https://cdn.jsdelivr.net/gh/LunFengChen/blog-imgbed@main"
    }
  },
  "picgoPlugins": {}
}
```

注意：`~/.picgo/config.json` 里会保存 token，脚本会把文件权限设为 `600`。不要把这个文件提交到 Git。

## GitHub token 权限

推荐建 fine-grained personal access token：

- Repository access：只选图床仓库，例如 `blog-imgbed`
- Permissions：Contents 读写

不要使用权限过大的全账号 token。

## 测试上传

准备一张图片后测试：

```bash
picgo upload /path/to/image.png
```

成功时 PicGo 会输出图片链接。若配置了 `customUrl`，MarkText 粘贴图片时插入的链接会走这个自定义地址。

## MarkText 里启用

打开 MarkText 后检查：

```text
Preferences -> Image
```

关键设置：

```text
Image Insert Action: Upload
Image Uploader: PicGo
```

对应配置文件里应为：

```json
{
  "imageInsertAction": "upload"
}
```

如果这里还是 `path`，粘贴图片只会保存到 `~/.config/marktext/images/` 并插入本地路径，不会自动上传。

如果检测不到 PicGo，优先检查桌面入口里的 `PATH`：

```bash
grep '^Exec=' ~/.local/share/applications/marktext.desktop
command -v picgo
```

当前 desktop 文件已经把 Node/npm global bin 放进 PATH：

```text
/home/xiaofeng/.nvm/versions/node/v24.16.0/bin
```

## 备选方案

如果以后不想用 MarkText，也可以考虑：

- VS Code + Markdown Image / PicGo 类扩展：更适合和代码仓库一起写文档。
- Typora：体验好，但不是开源，不符合当前需求。
- Obsidian：插件生态强，但核心不是开源，不符合当前“开源优先”。

当前需求下，MarkText + PicGo-Core 是比较贴合的一套。

## 参考

- MarkText：https://github.com/marktext/marktext
- PicGo-Core：https://github.com/PicGo/PicGo-Core
- PicGo：https://github.com/Molunerfinn/PicGo
