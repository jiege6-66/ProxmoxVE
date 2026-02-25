#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
   ___   ____  ______               __     __
  / _ | / / / /_  __/__ __ _  ___  / /__ _/ /____ ___
 / __ |/ / /   / / / -_)  ' \/ _ \/ / _ `/ __/ -_|_-<
/_/ |_/_/_/   /_/  \__/_/_/_/ .__/_/\_,_/\__/\__/___/
                           /_/
EOF
}

set -eEuo pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR
function error_exit() {
  trap - ERR
  local DEFAULT='Unknown failure occured.'
  local REASON="\e[97m${1:-$DEFAULT}\e[39m"
  local FLAG="\e[91m[ERROR] \e[93m$EXIT@$LINE"
  msg "$FLAG $REASON" 1>&2
  [ ! -z ${CTID-} ] && cleanup_ctid
  exit $EXIT
}
function warn() {
  local REASON="\e[97m$1\e[39m"
  local FLAG="\e[93m[WARNING]\e[39m"
  msg "$FLAG $REASON"
}
function info() {
  local REASON="$1"
  local FLAG="\e[36m[INFO]\e[39m"
  msg "$FLAG $REASON"
}
function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "all-templates" "addon"

function validate_container_id() {
  local ctid="$1"
  # Check if ID is numeric
  if ! [[ "$ctid" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  # Check if config file exists for VM or LXC
  if [[ -f "/etc/pve/qemu-server/${ctid}.conf" ]] || [[ -f "/etc/pve/lxc/${ctid}.conf" ]]; then
    return 1
  fi
  # Check if ID is used in LVM logical volumes
  if lvs --noheadings -o lv_name 2>/dev/null | grep -qE "(^|[-_])${ctid}($|[-_])"; then
    return 1
  fi
  return 0
}
function get_valid_container_id() {
  local suggested_id="${1:-$(pvesh get /cluster/nextid)}"
  while ! validate_container_id "$suggested_id"; do
    suggested_id=$((suggested_id + 1))
  done
  echo "$suggested_id"
}
function cleanup_ctid() {
  if pct status $CTID &>/dev/null; then
    if [ "$(pct status $CTID | awk '{print $2}')" == "running" ]; then
      pct stop $CTID
    fi
    pct destroy $CTID
  fi
}

# Stop Proxmox VE Monitor-All if running
if systemctl is-active -q ping-instances.service; then
  systemctl stop ping-instances.service
fi
header_info
echo "加载中..."
pveam update >/dev/null 2>&1
whiptail --backtitle "Proxmox VE Helper Scripts" --title "All Templates" --yesno "这将允许创建众多模板 LXC 容器之一。是否继续？" 10 68
TEMPLATE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  TEMPLATE_MENU+=("$ITEM" "$TAG " "OFF")
done < <(pveam available)
TEMPLATE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "All Template LXCs" --radiolist "\n选择要创建的模板 LXC：\n" 16 $((MSG_MAX_LENGTH + 58)) 10 "${TEMPLATE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')
[ -z "$TEMPLATE" ] && {
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Template LXC Selected" --msgbox "似乎未选择模板 LXC 容器" 10 68
  msg "完成"
  exit
}

# Setup script environment
NAME=$(echo "$TEMPLATE" | grep -oE '^[^-]+-[^-]+')
PASS="$(openssl rand -base64 8)"

# Get valid Container ID
CTID=$(pvesh get /cluster/nextid)
if ! validate_container_id "$CTID"; then
  warn "容器 ID $CTID 已被使用。"
  CTID=$(get_valid_container_id "$CTID")
  info "使用下一个可用 ID：$CTID"
fi

PCT_OPTIONS="
    -features keyctl=1,nesting=1
    -hostname $NAME
    -tags proxmox-helper-scripts
    -onboot 0
    -cores 2
    -memory 2048
    -password $PASS
    -net0 name=eth0,bridge=vmbr0,ip=dhcp
    -unprivileged 1
  "
DEFAULT_PCT_OPTIONS=(
  -arch $(dpkg --print-architecture)
)

# Set the CONTENT and CONTENT_LABEL variables
function select_storage() {
  local CLASS=$1
  local CONTENT
  local CONTENT_LABEL
  case $CLASS in
  container)
    CONTENT='rootdir'
    CONTENT_LABEL='Container'
    ;;
  template)
    CONTENT='vztmpl'
    CONTENT_LABEL='Container template'
    ;;
  *) false || die "Invalid storage class." ;;
  esac

  # Query all storage locations
  local -a MENU
  while read -r line; do
    local TAG=$(echo $line | awk '{print $1}')
    local TYPE=$(echo $line | awk '{printf "%-10s", $2}')
    local FREE=$(echo $line | numfmt --field 4-6 --from-unit=K --to=iec --format %.2f | awk '{printf( "%9sB", $6)}')
    local ITEM="  Type: $TYPE Free: $FREE "
    local OFFSET=2
    if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
      local MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
    fi
    MENU+=("$TAG" "$ITEM" "OFF")
  done < <(pvesm status -content $CONTENT | awk 'NR>1')

  # Select storage location
  if [ $((${#MENU[@]} / 3)) -eq 0 ]; then
    warn "至少需要为一个存储位置选择 '$CONTENT_LABEL'。"
    die "无法检测到有效的存储位置。"
  elif [ $((${#MENU[@]} / 3)) -eq 1 ]; then
    printf ${MENU[0]}
  else
    local STORAGE
    while [ -z "${STORAGE:+x}" ]; do
      STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Storage Pools" --radiolist \
        "您想为 ${CONTENT_LABEL,,} 使用哪个存储池？\n\n" \
        16 $(($MSG_MAX_LENGTH + 23)) 6 \
        "${MENU[@]}" 3>&1 1>&2 2>&3) || die "菜单已中止。"
    done
    printf $STORAGE
  fi
}
header_info
# Get template storage
TEMPLATE_STORAGE=$(select_storage template)
info "使用 '$TEMPLATE_STORAGE' 作为模板存储。"

# Get container storage
CONTAINER_STORAGE=$(select_storage container)
info "使用 '$CONTAINER_STORAGE' 作为容器存储。"

# Download template
msg "正在下载 LXC 模板（请耐心等待）..."
pveam download $TEMPLATE_STORAGE $TEMPLATE >/dev/null || die "下载 LXC 模板时出现问题。"

# Create variable for 'pct' options
PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs $CONTAINER_STORAGE:${PCT_DISK_SIZE:-8})

# Create LXC
msg "正在创建 LXC 容器..."
pct create $CTID ${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE} ${PCT_OPTIONS[@]} >/dev/null ||
  die "尝试创建容器时出现问题。"

# Save password
echo "$NAME password: ${PASS}" >>~/$NAME.creds # file is located in the Proxmox root directory

# Start container
msg "正在启动 LXC 容器..."
pct start "$CTID"
sleep 5

# Get container IP
set +eEuo pipefail
max_attempts=5
attempt=1
IP=""
while [[ $attempt -le $max_attempts ]]; do
  IP=$(pct exec $CTID ip a show dev eth0 | grep -oP 'inet \K[^/]+')
  if [[ -n $IP ]]; then
    break
  else
    warn "尝试 $attempt：未找到 IP 地址。暂停 5 秒..."
    sleep 5
    ((attempt++))
  fi
done

if [[ -z $IP ]]; then
  warn "已达到最大尝试次数。未找到 IP 地址。"
  IP="NOT FOUND"
fi

set -eEuo pipefail
# Start Proxmox VE Monitor-All if available
if [[ -f /etc/systemd/system/ping-instances.service ]]; then
  systemctl start ping-instances.service
fi

# Success message
header_info
echo
info "LXC 容器 '$CTID' 已成功创建，其 IP 地址为 ${IP}。"
echo
info "继续进入 LXC 控制台以完成设置。"
echo
info "登录名：root"
info "密码：$PASS"
echo
