#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.grandstream.com/products/networking-solutions/wi-fi-management/product/gwn-manager

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
    xfonts-utils \
    fontconfig
msg_ok "已安装依赖"

msg_info "正在设置 GWN Manager (Patience)"
RELEASE=$(curl -fsSL https://www.grandstream.com/support/tools#gwntools \
  | grep -oP 'https://firmware\.grandstream\.com/GWN_Manager-[^"]+-Ubuntu\.tar\.gz')
download_file "$RELEASE" "/tmp/gwnmanager.tar.gz"
cd /tmp
tar -xzf gwnmanager.tar.gz --strip-components=1
$STD ./install
msg_ok "设置 GWN Manager"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/gwnmanager.service
[Unit]
Description=GWN Manager
After=network.target
Requires=network.target

[Service]
Type=simple
WorkingDirectory=/gwn
ExecStart=/gwn/gwn start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q gwnmanager
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
