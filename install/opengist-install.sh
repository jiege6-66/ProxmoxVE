#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://opengist.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y git
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "opengist" "thomiceli/opengist" "prebuild" "latest" "/opt/opengist" "opengist*linux-amd64.tar.gz"
mkdir -p /opt/opengist-data
sed -i 's|opengist-home:.*|opengist-home: /opt/opengist-data|' /opt/opengist/config.yml

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/opengist.service
[Unit]
Description=Opengist server to manage your Gists
After=network.target

[Service]
WorkingDirectory=/opt/opengist
ExecStart=/opt/opengist/opengist --config /opt/opengist/config.yml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now opengist
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
