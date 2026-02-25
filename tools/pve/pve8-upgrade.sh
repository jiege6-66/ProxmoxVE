#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____ _    ____________     __  ______  __________  ___    ____  ______
   / __ \ |  / / ____( __ )   / / / / __ \/ ____/ __ \/   |  / __ \/ ____/
  / /_/ / | / / __/ / __  |  / / / / /_/ / / __/ /_/ / /| | / / / / __/
 / ____/| |/ / /___/ /_/ /  / /_/ / ____/ /_/ / _, _/ ___ |/ /_/ / /___
/_/     |___/_____/\____/   \____/_/    \____/_/ |_/_/  |_/_____/_____/

EOF
}

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

set -euo pipefail
shopt -s inherit_errexit nullglob

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "pve8-upgrade" "pve"

start_routines() {
  header_info

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 SOURCES" "这将设置正确的源以更新和安装 Proxmox VE 8。" 10 58
  msg_info "切换到 Proxmox VE 8 源"
  cat <<EOF >/etc/apt/sources.list
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
  msg_ok "已切换到 Proxmox VE 8 源"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8-ENTERPRISE" "'pve-enterprise' 仓库仅对购买了 Proxmox VE 订阅的用户可用。" 10 58
  msg_info "禁用 'pve-enterprise' 仓库"
  cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF
  msg_ok "已禁用 'pve-enterprise' 仓库"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8-NO-SUBSCRIPTION" "'pve-no-subscription' 仓库提供对 Proxmox VE 所有开源组件的访问。" 10 58
  msg_info "启用 'pve-no-subscription' 仓库"
  cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
  msg_ok "已启用 'pve-no-subscription' 仓库"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 CEPH PACKAGE REPOSITORIES" "'Ceph Package Repositories' 提供对 'no-subscription' 和 'enterprise' 仓库的访问。" 10 58
  msg_info "启用 'ceph package repositories'"
  cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
EOF
  msg_ok "已启用 'ceph package repositories'"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 TEST" "'pvetest' 仓库可以让高级用户在正式发布前访问新功能和更新（已禁用）。" 10 58
  msg_info "添加 'pvetest' 仓库并设置为禁用"
  cat <<EOF >/etc/apt/sources.list.d/pvetest-for-beta.list
# deb http://download.proxmox.com/debian/pve bookworm pvetest
EOF
  msg_ok "已添加 'pvetest' 仓库"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 UPDATE" "正在更新到 Proxmox VE 8" 10 58
  msg_info "正在更新到 Proxmox VE 8（请耐心等待）"
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -y
  msg_ok "Updated to Proxmox VE 8"

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu "\nReboot Proxmox VE 8 now? (recommended)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox VE 8"
    sleep 2
    msg_ok "Completed Install Routines"
    reboot
    ;;
  no)
    msg_error "Selected no to Rebooting Proxmox VE 8 (Reboot recommended)"
    msg_ok "Completed Install Routines"
    ;;
  esac
}

header_info
while true; do
  read -p "Start the Update to Proxmox VE 8 Script (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*)
    clear
    exit
    ;;
  *) echo "Please answer yes or no." ;;
  esac
done

if ! command -v pveversion >/dev/null 2>&1; then
  header_info
  msg_error "\n No PVE Detected!\n"
  exit
fi

if ! pveversion | grep -Eq "pve-manager/(7\.4-(16|17|18|19))"; then
  header_info
  msg_error "This version of Proxmox Virtual Environment is not supported"
  echo -e "  PVE Version 7.4-16 or higher is required."
  echo -e "\nExiting..."
  sleep 3
  exit
fi

start_routines
