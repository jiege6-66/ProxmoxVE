#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

clear
if command -v pveversion >/dev/null 2>&1; then
  echo -e "⚠️  无法从 Proxmox Shell 运行"
  exit
fi
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
APP="Home Assistant Core"
while true; do
  read -p "这将从备份恢复 ${APP}。是否继续(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "请回答 yes 或 no。" ;;
  esac
done
clear
function header_info {
  cat <<"EOF"
    __  __                        ___              _      __              __     ______              
   / / / /___  ____ ___  ___     /   |  __________(_)____/ /_____ _____  / /_   / ____/___  ________ 
  / /_/ / __ \/ __ `__ \/ _ \   / /| | / ___/ ___/ / ___/ __/ __ `/ __ \/ __/  / /   / __ \/ ___/ _ \
 / __  / /_/ / / / / / /  __/  / ___ |(__  |__  ) (__  ) /_/ /_/ / / / / /_   / /___/ /_/ / /  /  __/
/_/ /_/\____/_/ /_/ /_/\___/  /_/  |_/____/____/_/____/\__/\__,_/_/ /_/\__/   \____/\____/_/   \___/ 
                                     RESTORE FROM BACKUP                                
EOF
}

header_info

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "core-restore" "pve"

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}
function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}
function msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}
if [ -z "$(ls -A /root/.homeassistant/backups/)" ]; then
  msg_error "未找到备份！\n"
  exit 1
fi
DIR=/root/.homeassistant/restore
if [ -d "$DIR" ]; then
  msg_ok "恢复目录已存在。"
else
  mkdir -p /root/.homeassistant/restore
  msg_ok "已创建恢复目录。"
fi
cd /root/.homeassistant/backups/
PS3="请输入您的选择: "
files="$(ls -A .)"
select filename in ${files}; do
  msg_ok "您选择了 ${BL}${filename}${CL}"
  break
done
msg_info "正在停止 Home Assistant"
sudo service homeassistant stop
msg_ok "已停止 Home Assistant"
msg_info "正在使用 ${filename} 恢复 Home Assistant"
tar xvf ${filename} -C /root/.homeassistant/restore &>/dev/null
cd /root/.homeassistant/restore
tar -xvf homeassistant.tar.gz &>/dev/null
if ! command -v rsync >/dev/null 2>&1; then apt-get install -y rsync &>/dev/null; fi
rsync -a /root/.homeassistant/restore/data/ /root/.homeassistant
rm -rf /root/.homeassistant/restore/*
msg_ok "恢复完成"
msg_ok "正在启动 Home Assistant \n"
sudo service homeassistant start
