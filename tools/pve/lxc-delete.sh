#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____                                          __   _  ________   ____       __     __
   / __ \_________  _  ______ ___  ____  _  __   / /  | |/ / ____/  / __ \___  / /__  / /____
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / /   |   / /      / / / / _ \/ / _ \/ __/ _ \
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /___/   / /___   / /_/ /  __/ /  __/ /_/  __/
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|  /_____/_/|_\____/  /_____/\___/_/\___/\__/\___/

EOF
}

spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps -p $pid >/dev/null; do
    printf " [%c]  " "$spinstr"
    spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
    sleep $delay
    printf "\r"
  done
  printf "    \r"
}

set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
TAB="  "
CM="${TAB}✔️${TAB}${CL}"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "lxc-delete" "pve"

header_info
echo "加载中..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC 删除" --yesno "这将删除 LXC 容器。是否继续？" 10 58

NODE=$(hostname)
containers=$(pct list | tail -n +2 | awk '{print $0 " " $4}')

if [ -z "$containers" ]; then
  whiptail --title "LXC 容器删除" --msgbox "没有可用的 LXC 容器！" 10 60
  exit 1
fi

menu_items=("ALL" "删除所有容器" "OFF") # Add as first option
FORMAT="%-10s %-15s %-10s"

while read -r container; do
  container_id=$(echo $container | awk '{print $1}')
  container_name=$(echo $container | awk '{print $2}')
  container_status=$(echo $container | awk '{print $3}')
  formatted_line=$(printf "$FORMAT" "$container_name" "$container_status")
  menu_items+=("$container_id" "$formatted_line" "OFF")
done <<<"$containers"

CHOICES=$(whiptail --title "LXC 容器删除" \
  --checklist "选择要删除的 LXC 容器:" 25 60 13 \
  "${menu_items[@]}" 3>&2 2>&1 1>&3)

if [ -z "$CHOICES" ]; then
  whiptail --title "LXC 容器删除" \
    --msgbox "未选择容器！" 10 60
  exit 1
fi

read -p "手动还是自动删除容器？(默认: 手动) m/a: " DELETE_MODE
DELETE_MODE=${DELETE_MODE:-m}

selected_ids=$(echo "$CHOICES" | tr -d '"' | tr -s ' ' '\n')

# If "ALL" is selected, override with all container IDs
if echo "$selected_ids" | grep -q "^ALL$"; then
  selected_ids=$(echo "$containers" | awk '{print $1}')
fi

for container_id in $selected_ids; do
  status=$(pct status $container_id)

  if [ "$status" == "status: running" ]; then
    echo -e "${BL}[信息]${GN} 正在停止容器 $container_id...${CL}"
    pct stop $container_id &
    sleep 5
    echo -e "${BL}[信息]${GN} 容器 $container_id 已停止。${CL}"
  fi

  if [[ "$DELETE_MODE" == "a" ]]; then
    echo -e "${BL}[信息]${GN} 正在自动删除容器 $container_id...${CL}"
    pct destroy "$container_id" -f &
    pid=$!
    spinner $pid
    [ $? -eq 0 ] && echo "容器 $container_id 已删除。" || whiptail --title "错误" --msgbox "删除容器 $container_id 失败。" 10 60
  else
    read -p "删除容器 $container_id？(y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo -e "${BL}[信息]${GN} 正在删除容器 $container_id...${CL}"
      pct destroy "$container_id" -f &
      pid=$!
      spinner $pid
      [ $? -eq 0 ] && echo "容器 $container_id 已删除。" || whiptail --title "错误" --msgbox "删除容器 $container_id 失败。" 10 60
    else
      echo -e "${BL}[信息]${RD} 跳过容器 $container_id...${CL}"
    fi
  fi
done

header_info
echo -e "${GN}删除过程完成。${CL}\n"
