#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Lucas Zampieri (zampierilucas) | MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Cleanuparr/Cleanuparr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "Cleanuparr" "Cleanuparr/Cleanuparr" "prebuild" "latest" "/opt/cleanuparr" "*linux-amd64.zip"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/cleanuparr.service
[Unit]
Description=Cleanuparr Daemon
After=syslog.target network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cleanuparr
ExecStart=/opt/cleanuparr/Cleanuparr
Restart=on-failure
RestartSec=5
Environment="PORT=11011"
Environment="CONFIG_DIR=/opt/cleanuparr/config"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cleanuparr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
