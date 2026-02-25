#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gnmyt/myspeed

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  build-essential \
  ca-certificates \
  python3-setuptools
msg_ok "已安装依赖"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "myspeed" "gnmyt/myspeed" "prebuild" "latest" "/opt/myspeed" "MySpeed-*.zip"

msg_info "正在配置 MySpeed"
cd /opt/myspeed
$STD npm install
msg_ok "已安装 MySpeed"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/myspeed.service
[Unit]
Description=MySpeed
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node server
Restart=always
User=root
Environment=NODE_ENV=production
WorkingDirectory=/opt/myspeed 

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now myspeed
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
