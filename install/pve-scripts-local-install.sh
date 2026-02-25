#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

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
  sshpass \
  rsync \
  expect
msg_ok "Dependencies installed."

NODE_VERSION=24 setup_nodejs
fetch_and_deploy_gh_release "ProxmoxVE-Local" "jiege6-66/ProxmoxVE-Local" "tarball"

msg_info "正在安装 PVE Scripts local"
cd /opt/ProxmoxVE-Local
$STD npm install
cp .env.example .env
mkdir -p data
chmod 755 data

$STD npx prisma generate
$STD npx prisma migrate deploy

$STD npm run build
msg_ok "已安装 PVE Scripts local"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/pvescriptslocal.service
[Unit]
Description=PVEScriptslocal Service
After=network.target

[Service]
WorkingDirectory=/opt/ProxmoxVE-Local
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
Environment=NODE_ENV=production
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now pvescriptslocal
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
