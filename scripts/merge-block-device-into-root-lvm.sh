#!/usr/bin/env bash
set -Eeuo pipefail

# 通用 LVM 合盘脚本：擦除一个非根 block device，把它加入当前根分区所在 VG，在线扩容 /。
# 默认只做 dry-run；真正执行必须加 --execute，并手动输入确认文本。
#
# 示例（当前机器 Data 盘）：
#   sudo bash scripts/merge-block-device-into-root-lvm.sh \
#     --device /dev/disk/by-id/nvme-CT1000E100SSD8_2534EADBE6A0-part1 \
#     --expect-real /dev/nvme1n1p1 \
#     --expect-uuid AC72138E72135D00 \
#     --expect-label Data \
#     --expect-fstype ntfs \
#     --backup /home/xiaofeng/Desktop/projects/reverse/tools/reverse-tools_flash-packages_20260710.tar.zst \
#     --execute

usage() {
  cat <<'EOF'
Usage:
  sudo bash scripts/merge-block-device-into-root-lvm.sh --device DEV [options]

作用：
  1. 校验 DEV 不是当前 /，且当前 / 是 LVM 逻辑卷。
  2. 可选校验 DEV 的真实路径、UUID、LABEL、FSTYPE 和备份包 SHA256。
  3. 卸载 DEV 及其子设备上的挂载点。
  4. wipefs 擦除 DEV，pvcreate，把 DEV 加入 / 所在 VG。
  5. lvextend -r -l +100%FREE 在线扩容 /。

必填：
  --device DEV             要擦除并加入 / 的 block device，建议用 /dev/disk/by-id/... 或明确分区路径。

安全校验（建议至少填 UUID/LABEL/FSTYPE）：
  --expect-real DEV        校验 --device 解析后的真实设备，例如 /dev/nvme1n1p1。
  --expect-uuid UUID       校验目标设备当前文件系统 UUID。
  --expect-label LABEL     校验目标设备当前文件系统 LABEL。
  --expect-fstype TYPE     校验目标设备当前文件系统类型，例如 ntfs、ext4。
  --backup FILE            校验备份文件存在；若 FILE.sha256 存在，则先 sha256sum -c。
  --confirm-text TEXT      覆盖交互确认文本；默认是 WIPE-<设备名>-<UUID或NO_UUID>。

执行控制：
  --execute                真正执行擦盘和扩容；不加时只打印 dry-run 计划。
  --no-auto-unmount        如果目标设备已挂载则直接退出，不自动 umount。
  -h, --help               显示帮助。

示例 dry-run：
  sudo bash scripts/merge-block-device-into-root-lvm.sh \
    --device /dev/nvme1n1p1 --expect-uuid AC72138E72135D00

示例执行：
  sudo bash scripts/merge-block-device-into-root-lvm.sh \
    --device /dev/nvme1n1p1 --expect-uuid AC72138E72135D00 --execute
EOF
}

die() {
  echo "错误：$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令：$1"
}

trim_first_line() {
  awk '{$1=$1; print; exit}'
}

quote_args() {
  printf ' %q' "$@"
  printf '\n'
}

on_err() {
  local line=$1
  echo "错误：第 ${line} 行命令失败，已停止。请根据上方最后一条命令判断是否已进入擦盘/扩容阶段。" >&2
}
trap 'on_err $LINENO' ERR

