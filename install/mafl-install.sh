#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://mafl.hywax.space/

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
  build-essential
msg_ok "已安装依赖"

NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
fetch_and_deploy_gh_release "mafl" "hywax/mafl" "tarball"

msg_info "正在安装 Mafl"
mkdir -p /opt/mafl/data
curl -fsSL "https://raw.githubusercontent.com/hywax/mafl/main/.example/config.yml" -o "/opt/mafl/data/config.yml"
cd /opt/mafl
export NUXT_TELEMETRY_DISABLED=true
$STD yarn install
$STD yarn build
msg_ok "已安装 Mafl"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/mafl.service
[Unit]
Description=Mafl
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
WorkingDirectory=/opt/mafl/
ExecStart=yarn preview

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mafl
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
