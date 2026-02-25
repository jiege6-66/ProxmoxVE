#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pymedusa/Medusa

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  git-core \
  mediainfo

cat <<EOF >/etc/apt/sources.list.d/non-free.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
EOF
$STD apt update
$STD apt install -y unrar
rm /etc/apt/sources.list.d/non-free.list
msg_ok "已安装依赖"

msg_info "正在安装 Medusa"
$STD git clone https://github.com/pymedusa/Medusa.git /opt/medusa
msg_ok "已安装 Medusa"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/medusa.service
[Unit]
Description=Medusa Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/medusa/start.py -q --nolaunch --datadir=/opt/medusa
TimeoutStopSec=25
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now medusa
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
