# Clash Verge Rev 全局脚本

相关仓库：

```text
https://github.com/LunFengChen/clash-proxychain-script
```

## 仓库关系

`clash-proxychain-script` 是独立脚本项目，继续保留独立仓库：

```text
/home/xiaofeng/Desktop/projects/clash-proxychain-script
https://github.com/LunFengChen/clash-proxychain-script
```

`ubuntu-use` 这里只记录 Ubuntu 桌面环境里的使用方式、配置位置和注意事项，不把脚本仓库作为 submodule 引入。

原因：

- `clash-proxychain-script` 是可独立维护和发布的脚本项目；
- `Script.js` 有真实代理配置风险，独立仓库更容易控制模板和占位符；
- `ubuntu-use` 只做个人 Ubuntu 工具使用笔记，避免把脚本源码和桌面笔记混在一起。

## 用途

这个仓库记录 Clash Verge Rev 的全局增强脚本，用于处理链式代理、域名直连和常见进程例外。

核心目标：

- 换订阅后不需要重新手动改最终 Mihomo 配置。
- 使用全局 `Script.js` 在配置生成阶段自动插入链式代理节点和策略组。
- 支持单跳、三级跳和更多 hop。
- 保留国内网站直连策略，同时给国内站策略组保留落地节点选项，方便临时切换。

## 链路方向

基本链路：

```text
本机应用 -> 订阅节点/前置节点 -> SOCKS5 落地节点 -> 目标网站
```

对应配置：

```text
Chain-Front -> US-Chicago-Chain -> 目标网站
```

`US-Chicago-Chain` 里会自动生成：

```yaml
dialer-proxy: Chain-Front
```

含义是：最终落地节点通过 `Chain-Front` 拨出。

多级跳时：

```text
本机应用 -> Chain-Front -> Hop1 -> Hop2 -> Landing -> 目标网站
```

最后一个 hop 是最终落地，中间 hop 只是中转。

## 文件位置

Clash Verge Rev 的全局脚本通常在：

```text
~/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/Script.js
```

可以在 Clash Verge Rev 里打开全局 `Script` / `Global Script` 编辑器，或者直接覆盖这个文件。

## 必改项

公开仓库里的 `Script.js` 应保留占位符，不要提交真实代理信息。

需要在本机私有环境里修改 `CHAINS`：

```js
{
  name: "US-Chicago",
  chainName: "US-Chicago-Chain",
  chainGroup: "Chain-US-Chicago",
  hops: [
    {
      name: "US-Chicago",
      proxy: {
        type: "socks5",
        server: "YOUR_LANDING_SERVER",
        port: 443,
        username: "YOUR_USERNAME",
        password: "YOUR_PASSWORD",
        udp: true,
      },
    },
  ],
}
```

如果 SOCKS5 不需要账号密码，可以删掉 `username` 和 `password`。

## 生成的主要策略组

脚本会生成或维护：

```text
Chain-Front       # 前置节点选择组
US-Chicago        # SOCKS5 落地节点
US-Chicago-Chain  # 通过 Chain-Front 拨出的链式落地节点
Chain-US-Chicago  # GUI 选择用的链式组
Domestic-Sites    # 国内网站策略组
Default           # 最终默认出口
```

## 国内站处理

`Domestic-Sites` 默认优先 `DIRECT`。

这样国内站仍然直连，不会因为使用链式代理脚本就全局走落地节点。

如果某个国内站直连异常，可以只给该域名单独加规则，而不是把整个 `Domestic-Sites` 切到代理。

## 指定域名直连

需要绕过所有代理策略，并让 Mihomo 用系统 DNS 解析时，把域名写到全局脚本的 `USER_CONFIG.directDomains`：

```js
directDomains: [
  "git.datastory.com.cn",
],
```

脚本会生成直连规则：

```yaml
DOMAIN,git.datastory.com.cn,DIRECT
```

还会给 DNS 加策略：

```yaml
dns:
  nameserver-policy:
    git.datastory.com.cn: system
  direct-nameserver-follow-policy: true
```

这里填主机名即可，不要填 `https://`、路径或端口。

## 微信、QQ 和企业微信

脚本里保留了微信/QQ/企业微信直连处理：

- `find-process-mode: always`
- 微信/QQ/企业微信进程直连，例如 `WeChat.exe`、`QQ`、`WXWork.exe`、`WeMailNode.exe`
- `qq.com`、`tencent.com`、`gtimg.com`、`qpic.cn` 等域名直连
- 部分微信图片相关 IP 段加入 `tun.route-exclude-address`

如果图片慢，先看 Clash Verge Rev 日志命中了哪个规则，再补域名或 IP 段。

## 注意

不要把真实 `server`、`username`、`password` 提交到公开仓库。
