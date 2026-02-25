#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bluenviron/mediamtx

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "正在安装依赖"
$STD apt install -y ffmpeg
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "mediamtx" "bluenviron/mediamtx" "prebuild" "latest" "/opt/mediamtx" "mediamtx*linux_amd64.tar.gz"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/mediamtx.service
[Unit]
Description=MediaMTX
After=syslog.target network-online.target

[Service]
ExecStart=/opt/mediamtx/./mediamtx
WorkingDirectory=/opt/mediamtx
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mediamtx
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
