#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    _   __     __  ____  _          __
   / | / /__  / /_/ __ )(_)________/ /
  /  |/ / _ \/ __/ __  / / ___/ __  / 
 / /|  /  __/ /_/ /_/ / / /  / /_/ / 
/_/ |_/\___/\__/_____/_/_/   \__,_/  

EOF
}
header_info
set -e

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "add-netbird-lxc" "addon"

while true; do
  read -p "这将仅向现有 LXC 容器添加 NetBird。是否继续(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "请回答 yes 或 no。" ;;
  esac
done
header_info
echo "加载中..."

function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}

NODE=$(hostname)
MSG_MAX_LENGTH=0
while read -r line; do
  TAG=$(echo "$line" | awk '{print $1}')
  ITEM=$(echo "$line" | awk '{print substr($0,36)}')
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  CTID_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')

while [ -z "${CTID:+x}" ]; do
  CTID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --radiolist \
    "\n选择要添加 NetBird 的容器：\n" \
    16 $(($MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3)
done

LXC_STATUS=$(pct status "$CTID" | awk '{print $2}')
if [[ "$LXC_STATUS" != "running" ]]; then
  msg "\e[1;33m 容器 $CTID 未运行。正在启动...\e[0m"
  pct start "$CTID"
  while [[ "$(pct status "$CTID" | awk '{print $2}')" != "running" ]]; do
    msg "\e[1;33m 等待容器启动...\e[0m"
    sleep 2
  done
  msg "\e[1;32m 容器 $CTID 现已运行。\e[0m"
fi

DISTRO=$(pct exec "$CTID" -- cat /etc/os-release | grep -w "ID" | cut -d'=' -f2 | tr -d '"')
if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" ]]; then
  msg "\e[1;31m 错误：此脚本仅支持 Debian 或 Ubuntu LXC 容器。检测到：$DISTRO。正在中止...\e[0m"
  exit 1
fi

CTID_CONFIG_PATH=/etc/pve/lxc/${CTID}.conf
cat <<EOF >>$CTID_CONFIG_PATH
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
EOF
header_info
msg "正在安装 NetBird..."
pct exec "$CTID" -- bash -c '
if ! command -v curl &>/dev/null; then
  apt-get update -qq
  apt-get install -y curl >/dev/null
fi
apt install -y ca-certificates gpg &>/dev/null
curl -fsSL "https://pkgs.netbird.io/debian/public.key" | gpg --dearmor >/usr/share/keyrings/netbird-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main" >/etc/apt/sources.list.d/netbird.list
apt-get update &>/dev/null
apt-get install -y netbird-ui &>/dev/null
if systemctl list-unit-files docker.service &>/dev/null; then
  mkdir -p /etc/systemd/system/netbird.service.d
  cat <<OVERRIDE >/etc/systemd/system/netbird.service.d/after-docker.conf
[Unit]
After=docker.service
Wants=docker.service
OVERRIDE
  systemctl daemon-reload
fi
'
msg "\e[1;32m ✔ 已安装 NetBird。\e[0m"
sleep 2
msg "\e[1;31m 重启 ${CTID} LXC 以应用更改，然后在 LXC 控制台中运行 netbird up\e[0m"
