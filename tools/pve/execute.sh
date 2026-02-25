#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: jeroenzwart
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
     ______                     __          __   _  ________
   / ____/  _____  _______  __/ /____     / /  | |/ / ____/
  / __/ | |/_/ _ \/ ___/ / / / __/ _ \   / /   |   / /     
 / /____>  </  __/ /__/ /_/ / /_/  __/  / /___/   / /___   
/_____/_/|_|\___/\___/\__,_/\__/\___/  /_____/_/|_\____/   
                                                           
EOF
}
set -eEuo pipefail
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "execute-lxcs" "pve"

header_info
echo "加载中..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC 执行" --yesno "这将在选定的 LXC 容器内执行命令。是否继续？" 10 58
NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\n选择要跳过执行的容器:\n" \
  16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

if [ $? -ne 0 ]; then
  exit
fi

read -r -p "在此输入要在容器内执行的命令: " custom_command

header_info
echo "请稍候...\n"

function execute_in() {
  container=$1
  name=$(pct exec "$container" hostname)
  echo -e "${BL}[信息]${GN} 在${BL} ${name}${GN} 内执行，输出: ${CL}"
  if ! pct exec "$container" -- bash -c "command ${custom_command} >/dev/null 2>&1"; then
    echo -e "${BL}[信息]${GN} 跳过 ${name} ${RD}$container 没有命令: ${custom_command}"
  else
    pct exec "$container" -- bash -c "${custom_command}" | tee
  fi
}

for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    echo -e "${BL}[信息]${GN} 跳过 ${BL}$container${CL}"
  else
    os=$(pct config "$container" | awk '/^ostype/ {print $2}')
    if [ "$os" != "debian" ] && [ "$os" != "ubuntu" ]; then
      echo -e "${BL}[信息]${GN} 跳过 ${name} ${RD}$container 不是 Debian 或 Ubuntu ${CL}"
      continue
    fi

    status=$(pct status "$container")
    template=$(pct config "$container" | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[信息]${GN} 正在启动${BL} $container ${CL}"
      pct start "$container"
      echo -e "${BL}[信息]${GN} 等待${BL} $container${CL}${GN} 启动 ${CL}"
      sleep 5
      execute_in "$container"
      echo -e "${BL}[信息]${GN} 正在关闭${BL} $container ${CL}"
      pct shutdown "$container" &
    elif [ "$status" == "status: running" ]; then
      execute_in "$container"
    fi
  fi
done

wait

echo -e "${GN} 完成，已在选定的容器内执行命令。${CL} \n"
