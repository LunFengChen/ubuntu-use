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
本机应用 -> 订阅自动节点/前置节点 -> SOCKS5 落地节点 -> 目标网站
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

`dialer-proxy` 可以填单个节点，也可以填策略组名。当前本机脚本里，机场 webshare 住宅链的 `front` 已改成订阅里的 `自动选择`：

```js
front: "自动选择",
```

这样不是固定绑死 `日本JP-HY2`，而是让原机场自动组作为跳板；某个机场节点挂掉时，自动组会切到其他可用节点，住宅落地节点仍然作为最终出口。

GUI 里的链名也要表达这一点，所以本机脚本把原来的 `local->机场:JP->webshare:...` 改成了：

```text
local->机场:auto->webshare:US:chicago
local->机场:auto->webshare:US:california
local->机场:auto->webshare:US:newYork
```

多级跳时：

```text
本机应用 -> Chain-Front -> Hop1 -> Hop2 -> Landing -> 目标网站
```

最后一个 hop 是最终落地，中间 hop 只是中转。

## 新增链式代理的维护方式

日常只改 `USER_CONFIG.chains`，不要手工改最终 YAML。

单跳落地：

```js
{
  id: "US",
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

指定前置节点/前置组：

```js
{
  id: "local->airport:auto->webshare:US",
  name: "local->airport:auto->webshare:US",
  chainName: "[Chain] local->airport:auto->webshare:US",
  front: "自动选择",
  hops: [/* landing proxy */],
}
```

多跳链：

```js
{
  id: "multi-hop-demo",
  name: "multi-hop-demo",
  chainName: "[Chain] multi-hop-demo",
  front: "自动选择",
  hops: [
    { name: "Hop1", proxy: {/* socks/http */} },
    { name: "Landing", proxy: {/* socks/http */} },
  ],
}
```

脚本会自动生成每一跳的 `dialer-proxy`，最后一个 hop 的生成节点就是完整链路。

公开仓库不要提交真实 `server`、`username`、`password`。

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

## 指定域名/内网域名直连、DNS 和 fake-ip 排除

需要绕过所有代理策略的域名统一写在 `USER_CONFIG`，不要分散改 YAML：

```js
directDomains: [
  "git.datastory.com.cn",              // 精确主机名
],

directDomainSuffixes: [
  "datastory.com.cn",                  // 整个后缀直连
  "ds-int.cn",
],

directDomainKeywords: [],

directDns: {
  // 推荐先用 dhcp://system；它不写死网卡名，通常比 system 更不容易绕回 Clash Meta。
  // 如果你的环境没有 systemd-resolved，或者仍然需要按某块网卡拿专用 DNS，再改成 dhcp://真实网卡名。
  nameserver: "dhcp://system",
  fakeIpFilter: true,
  directNameserverFollowPolicy: true,
},
```

脚本会一次性生成三类配置。

### 1. 路由直连

```yaml
DOMAIN,git.datastory.com.cn,DIRECT
DOMAIN-SUFFIX,datastory.com.cn,DIRECT
DOMAIN-SUFFIX,ds-int.cn,DIRECT
```

### 2. DNS nameserver-policy

```yaml
dns:
  nameserver-policy:
    git.datastory.com.cn: dhcp://system
    +.datastory.com.cn: dhcp://system
    +.ds-int.cn: dhcp://system
  direct-nameserver-follow-policy: true
```

### 3. fake-ip-filter

```yaml
dns:
  fake-ip-filter:
    - git.datastory.com.cn
    - +.datastory.com.cn
    - "*.datastory.com.cn"
    - +.ds-int.cn
    - "*.ds-int.cn"
```

这样可以继续保留全局 `enhanced-mode: fake-ip`，但公司内网域名不会拿到 `28.x.x.x` / `198.18.x.x` 这类 fake IP。

这里填域名即可，不要填 `https://`、路径或端口。

## directDns.nameserver 怎么选

`directDns.nameserver` 是内网域名专用 DNS。常见选择：

### 通用模板：`dhcp://system`

