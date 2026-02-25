#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/duplicati/duplicati/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  libice6 \
  libsm6 \
  libfontconfig1
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "duplicati" "duplicati/duplicati" "binary" "latest" "/opt/duplicati" "duplicati-*-linux-x64-gui.deb"

msg_info "正在配置 duplicati"
DECRYPTKEY=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
ADMINPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
{
  echo "Admin password = ${ADMINPASS}"
  echo "Database encryption key = ${DECRYPTKEY}"
} >>~/duplicati.creds
msg_ok "已配置 duplicati"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/duplicati.service
[Unit]
Description=Duplicati Service
After=network.target

[Service]
ExecStart=/usr/bin/duplicati-server --webservice-interface=any --webservice-password=$ADMINPASS --settings-encryption-key=$DECRYPTKEY
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now duplicati
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
