#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: fstof
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/donetick/donetick

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y ca-certificates
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "donetick" "donetick/donetick" "prebuild" "latest" "/opt/donetick" "donetick_Linux_x86_64.tar.gz"

msg_info "设置 Donetick"
cd /opt/donetick
TOKEN=$(openssl rand -hex 16)
sed -i -e "s/change_this_to_a_secure_random_string_32_characters_long/${TOKEN}/g" config/selfhosted.yaml
msg_ok "设置 Donetick"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/donetick.service
[Unit]
Description=donetick Service
After=network.target

[Service]
Environment="DT_ENV=selfhosted"
WorkingDirectory=/opt/donetick
ExecStart=/opt/donetick/donetick
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now donetick
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
