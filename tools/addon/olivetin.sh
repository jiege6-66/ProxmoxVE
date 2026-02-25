#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
   ____  ___          _______     
  / __ \/ (_)   _____/_  __(_)___ 
 / / / / / / | / / _ \/ / / / __ \
/ /_/ / / /| |/ /  __/ / / / / / /
\____/_/_/ |___/\___/_/ /_/_/ /_/ 
                                  
EOF
}

IP=$(hostname -I | awk '{print $1}')
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
APP="OliveTin"
hostname="$(hostname)"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "olivetin" "addon"

set-e
header_info

while true; do
  read -p "这将在 $hostname 上安装 ${APP}。是否继续(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "请回答 yes 或 no。" ;;
  esac
done
header_info

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "正在安装 ${APP}"
if ! command -v curl &>/dev/null; then
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
curl -fsSL "https://github.com/OliveTin/OliveTin/releases/latest/download/OliveTin_linux_amd64.deb" -o $(basename "https://github.com/OliveTin/OliveTin/releases/latest/download/OliveTin_linux_amd64.deb")
dpkg -i OliveTin_linux_amd64.deb &>/dev/null
systemctl enable --now OliveTin &>/dev/null
rm OliveTin_linux_amd64.deb
msg_ok "已在 $hostname 上安装 ${APP}"

msg_ok "成功完成！\n"
echo -e "${APP} 应该可以通过以下 URL 访问。
         ${BL}http://$IP:1337${CL} \n"
