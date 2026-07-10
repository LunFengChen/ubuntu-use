# Ubuntu LVM 合盘：把数据盘并入根目录 `/`

记录把一块可清空的数据盘加入当前根目录 `/` 所在 LVM VG，并在线扩容 `/` 的流程。

> 高危操作：目标盘会被 `wipefs` 清空。只适合目标盘数据已备份、且当前 `/` 本身就是 LVM 逻辑卷的机器。

## 本机当前场景

目标：把原 Data 盘并入 `/`。

已保留的刷机包备份：

```text
/home/xiaofeng/Desktop/projects/reverse/tools/reverse-tools_flash-packages_20260710.tar.zst
/home/xiaofeng/Desktop/projects/reverse/tools/reverse-tools_flash-packages_20260710.tar.zst.sha256
```

通用脚本位置：

```text
/home/xiaofeng/Desktop/projects/ubuntu-use/scripts/merge-block-device-into-root-lvm.sh
```

兼容入口位置：

```text
/home/xiaofeng/Desktop/projects/reverse/tools/merge_data_disk_into_root.sh
```

本机继续执行可以直接用兼容入口：

```bash
sudo bash /home/xiaofeng/Desktop/projects/reverse/tools/merge_data_disk_into_root.sh
```

它会校验目标盘必须是：

```text
/dev/disk/by-id/nvme-CT1000E100SSD8_2534EADBE6A0-part1 -> /dev/nvme1n1p1
LABEL=Data
UUID=AC72138E72135D00
FSTYPE=ntfs
```

确认文本是：

```text
WIPE-Data-AC72138E72135D00
```

## 通用脚本用法

先 dry-run，只看计划，不擦盘：

```bash
sudo bash scripts/merge-block-device-into-root-lvm.sh \
  --device /dev/disk/by-id/xxx-part1 \
  --expect-real /dev/nvme1n1p1 \
  --expect-uuid <UUID> \
  --expect-label <LABEL> \
  --expect-fstype <FSTYPE> \
  --backup /path/to/backup.tar.zst
```

确认 dry-run 输出无误后，加 `--execute` 真正执行：

```bash
sudo bash scripts/merge-block-device-into-root-lvm.sh \
  --device /dev/disk/by-id/xxx-part1 \
  --expect-real /dev/nvme1n1p1 \
  --expect-uuid <UUID> \
  --expect-label <LABEL> \
  --expect-fstype <FSTYPE> \
  --backup /path/to/backup.tar.zst \
  --execute
```

脚本会执行：

```text
umount <目标盘挂载点>
wipefs -a <目标盘>
pvcreate -ff -y <目标盘>
vgextend <根目录所在VG> <目标盘>
lvextend -r -l +100%FREE <根目录LV>
```

## 安全边界

脚本做了这些保护：

- 默认 dry-run，必须显式传 `--execute` 才会写盘。
- 要求 root 权限执行。
- 自动识别当前 `/` 所在 LVM VG/LV，不再硬编码 `ubuntu-vg`。
- 校验目标设备不是当前 `/`。
- 可校验目标盘真实路径、UUID、LABEL、FSTYPE。
- 如果目标盘或其子设备已经是 LVM PV，拒绝继续。
- 如果指定 `--backup` 且存在 `.sha256`，会先校验备份包。
- 真正执行前必须手动输入确认文本。

仍然需要注意：

- 目标盘内容会永久删除。
- 扩容后的 `/` 会依赖两块盘；之后这块盘不能随便拔。
- 这是扩容，不是 RAID；任一承载 `/` 的盘损坏都可能影响系统。
- LVM 缩容/拆盘比扩容复杂很多，不要把它当作临时挂载方案。

## 目标盘 busy 的处理

如果遇到：

```text
umount: /media/xiaofeng/Data: target is busy
```

先确认挂载：

```bash
findmnt /media/xiaofeng/Data
lsblk -f /dev/nvme1n1
```

普通桌面自动挂载的盘，通常可用 `udisksctl` 卸载：

```bash
udisksctl unmount -b /dev/nvme1n1p1
```

如果还不行，查占用进程：

```bash
sudo fuser -vm /media/xiaofeng/Data
sudo lsof +f -- /media/xiaofeng/Data
```

退出占用该目录的终端、文件管理器、编辑器或后台进程后，再重新运行脚本。

## 执行后验证

扩容完成后检查：

```bash
df -hT /
lsblk -f
sudo vgs
sudo lvs -a -o +devices
```

预期：

- `/` 的容量变大。
- 目标盘变成 LVM PV。
- 根 LV 的 `devices` 里能看到原系统盘 PV 和新加入的目标盘 PV。

## 恢复刷机包备份

查看压缩包是否完好：

```bash
sha256sum -c /home/xiaofeng/Desktop/projects/reverse/tools/reverse-tools_flash-packages_20260710.tar.zst.sha256
zstd -t /home/xiaofeng/Desktop/projects/reverse/tools/reverse-tools_flash-packages_20260710.tar.zst
```

解压到指定目录：

```bash
mkdir -p /path/to/restore
cd /path/to/restore
tar -I zstd -xf /home/xiaofeng/Desktop/projects/reverse/tools/reverse-tools_flash-packages_20260710.tar.zst
```

这份备份只保存 `reverse-tools` 里 `【刷机】*` 相关刷机包、小镜像和元数据；大的已解包 raw 镜像、重复 nested `image-*.zip`、JADX cache 已排除。
