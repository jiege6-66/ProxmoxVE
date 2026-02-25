#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  cat <<"EOF"
   ______          __        _____                          
  / ____/___  ____/ /__     / ___/___  ______   _____  _____
 / /   / __ \/ __  / _ \    \__ \/ _ \/ ___/ | / / _ \/ ___/
/ /___/ /_/ / /_/ /  __/   ___/ /  __/ /   | |/ /  __/ /    
\____/\____/\__,_/\___/   /____/\___/_/    |___/\___/_/     
 
EOF
}
IP=$(hostname -I | awk '{print $1}')
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
APP="Coder Code Server"
hostname="$(hostname)"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "coder-code-server" "addon"

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
clear
header_info
if command -v pveversion >/dev/null 2>&1; then
  echo -e "⚠️  无法在 Proxmox 上安装 "
  exit
fi
if [ -e /etc/alpine-release ]; then
  echo -e "⚠️  无法在 Alpine 上安装"
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

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "正在安装依赖项"
apt-get update &>/dev/null
apt-get install -y curl &>/dev/null
apt-get install -y git &>/dev/null
msg_ok "已安装依赖项"

VERSION=$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest |
  grep "tag_name" |
  awk '{print substr($2, 3, length($2)-4) }')

msg_info "正在安装 Code-Server v${VERSION}"
curl -fOL https://github.com/coder/code-server/releases/download/v"$VERSION"/code-server_"${VERSION}"_amd64.deb &>/dev/null
dpkg -i code-server_"${VERSION}"_amd64.deb &>/dev/null
rm -rf code-server_"${VERSION}"_amd64.deb
mkdir -p ~/.config/code-server/
systemctl enable -q --now code-server@"$USER"
cat <<EOF >~/.config/code-server/config.yaml
bind-addr: 0.0.0.0:8680
auth: none
password: 
cert: false
EOF
systemctl restart code-server@"$USER"
msg_ok "已在 $hostname 上安装 Code-Server v${VERSION}"

echo -e "${APP} 应该可以通过以下 URL 访问。
         ${BL}http://$IP:8680${CL} \n"
