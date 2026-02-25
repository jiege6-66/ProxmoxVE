#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.unmanic.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖 (Patience)"
$STD apt install -y \
  ffmpeg \
  python3-pip
msg_ok "已安装依赖"

setup_hwaccel

msg_info "正在安装 Unmanic"
$STD pip3 install unmanic
msg_ok "已安装 Unmanic"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/unmanic.service
[Unit]
Description=Unmanic - Library Optimiser
After=network-online.target
StartLimitInterval=200
StartLimitBurst=3

[Service]
Type=simple
ExecStart=/usr/local/bin/unmanic
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q unmanic.service
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
