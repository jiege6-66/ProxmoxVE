#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TwiN/gatus

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  ca-certificates \
  libcap2-bin
msg_ok "已安装依赖"

setup_go
fetch_and_deploy_gh_release "gatus" "TwiN/gatus" "tarball"

msg_info "正在配置 gatus"
cd /opt/gatus
$STD go mod tidy
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
setcap CAP_NET_RAW+ep gatus
mv config.yaml config
msg_ok "已配置 gatus"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/gatus.service
[Unit]
Description=gatus Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gatus
ExecStart=/opt/gatus/gatus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gatus
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
