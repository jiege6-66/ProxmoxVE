#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    _   __     __  ____        __
   / | / /__  / /_/ __ \____ _/ /_____ _
  /  |/ / _ \/ __/ / / / __ `/ __/ __ `/
 / /|  /  __/ /_/ /_/ / /_/ / /_/ /_/ /
/_/ |_/\___/\__/_____/\__,_/\__/\__,_/

EOF
}

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
silent() { "$@" >/dev/null 2>&1; }

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "netdata" "addon"

set -e
header_info
echo "Loading..."
function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

function msg_error() { echo -e "${RD}✗ $1${CL}"; }

# This function checks the version of Proxmox Virtual Environment (PVE) and exits if the version is not supported.
# Supported: Proxmox VE 8.0.x – 8.9.x and 9.0–9.1.x
pve_check() {
  local PVE_VER
  PVE_VER="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}')"

  # Check for Proxmox VE 8.x: allow 8.0–8.9
  if [[ "$PVE_VER" =~ ^8\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 9)); then
      msg_error "不支持此版本的 Proxmox VE。"
      msg_error "支持的版本：Proxmox VE 8.0 – 8.9"
      exit 1
    fi
    return 0
  fi

  # Check for Proxmox VE 9.x: allow 9.0–9.1.x
  if [[ "$PVE_VER" =~ ^9\.([0-9]+) ]]; then
    local MINOR="${BASH_REMATCH[1]}"
    if ((MINOR < 0 || MINOR > 1)); then
      msg_error "尚不支持此版本的 Proxmox VE。"
      msg_error "支持的版本：Proxmox VE 9.0–9.1.x"
      exit 1
    fi
    return 0
  fi

  # All other unsupported versions
  msg_error "不支持此版本的 Proxmox VE。"
  msg_error "支持的版本：Proxmox VE 8.0 – 8.9 或 9.0–9.1.x"
  exit 1
}

detect_codename() {
  source /etc/os-release
  if [[ "$ID" != "debian" ]]; then
    msg_error "不支持的基础操作系统：$ID（仅支持 Proxmox VE / Debian）。"
    exit 1
  fi
  CODENAME="${VERSION_CODENAME:-}"
  if [[ -z "$CODENAME" ]]; then
    msg_error "无法检测 Debian 代号。"
    exit 1
  fi
  echo "$CODENAME"
}

get_latest_repo_pkg() {
  local REPO_URL=$1
  curl -fsSL "$REPO_URL" |
    grep -oP 'netdata-repo_[^"]+all\.deb' |
    sort -V |
    tail -n1
}

install() {
  header_info
  while true; do
    read -p "您确定要在 Proxmox VE 主机上安装 NetData 吗？是否继续(y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "请回答 yes 或 no。" ;;
    esac
  done

  read -r -p "详细模式？<y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"

  CODENAME=$(detect_codename)
  REPO_URL="https://repo.netdata.cloud/repos/repoconfig/debian/${CODENAME}/"

  msg_info "正在设置仓库"
  $STD apt-get install -y debian-keyring
  PKG=$(get_latest_repo_pkg "$REPO_URL")
  if [[ -z "$PKG" ]]; then
    msg_error "无法找到 Debian $CODENAME 的 netdata-repo 包"
    exit 1
  fi
  curl -fsSL "${REPO_URL}${PKG}" -o "$PKG"
  $STD dpkg -i "$PKG"
  rm -f "$PKG"
  msg_ok "已设置仓库"

  msg_info "正在安装 Netdata"
  $STD apt-get update
  $STD apt-get install -y netdata
  msg_ok "已安装 Netdata"
  msg_ok "成功完成！\n"
  echo -e "\n Netdata 应该可以通过以下地址访问${BL} http://$(hostname -I | awk '{print $1}'):19999 ${CL}\n"
}

uninstall() {
  header_info
  read -r -p "详细模式？<y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"

  msg_info "正在卸载 Netdata"
  systemctl stop netdata || true
  rm -rf /var/log/netdata /var/lib/netdata /var/cache/netdata /etc/netdata/go.d
  rm -rf /etc/apt/trusted.gpg.d/netdata-archive-keyring.gpg /etc/apt/sources.list.d/netdata.list
  $STD apt-get remove --purge -y netdata netdata-repo
  systemctl daemon-reload
  $STD apt autoremove -y
  $STD userdel netdata || true
  msg_ok "已卸载 Netdata"
  msg_ok "成功完成！\n"
}

header_info
pve_check

OPTIONS=(Install "在 Proxmox VE 上安装 NetData"
  Uninstall "从 Proxmox VE 卸载 NetData")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "NetData" \
  --menu "选择一个选项:" 10 58 2 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
"Install") install ;;
"Uninstall") uninstall ;;
*)
  echo "正在退出..."
  exit 0
  ;;
esac
