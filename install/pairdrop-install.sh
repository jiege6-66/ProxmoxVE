#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://pairdrop.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "pairdrop" "schlagmichdoch/PairDrop" "tarball"

msg_info "正在配置 PairDrop"
cd /opt/pairdrop
$STD npm install
msg_ok "已安装 PairDrop"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/pairdrop.service
[Unit]
Description=PairDrop Service
After=network.target

[Service]
ExecStart=npm start
WorkingDirectory=/opt/pairdrop
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pairdrop
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
