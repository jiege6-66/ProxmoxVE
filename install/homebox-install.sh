#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sysadminsmedia/homebox

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "homebox" "sysadminsmedia/homebox" "prebuild" "latest" "/opt/homebox" "homebox_Linux_x86_64.tar.gz"

msg_info "正在配置 Homebox"
chmod +x /opt/homebox/homebox
cat <<EOF >/opt/homebox/.env
# For possible environment variables check here: https://homebox.software/en/configure-homebox
HBOX_MODE=production
HBOX_WEB_PORT=7745
HBOX_WEB_HOST=0.0.0.0
EOF
msg_ok "已配置 Homebox"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/homebox.service
[Unit]
Description=Start Homebox Service
After=network.target

[Service]
WorkingDirectory=/opt/homebox
ExecStart=/opt/homebox/homebox
EnvironmentFile=/opt/homebox/.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homebox
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
