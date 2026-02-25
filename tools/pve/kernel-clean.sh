#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    __ __                     __   ________
   / //_/__  _________  ___  / /  / ____/ /__  ____ _____
  / ,< / _ \/ ___/ __ \/ _ \/ /  / /   / / _ \/ __ `/ __ \
 / /| /  __/ /  / / / /  __/ /  / /___/ /  __/ /_/ / / / /
/_/ |_\___/_/  /_/ /_/\___/_/   \____/_/\___/\__,_/_/ /_/

EOF
}

# Color variables
YW="\033[33m"
GN="\033[1;92m"
RD="\033[01;31m"
CL="\033[m"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "kernel-clean" "pve"

# Detect current kernel
current_kernel=$(uname -r)
available_kernels=$(dpkg --list | grep 'kernel-.*-pve' | awk '{print $2}' | grep -v "$current_kernel" | sort -V)

header_info

if [ -z "$available_kernels" ]; then
  echo -e "${GN}未检测到旧内核。当前内核: ${current_kernel}${CL}"
  exit 0
fi

echo -e "${GN}当前运行的内核: ${current_kernel}${CL}"
echo -e "${YW}可移除的内核:${CL}"
echo "$available_kernels" | nl -w 2 -s '. '

echo -e "\n${YW}选择要移除的内核（用逗号分隔，例如 1,2）:${CL}"
read -r selected

# Parse selection
IFS=',' read -r -a selected_indices <<<"$selected"
kernels_to_remove=()

for index in "${selected_indices[@]}"; do
  kernel=$(echo "$available_kernels" | sed -n "${index}p")
  if [ -n "$kernel" ]; then
    kernels_to_remove+=("$kernel")
  fi
done

if [ ${#kernels_to_remove[@]} -eq 0 ]; then
  echo -e "${RD}未进行有效选择。正在退出。${CL}"
  exit 1
fi

# Confirm removal
echo -e "${YW}将要移除的内核:${CL}"
printf "%s\n" "${kernels_to_remove[@]}"
read -rp "是否继续移除？(y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo -e "${RD}已中止。${CL}"
  exit 1
fi

# Remove kernels
for kernel in "${kernels_to_remove[@]}"; do
  echo -e "${YW}正在移除 $kernel...${CL}"
  if apt-get purge -y "$kernel" >/dev/null 2>&1; then
    echo -e "${GN}成功移除: $kernel${CL}"
  else
    echo -e "${RD}移除失败: $kernel。请检查依赖关系。${CL}"
  fi
done

# Clean up and update GRUB
echo -e "${YW}正在清理...${CL}"
apt-get autoremove -y >/dev/null 2>&1 && update-grub >/dev/null 2>&1
echo -e "${GN}清理和 GRUB 更新完成。${CL}"
