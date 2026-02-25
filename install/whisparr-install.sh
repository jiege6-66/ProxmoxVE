#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Whisparr/Whisparr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y sqlite3
msg_ok "已安装依赖"

fetch_and_deploy_from_url "https://whisparr.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore&arch=x64" /opt/Whisparr

msg_info "正在配置 Whisparr"
mkdir -p /var/lib/whisparr/
chmod 775 /var/lib/whisparr/
chmod 775 /opt/Whisparr
msg_ok "已配置 Whisparr"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/whisparr.service
[Unit]
Description=whisparr Daemon
After=syslog.target network.target

[Service]
UMask=0002
Type=simple
ExecStart=/opt/Whisparr/Whisparr -nobrowser -data=/var/lib/whisparr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now whisparr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
