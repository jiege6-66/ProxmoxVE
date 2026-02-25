#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/excalidraw/excalidraw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y xdg-utils
msg_ok "已安装依赖"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
fetch_and_deploy_gh_release "excalidraw" "excalidraw/excalidraw" "tarball"

msg_info "正在配置 Excalidraw"
cd /opt/excalidraw
$STD yarn
msg_ok "设置 Excalidraw"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/excalidraw.service
[Unit]
Description=Excalidraw Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/excalidraw
ExecStart=/usr/bin/yarn start --host
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now excalidraw
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
