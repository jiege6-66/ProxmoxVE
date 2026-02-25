#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Sportarr/Sportarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "正在安装依赖"
$STD apt install -y \
  ffmpeg \
  gosu \
  sqlite3
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "sportarr" "Sportarr/Sportarr" "prebuild" "latest" "/opt/sportarr" "Sportarr-linux-x64-*.tar.gz"

msg_info "正在创建 Service"
cat <<EOF >/opt/sportarr/.env
Sportarr__DataPath="/opt/sportarr-data/config"
ASPNETCORE_URLS="http://*:1867"
ASPNETCORE_ENVIRONMENT="Production"
DOTNET_CLI_TELEMETRY_OPTOUT=1
DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
LIBVA_DRIVER_NAME=iHD
EOF
cat <<EOF >/etc/systemd/system/sportarr.service
[Unit]
Description=Sportarr Service
After=network.target

[Service]
EnvironmentFile=/opt/sportarr/.env
WorkingDirectory=/opt/sportarr
ExecStart=/opt/sportarr/Sportarr
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sportarr
msg_info "已创建 Service"

motd_ssh
customize
cleanup_lxc
