#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
 ______              __ __           __   _  _______
/_  __/_ _________  / //_/__ __ __  / /  | |/_/ ___/
 / / / // / __/ _ \/ ,< / -_) // / / /___>  </ /__
/_/  \_,_/_/ /_//_/_/|_|\__/\_, / /____/_/|_|\___/
                           /___/
EOF
}

set -euo pipefail
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
whiptail --backtitle "Proxmox VE Helper Scripts" --title "TurnKey LXC 容器" --yesno "这将允许创建多种 TurnKey LXC 容器之一。是否继续？" 10 68
TURNKEY_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  TURNKEY_MENU+=("$TAG" "$ITEM " "OFF")
done < <(
  cat <<EOF
ansible Ansible
bookstack BookStack
core Core
faveo-helpdesk Faveo Helpdesk
fileserver File Server
gallery Gallery
gameserver Game Server
gitea Gitea
gitlab GitLab
invoice-ninja Invoice Ninja
mediaserver Media Server
nextcloud Nextcloud
observium Observium
odoo Odoo
openldap OpenLDAP
openvpn OpenVPN
owncloud ownCloud
phpbb phpBB
torrentserver Torrent Server
wireguard WireGuard
wordpress Wordpress
zoneminder ZoneMinder
EOF
)
turnkey=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "TurnKey LXC 容器" --radiolist "\n选择要创建的 TurnKey LXC：\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${TURNKEY_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')
[ -z "$turnkey" ] && {
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "未选择 TurnKey LXC" --msgbox "看起来没有选择任何 TurnKey LXC 容器" 10 68
  msg "完成"
  exit
}

# Setup script environment
PASS="$(openssl rand -base64 8)"
# Prompt user to confirm container ID
while true; do
  CTID=$(whiptail --backtitle "容器 ID" --title "选择容器 ID" --inputbox "请输入容器 ID..." 8 40 $(pvesh get /cluster/nextid) 3>&1 1>&2 2>&3)

  # Check if user cancelled
  [ -z "$CTID" ] && die "未选择容器 ID"

  # Validate Container ID
  if ! validate_container_id "$CTID"; then
    SUGGESTED_ID=$(get_valid_container_id "$CTID")
    if whiptail --backtitle "容器 ID" --title "ID 已被使用" --yesno "容器/虚拟机 ID $CTID 已被使用。\n\n是否使用下一个可用 ID ($SUGGESTED_ID)？" 10 58; then
      CTID="$SUGGESTED_ID"
      break
    fi
    # User declined, loop back to input
  else
    break
  fi
done
# Prompt user to confirm Hostname
HOST_NAME=$(whiptail --backtitle "主机名" --title "选择主机名" --inputbox "请输入容器的主机名..." 8 40 "turnkey-${turnkey}" 3>&1 1>&2 2>&3)
PCT_OPTIONS="
    -features keyctl=1,nesting=1
    -hostname $HOST_NAME
    -tags community-script
    -onboot 1
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
    warn "'$CONTENT_LABEL' 需要至少为一个存储位置选择。"
    die "无法检测到有效的存储位置。"
  elif [ $((${#MENU[@]} / 3)) -eq 1 ]; then
    printf ${MENU[0]}
  else
    local STORAGE
    while [ -z "${STORAGE:+x}" ]; do
      STORAGE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "存储池" --radiolist \
        "要使用哪个存储池来存储${CONTENT_LABEL,,}？\n\n" \
        16 $(($MSG_MAX_LENGTH + 23)) 6 \
        "${MENU[@]}" 3>&1 1>&2 2>&3) || die "菜单已中止。"
    done
    printf $STORAGE
  fi
}

# Get template storage
TEMPLATE_STORAGE=$(select_storage template)
info "使用 '$TEMPLATE_STORAGE' 作为模板存储。"

# Get container storage
CONTAINER_STORAGE=$(select_storage container)
info "使用 '$CONTAINER_STORAGE' 作为容器存储。"

# Update LXC template list
msg "正在更新 LXC 模板列表..."
pveam update >/dev/null

# Get LXC template string
mapfile -t TEMPLATES < <(pveam available -section turnkeylinux | awk -v turnkey="${turnkey}" '$0 ~ turnkey {print $2}' | sort -t - -k 2 -V)
[ ${#TEMPLATES[@]} -gt 0 ] || die "搜索 '${turnkey}' 时未找到模板。"
TEMPLATE="${TEMPLATES[-1]}"

# Download LXC template
if ! pveam list $TEMPLATE_STORAGE | grep -q $TEMPLATE; then
  msg "正在下载 LXC 模板（请耐心等待）..."
  pveam download $TEMPLATE_STORAGE $TEMPLATE >/dev/null ||
    die "下载 LXC 模板时出现问题。"
fi

# Create variable for 'pct' options
PCT_OPTIONS=(${PCT_OPTIONS[@]:-${DEFAULT_PCT_OPTIONS[@]}})
[[ " ${PCT_OPTIONS[@]} " =~ " -rootfs " ]] || PCT_OPTIONS+=(-rootfs $CONTAINER_STORAGE:${PCT_DISK_SIZE:-8})

# Create LXC
msg "正在创建 LXC 容器..."
pct create $CTID ${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE} ${PCT_OPTIONS[@]} >/dev/null ||
  die "创建容器时出现问题。"

# Save password
echo "TurnKey ${turnkey} password: ${PASS}" >>~/turnkey-${turnkey}.creds # file is located in the Proxmox root directory

# If turnkey is "OpenVPN", add access to the tun device
TUN_DEVICE_REQUIRED=("openvpn") # Setup this way in case future turnkeys also need tun access
if printf '%s\n' "${TUN_DEVICE_REQUIRED[@]}" | grep -qw "${turnkey}"; then
  info "${turnkey} 需要访问主机上的 /dev/net/tun。正在修改容器配置以允许访问。"
  echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >>/etc/pve/lxc/${CTID}.conf
  echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0" >>/etc/pve/lxc/${CTID}.conf
  sleep 5
fi

# Start container
msg "正在启动 LXC 容器..."
pct start "$CTID"
sleep 10

# Get container IP
set +euo pipefail # Turn off error checking
max_attempts=5
attempt=1
IP=""
while [[ $attempt -le $max_attempts ]]; do
  IP=$(pct exec $CTID ip a show dev eth0 | grep -oP 'inet \K[^/]+')
  if [[ -n $IP ]]; then
    break
  else
    warn "第 $attempt 次尝试：未找到 IP 地址。暂停 5 秒..."
    sleep 5
    ((attempt++))
  fi
done

if [[ -z $IP ]]; then
  warn "已达到最大尝试次数。未找到 IP 地址。"
  IP="未找到"
fi

# Start Proxmox VE Monitor-All if available
if [[ -f /etc/systemd/system/ping-instances.service ]]; then
  systemctl start ping-instances.service
fi

# Success message
header_info
echo
info "LXC 容器 '$CTID' 已成功创建，IP 地址为 ${IP}。"
echo
info "请前往 LXC 控制台完成设置。"
echo
info "用户名: root"
info "密码: $PASS"
info "（凭据也保存在 root 用户主目录的 'turnkey-${turnkey}.creds' 文件中。）"
echo
