#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://uptime.kuma.pet/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装 dependencies"
$STD apt install -y chromium
msg_ok "已安装 dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "uptime-kuma" "louislam/uptime-kuma" "tarball"

msg_info "正在安装 Uptime Kuma"
cd /opt/uptime-kuma
$STD npm ci --omit dev
$STD npm run download-dist
msg_ok "已安装 Uptime Kuma"

msg_info "正在创建 Service"
ln -s /usr/bin/chromium /opt/uptime-kuma/chromium
cat <<EOF >/etc/systemd/system/uptime-kuma.service
[Unit]
Description=uptime-kuma

[Service]
Type=simple
Restart=always
User=root
WorkingDirectory=/opt/uptime-kuma
ExecStart=/usr/bin/npm start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now uptime-kuma
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
