#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pocketbase.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "pocketbase" "pocketbase/pocketbase" "prebuild" "latest" "/opt/pocketbase" "pocketbase*linux_amd64.zip"

msg_info "正在配置 Pocketbase"
mkdir -p /opt/pocketbase/{pb_public,pb_migrations,pb_hooks}
msg_ok "已配置 Pocketbase"

msg_info "正在创建 service"
cat <<EOF >/etc/systemd/system/pocketbase.service
[Unit]
Description = pocketbase

[Service]
Type           = simple
LimitNOFILE    = 4096
Restart        = always
RestartSec     = 5s
StandardOutput = append:/opt/pocketbase/errors.log
StandardError  = append:/opt/pocketbase/errors.log
ExecStart      = /opt/pocketbase/pocketbase serve --http=0.0.0.0:8080

[Install]
WantedBy = multi-user.target
EOF
systemctl enable -q --now pocketbase
msg_ok "Service created"

motd_ssh
customize
cleanup_lxc
