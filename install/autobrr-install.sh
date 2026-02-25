#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://autobrr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "autobrr" "autobrr/autobrr" "prebuild" "latest" "/usr/local/bin" "autobrr_*_linux_x86_64.tar.gz"

msg_info "正在配置 Autobrr"
mkdir -p /root/.config/autobrr
cat <<EOF >>/root/.config/autobrr/config.toml
# https://autobrr.com/configuration/autobrr
host = "0.0.0.0"
port = 7474
logLevel = "DEBUG"
sessionSecret = "$(openssl rand -base64 24)"
EOF
msg_ok "已配置 Autobrr"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/autobrr.service
[Unit]
Description=autobrr service
After=syslog.target network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/autobrr --config=/root/.config/autobrr/

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q autobrr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
