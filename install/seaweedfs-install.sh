#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/seaweedfs/seaweedfs

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y fuse3
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "seaweedfs" "seaweedfs/seaweedfs" "prebuild" "latest" "/opt/seaweedfs" "linux_amd64.tar.gz"

msg_info "正在设置 SeaweedFS"
mkdir -p /opt/seaweedfs-data
ln -sf /opt/seaweedfs/weed /usr/local/bin/weed
msg_ok "Set up SeaweedFS"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/seaweedfs.service
[Unit]
Description=SeaweedFS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/seaweedfs
ExecStart=/opt/seaweedfs/weed server -dir=/opt/seaweedfs-data -master.port=9333 -volume.port=8080 -filer -s3
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seaweedfs
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
