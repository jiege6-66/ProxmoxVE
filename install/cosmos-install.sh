#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://https://cosmos-cloud.io/

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
  openssl \
  snapraid \
  avahi-daemon \
  fdisk \
  mergerfs \
  unzip
msg_ok "已安装依赖"

setup_docker
fetch_and_deploy_gh_release "cosmos" "azukaar/Cosmos-Server" "prebuild" "latest" "/opt/cosmos" "cosmos-cloud-*-amd64.zip"

msg_info "正在设置 Cosmos"
cd /opt/cosmos
chmod +x /opt/cosmos/cosmos
msg_ok "Set up Cosmos"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/cosmos.service
[Unit]
Description=Cosmos Cloud service
ConditionFileIsExecutable=/opt/cosmos/start.sh

[Service]
StartLimitInterval=10
StartLimitBurst=5
ExecStart=/opt/cosmos/start.sh

WorkingDirectory=/opt/cosmos

Restart=always

RestartSec=2
EnvironmentFile=-/etc/sysconfig/CosmosCloud

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now cosmos
msg_info "已创建 Service"

motd_ssh
customize
cleanup_lxc
