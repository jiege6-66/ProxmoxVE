#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
   ________                    __   _  ________
  / ____/ /__  ____ _____     / /  | |/ / ____/
 / /   / / _ \/ __ `/ __ \   / /   |   / /
/ /___/ /  __/ /_/ / / / /  / /___/   / /___
\____/_/\___/\__,_/_/ /_/  /_____/_/|_\____/

EOF
}

set -eEuo pipefail
BL="\033[36m"
RD="\033[01;31m"
CM='\xE2\x9C\x94\033'
GN="\033[1;92m"
CL="\033[m"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "clean-lxcs" "pve"

header_info
echo "加载中..."

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC 更新器" --yesno "这将清理选定 LXC 容器上的日志、缓存并更新软件包列表。是否继续？" 10 58

NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0

while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')

excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\n选择要跳过清理的容器:\n" \
  16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

if [ $? -ne 0 ]; then
  exit
fi

function run_lxc_clean() {
  local container=$1
  header_info
  name=$(pct exec "$container" hostname)

  pct exec "$container" -- bash -c '
    BL="\033[36m"; GN="\033[1;92m"; CL="\033[m"
    name=$(hostname)
    if [ -e /etc/alpine-release ]; then
      echo -e "${BL}[信息]${GN} 正在清理 $name (Alpine)${CL}\n"
      apk cache clean
      find /var/log -type f -delete 2>/dev/null
      find /tmp -mindepth 1 -delete 2>/dev/null
      apk update
    elif [ -e /etc/redhat-release ]; then
      echo -e "${BL}[信息]${GN} 正在清理 $name (CentOS)${CL}\n"
      yum clean all
      find /var/log -type f -delete 2>/dev/null
      find /tmp -mindepth 1 -delete 2>/dev/null
      yum update
      yum upgrade -y
    else
      echo -e "${BL}[信息]${GN} 正在清理 $name (Debian/Ubuntu)${CL}\n"
      find /var/cache -type f -delete 2>/dev/null
      find /var/log -type f -delete 2>/dev/null
      find /tmp -mindepth 1 -delete 2>/dev/null
      apt -y --purge autoremove
      apt -y autoclean
      rm -rf /var/lib/apt/lists/*
      apt update
    fi
  '
}

for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[信息]${GN} 跳过 ${BL}$container${CL}"
    sleep 1
    continue
  fi

  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  # Supported: debian, ubuntu, alpine, centos
  if [ "$os" != "debian" ] && [ "$os" != "ubuntu" ] && [ "$os" != "alpine" ] && [ "$os" != "centos" ]; then
    header_info
    echo -e "${BL}[信息]${GN} 跳过 ${RD}$container 不是 Debian、Ubuntu、Alpine 或 Red Hat 兼容系统${CL} \n"
    sleep 1
    continue
  fi

  status=$(pct status "$container")
  template=$(pct config "$container" | grep -q "template:" && echo "true" || echo "false")

  if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
    echo -e "${BL}[信息]${GN} 正在启动${BL} $container ${CL} \n"
    pct start "$container"
    echo -e "${BL}[信息]${GN} 等待${BL} $container${CL}${GN} 启动 ${CL} \n"
    sleep 5
    run_lxc_clean "$container"
    echo -e "${BL}[信息]${GN} 正在关闭${BL} $container ${CL} \n"
    pct shutdown "$container" &
  elif [ "$status" == "status: running" ]; then
    run_lxc_clean "$container"
  fi
done

wait
header_info
echo -e "${GN} 完成，已清理选定的容器。${CL} \n"
