#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
APP="CrowdSec"
hostname="$(hostname)"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "crowdsec" "addon"

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR

function error_exit() {
  trap - ERR
  local reason="Unknown failure occured."
  local msg="${1:-$reason}"
  local flag="${RD}‼ ERROR ${CL}$EXIT@$LINE"
  echo -e "$flag $msg" 1>&2
  exit "$EXIT"
}
if command -v pveversion >/dev/null 2>&1; then
  echo -e "⚠️  无法在 Proxmox 上安装 "
  exit
fi
while true; do
  read -p "这将在 $hostname 上安装 ${APP}。是否继续(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "请回答 yes 或 no。" ;;
  esac
done
clear
function header_info() {
  echo -e "${BL}
   _____                      _  _____           
  / ____|                    | |/ ____|          
 | |     _ __ _____      ____| | (___   ___  ___ 
 | |    |  __/ _ \ \ /\ / / _  |\___ \ / _ \/ __|
 | |____| | | (_) \ V  V / (_| |____) |  __/ (__ 
  \_____|_|  \___/ \_/\_/ \__ _|_____/ \___|\___|
${CL}"
}

header_info

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "正在设置 ${APP} 仓库"
apt-get update &>/dev/null
apt-get install -y curl &>/dev/null
apt-get install -y gnupg &>/dev/null
curl -fsSL "https://install.crowdsec.net" | bash &>/dev/null
msg_ok "已设置 ${APP} 仓库"

msg_info "正在安装 ${APP}"
apt-get update &>/dev/null
apt-get install -y crowdsec &>/dev/null
msg_ok "已在 $hostname 上安装 ${APP}"

msg_info "正在安装 ${APP} Common Bouncer"
apt-get install -y crowdsec-firewall-bouncer-iptables &>/dev/null
msg_ok "已安装 ${APP} Common Bouncer"

msg_ok "成功完成！\n"
