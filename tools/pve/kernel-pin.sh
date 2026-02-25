#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    __ __                     __   ____  _
   / //_/__  _________  ___  / /  / __ \(_)___
  / ,< / _ \/ ___/ __ \/ _ \/ /  / /_/ / / __ \
 / /| /  __/ /  / / / /  __/ /  / ____/ / / / /
/_/ |_\___/_/  /_/ /_/\___/_/  /_/   /_/_/ /_/

EOF
}
YW=$(echo "\033[33m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
current_kernel=$(uname -r)
available_kernels=$(dpkg --list | grep 'kernel-.*-pve' | awk '{print substr($2, 16, length($2)-22)}')

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "kernel-pin" "pve"

header_info

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Kernel Pin" --yesno "这将固定/取消固定内核镜像，是否继续？" 10 68

KERNEL_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  KERNEL_MENU+=("$TAG" "$ITEM " "OFF")
done < <(echo "$available_kernels")

pin_kernel=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "当前内核 $current_kernel" --radiolist "\n选择要固定的内核:\n取消以取消固定任何内核" 16 $((MSG_MAX_LENGTH + 58)) 6 "${KERNEL_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')
[ -z "$pin_kernel" ] && {
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "未选择内核" --msgbox "似乎未选择内核\n取消固定任何已固定的内核" 10 68
  msg_info "正在取消固定任何内核"
  proxmox-boot-tool kernel unpin &>/dev/null
  msg_ok "已取消固定任何内核\n"
  proxmox-boot-tool kernel list
  echo ""
  msg_ok "完成\n"
  echo -e "${RD} 重启${CL}"
  exit
}
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Kernel Pin" --yesno "您想固定 $pin_kernel 内核吗？" 10 68

msg_info "正在固定 $pin_kernel"
proxmox-boot-tool kernel pin $pin_kernel &>/dev/null
msg_ok "成功固定 $pin_kernel\n"
proxmox-boot-tool kernel list
echo ""
msg_ok "完成\n"
echo -e "${RD} 重启${CL}"
