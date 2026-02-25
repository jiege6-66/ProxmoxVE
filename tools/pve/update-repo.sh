#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: MickLesk
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
   __  __          __      __          ____                 
  / / / /___  ____/ /___ _/ /____     / __ \___  ____  ____ 
 / / / / __ \/ __  / __ `/ __/ _ \   / /_/ / _ \/ __ \/ __ \
/ /_/ / /_/ / /_/ / /_/ / /_/  __/  / _, _/  __/ /_/ / /_/ /
\____/ .___/\__,_/\__,_/\__/\___/  /_/ |_|\___/ .___/\____/ 
    /_/                                      /_/            
EOF
}

set -eEuo pipefail
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "update-repo" "pve"

header_info
echo "正在加载..."
NODE=$(hostname)

function update_container() {
  container=$1
  os=$(pct config "$container" | awk '/^ostype/ {print $2}')

  if [[ "$os" == "ubuntu" || "$os" == "debian" ]]; then
    echo -e "${BL}[信息]${GN} 正在检查 /usr/bin/update in ${BL}$container${CL} (OS: ${GN}$os${CL})"

    if pct exec "$container" -- [ -e /usr/bin/update ]; then
      if pct exec "$container" -- grep -q "jiege6-66/ProxmoxVE" /usr/bin/update; then
        echo -e "${RD}[无变化]${CL} /usr/bin/update 已是最新 in ${BL}$container${CL}.\n"
      elif pct exec "$container" -- grep -q -v "tteck" /usr/bin/update; then
        echo -e "${RD}[警告]${CL} /usr/bin/update in ${BL}$container${CL} 包含不同的条目 (${RD}tteck${CL}). 未做任何更改。\n"
      else
        pct exec "$container" -- bash -c "sed -i 's/tteck\\/Proxmox/community-scripts\\/ProxmoxVE/g' /usr/bin/update"

        if pct exec "$container" -- grep -q "jiege6-66/ProxmoxVE" /usr/bin/update; then
          echo -e "${GN}[成功]${CL} /usr/bin/update updated in ${BL}$container${CL}.\n"
        else
          echo -e "${RD}[错误]${CL} /usr/bin/update in ${BL}$container${CL} 无法正确更新.\n"
        fi
      fi
    else
      echo -e "${RD}[错误]${CL} /usr/bin/update 未找到 in container ${BL}$container${CL}.\n"
    fi
  else
    echo -e "${BL}[信息]${GN} 正在跳过 ${BL}$container${CL} (非 Debian/Ubuntu)\n"
  fi
}

header_info
for container in $(pct list | awk '{if(NR>1) print $1}'); do
  update_container "$container"
done

header_info
echo -e "${GN}处理已完成. 仓库已切换至 jiege6-66/ProxmoxVE.${CL}\n"
