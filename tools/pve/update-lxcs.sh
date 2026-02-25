#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
   __  __          __      __          __   _  ________
  / / / /___  ____/ /___ _/ /____     / /  | |/ / ____/
 / / / / __ \/ __  / __ `/ __/ _ \   / /   |   / /
/ /_/ / /_/ / /_/ / /_/ / /_/  __/  / /___/   / /___
\____/ .___/\__,_/\__,_/\__/\___/  /_____/_/|_\____/
    /_/

EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
CM='\xE2\x9C\x94\033'
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "update-lxcs" "pve"

header_info
echo "加载中..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE LXC 更新器" --yesno "这将更新 LXC 容器。是否继续？" 10 58
if whiptail --backtitle "Proxmox VE Helper Scripts" --title "跳过未运行的容器" --yesno "您想跳过当前未运行的容器吗？" 10 58; then
  SKIP_STOPPED="yes"
else
  SKIP_STOPPED="no"
fi

NODE=$(hostname)
EXCLUDE_MENU=()
MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  EXCLUDE_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
excluded_containers=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Containers on $NODE" --checklist "\n选择要跳过更新的容器:\n" 16 $((MSG_MAX_LENGTH + 23)) 6 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

function needs_reboot() {
  local container=$1
  local os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  local reboot_required_file="/var/run/reboot-required.pkgs"
  if [ -f "$reboot_required_file" ]; then
    if [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
      if pct exec "$container" -- [ -s "$reboot_required_file" ]; then
        return 0
      fi
    fi
  fi
  return 1
}

function update_container() {
  container=$1
  header_info
  name=$(pct exec "$container" hostname)
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')
  if [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "fedora" ]]; then
    disk_info=$(pct exec "$container" df /boot | awk 'NR==2{gsub("%","",$5); printf "%s %.1fG %.1fG %.1fG", $5, $3/1024/1024, $2/1024/1024, $4/1024/1024 }')
    read -ra disk_info_array <<<"$disk_info"
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}Boot Disk: ${disk_info_array[0]}% full [${disk_info_array[1]}/${disk_info_array[2]} used, ${disk_info_array[3]} free]${CL}\n"
  else
    echo -e "${BL}[Info]${GN} Updating ${BL}$container${CL} : ${GN}$name${CL} - ${YW}[No disk info for ${os}]${CL}\n"
  fi
  case "$os" in
  alpine) pct exec "$container" -- ash -c "apk -U upgrade" ;;
  archlinux) pct exec "$container" -- bash -c "pacman -Syyu --noconfirm" ;;
  fedora | rocky | centos | alma) pct exec "$container" -- bash -c "dnf -y update && dnf -y upgrade" ;;
  ubuntu | debian | devuan) pct exec "$container" -- bash -c "apt-get update 2>/dev/null | grep 'packages.*upgraded'; apt list --upgradable && apt-get -yq dist-upgrade 2>&1; rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED || true" ;;
  opensuse) pct exec "$container" -- bash -c "zypper ref && zypper --non-interactive dup" ;;
  esac
}

containers_needing_reboot=()
header_info
for container in $(pct list | awk '{if(NR>1) print $1}'); do
  if [[ " ${excluded_containers[@]} " =~ " $container " ]]; then
    header_info
    echo -e "${BL}[信息]${GN} 跳过 ${BL}$container${CL}"
    sleep 1
  else
    status=$(pct status $container)
    if [ "$SKIP_STOPPED" == "yes" ] && [ "$status" == "status: stopped" ]; then
      header_info
      echo -e "${BL}[信息]${GN} 跳过 ${BL}$container${CL}${GN} (未运行)${CL}"
      sleep 1
      continue
    fi
    template=$(pct config $container | grep -q "template:" && echo "true" || echo "false")
    if [ "$template" == "false" ] && [ "$status" == "status: stopped" ]; then
      echo -e "${BL}[信息]${GN} 正在启动${BL} $container ${CL} \n"
      pct start $container
      echo -e "${BL}[信息]${GN} 等待${BL} $container${CL}${GN} 启动 ${CL} \n"
      sleep 5
      update_container $container
      echo -e "${BL}[信息]${GN} 正在关闭${BL} $container ${CL} \n"
      pct shutdown $container &
    elif [ "$status" == "status: running" ]; then
      update_container $container
    fi
    if pct exec "$container" -- [ -e "/var/run/reboot-required" ]; then
      # Get the container's hostname and add it to the list
      container_hostname=$(pct exec "$container" hostname)
      containers_needing_reboot+=("$container ($container_hostname)")
    fi
    # check if patchmon agent is present in container and run a report if found
    if pct exec "$container" -- [ -e "/usr/local/bin/patchmon-agent" ]; then
      echo -e "${BL}[信息]${GN} 在 ${BL} $container ${CL} 中找到 patchmon-agent，正在触发报告。\n"
      pct exec "$container" -- "/usr/local/bin/patchmon-agent" "report"
    fi
  fi
done
wait
header_info
echo -e "${GN}过程完成，容器已成功更新。${CL}\n"
if [ "${#containers_needing_reboot[@]}" -gt 0 ]; then
  echo -e "${RD}以下容器需要重启:${CL}"
  for container_name in "${containers_needing_reboot[@]}"; do
    echo "$container_name"
  done
fi
echo ""
