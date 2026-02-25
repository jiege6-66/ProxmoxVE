#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sbondCo/Watcharr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y gcc
msg_ok "已安装依赖"

setup_go
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "watcharr" "sbondCo/Watcharr" "tarball"

msg_info "设置 Watcharr"
cd /opt/watcharr
$STD npm i
$STD npm run build
mv ./build ./server/ui
cd server
export CGO_ENABLED=1 GOOS=linux
$STD go mod download
$STD go build -o ./watcharr
msg_ok "设置 Watcharr"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/watcharr.service
[Unit]
Description=Watcharr Service
After=network.target

[Service]
WorkingDirectory=/opt/watcharr/server
ExecStart=/opt/watcharr/server/watcharr
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now watcharr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
