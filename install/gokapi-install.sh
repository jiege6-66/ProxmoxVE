#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Forceu/Gokapi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "gokapi" "Forceu/Gokapi" "prebuild" "latest" "/opt/gokapi" "gokapi-linux_amd64.zip"

msg_info "正在配置 Gokapi"
mkdir -p /opt/gokapi/{data,config}
chmod +x /opt/gokapi/gokapi-linux_amd64
msg_ok "已配置 Gokapi"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/gokapi.service
[Unit]
Description=gokapi

[Service]
Type=simple
Environment=GOKAPI_DATA_DIR=/opt/gokapi/data
Environment=GOKAPI_CONFIG_DIR=/opt/gokapi/config
ExecStart=/opt/gokapi/gokapi-linux_amd64

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gokapi
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
