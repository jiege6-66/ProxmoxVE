#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: DragoQC
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://discopanel.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y build-essential
msg_ok "已安装依赖"

NODE_VERSION="22" setup_nodejs
setup_go
fetch_and_deploy_gh_release "discopanel" "nickheyer/discopanel" "tarball" "latest" "/opt/discopanel"
setup_docker

msg_info "正在设置 DiscoPanel"
cd /opt/discopanel
$STD make gen
cd /opt/discopanel/web/discopanel
$STD npm install
$STD npm run build
cd /opt/discopanel
$STD go build -o discopanel cmd/discopanel/main.go
msg_ok "设置 DiscoPanel"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/discopanel.service
[Unit]
Description=DiscoPanel Service
After=network.target

[Service]
WorkingDirectory=/opt/discopanel
ExecStart=/opt/discopanel/discopanel
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now discopanel
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