```js
directDns: {
  nameserver: "dhcp://system",
  fakeIpFilter: true,
  directNameserverFollowPolicy: true,
},
```

优点是不写死网卡名，通常可以跟着系统当前 DNS 走。它比直接写 `wlp68s0` 这类接口名更通用。

如果你的系统 DNS 仍然被 Clash Meta 接管，还是会出现回环；那时再换成 `dhcp://真实网卡名`。

排查：

```bash
resolvectl status
```

如果看到类似：

```text
Link ... (Meta)
  DNS Servers: 28.0.0.2
  DNS Domain: ~.
```

并且 Clash 日志有：

```text
dial DIRECT ... --> mnet.ds-int.cn:56000 error: dns resolve failed
```

就不要用 `system`。

### 需要绑定到某块网卡：`dhcp://网卡名`

```js
directDns: {
  nameserver: "dhcp://wlp68s0",
  fakeIpFilter: true,
  directNameserverFollowPolicy: true,
},
```

这个写法让 Mihomo 使用该网卡 DHCP 下发的 DNS。

注意：`wlp68s0` 只是你当前机器的示例，别人的电脑可能是 `wlan0`、`wlo1`、`enp3s0`、`eth0` 等。

适合：

- 主要使用同一块 Wi-Fi 网卡；
- 公司 DNS 会随 Wi-Fi 自动下发；
- 不想写死公司 DNS IP。

查看当前网卡和 DNS：

```bash
resolvectl status
ip -br addr
```

验证某域名能不能从该接口解析：

```bash
resolvectl query -i wlp68s0 mnet.ds-int.cn
```

如果换到有线、USB 网卡或 VPN，网卡名变了，需要把 `wlp68s0` 改成新的接口名。

### 路由冲突兜底：`udp://DNS_IP#iface`

如果 Docker/VPN 抢了公司 DNS 所在网段，普通查询会超时。例子：公司 DNS 是 `172.18.5.18`，但 Docker bridge 占了 `172.18.0.0/16`：

```bash
ip route get 172.18.5.18
```

异常结果：

```text
172.18.5.18 dev br-xxxx src 172.18.0.1
```

这说明包被发进 Docker bridge 了，不是 Wi-Fi。可以临时绑定 DNS 查询出口接口：

```js
directDns: {
  nameserver: [
    "udp://172.18.5.18#wlp68s0",
    "udp://172.18.5.19#wlp68s0",
  ],
  fakeIpFilter: true,
  directNameserverFollowPolicy: true,
},
```

更长期的修法是改 Docker 默认地址池，避免 Docker 使用公司内网网段。

## directIpRanges 注意事项

如果关 Clash/TUN 能访问，开 Clash/TUN 后同一域名直连超时，且 DNS 已经返回真实 IP，才考虑把**目标真实 IP/CIDR** 加到 `directIpRanges`，不要填写 Mihomo fake-ip 地址。

```js
directIpRanges: [
  "目标真实IP/32",
],
```

脚本会同时生成 `IP-CIDR,目标真实IP/32,DIRECT,no-resolve`，并加入 `tun.route-exclude-address`。

注意：如果 `getent hosts 域名` 看到的是 `28.0.0.0/8`、`198.18.0.0/15` 这类 fake-ip 地址，不要加入 `directIpRanges`。fake-ip 会被 Mihomo 动态复用；把它排除出 TUN 后，其他域名可能刚好拿到同一个 fake-ip，导致连接被强制直连到假地址并超时。

## 微信、QQ 和企业微信

脚本里保留了微信/QQ/企业微信直连处理：

- `find-process-mode: always`
- 微信/QQ/企业微信进程直连，例如 `WeChat.exe`、`QQ`、`WXWork.exe`、`WeMailNode.exe`
- `qq.com`、`tencent.com`、`gtimg.com`、`qpic.cn` 等域名直连
- 部分微信图片相关 IP 段加入 `tun.route-exclude-address`

如果图片慢，先看 Clash Verge Rev 日志命中了哪个规则，再补域名或 IP 段。

## 注意

不要把真实 `server`、`username`、`password` 提交到公开仓库。
