#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Suwayomi/Suwayomi-Server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y libc++-dev
msg_ok "已安装依赖"

JAVA_VERSION=21 setup_java
fetch_and_deploy_gh_release "suwayomi-server" "Suwayomi/Suwayomi-Server" "binary"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/suwayomi-server.service
[Unit]
Description=Suwayomi-Server Service
After=network.target

[Service]
ExecStart=/usr/bin/suwayomi-server
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now suwayomi-server
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