TARGET_DEV=''
EXPECT_REAL=''
EXPECT_UUID=''
EXPECT_LABEL=''
EXPECT_FSTYPE=''
BACKUP_FILE=''
CONFIRM_TEXT=''
EXECUTE=0
AUTO_UNMOUNT=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      [[ $# -ge 2 ]] || die "--device 需要参数"
      TARGET_DEV=$2
      shift 2
      ;;
    --expect-real)
      [[ $# -ge 2 ]] || die "--expect-real 需要参数"
      EXPECT_REAL=$2
      shift 2
      ;;
    --expect-uuid)
      [[ $# -ge 2 ]] || die "--expect-uuid 需要参数"
      EXPECT_UUID=$2
      shift 2
      ;;
    --expect-label)
      [[ $# -ge 2 ]] || die "--expect-label 需要参数"
      EXPECT_LABEL=$2
      shift 2
      ;;
    --expect-fstype)
      [[ $# -ge 2 ]] || die "--expect-fstype 需要参数"
      EXPECT_FSTYPE=$2
      shift 2
      ;;
    --backup)
      [[ $# -ge 2 ]] || die "--backup 需要参数"
      BACKUP_FILE=$2
      shift 2
      ;;
    --confirm-text)
      [[ $# -ge 2 ]] || die "--confirm-text 需要参数"
      CONFIRM_TEXT=$2
      shift 2
      ;;
    --execute)
      EXECUTE=1
      shift
      ;;
    --no-auto-unmount)
      AUTO_UNMOUNT=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1"
      ;;
  esac
done

[[ -n "$TARGET_DEV" ]] || { usage >&2; die "必须指定 --device"; }

for cmd in awk basename blkid df findmnt lsblk lvs pvs pvcreate readlink sha256sum sort tr umount vgextend vgs wipefs lvextend; do
  need_cmd "$cmd"
done

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  die "请用 sudo 运行，例如：sudo bash scripts/merge-block-device-into-root-lvm.sh --device DEV"
fi

[[ -e "$TARGET_DEV" ]] || die "目标设备不存在：$TARGET_DEV"
TARGET_REAL=$(readlink -f -- "$TARGET_DEV")
[[ -b "$TARGET_REAL" ]] || die "目标不是 block device：$TARGET_DEV -> $TARGET_REAL"

if [[ -n "$EXPECT_REAL" ]]; then
  EXPECT_REAL_RESOLVED=$(readlink -f -- "$EXPECT_REAL")
  [[ "$TARGET_REAL" == "$EXPECT_REAL_RESOLVED" ]] || \
    die "目标设备真实路径不匹配：$TARGET_DEV -> $TARGET_REAL，预期 $EXPECT_REAL_RESOLVED"
fi

UUID=$(blkid -s UUID -o value "$TARGET_REAL" 2>/dev/null || true)
LABEL=$(blkid -s LABEL -o value "$TARGET_REAL" 2>/dev/null || true)
FSTYPE=$(blkid -s TYPE -o value "$TARGET_REAL" 2>/dev/null || true)

[[ -z "$EXPECT_UUID" || "$UUID" == "$EXPECT_UUID" ]] || \
  die "UUID 不匹配：实际 '${UUID:-<none>}'，预期 '$EXPECT_UUID'"
[[ -z "$EXPECT_LABEL" || "$LABEL" == "$EXPECT_LABEL" ]] || \
  die "LABEL 不匹配：实际 '${LABEL:-<none>}'，预期 '$EXPECT_LABEL'"
[[ -z "$EXPECT_FSTYPE" || "$FSTYPE" == "$EXPECT_FSTYPE" ]] || \
  die "FSTYPE 不匹配：实际 '${FSTYPE:-<none>}'，预期 '$EXPECT_FSTYPE'"

ROOT_SOURCE=$(findmnt -no SOURCE /)
ROOT_REAL=$(readlink -f -- "$ROOT_SOURCE")
[[ -b "$ROOT_REAL" ]] || die "当前 / 来源不是 block device：$ROOT_SOURCE -> $ROOT_REAL"

if ! lvs "$ROOT_SOURCE" >/dev/null 2>&1; then
  die "当前 / 不是可识别的 LVM 逻辑卷：$ROOT_SOURCE"
fi

ROOT_VG=$(lvs --noheadings -o vg_name "$ROOT_SOURCE" | trim_first_line)
ROOT_LV_PATH=$(lvs --noheadings -o lv_path "$ROOT_SOURCE" | trim_first_line)
[[ -n "$ROOT_VG" ]] || die "无法识别 / 所在 VG"
[[ -n "$ROOT_LV_PATH" ]] || die "无法识别 / 所在 LV"
ROOT_LV_REAL=$(readlink -f -- "$ROOT_LV_PATH")
[[ "$ROOT_LV_REAL" == "$ROOT_REAL" ]] || \
  die "识别到的根 LV 与当前 / 不一致：/=$ROOT_SOURCE($ROOT_REAL)，LV=$ROOT_LV_PATH($ROOT_LV_REAL)"

mapfile -t TARGET_NODES < <(lsblk -nrpo NAME "$TARGET_REAL")
[[ ${#TARGET_NODES[@]} -gt 0 ]] || TARGET_NODES=("$TARGET_REAL")

for node in "${TARGET_NODES[@]}"; do
  node_real=$(readlink -f -- "$node")
  [[ "$node_real" != "$ROOT_REAL" ]] || die "目标设备包含当前 /：$node_real"
  if pvs "$node_real" >/dev/null 2>&1; then
    existing_vg=$(pvs --noheadings -o vg_name "$node_real" | trim_first_line)
    die "目标设备或子设备已经是 LVM PV：$node_real (VG=${existing_vg:-<none>})，拒绝擦除"
  fi
done

MOUNTS=()
for node in "${TARGET_NODES[@]}"; do
  while IFS= read -r mount_point; do
    [[ -n "$mount_point" ]] && MOUNTS+=("$mount_point")
  done < <(findmnt -rn -S "$node" -o TARGET || true)
done
if [[ ${#MOUNTS[@]} -gt 0 ]]; then
  mapfile -t MOUNTS < <(printf '%s\n' "${MOUNTS[@]}" | sort -u)
fi

for mount_point in "${MOUNTS[@]}"; do
  case "$mount_point" in
    /|/boot|/boot/*|/home|/home/*|/usr|/usr/*|/var|/var/*)
      die "目标设备挂载在关键路径 $mount_point，拒绝自动处理"
      ;;
  esac
done

if [[ -n "$BACKUP_FILE" ]]; then
  [[ -f "$BACKUP_FILE" ]] || die "备份文件不存在：$BACKUP_FILE"
  if [[ -f "$BACKUP_FILE.sha256" ]]; then
    sha256sum -c "$BACKUP_FILE.sha256"
    BACKUP_STATUS="已校验：$BACKUP_FILE.sha256"
  else
    BACKUP_STATUS="仅确认存在：$BACKUP_FILE（未找到 .sha256）"
  fi
else
  BACKUP_STATUS='未指定 --backup；脚本不会验证任何备份文件'
fi

if [[ -z "$CONFIRM_TEXT" ]]; then
  CONFIRM_TEXT="WIPE-$(basename "$TARGET_REAL")-${UUID:-NO_UUID}"
fi

if [[ ${#MOUNTS[@]} -gt 0 && "$AUTO_UNMOUNT" -ne 1 ]]; then
  die "目标设备仍有挂载点：${MOUNTS[*]}；--no-auto-unmount 已启用"
fi

cat <<EOF
当前磁盘：
EOF
lsblk -f

cat <<EOF

计划：
  目标设备：$TARGET_DEV -> $TARGET_REAL
  目标签名：LABEL=${LABEL:-<none>} UUID=${UUID:-<none>} TYPE=${FSTYPE:-<none>}
  目标挂载：${MOUNTS[*]:-<none>}
  根分区：  / = $ROOT_SOURCE -> $ROOT_REAL
  根 LVM：  VG=$ROOT_VG LV=$ROOT_LV_PATH
  备份校验：$BACKUP_STATUS

将执行：
EOF
if [[ ${#MOUNTS[@]} -gt 0 ]]; then
  for mount_point in "${MOUNTS[@]}"; do
    quote_args umount "$mount_point"
  done
fi
quote_args wipefs -a "$TARGET_REAL"
quote_args pvcreate -ff -y "$TARGET_REAL"
quote_args vgextend "$ROOT_VG" "$TARGET_REAL"
quote_args lvextend -r -l +100%FREE "$ROOT_LV_PATH"

if [[ "$EXECUTE" -ne 1 ]]; then
  cat <<EOF

DRY-RUN：没有执行擦盘/扩容。确认计划正确后，加 --execute 再运行。
EOF
  exit 0
fi

cat <<EOF

高危确认：这会永久删除 $TARGET_REAL 上的数据，并把它加入 / 所在 VG。
确认继续请输入：$CONFIRM_TEXT
EOF
read -r -p '> ' answer
[[ "$answer" == "$CONFIRM_TEXT" ]] || die "确认文本不匹配，已取消"

if [[ ${#MOUNTS[@]} -gt 0 ]]; then
  mapfile -t MOUNTS_DESC < <(printf '%s\n' "${MOUNTS[@]}" | awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2-)
  for mount_point in "${MOUNTS_DESC[@]}"; do
    umount "$mount_point"
  done
fi

wipefs -a "$TARGET_REAL"
pvcreate -ff -y "$TARGET_REAL"
vgextend "$ROOT_VG" "$TARGET_REAL"
lvextend -r -l +100%FREE "$ROOT_LV_PATH"

cat <<'EOF'

扩容完成：
EOF
vgs
lvs -a -o +devices
df -hT /
