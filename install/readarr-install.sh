#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://readarr.com/

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

msg_info "正在安装 Readarr"
mkdir -p /var/lib/readarr/
chmod 775 /var/lib/readarr/
cd /var/lib/readarr/
$STD curl -fsSL 'https://readarr.servarr.com/v1/update/develop/updatefile?os=linux&runtime=netcore&arch=x64' -o readarr.tar.gz
$STD tar -xvzf readarr.tar.gz
mv Readarr /opt
chmod 775 /opt/Readarr
rm -rf Readarr.develop.*.tar.gz
msg_ok "已安装 Readarr"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/readarr.service
[Unit]
Description=Readarr Daemon
After=syslog.target network.target
[Service]
UMask=0002
Type=simple
ExecStart=/opt/Readarr/Readarr -nobrowser -data=/var/lib/readarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl -q daemon-reload
systemctl enable --now -q readarr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
