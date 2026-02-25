#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Threadfin/Threadfin

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
  vlc
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "threadfin" "threadfin/threadfin" "singlefile" "latest" "/opt/threadfin" "Threadfin_linux_amd64"
mv /root/.threadfin /root/.threadfin_version
mkdir -p /root/.threadfin

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/threadfin.service
[Unit]
Description=Threadfin: M3U Proxy for Plex DVR and Emby/Jellyfin Live TV
After=syslog.target network.target
[Service]
Type=simple
WorkingDirectory=/opt/threadfin
ExecStart=/opt/threadfin/threadfin
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now threadfin
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
