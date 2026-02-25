#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
  _      __    __         _
 | | /| / /__ / /  __ _  (_)__
 | |/ |/ / -_) _ \/  ' \/ / _ \
 |__/|__/\__/_.__/_/_/_/_/_//_/

EOF
}
set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
CM="${GN}✓${CL}"
BFR="\\r\\033[K"
HOLD="-"

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "webmin" "addon"

header_info

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Webmin 安装程序" --yesno "这将在此 LXC 容器上安装 Webmin。是否继续？" 10 58

msg_info "正在安装先决条件"
apt update &>/dev/null
apt-get -y install libnet-ssleay-perl libauthen-pam-perl libio-pty-perl unzip shared-mime-info curl &>/dev/null
msg_ok "已安装先决条件"

LATEST=$(curl -fsSL https://api.github.com/repos/webmin/webmin/releases/latest | grep '"tag_name":' | cut -d'"' -f4)

msg_info "正在下载 Webmin"
curl -fsSL "https://github.com/webmin/webmin/releases/download/$LATEST/webmin_${LATEST}_all.deb" -o $(basename "https://github.com/webmin/webmin/releases/download/$LATEST/webmin_${LATEST}_all.deb")
msg_ok "已下载 Webmin"

msg_info "正在安装 Webmin"
dpkg -i webmin_${LATEST}_all.deb &>/dev/null
/usr/share/webmin/changepass.pl /etc/webmin root root &>/dev/null
rm -rf /root/webmin_${LATEST}_all.deb
msg_ok "已安装 Webmin"

IP=$(hostname -I | cut -f1 -d ' ')
echo -e "安装成功！！Webmin 应该可以通过以下地址访问 ${BL}https://${IP}:10000${CL}"
