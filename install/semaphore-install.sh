#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://semaphoreui.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  git \
  ansible
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "semaphore" "semaphoreui/semaphore" "binary" "latest" "/opt/semaphore" "semaphore_*_linux_amd64.deb"

msg_info "正在配置 Semaphore"
mkdir -p /opt/semaphore
cd /opt/semaphore
SEM_HASH=$(openssl rand -base64 32)
SEM_ENCRYPTION=$(openssl rand -base64 32)
SEM_KEY=$(openssl rand -base64 32)
SEM_PW=$(openssl rand -base64 12)
cat <<EOF >/opt/semaphore/config.json
{
  "bolt": {
    "host": "/opt/semaphore/semaphore_db.bolt"
  },
  "tmp_path": "/opt/semaphore/tmp",
  "cookie_hash": "${SEM_HASH}",
  "cookie_encryption": "${SEM_ENCRYPTION}",
  "access_key_encryption": "${SEM_KEY}"
}
EOF
$STD semaphore user add --admin --login admin --email admin@helper-scripts.com --name Administrator --password "${SEM_PW}" --config /opt/semaphore/config.json
echo "${SEM_PW}" >~/semaphore.creds
msg_ok "设置 Semaphore"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/semaphore.service
[Unit]
Description=Semaphore UI
Documentation=https://docs.semaphoreui.com/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/semaphore server --config /opt/semaphore/config.json
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now semaphore
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
